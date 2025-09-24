# Chuwi Minibook X N100/N150 Fedora KDE Complete Rotation Fixes

This package contains a comprehensive solution for fixing screen rotation issues on Chuwi Minibook X N100/N150 devices running Fedora with KDE desktop environment.

## What This Fixes

This solution addresses two main rotation issues:

1. **GRUB Boot Screen Rotation**: Fixes the login screen and boot process orientation
2. **KDE Autorotation**: Enables automatic screen rotation based on device orientation using accelerometer

## Prerequisites

- Fedora Linux with KDE desktop environment
- Chuwi Minibook X N100 or N150 device
- Root or sudo access
- GRUB bootloader
- Accelerometer sensor (iio-sensor-proxy service)

## Required Dependencies

The script will check for and install these dependencies:

```bash
# Required packages
sudo dnf install bc plasma-workspace systemd

# Ensure iio-sensor-proxy is running
sudo systemctl start iio-sensor-proxy
sudo systemctl enable iio-sensor-proxy
```

## Quick Start

1. **Navigate to the Downloads folder:**
   ```bash
   cd ~/Downloads/chuwi-minibook-rotation-fixes
   ```

2. **Run the complete rotation fix script:**
   ```bash
   ./apply_rotation_fixes.sh
   ```

3. **Reboot your system:**
   ```bash
   sudo reboot
   ```

4. **Test the fixes:**
   - Check if boot screen appears correctly oriented
   - Rotate your device to test automatic screen rotation
   - Verify login screen orientation

## What the Script Does

### GRUB Configuration Fixes

The script modifies `/etc/default/grub` to add these parameters:
- `video=dsi-1:panel_orientation=right_side_up` - Sets proper panel orientation
- `fbcon=rotate:1` - Rotates framebuffer console 90 degrees clockwise

### KDE Autorotation Setup

The script creates a complete autorotation system:

1. **Autorotation Script** (`~/.local/bin/kde-autorotate`):
   - Monitors accelerometer data every 0.5 seconds
   - Uses working configuration from `KDE_Autorotation_Setup_Instructions.txt`
   - Automatically rotates screen based on device orientation
   - Uses `kscreen-doctor` for screen control

2. **Systemd Service** (`~/.config/systemd/user/kde-autorotate.service`):
   - Runs autorotation script automatically at login
   - Restarts automatically if it crashes
   - Starts after graphical session is ready

3. **Configuration**:
   - `ORIENTATION_OFFSET=0` (no offset - working config)
   - `THRESHOLD=0.5` (sensitivity for rotation detection)
   - `DISPLAY_NAME="DSI-1"` (Chuwi Minibook X display)

## Working Configuration

Based on the working setup from `KDE_Autorotation_Setup_Instructions.txt`:

- **X positive** → "left" rotation
- **X negative** → "right" rotation  
- **Y positive** → "inverted" rotation
- **Y negative** → "none" rotation
- **No orientation offset** (direct accelerometer reading)

## Service Management

After installation, you can manage the autorotation service:

```bash
# Check service status
systemctl --user status kde-autorotate.service

# Stop autorotation
systemctl --user stop kde-autorotate.service

# Start autorotation
systemctl --user start kde-autorotate.service

# View real-time logs
journalctl --user -u kde-autorotate.service -f

# Disable auto-start
systemctl --user disable kde-autorotate.service

# Re-enable auto-start
systemctl --user enable kde-autorotate.service
```

## Verification

After running the script and rebooting:

1. **Check GRUB boot screen** - Should appear correctly oriented
2. **Verify console text** - Should be readable during boot
3. **Test device rotation** - Screen should automatically rotate
4. **Check service status** - Autorotation service should be running

## Troubleshooting

### Common Issues

1. **Autorotation not working:**
   ```bash
   # Check if accelerometer is available
   ls /sys/bus/iio/devices/
   cat /sys/bus/iio/devices/iio:device0/name
   
   # Check service status
   systemctl --user status kde-autorotate.service
   
   # View service logs
   journalctl --user -u kde-autorotate.service
   ```

2. **Wrong rotation directions:**
   - Edit `~/.local/bin/kde-autorotate`
   - Adjust the `ORIENTATION_OFFSET` value (0-3)
   - Restart service: `systemctl --user restart kde-autorotate.service`

3. **GRUB changes not applied:**
   ```bash
   # Verify GRUB configuration
   grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub
   
   # Rebuild GRUB if needed
   sudo grub2-mkconfig -o /boot/grub2/grub.cfg
   ```

4. **Display name issues:**
   ```bash
   # Check available displays
   kscreen-doctor -o
   
   # Update DISPLAY_NAME in ~/.local/bin/kde-autorotate if needed
   ```

### Recovery

If something goes wrong, restore the GRUB backup:

```bash
sudo cp /etc/default/grub.backup /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo reboot
```

To disable autorotation:

```bash
systemctl --user stop kde-autorotate.service
systemctl --user disable kde-autorotate.service
```

## Configuration Options

You can customize the autorotation behavior by editing `~/.local/bin/kde-autorotate`:

- **ORIENTATION_OFFSET**: 
  - `0` = No offset (default, working config)
  - `1` = 90 degrees clockwise
  - `2` = 180 degrees (fixes upside-down screen)
  - `3` = 90 degrees counter-clockwise

- **THRESHOLD**: Sensitivity for rotation detection (default: 0.5)
- **DISPLAY_NAME**: Your display name (default: "DSI-1")

## Files Created

The script creates these files:

- `~/.local/bin/kde-autorotate` - Main autorotation script
- `~/.config/systemd/user/kde-autorotate.service` - Systemd service
- `/etc/default/grub.backup` - Backup of original GRUB config

## System Information

- **Target Hardware:** Chuwi Minibook X N100/N150
- **OS:** Fedora Linux
- **Desktop Environment:** KDE Plasma
- **Display:** DSI-1 panel
- **Bootloader:** GRUB
- **Accelerometer:** mxc4005 (detected automatically)

## Based On

This solution is based on the working configuration documented in:
- `KDE_Autorotation_Setup_Instructions.txt` - For autorotation setup
- `Complete_Rotation_Fix_Instructions.md` - For GRUB configuration

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify your system matches the prerequisites
3. Check service logs: `journalctl --user -u kde-autorotate.service`
4. Ensure accelerometer is working: `cat /sys/bus/iio/devices/iio:device0/in_accel_*_raw`

## Notes

- These fixes are specifically designed for Chuwi Minibook X devices
- GRUB changes require a reboot to take effect
- Autorotation starts automatically after login
- Keep backups of all modified configuration files
- Test changes in a safe environment before applying to production systems

---

**Warning:** Always backup your system before making these changes. Incorrect GRUB configuration can prevent your system from booting.