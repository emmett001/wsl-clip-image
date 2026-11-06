# 剪贴板格式实测记录

环境：Windows 11 Pro + WSL2（WSLg）、微信 4.x、Windows Terminal。
探测方式：`scripts/windows-clip.ps1 -Action formats`。

## 微信 Alt+A，选框后按 Enter 完成（未发送）

```
formats:
  - DeviceIndependentBitmap
  - application/x-capturer-status
  - WeChatScreenshotFormat
  - image/png
  - image/bmp
  - image/jpeg
  - image/jpg
  - image/pbm
  - image/pgm
  - image/ppm
  - image/webp
  - image/xbm
  - image/xpm
image: 1920x1020
files: none
text: none
```

要点：

- **未发送前图片已在剪贴板**，不需要先发到文件传输助手。
- 有 `image/png`，`grab.sh` 走原始 PNG 分支。
- `WeChatScreenshotFormat` 是私有格式，标准 API 读不到，忽略。
- `files: none`，所以终端不会把它当文件路径粘贴。

## 微信发送后，在聊天里点"复制"

在上一组之外多出：

```
  - FileDrop
  - UniformResourceLocatorW
  - UniformResourceLocator
files:
  F:\xwechat_files\wxid_.../temp/RWTemp/2026-11/<hash>/<hash>.png
```

要点：

- `FileDrop` 指向微信临时目录里的 png。
- Windows Terminal 遇到剪贴板里的文件会粘贴其路径文本。
  这解释了"发送出去再复制，Ctrl+V 就能进终端"的老现象：
  进终端的是 `F:\...png` 路径字符串，不是图片。

## WSL 侧能看到的

```bash
$ xclip -selection clipboard -t TARGETS -o
TIMESTAMP
TARGETS
UTF8_STRING
TEXT
```

没有 `image/*`。WSLg 的剪贴板桥只同步文本，图像不同步。
`wl-paste` 未安装；即便安装，桥不给位图类型也一样读不到。

因此读图只有一条路：`powershell.exe` → `Clipboard.GetImage()` / `'PNG'` 流。

## 曾经踩到的环境故障

`/proc/sys/fs/binfmt_misc/WSLInterop` 丢失（`binfmt_misc` 已挂载但没注册 MZ 格式）。
`/usr/lib/binfmt.d/WSLInterop.conf` 存在，内容 `:WSLInterop:M::MZ::/init:PF`。
`systemctl restart systemd-binfmt` 可立即恢复。

失效期间的表现：`powershell.exe -c echo` 报
`cannot execute binary file: Exec format error`；Windows MCP 报
`uvx.exe: 1: MZ... not found`（把 exe 当 shell 脚本解释）。

## 热键冲突：Alt+A 不只微信在用

同一台机器上飞书（Lark）也默认注册 `Alt+A` 截图。
实测：激活微信主窗口后发 `Alt+A`，前台被飞书接管，剪贴板只出现

```
formats: UnicodeText, Locale, Text, OEMText
image: none
```

判断方法：截图完成后立刻跑 `windows-clip.ps1 -Action formats`。
`image:` 为 `none` 就是没截到位图（或热键被别的程序接管），
不是脚本的问题。改微信截图热键，或退出抢键的程序。

## 性能：wl-paste 快路径（2026-11-06 实测）

装 `wl-clipboard` 后，WSLg 的 Wayland 桥**能**给出位图：

```bash
$ wl-paste --list-types
image/bmp
$ wl-paste --type image/bmp --no-newline | wc -c
7833666          # 1920x1020 @32bpp
```

同一张 1920x1020 截图，pi 的 `readClipboardImage()` 连续 5 次：

```
run1 image/png 45702B 116ms
run2 image/png 45702B 100ms
run3 image/png 45702B  95ms
run4 image/png 45702B  99ms
run5 image/png 45702B 125ms
```

装之前走 PowerShell 时同一测试是 1709 ms。差约 17 倍。

pi 的转换逻辑（`dist/utils/clipboard-image.js`）：

```js
// Convert unsupported formats (e.g., Windows DIB data wrapped as BMP) to PNG
if (!isSupportedImageMimeType(image.mimeType)) {
    const pngBytes = await convertToPng(image.bytes);   // Photon
    ...
}
```

`image/bmp` 不在 pi 的直通白名单（png/jpeg/webp/gif），所以每次都走 Photon 转码，
这也是 7.8 MB 传输之外的第二笔开销。

桥的已知不完美：

- 即使剪贴板同时有 `image/png`，桥也只报 `image/bmp`。
- 极少数情况下报 `image/bmp` 但 `wl-paste` 输出 0 字节（延迟渲染的 HBITMAP 跨进程失效）。
  pi 此时退回 PowerShell；`grab.sh` 也会 fallback，所以不必处理。
