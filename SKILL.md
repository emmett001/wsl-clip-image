---
name: wsl-clip-image
description: 在 WSL 里取 Windows 剪贴板中的图片（微信 Alt+A 截图、Win+Shift+S、浏览器复制图片）并存成 PNG 路径；诊断终端粘贴图片无反应（WSL interop / binfmt 丢失）。Use when a Windows screenshot cannot be pasted into a WSL terminal, or when a Linux tool needs the image currently on the Windows clipboard.
license: MIT
compatibility: WSL2 + Windows PowerShell 5.1；WSL 侧需要 wslpath。
---

# WSL 剪贴板取图

把 Windows 剪贴板里的图片落到 WSL 文件系统，打印可用路径。
顺带诊断"截图后粘不进终端"的常见故障。

## 先看这一条：粘贴键不是 Ctrl+V

`Windows Terminal` 里 `Ctrl+V` 由终端自己处理，只粘文本。
剪贴板只有位图时，终端无文本可粘，按键不会转给应用，看起来就是"按了没反应"。

pi 在 WSL 下图片粘贴的默认键是 **`Alt+V`**（`app.clipboard.pasteImage`）。
它会把剪贴板图片写成 `/tmp/pi-clipboard-<uuid>.png` 并插入输入框。

微信截图正确顺序：

| 步 | 操作 |
|-|-|
| 1 | `Alt+A` 选框 |
| 2 | `Enter` 或点对勾完成（此时图片才进剪贴板） |
| 3 | 回终端按 `Alt+V` |

自定义键位写 `~/.pi/agent/keybindings.json`：

```json
{ "app.clipboard.pasteImage": "ctrl+alt+v" }
```

## 命令

脚本在本 skill 目录的 `scripts/` 下，用相对路径调用。

```bash
# 取图，打印 WSL 路径
scripts/grab.sh

# 指定输出位置
scripts/grab.sh --out ~/shots/now.png

# 诊断通道（interop、powershell、剪贴板格式、键位）
scripts/doctor.sh

# 修 WSL interop（需要 sudo）
scripts/doctor.sh --fix
```

`grab.sh` 退出码：`0` 成功；`1` 剪贴板无图；`2` 环境不可用。

`windows-clip.ps1` 可单独用，动作有 `image` / `formats` / `text` / `files`。

## 通道原理

两条路径，快的先试：

```
grab.sh
  │
  ├─ 快路径 (~0.1s)：wl-paste --list-types
  │       ├─ image/png → 原始字节直接落盘
  │       ├─ image/bmp → convert bmp:- png:（需 ImageMagick）
  │       └─ 只有文本 → 转慢路径
  │
  └─ 慢路径 (~0.7-1.7s)：powershell.exe -STA -File windows-clip.ps1
          ├─ 检查 /proc/sys/fs/binfmt_misc/WSLInterop
          ├─ cd /          ← 深目录下 exe 起不来（\\wsl.localhost\ 超 260 字符）
          ├─ 剪贴板 'PNG' 原始字节优先（无损）
          └─ 退化到 Clipboard::GetImage() 存 PNG
```

WSLg 的 Wayland 桥**能**给位图，但只报 `image/bmp`（1920x1020 约 7.8 MB）。
`xclip`（X11 侧）只能看到文本，拿不到位图。

实测耗时（1920x1020 全屏截图，同机）：

| 路径 | 耗时 | 条件 |
|-|-|-|
| wl-paste + Photon（pi 内部） | 82–125 ms | 装 `wl-clipboard` |
| wl-paste + ImageMagick（grab.sh） | 210 ms | 再装 `imagemagick` |
| PowerShell | 660–1709 ms | 无 `wl-clipboard` |

所以 **`wl-clipboard` 是性能关键，不是可选项**：差 5–17 倍。

## 故障：interop 丢了

症状：

| 现象 | 证据 |
|-|-|
| 终端粘贴图片无反应 | 剪贴板有图，但读不到 |
| 任何 exe 都跑不了 | `cannot execute binary file: Exec format error` |
| Windows MCP 起不来 | `uvx.exe: 1: MZ... not found` |
| `ls /proc/sys/fs/binfmt_misc/` | 只有 `register`、`status`，缺 `WSLInterop` |

修复：

```bash
scripts/doctor.sh --fix
```

`--fix` 先 `systemctl restart systemd-binfmt`，仍缺则直接写
`:WSLInterop:M::MZ::/init:PF` 到 `/proc/sys/fs/binfmt_misc/register`。

要长期有效，加一个开机自检单元，内容见 `references/interop-unit.md`。

## 坑

| 坑 | 规避 |
|-|-|
| 无 `wl-clipboard` 时粘贴要 1.7s，感觉像卡住 | `sudo apt install -y wl-clipboard`，降到 ~0.1s |
| WSLg 桥只报 `image/bmp`，一个 1920x1020 图要传 7.8 MB | 正常现象；pi 用 Photon 转 PNG，grab.sh 用 ImageMagick |
| 桥偶尔报 `image/bmp` 但数据 0 字节 | 退回 PowerShell 即可；`grab.sh` 自动 fallback |
| 剪贴板里的图会“过期”（提供者退出后消失） | 每次粘贴前重新截图；脚本会报 `剪贴板里没有图片` |
| `windows-clip.ps1` 存成无 BOM 的 UTF-8，PS 5.1 按 GBK 读中文，全篇语法错 | 文件保持 UTF-8 with BOM |
| PowerShell 输出中文乱码 | 脚本内设 `[Console]::OutputEncoding` 为 UTF-8；面向 WSL 的输出只用 ASCII |
| 从深目录启动 `powershell.exe` 失败 | 先 `cd /` |
| 剪贴板被截图工具占用 | `GetDataObject()` 重试；失败报 `clipboard-busy` |
| 只要 `GetImage()` 会丢色彩或透明 | 优先读 `'PNG'` 原始流 |
| 微信"发送后再复制"的图带 `FileDrop` | 那条路径会让终端粘出 `F:\...png` 文本；`Alt+A` 直接完成没有 `FileDrop`，反而更干净 |
| `Alt+A` 被别的程序抢走（飞书默认也注册 `Alt+A` 截图） | 热键先注册者生效。截图后 `windows-clip.ps1 -Action formats` 若显示 `image: none`，说明截的不是位图或热键被接管；改微信截图热键 |

截图后拿不到图，先按下面顺序排除，别改代码：

| 顺序 | 检查 | 命令 |
|-|-|-|
| 1 | 按对键了吗（`Alt+V` 不是 `Ctrl+V`） | — |
| 2 | 截图真的完成了吗（按了 `Enter`） | `windows-clip.ps1 -Action formats` |
| 3 | 剪贴板里是位图吗（`image:` 非 `none`） | 同上 |
| 4 | interop 通吗 | `doctor.sh` |

各来源的剪贴板格式实测值见 `references/clipboard-sources.md`。
