<h1 align="center">wsl-clip-image</h1>

<p align="center">
  <em>スクリーンショットを撮って、<code>Alt+V</code>。それだけ。</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/emmett001/wsl-clip-image?style=flat-square&color=111111&label=stars" alt="Stars">
  <img src="https://img.shields.io/badge/wsl2-Ubuntu-111111?style=flat-square" alt="WSL2 Ubuntu">
  <img src="https://img.shields.io/badge/works%20with-pi-111111?style=flat-square" alt="Works with pi">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT license">
</p>

<p align="center">
  <strong>4 ステップが 2 ステップに。</strong><br>
  <strong>消えたのは「ファイル転送に送る」と「コピーを押す」。</strong><br>
  <sub>Windows 11 · WSL2 Ubuntu · pi · 実測 82–125 ms</sub>
</p>

<p align="center">
  <sub><a href="../README.md">English</a> &middot; <a href="README.zh-CN.md">简体中文</a></sub>
</p>

---

## 余計な 2 ステップ

ターミナルの中の AI に、エラーダイアログを見せたい。

`Alt+A` で範囲を選び、`Enter`。画像はクリップボードに入った。

ターミナルに戻って `Ctrl+V`。何も起きない。

そこで WeChat を開き、「ファイル転送」を探し、画像を送信し、表示されるのを待ち、右クリックして「コピー」。

ターミナルに戻り、もう一度 `Ctrl+V`。今度は入った。`F:\xwechat_files\wxid_xxx\temp\RWTemp\...png` のような 1 行が貼り付く。

使えるし、AI もそのパスを読める。でもスクリーンショット 1 枚のために、チャットアプリを開き、メッセージを 1 通送り、コピーを 1 回押した。

## 導入後

```
Alt+A で撮影  →  Alt+V  →  /tmp/pi-clipboard-3f2a91c8-....png
```

`Alt+V` を押すと、プログラムが自分でクリップボードを読み、ファイルに書き、パスを入力欄に入れる。

WeChat の `Alt+A` でも、Windows 標準の `Win+Shift+S` でも動く。

## インストール

```bash
sudo apt install -y wl-clipboard imagemagick
git clone https://github.com/emmett001/wsl-clip-image.git ~/.agents/skills/wsl-clip-image
```

そのあと `Alt+A` → `Enter` → `Alt+V`。pi は次回起動時にこの skill を読み込む。

pi を使わない場合:

```console
$ git clone https://github.com/emmett001/wsl-clip-image.git
$ wsl-clip-image/scripts/grab.sh
/tmp/wslclip-20261106-174535-2946895.png
```

`grab.sh` が返すのは Linux のパス。`cat` でも `identify` でも `cp` でも、そのまま使える。

## 動作確認済みの環境

| | |
|-|-|
| 確認済み | Windows 11 · WSL2 Ubuntu · Windows Terminal · pi 1.5.0 |
| 確認済み | 同じ環境で `grab.sh` を任意のスクリプトから呼ぶ場合 |
| 未確認 | 他のエージェント、他のターミナル、他のディストリビューション、WSL1、ネイティブ Linux、macOS |

`Alt+V` は pi 自身のキーバインド。別のエージェントでは、キーも画像パスの扱いも確認し直す必要がある。
`grab.sh` は bash とシステムコマンドに依存するので、他環境へ移しやすい。ただし実測はまだ。

## 数値

同じ 1920x1020 のスクリーンショット、同じマシンでの実測:

| 経路 | 時間 |
|-|-|
| `wl-paste`（pi 内部） | 82–125 ms |
| `wl-paste` + ImageMagick（`grab.sh`） | 210 ms |
| PowerShell フォールバック | 660–1709 ms |

速いか遅いかの分かれ目は `wl-clipboard`。5〜17 倍の差。

## 貼り付かないとき

```console
$ scripts/doctor.sh
== 1. WSL interop ==          正常  binfmt WSLInterop 登録済み
== 2. powershell.exe ==       正常  実行可能
== 3. WSL 側クリップボード == 正常  wl-paste あり、高速経路が使える: image/bmp
== 4. Windows クリップボード  正常  取得成功、82 ms
結論: 経路は使用可能
```

| 症状 | 対処 |
|-|-|
| `Exec format error`、または `xxx.exe: 1: MZ...: not found` | `scripts/doctor.sh --fix` |
| 「クリップボードに画像がない」 | スクリーンショットが未完了、または他のアプリがホットキーを取った |
| `Alt+V` に 1〜2 秒かかる | `sudo apt install -y wl-clipboard` |
| 画像がときどき「消える」 | クリップボードを提供していたプロセスが終了した。撮り直す |

間違えやすい 2 点:

| よくある思い込み | 実際に起きていること |
|-|-|
| スクリーンショットはファイルとしてクリップボードに入る | 入るのはビットマップ。ファイルパスは「送信してコピー」の後にしか現れない |
| 先にファイル転送へ送る必要がある | `Enter` を押した時点で、クリップボードには既に入っている |

## 対象外

クリップボードの履歴と検索、テキストのコピー、WSL 側の画像を Windows へ戻す機能。

## ライセンス

[MIT](../LICENSE)
