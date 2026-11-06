#!/usr/bin/env bash
# 诊断 WSL → Windows 剪贴板的图片通道。加 --fix 自动修 WSL interop。
# 退出码：0 通；1 有故障
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PS1="$HERE/windows-clip.ps1"
FIX=0
[ "${1:-}" = "--fix" ] && FIX=1

PROBLEMS=0
note() { echo "  $1"; }
bad() { echo "  ✗ $1"; PROBLEMS=$((PROBLEMS + 1)); }
ok() { echo "  ✓ $1"; }

echo "== 1. WSL interop（调用 Windows exe 的前提）=="
if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
  ok "binfmt WSLInterop 已注册"
else
  bad "缺 binfmt WSLInterop，powershell.exe 无法执行"
  if [ "$FIX" = 1 ]; then
    echo "  → 重新注册"
    sudo systemctl restart systemd-binfmt 2>/dev/null
    if [ ! -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
      echo ':WSLInterop:M::MZ::/init:PF' | sudo tee /proc/sys/fs/binfmt_misc/register >/dev/null
    fi
    if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
      ok "已修复"
      PROBLEMS=$((PROBLEMS - 1))
    else
      note "仍失败：检查 /etc/wsl.conf 是否有 protectBinfmt=true"
    fi
  fi
fi

echo "== 2. powershell.exe 可执行 =="
PWSH="$(command -v powershell.exe || true)"
if [ -n "$PWSH" ] && (cd / && "$PWSH" -NoProfile -Command "'ok'" >/dev/null 2>&1); then
  ok "可执行（$PWSH）"
else
  bad "无法执行；症状为 cannot execute binary file: Exec format error"
fi

echo "== 3. WSL 侧剪贴板工具（只影响文本，图片一定走 PowerShell）=="
for t in wl-paste xclip xsel; do
  if command -v "$t" >/dev/null; then
    ok "$t 已安装"
  else
    note "$t 未安装（不影响读图）"
  fi
done
if command -v xclip >/dev/null; then
  TYPES="$(timeout 3 xclip -selection clipboard -t TARGETS -o 2>/dev/null | tr '\n' ' ')"
  note "X11 剪贴板类型：${TYPES:-<空>}"
fi

echo "== 4. Windows 剪贴板内容 =="
if [ "$PROBLEMS" -eq 0 ]; then
  cd / || exit 1
  "$PWSH" -STA -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$PS1")" -Action formats 2>&1 | tr -d '\r' | sed 's/^/  /'
  RESULT="$(cd / && "$PWSH" -STA -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$PS1")" -Action image -Out "$(wslpath -w /tmp/wslclip-doctor.png)" 2>&1 | tr -d '\r')"
  case "$RESULT" in
    ok:*) ok "取图成功：$RESULT" ;;
    *no-image*) note "剪贴板当前无图（正常，截一张再跑）" ;;
    *) bad "取图失败：$RESULT" ;;
  esac
  rm -f /tmp/wslclip-doctor.png
else
  note "跳过：interop 不通时读不到"
fi

echo "== 5. 粘贴键位提示 =="
case "${WT_SESSION:-}" in
  '') note "未检测到 Windows Terminal" ;;
  *) note "Windows Terminal：Ctrl+V 是终端自己的粘贴，剪贴板只有图片时无反应" ;;
esac
if command -v pi >/dev/null; then
  note "pi 在 WSL 下图片粘贴默认键是 Alt+V（不是 Ctrl+V）"
  note "自定义见 ~/.pi/agent/keybindings.json 的 app.clipboard.pasteImage"
fi

echo
if [ "$PROBLEMS" -eq 0 ]; then
  echo "结论：通道可用"
  exit 0
fi
echo "结论：$PROBLEMS 处故障；加 --fix 尝试修复 interop"
exit 1
