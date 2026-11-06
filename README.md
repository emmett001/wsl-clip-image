# wsl-clip-image

> 把 Windows 剪贴板里的截图取到 WSL，一条命令拿到 PNG 路径。

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-WSL2%20%2B%20Windows%2011-lightgrey)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE)
![Dependencies](https://img.shields.io/badge/dependencies-none%20required-brightgreen)

在 WSL 里用微信 `Alt+A`、`Win+Shift+S`、浏览器「复制图片」之后，直接拿到可用路径。
附带一套诊断，定位「截图粘不进终端」到底是哪一层坏了。

---

## 目录

- [解决什么问题](#解决什么问题)
- [快速开始](#快速开始)
- [用法](#用法)
- [工作原理](#工作原理)
- [性能](#性能)
- [故障排查](#故障排查)
- [常见误解](#常见误解)
- [项目结构](#项目结构)
- [贡献](#贡献)
- [许可证](#许可证)

## 解决什么问题

WSLg 的剪贴板桥只给 Wayland 客户端传位图，`xclip` 这类 X11 工具只看得到文本。
于是「Windows 截图 → WSL 程序」这条链经常断，表现为：

- 在终端按 `Ctrl+V` 毫无反应
- 想喂给 AI 编程助手一张截图，只能先存文件再手动敲路径
- 明明剪贴板里有图，脚本却报「没有图片」

这个仓库给你一条稳定的取图命令，和一套能定位问题的检查。

## 快速开始

### 作为 pi skill

```bash
git clone https://github.com/emmett001/wsl-clip-image.git ~/.agents/skills/wsl-clip-image
```

pi 会自动发现 `~/.agents/skills/*/SKILL.md`，之后可用 `/skill:wsl-clip-image`。

### 直接当脚本用

```bash
git clone https://github.com/emmett001/wsl-clip-image.git
cd wsl-clip-image

sudo apt install -y wl-clipboard imagemagick   # 强烈建议，快 5–17 倍
scripts/grab.sh
```

输出：

```
/tmp/wslclip-20261106-172417-2929208.png
```

### 依赖

| 组件 | 必需 | 用途 |
|-|-|-|
| WSL2（WSLg） | 是 | 运行环境 |
| Windows PowerShell 5.1 | 是 | 慢路径读剪贴板 |
| `wslpath` | 是 | 路径转换，WSL 自带 |
| `wl-clipboard` | 强烈建议 | 快路径，`~0.1s` vs `~1.7s` |
| `imagemagick` | 可选 | 把桥给的 `image/bmp` 转 PNG |

## 用法

```bash
scripts/grab.sh                 # 取图，打印 WSL 路径
scripts/grab.sh --out shot.png  # 指定输出文件
scripts/grab.sh --dir ~/shots   # 指定输出目录
scripts/grab.sh --no-fast       # 跳过快路径，只用 PowerShell
```

退出码：

| 码 | 含义 |
|-|-|
| `0` | 成功 |
| `1` | 剪贴板里没有图片 |
| `2` | 环境不可用（interop 断开、找不到 `powershell.exe`） |

诊断与修复：

```bash
scripts/doctor.sh          # 逐层检查并打印实际耗时
scripts/doctor.sh --fix    # 修 WSL interop，需要 sudo
```

Windows 侧实现可单独调用：

```bash
powershell.exe -STA -NoProfile -File scripts/windows-clip.ps1 -Action formats
# Action: image | formats | text | files
```

## 工作原理

两条路径，快的先试。

```
grab.sh
  │
  ├─ 快路径 (~0.1s)
  │    wl-paste --list-types
  │      ├─ image/png → 原始字节直接落盘
  │      ├─ image/bmp → convert bmp:- png:（ImageMagick）
  │      └─ 只有文本   → 转慢路径
  │
  └─ 慢路径 (~0.7–1.7s)
       powershell.exe -STA -File windows-clip.ps1
         ├─ 确认 binfmt WSLInterop 已注册
         ├─ cd /              深目录下 exe 起不来（\\wsl.localhost\ 超 260 字符）
         ├─ 剪贴板 'PNG' 原始字节优先（无损）
         └─ 退化到 Clipboard::GetImage() 存 PNG
```

三层世界：

```
① Windows 会话    微信/截图工具 → 写剪贴板数据对象
                  Windows Terminal → 按键的第一道关
        │
        │ WSLg 剪贴板桥（cliprdr）+ binfmt interop
        │
② WSL2 虚拟机     Wayland 剪贴板 / X11 剪贴板
        │
③ pi 或你的脚本   wl-paste → xclip → powershell.exe
```

几个关键事实：

- 剪贴板是「格式袋」，同一份内容可有多种表示（`CF_DIB`、`PNG`、`CF_HDROP`、文本）。
- 微信 `Alt+A` 按 `Enter` 完成时只写位图，**不带** `CF_HDROP`；发送后点「复制」才带文件路径。
- `Ctrl+V` 被 Windows Terminal 截获：有文本粘文本，有 `CF_HDROP` 粘路径，只有位图则静默。
- X11 侧（`xclip`）看不到位图，只有 `TEXT` / `UTF8_STRING`。
- WSL 执行 `.exe` 依赖内核 `binfmt_misc` 的 `:WSLInterop:M::MZ::/init:PF` 注册项；它丢了会报 `Exec format error`。

## 性能

同一张 1920x1020 全屏截图，同机实测：

| 路径 | 耗时 | 说明 |
|-|-|-|
| `wl-paste` + Photon（pi 内部粘贴） | 82–125 ms | 装 `wl-clipboard` |
| `wl-paste` + ImageMagick（`grab.sh`） | 210 ms | 另需 `imagemagick` |
| PowerShell | 660–1709 ms | 无 `wl-clipboard` |

慢路径的耗时构成：

| 环节 | 量级 |
|-|-|
| PowerShell 进程冷启动 | ~680 ms |
| 两次 `Add-Type` 加载程序集 | 数百 ms |
| PNG 编码 1920x1020 | 数十到数百 ms |
| 9P 写 + 9P 读临时文件 | 数十 ms |

WSLg 的桥只报 `image/bmp`，1920x1020 约 **7.8 MB**。pi 用 Photon（Rust/WASM）转 PNG，
`grab.sh` 用 ImageMagick。这是快路径剩下的主要成本。

## 故障排查

| 症状 | 原因 | 处理 |
|-|-|-|
| `cannot execute binary file: Exec format error` | `binfmt WSLInterop` 未注册 | `scripts/doctor.sh --fix` |
| 其他工具报 `xxx.exe: 1: MZ...: not found` | 同上，exe 被当 shell 脚本读 | 同上 |
| 取图报「剪贴板里没有图片」 | 截图未完成（没按 `Enter`）或热键被别的程序接管 | 重截一次；见下条 |
| `Alt+A` 弹出别的程序 | 热键冲突，先注册者生效（如飞书也占 `Alt+A`） | 改微信截图热键 |
| 粘贴卡 1–2 秒 | 缺 `wl-clipboard`，落到 PowerShell 冷启动 | `sudo apt install -y wl-clipboard` |
| 图偶尔「过期」 | OLE 延迟渲染，提供者进程退出后数据消失 | 重新截图 |
| `doctor.sh` 报 interop 正常但仍无图 | 剪贴板本身没有位图 | `windows-clip.ps1 -Action formats` 看格式 |

排查顺序：

1. 按对键了吗（终端里 `Ctrl+V` 不等于应用自己的粘贴键）
2. 截图真的完成了吗
3. 剪贴板里是位图吗（`image:` 不是 `none`）
4. interop 通吗（`doctor.sh`）

## 常见误解

| 误解 | 实际 |
|-|-|
| 截图以「临时文件」存在剪贴板 | 存的是位图数据；文件路径只在发送后复制时出现 |
| `Ctrl+V` 能把图粘进终端 | 终端只处理文本和文件路径 |
| 必须先发到文件传输助手才能粘 | 不需要，`Alt+A` 完成时就已就绪 |
| 剪贴板里的图会一直在 | 延迟渲染，提供者退出即失效 |

## 项目结构

```
.
├── SKILL.md                        给 agent 用的操作指引
├── scripts/
│   ├── grab.sh                     取图，打印路径
│   ├── doctor.sh                   诊断 / 修复
│   └── windows-clip.ps1            Windows 侧实现
├── references/
│   ├── clipboard-sources.md        各来源剪贴板格式实测
│   └── interop-unit.md             interop 开机自检单元
└── LICENSE
```

## 贡献

欢迎 issue 与 PR。提交前请确认：

1. `scripts/windows-clip.ps1` 保持 **UTF-8 with BOM**，否则 PowerShell 5.1 按 GBK 解析中文并报语法错。
2. `scripts/grab.sh` 两条路径都要实测：`grab.sh` 与 `grab.sh --no-fast`。
3. 新的剪贴板来源，把 `windows-clip.ps1 -Action formats` 的输出补进 `references/clipboard-sources.md`。

## 许可证

[MIT](LICENSE)
