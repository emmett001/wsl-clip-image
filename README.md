<h1 align="center">wsl-clip-image</h1>

<p align="center">
  <em>截图，然后 <code>Alt+V</code>。就这样。</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/emmett001/wsl-clip-image?style=flat-square&color=111111&label=stars" alt="Stars">
  <img src="https://img.shields.io/badge/wsl2-Ubuntu-111111?style=flat-square" alt="WSL2 Ubuntu">
  <img src="https://img.shields.io/badge/works%20with-pi-111111?style=flat-square" alt="Works with pi">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT license">
</p>

<p align="center">
  <strong>四步变两步。</strong><br>
  <strong>去掉的是「发到文件传输助手」和「点复制」。</strong><br>
  <sub>Windows 11 · WSL2 Ubuntu · pi · 实测 82–125 ms</sub>
</p>

---

## 多出来的那两步

你想给终端里的 AI 看一眼报错。

`Alt+A`，选框，回车。图在剪贴板里了。

回终端，按 `Ctrl+V`。什么都没发生。

于是你打开微信，找到文件传输助手，把图发过去。等它出现在聊天记录里，右键，点「复制」。

再回终端，再按 `Ctrl+V`。这回有了——一行 `F:\xwechat_files\wxid_xxx\temp\RWTemp\...png`。

能用，AI 也读得懂。可你为了贴一张图，开了个聊天软件，发了条消息，点了一次复制。

## 装上之后

```
Alt+A 截图   →   Alt+V   →   /tmp/pi-clipboard-3f2a91c8-....png
```

按 `Alt+V`，程序自己去读剪贴板，写成文件，把路径放进输入框。

微信 `Alt+A` 可以，Windows 自带的 `Win+Shift+S` 也可以。

## 安装

```bash
sudo apt install -y wl-clipboard imagemagick
git clone https://github.com/emmett001/wsl-clip-image.git ~/.agents/skills/wsl-clip-image
```

之后：`Alt+A` → `Enter` → `Alt+V`。pi 在下次启动时加载这个 skill。

不用 pi 的，一条命令：

```console
$ git clone https://github.com/emmett001/wsl-clip-image.git
$ wsl-clip-image/scripts/grab.sh
/tmp/wslclip-20261106-174535-2946895.png
```

`grab.sh` 打印的是 Linux 路径，`cat`、`identify`、`cp` 都能直接用。

## 能用在什么环境

| | |
|-|-|
| 已实测 | Windows 11 · WSL2 Ubuntu · Windows Terminal · pi 1.5.0 |
| 已实测 | 同环境下由 `grab.sh` 供任意脚本调用 |
| 未验证 | 其他 AI 代理、其他终端、其他发行版、WSL1、原生 Linux、macOS |

`Alt+V` 是 pi 自己的键位。换代理，键位从哪来、认不认图片路径，都需要重新确认。
`grab.sh` 依赖 bash 与系统命令，可移植性更宽，其余环境尚未实测。

## 数字

同一张 1920x1020 截图，同机实测：

| 路径 | 耗时 |
|-|-|
| `wl-paste`（pi 内部粘贴） | 82–125 ms |
| `wl-paste` + ImageMagick（`grab.sh`） | 210 ms |
| PowerShell 兜底 | 660–1709 ms |

`wl-clipboard` 是快慢的分界，差 5–17 倍。

## 贴不上时

```console
$ scripts/doctor.sh
== 1. WSL interop ==          ✓ binfmt WSLInterop 已注册
== 2. powershell.exe ==       ✓ 可执行
== 3. WSL 侧剪贴板工具 ==     ✓ wl-paste 已装，快路径可用：image/bmp
== 4. Windows 剪贴板内容 ==   ✓ 取图成功，实际耗时 82 ms
结论：通道可用
```

| 症状 | 处理 |
|-|-|
| `Exec format error`，或 `xxx.exe: 1: MZ...: not found` | `scripts/doctor.sh --fix` |
| 报「剪贴板里没有图片」 | 截图没按 `Enter`，或热键被别的程序抢了 |
| `Alt+V` 卡 1–2 秒 | `sudo apt install -y wl-clipboard` |
| 图偶尔「过期」 | 提供剪贴板的进程退出了，重新截图 |

两处容易记错的地方：

| 常见的记法 | 实际发生的事 |
|-|-|
| 截图会以文件形式存进剪贴板 | 存的是位图。文件路径只在「发送后点复制」时出现 |
| 得先发到文件传输助手才能贴 | 按 `Enter` 完成的那一刻，剪贴板就已就绪 |

## 不管什么

剪贴板历史与搜索、文本复制、把 WSL 里的图送回 Windows。这三件事不在范围内。

## 许可

[MIT](LICENSE)
