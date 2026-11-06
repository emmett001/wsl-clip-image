# wsl-clip-image

从 WSL 取 Windows 剪贴板里的图片，存成 PNG 路径。
用于把微信 `Alt+A` 截图、`Win+Shift+S` 截图、浏览器复制的图片直接喂给 WSL 里的程序。

## 装

作为 pi skill：

```bash
git clone https://github.com/<you>/wsl-clip-image.git ~/.agents/skills/wsl-clip-image
```

pi 会自动发现 `~/.agents/skills/*/SKILL.md`，之后可 `/skill:wsl-clip-image`。

不装 skill 也能直接用脚本：

```bash
~/workspace/wsl-clip-image/scripts/grab.sh
```

## 用

```bash
scripts/grab.sh                 # → /tmp/wslclip-20261106-171002-2922022.png
scripts/grab.sh --out shot.png  # 指定输出
scripts/doctor.sh               # 诊断
scripts/doctor.sh --fix         # 修 WSL interop（sudo）
```

## 为什么需要它

WSLg 的剪贴板桥只同步文本。Windows 截图放的是位图，WSL 侧 `xclip` / `wl-paste`
只能看到 `TEXT`、`UTF8_STRING`，拿不到位图。
唯一通路是调 Windows 的 `powershell.exe` 读 `Clipboard` 对象。

顺带解决一个高频误解：

- Windows Terminal 的 `Ctrl+V` 是终端自己的粘贴，剪贴板只有图片时无反应。
- pi 在 WSL 下图片粘贴默认键是 `Alt+V`。

正确顺序：`Alt+A` 选框 → `Enter` 完成 → 终端按 `Alt+V`。

## 内容

```
SKILL.md                        给 agent 的操作指引
scripts/grab.sh                 取图，打印路径
scripts/doctor.sh               诊断 / 修复
scripts/windows-clip.ps1        Windows 侧实现（image/formats/text/files）
references/clipboard-sources.md 各来源剪贴板格式实测
references/interop-unit.md      interop 开机自检单元
```

## 依赖

| 组件 | 必需 | 用途 |
|-|-|-|
| WSL2 | 是 | 运行环境 |
| Windows PowerShell 5.1 | 是 | 慢路径读剪贴板；`powershell.exe` 在 PATH 里 |
| `wslpath` | 是 | 路径转换，WSL 自带 |
| `wl-clipboard` | 强烈建议 | 快路径，`sudo apt install -y wl-clipboard` |
| `imagemagick` | 可选 | `grab.sh` 把桥给的 `image/bmp` 转 PNG |

耗时实测（1920x1020 截图）：

| 路径 | 耗时 |
|-|-|
| `wl-paste` + Photon（pi 内部粘贴） | 82–125 ms |
| `wl-paste` + ImageMagick（`grab.sh`） | 210 ms |
| 无 `wl-clipboard`，走 PowerShell | 660–1709 ms |

WSLg 的 Wayland 桥只提供 `image/bmp`，`xclip` 只能看到文本。

`windows-clip.ps1` 必须保持 **UTF-8 with BOM**，否则 PowerShell 5.1 按 GBK 解析中文并报语法错。

## 许可证

MIT
