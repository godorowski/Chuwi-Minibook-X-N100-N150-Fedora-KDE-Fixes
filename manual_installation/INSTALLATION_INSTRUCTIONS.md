# Manual Installation Instructions

This directory contains all the files needed for manual installation of Chuwi Minibook X rotation fixes.

## Files Included

- `kde-autorotate` - Autorotation script
- `kde-autorotate.service` - Systemd service file
- `grub_example.txt` - GRUB configuration example
- `INSTALLATION_INSTRUCTIONS.md` - This file

## Installation Steps

### Option 1: GRUB Fixes Only

1. **Backup your current GRUB configuration:**
   ```bash
   sudo cp /etc/default/grub /etc/default/grub.backup
   ```

2. **Edit GRUB configuration:**
   ```bash
   sudo nano /etc/default/grub
   ```

3. **Add rotation parameters to GRUB_CMDLINE_LINUX_DEFAULT:**
   ```
   GRUB_CMDLINE_LINUX_DEFAULT="quiet video=dsi-1:panel_orientation=right_side_up fbcon=rotate:1"
   ```

4. **Update GRUB:**
   ```bash
   sudo grub2-mkconfig -o /boot/grub2/grub.cfg
   ```

5. **Reboot:**
   ```bash
   sudo reboot
   ```

### Option 2: Autorotation Only

1. **Install dependencies:**
   ```bash
   sudo dnf install bc plasma-workspace
   sudo systemctl start iio-sensor-proxy
   sudo systemctl enable iio-sensor-proxy
   ```

2. **Copy autorotation script:**
   ```bash
   mkdir -p ~/.local/bin
   cp kde-autorotate ~/.local/bin/
   chmod +x ~/.local/bin/kde-autorotate
   ```

3. **Copy systemd service:**
   ```bash
   mkdir -p ~/.config/systemd/user
   cp kde-autorotate.service ~/.config/systemd/user/
   ```

4. **Enable and start service:**
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable kde-autorotate.service
   systemctl --user start kde-autorotate.service
   ```

### Option 3: Both GRUB and Autorotation

Follow both Option 1 and Option 2 above.

## Verification

### Check GRUB Configuration
```bash
grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub
```

### Check Autorotation Service
```bash
systemctl --user status kde-autorotate.service
journalctl --user -u kde-autorotate.service -f
```

### Test Autorotation
Rotate your device and check if the screen rotates automatically (with ~1.4 second delay).

## Service Management

```bash
# Check status
systemctl --user status kde-autorotate.service

# Stop autorotation
systemctl --user stop kde-autorotate.service

# Start autorotation
systemctl --user start kde-autorotate.service

# View logs
journalctl --user -u kde-autorotate.service -f

# Disable auto-start
systemctl --user disable kde-autorotate.service
```

## Troubleshooting

### Autorotation not working
1. Check accelerometer: `ls /sys/bus/iio/devices/`
2. Check service status: `systemctl --user status kde-autorotate.service`
3. Check logs: `journalctl --user -u kde-autorotate.service`

### GRUB changes not applied
1. Verify configuration: `grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub`
2. Rebuild GRUB: `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`
3. Reboot: `sudo reboot`

### Wrong rotation directions
Edit `~/.local/bin/kde-autorotate` and adjust `ORIENTATION_OFFSET`:
- `0` = No offset (default)
- `1` = 90 degrees clockwise
- `2` = 180 degrees
- `3` = 90 degrees counter-clockwise

Then restart: `systemctl --user restart kde-autorotate.service`

## Recovery

### Restore GRUB backup
```bash
sudo cp /etc/default/grub.backup /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo reboot
```

### Disable autorotation
```bash
systemctl --user stop kde-autorotate.service
systemctl --user disable kde-autorotate.service
```
