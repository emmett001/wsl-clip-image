# 从 Windows 剪贴板取内容。由 WSL 侧 grab.sh / doctor.sh 调用，也可单独用。
# 用法：powershell.exe -STA -NoProfile -File windows-clip.ps1 -Action image -Out C:\tmp\x.png
param(
    [ValidateSet('image', 'formats', 'text', 'files')]
    [string]$Action = 'image',
    [string]$Out = 'C:\Users\Public\winclip.png'
)

$ErrorActionPreference = 'Stop'
# 从 WSL 读 stdout 时按 UTF-8 解码，避免中文路径被控制台代码页破坏
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 剪贴板被别的进程占用时通常是被截图工具持有，重试几次
function Get-ClipObject {
    for ($i = 0; $i -lt 5; $i++) {
        try { return [System.Windows.Forms.Clipboard]::GetDataObject() }
        catch { Start-Sleep -Milliseconds 120 }
    }
    return $null
}

$data = Get-ClipObject
if ($null -eq $data) {
    Write-Output 'error: clipboard-busy'
    exit 2
}

switch ($Action) {
    'image' {
        $bytes = $null
        # 优先取原始 PNG 像素流：色彩保真，且避免 DIB 重编码
        try {
            $pngData = $data.GetData('PNG')
            if ($pngData -is [System.IO.Stream]) {
                $bytes = $pngData.ToArray()
            } elseif ($pngData -is [byte[]]) {
                $bytes = $pngData
            }
        } catch { }

        if (-not $bytes -or $bytes.Length -eq 0) {
            $img = [System.Windows.Forms.Clipboard]::GetImage()
            if ($img) {
                $img.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
                $img.Dispose()
                Write-Output "ok:png-dib:$Out"
                exit 0
            }
            Write-Output 'error: no-image'
            exit 1
        }

        [System.IO.File]::WriteAllBytes($Out, $bytes)
        Write-Output "ok:png-raw:$Out"
        exit 0
    }

    'formats' {
        'formats:'
        foreach ($f in $data.GetFormats($false)) { '  - ' + $f }
        $img = [System.Windows.Forms.Clipboard]::GetImage()
        if ($img) { "image: $($img.Width)x$($img.Height)" } else { 'image: none' }
        $files = [System.Windows.Forms.Clipboard]::GetFileDropList()
        if ($files -and $files.Count -gt 0) {
            'files:'
            foreach ($p in $files) { '  - ' + $p }
        } else { 'files: none' }
        $txt = [System.Windows.Forms.Clipboard]::GetText()
        if ($txt) { 'text: ' + $txt.Substring(0, [Math]::Min(80, $txt.Length)) } else { 'text: none' }
        exit 0
    }

    'text' {
        $txt = [System.Windows.Forms.Clipboard]::GetText()
        if (-not $txt) { exit 1 }
        Write-Output $txt
        exit 0
    }

    'files' {
        $files = [System.Windows.Forms.Clipboard]::GetFileDropList()
        if (-not $files -or $files.Count -eq 0) { exit 1 }
        foreach ($p in $files) { Write-Output $p }
        exit 0
    }
}
