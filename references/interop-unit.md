# 开机自检单元（可选）

WSL 重启后 `binfmt WSLInterop` 可能再次丢失。装一个 oneshot 单元兜住。

写入 `/etc/systemd/system/wsl-interop-fix.service`：

```ini
[Unit]
Description=Re-register WSLInterop binfmt handler when missing
After=systemd-binfmt.service
ConditionPathExists=/proc/sys/fs/binfmt_misc/register

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c '[ -e /proc/sys/fs/binfmt_misc/WSLInterop ] || echo ":WSLInterop:M::MZ::/init:PF" > /proc/sys/fs/binfmt_misc/register'

[Install]
WantedBy=multi-user.target
```

启用：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now wsl-interop-fix.service
systemctl is-enabled wsl-interop-fix.service   # enabled
```

卸载：

```bash
sudo systemctl disable --now wsl-interop-fix.service
sudo rm /etc/systemd/system/wsl-interop-fix.service
```

`/etc/wsl.conf` 里不要有 `[interop] enabled=false` 或 `appendWindowsPath=false`；
`protectBinfmt=true` 也会让注册失效。
