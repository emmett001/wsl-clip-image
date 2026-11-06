<h1 align="center">wsl-clip-image</h1>

<p align="center">
  <em>Снимок экрана, затем <code>Alt+V</code>. Всё.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/emmett001/wsl-clip-image?style=flat-square&color=111111&label=stars" alt="Stars">
  <img src="https://img.shields.io/badge/wsl2-Ubuntu-111111?style=flat-square" alt="WSL2 Ubuntu">
  <img src="https://img.shields.io/badge/works%20with-pi-111111?style=flat-square" alt="Works with pi">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT license">
</p>

<p align="center">
  <strong>Четыре шага стали двумя.</strong><br>
  <strong>Убраны: «отправить в Файл-помощник» и «нажать Копировать».</strong><br>
  <sub>Windows 11 · WSL2 Ubuntu · pi · измерено 82–125 мс</sub>
</p>

<p align="center">
  <sub><a href="../README.md">English</a> &middot; <a href="README.zh-CN.md">简体中文</a> &middot; <a href="README.ja.md">日本語</a> &middot; <a href="README.ko.md">한국어</a> &middot; <a href="README.fr.md">Français</a></sub>
</p>

---

## Два лишних шага

Вы хотите показать агенту в терминале диалог с ошибкой.

`Alt+A`, обводите область, `Enter`. Изображение уже в буфере обмена.

Возвращаетесь в терминал, `Ctrl+V`. Ничего не происходит.

Тогда вы открываете WeChat, находите «Файл-помощник», отправляете туда картинку, ждёте, пока она появится, жмёте правой кнопкой, выбираете «Копировать».

Снова в терминал, ещё раз `Ctrl+V`. Теперь получилось — вставляется строка вида `F:\xwechat_files\wxid_xxx\temp\RWTemp\...png`.

Работает, и агент этот путь читает. Но ради одного снимка вы открыли мессенджер, отправили сообщение и один раз нажали «Копировать».

## После установки

```
Alt+A снимок  →  Alt+V  →  /tmp/pi-clipboard-3f2a91c8-....png
```

Нажимаете `Alt+V` — программа сама читает буфер обмена, записывает файл и вставляет путь в строку ввода.

`Alt+A` в WeChat подходит. `Win+Shift+S` в Windows тоже.

## Установка

```bash
sudo apt install -y wl-clipboard imagemagick
git clone https://github.com/emmett001/wsl-clip-image.git ~/.agents/skills/wsl-clip-image
```

Дальше: `Alt+A` → `Enter` → `Alt+V`. pi подхватит skill при следующем запуске.

Без pi — одна команда:

```console
$ git clone https://github.com/emmett001/wsl-clip-image.git
$ wsl-clip-image/scripts/grab.sh
/tmp/wslclip-20261106-174535-2946895.png
```

`grab.sh` печатает путь Linux. `cat`, `identify` и `cp` принимают его как есть.

## Проверенные окружения

| | |
|-|-|
| Проверено | Windows 11 · WSL2 Ubuntu · Windows Terminal · pi 1.5.0 |
| Проверено | `grab.sh` из любого скрипта в той же конфигурации |
| Не проверено | Другие агенты, другие терминалы, другие дистрибутивы, WSL1, обычный Linux, macOS |

`Alt+V` — собственная комбинация pi. У другого агента будет своя клавиша и своё отношение к путям изображений.
`grab.sh` опирается на bash и системные утилиты, поэтому переносится легче. Замеров пока нет.

## Цифры

Один снимок 1920x1020, одна и та же машина:

| Путь | Время |
|-|-|
| `wl-paste` (внутри pi) | 82–125 мс |
| `wl-paste` + ImageMagick (`grab.sh`) | 210 мс |
| Запасной путь через PowerShell | 660–1709 мс |

`wl-clipboard` задаёт границу: разница в 5–17 раз.

## Если не вставляется

```console
$ scripts/doctor.sh
== 1. WSL interop ==          ok  binfmt WSLInterop зарегистрирован
== 2. powershell.exe ==       ok  запускается
== 3. Буфер в WSL ==          ok  wl-paste есть, быстрый путь: image/bmp
== 4. Буфер Windows ==        ok  изображение получено, 82 мс
Итог: канал рабочий
```

| Симптом | Что делать |
|-|-|
| `Exec format error` или `xxx.exe: 1: MZ...: not found` | `scripts/doctor.sh --fix` |
| «В буфере обмена нет изображения» | Снимок не завершён, или горячую клавишу перехватило другое приложение |
| `Alt+V` занимает 1–2 с | `sudo apt install -y wl-clipboard` |
| Изображение «исчезает» | Процесс, владевший буфером, завершился. Сделайте снимок заново |

Два места, где легко ошибиться:

| Частое мнение | Что происходит на самом деле |
|-|-|
| Снимок лежит в буфере как файл | Там лежит битмап. Путь к файлу появляется только после «отправить и скопировать» |
| Сначала нужно отправить в Файл-помощник | В момент нажатия `Enter` изображение уже в буфере |

## Что не входит

История и поиск по буферу обмена, копирование текста, отправка изображений из WSL в Windows.

## Лицензия

[MIT](../LICENSE)
