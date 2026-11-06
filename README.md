<h1 align="center">wsl-clip-image</h1>

<p align="center">
  <em>Screenshot, then <code>Alt+V</code>. That's it.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/emmett001/wsl-clip-image?style=flat-square&color=111111&label=stars" alt="Stars">
  <img src="https://img.shields.io/badge/wsl2-Ubuntu-111111?style=flat-square" alt="WSL2 Ubuntu">
  <img src="https://img.shields.io/badge/works%20with-pi-111111?style=flat-square" alt="Works with pi">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT license">
</p>

<p align="center">
  <strong>Four steps down to two.</strong><br>
  <strong>Gone: "send to File Transfer" and "click Copy".</strong><br>
  <sub>Windows 11 · WSL2 Ubuntu · pi · measured 82–125 ms</sub>
</p>

<p align="center">
  <sub><a href="i18n/README.zh-CN.md">简体中文</a> &middot; <a href="i18n/README.ja.md">日本語</a> &middot; <a href="i18n/README.ko.md">한국어</a> &middot; <a href="i18n/README.fr.md">Français</a> &middot; <a href="i18n/README.ru.md">Русский</a></sub>
</p>

---

## The two extra steps

You want the agent in your terminal to look at an error dialog.

`Alt+A`, drag a box, `Enter`. The image sits on the clipboard.

Back in the terminal, `Ctrl+V`. Nothing happens.

So you open WeChat, find File Transfer, send the image, wait for it to show up, right-click, Copy.

Back to the terminal, `Ctrl+V` again. Now something arrives — a line like `F:\xwechat_files\wxid_xxx\temp\RWTemp\...png`.

It works. Your agent can read that path too. But to paste one screenshot you opened a chat app, sent a message and clicked Copy once.

## After

```
Alt+A screenshot  →  Alt+V  →  /tmp/pi-clipboard-3f2a91c8-....png
```

Press `Alt+V` and the program reads the clipboard itself, writes a file, and drops the path into the input box.

WeChat `Alt+A` works. Windows `Win+Shift+S` works too.

## Install

```bash
sudo apt install -y wl-clipboard imagemagick
git clone https://github.com/emmett001/wsl-clip-image.git ~/.agents/skills/wsl-clip-image
```

Then `Alt+A` → `Enter` → `Alt+V`. pi picks the skill up on its next start.

Not using pi? One command:

```console
$ git clone https://github.com/emmett001/wsl-clip-image.git
$ wsl-clip-image/scripts/grab.sh
/tmp/wslclip-20261106-174535-2946895.png
```

`grab.sh` prints a Linux path. `cat`, `identify` and `cp` take it as is.

## Where it has been tested

| | |
|-|-|
| Tested | Windows 11 · WSL2 Ubuntu · Windows Terminal · pi 1.5.0 |
| Tested | `grab.sh` called from any script on the same setup |
| Untested | Other agents, other terminals, other distros, WSL1, native Linux, macOS |

`Alt+V` is pi's own binding. Another agent brings its own key, and its own idea of image paths.
`grab.sh` leans on bash and system tools, so it should travel further. Untested so far.

## Numbers

One 1920x1020 screenshot, same machine:

| Path | Time |
|-|-|
| `wl-paste` (inside pi) | 82–125 ms |
| `wl-paste` + ImageMagick (`grab.sh`) | 210 ms |
| PowerShell fallback | 660–1709 ms |

`wl-clipboard` is the dividing line: 5–17x.

## When it will not paste

```console
$ scripts/doctor.sh
== 1. WSL interop ==          ok  binfmt WSLInterop registered
== 2. powershell.exe ==       ok  runnable
== 3. WSL clipboard tools ==  ok  wl-paste present, fast path available: image/bmp
== 4. Windows clipboard ==    ok  image captured, 82 ms
Verdict: path is usable
```

| Symptom | Fix |
|-|-|
| `Exec format error`, or `xxx.exe: 1: MZ...: not found` | `scripts/doctor.sh --fix` |
| "No image in clipboard" | Screenshot never completed, or another app grabbed the hotkey |
| `Alt+V` takes 1–2 s | `sudo apt install -y wl-clipboard` |
| An image "expires" | The process owning the clipboard exited. Take the shot again |

Two things that are easy to misremember:

| Common belief | What actually happens |
|-|-|
| The screenshot is stored on the clipboard as a file | It is stored as a bitmap. A file path shows up only after "send, then Copy" |
| You must send it to File Transfer first | The moment you press `Enter`, the clipboard already has it |

## Out of scope

Clipboard history and search, text copying, and pushing WSL images back to Windows.

## License

[MIT](LICENSE)
