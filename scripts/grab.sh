#!/usr/bin/env bash
# 把 Windows 剪贴板里的图片存成 WSL 内的 PNG，打印绝对路径。
# 用法：
#   grab.sh                # 存到 /tmp/wslclip-<时间戳>.png，打印路径
#   grab.sh --out a.png    # 指定输出文件
#   grab.sh --dir ~/shots  # 指定输出目录
#   grab.sh --no-fast      # 跳过 wl-paste 快路径，只用 PowerShell
# 退出码：0 成功；1 剪贴板无图；2 环境不可用（interop / 无 powershell）
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PS1="$HERE/windows-clip.ps1"

OUT=""
DIR="/tmp"
FAST=1
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="${2:?--out 需要路径}"; shift 2 ;;
    --dir) DIR="${2:?--dir 需要目录}"; shift 2 ;;
    --no-fast) FAST=0; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 64 ;;
  esac
done

if [ -z "$OUT" ]; then
  mkdir -p "$DIR"
  OUT="$DIR/wslclip-$(date +%Y%m%d-%H%M%S)-$$.png"
fi
mkdir -p "$(dirname "$OUT")"
OUT_ABS="$(cd "$(dirname "$OUT")" && pwd -P)/$(basename "$OUT")"

is_png() {
  [ -s "$1" ] && [ "$(od -An -tx1 -N8 "$1" | tr -d ' \n')" = "89504e470d0a1a0a" ]
}

# 快路径：WSLg 的 Wayland 桥直接把位图交给 wl-paste，约 100ms
fast_path() {
  [ "$FAST" = 1 ] || return 1
  command -v wl-paste >/dev/null || return 1
  local types
  types="$(timeout 3 wl-paste --list-types 2>/dev/null)" || return 1
  rm -f "$OUT_ABS"
  case "$types" in
    *image/png*)
      timeout 10 wl-paste --type image/png --no-newline >"$OUT_ABS" 2>/dev/null
      is_png "$OUT_ABS" && return 0
      ;;
    *image/bmp*)
      command -v convert >/dev/null || return 1
      timeout 10 wl-paste --type image/bmp --no-newline 2>/dev/null \
        | convert bmp:- png:"$OUT_ABS" 2>/dev/null
      is_png "$OUT_ABS" && return 0
      ;;
  esac
  rm -f "$OUT_ABS"
  return 1
}

if fast_path; then
  echo "$OUT_ABS"
  exit 0
fi

# 慢路径：调 Windows PowerShell 读剪贴板，约 1.5s
if [ ! -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
  echo "error: WSL interop 不可用（缺 binfmt WSLInterop），无法调用 powershell.exe" >&2
  echo "hint: 运行 $(dirname "$HERE")/scripts/doctor.sh --fix" >&2
  exit 2
fi

PWSH="$(command -v powershell.exe || echo /mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe)"
if [ ! -x "$PWSH" ]; then
  echo "error: 找不到 powershell.exe（WSL interop 被禁用？）" >&2
  exit 2
fi

WIN_OUT="$(wslpath -w "$OUT_ABS")"
WIN_PS1="$(wslpath -w "$PS1")"

# 必须从浅目录启动 exe：\\wsl.localhost\... 超过 260 字符时 Windows 程序起不来
cd / || exit 2
RESULT="$("$PWSH" -STA -NoProfile -ExecutionPolicy Bypass -File "$WIN_PS1" -Action image -Out "$WIN_OUT" 2>&1 | tr -d '\r')"
CODE=$?

case "$RESULT" in
  ok:*)
    if ! is_png "$OUT_ABS"; then
      echo "error: 输出不是 PNG：$OUT_ABS" >&2
      exit 2
    fi
    echo "$OUT_ABS"
    exit 0
    ;;
  *no-image*)
    echo "error: 剪贴板里没有图片" >&2
    exit 1
    ;;
  *)
    echo "error: 读取失败（退出码 $CODE）：$RESULT" >&2
    exit 2
    ;;
esac
