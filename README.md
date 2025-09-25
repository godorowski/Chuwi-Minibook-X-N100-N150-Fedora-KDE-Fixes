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

2. **Run the rotation fix script:**
   ```bash
   ./apply_rotation_fixes.sh
   ```

3. **Select installation option:**
   The script will present you with a menu:
   - **Option 1**: GRUB fixes only (fixes boot screen orientation)
   - **Option 2**: Autorotation only (enables automatic screen rotation)
   - **Option 3**: Both GRUB fixes and autorotation (complete solution)
   - **Option 4**: Manual installation (copy files to current directory)
   - **Option 5**: Exit

4. **Follow the instructions** based on your selected option

5. **Reboot your system** (if GRUB fixes were applied):
   ```bash
   sudo reboot
   ```

6. **Test the fixes:**
   - Check if boot screen appears correctly oriented (if GRUB fixes applied)
   - Rotate your device to test automatic screen rotation (if autorotation enabled)
   - Verify login screen orientation

## Installation Options

The script now offers flexible installation options to suit different needs:

### Option 1: GRUB Fixes Only
- **Purpose**: Fixes boot screen and login screen orientation
- **What it does**: Modifies GRUB configuration to add rotation parameters
- **When to use**: If you only have issues with boot/login screen orientation
- **Requires**: Reboot to take effect

### Option 2: Autorotation Only
- **Purpose**: Enables automatic screen rotation based on device orientation
- **What it does**: Creates autorotation script and systemd service
- **When to use**: If you only want automatic rotation during desktop use
- **Requires**: No reboot needed, starts immediately

### Option 3: Both GRUB and Autorotation (Complete Solution)
- **Purpose**: Comprehensive fix for all rotation issues
- **What it does**: Applies both GRUB fixes and autorotation setup
- **When to use**: For complete rotation solution (recommended)
- **Requires**: Reboot for GRUB changes

### Option 4: Manual Installation
- **Purpose**: Copy files for manual installation
- **What it does**: Creates a `manual_installation` directory with all necessary files
- **When to use**: If you prefer to install manually or want to customize the installation
- **Files created**:
  - `kde-autorotate` - Autorotation script
  - `kde-autorotate.service` - Systemd service file
  - `grub_example.txt` - GRUB configuration example
  - `INSTALLATION_INSTRUCTIONS.md` - Detailed manual installation guide

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
   - `THRESHOLD=2.5` (ultra-low sensitivity for rotation detection)
   - `HYSTERESIS_THRESHOLD=1.8` (prevents rapid switching between orientations)
   - `STABLE_THRESHOLD=7` (requires 7 consecutive stable readings before rotation)
   - `DISPLAY_NAME="DSI-1"` (Chuwi Minibook X display)

## Working Configuration

Based on the working setup from `KDE_Autorotation_Setup_Instructions.txt`:

- **X positive** → "left" rotation
- **X negative** → "right" rotation  
- **Y positive** → "inverted" rotation
- **Y negative** → "none" rotation
- **No orientation offset** (direct accelerometer reading)

## Sensitivity and Timing

**Ultra-Low Sensitivity Settings:**
- **Threshold**: `2.5` (requires significant movement ~15-20 degrees)
- **Hysteresis**: `1.8` (prevents rapid switching)
- **Stability**: Requires 7 consecutive readings (about 1.4 seconds)
- **Check interval**: 0.2 seconds

**Rotation Timing:**
- **Small movements (1-8 degrees)**: Completely ignored
- **Medium movements (8-15 degrees)**: May be detected but require holding position
- **Large movements (15+ degrees)**: Will trigger rotation after 1.4+ seconds of stability
- **Deliberate rotations**: Must be held in position for ~1.4 seconds before screen rotates

This configuration prevents accidental rotations from small movements while still allowing intentional rotations with deliberate, sustained positioning.

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
3. **Test device rotation** - Screen should automatically rotate (with ~1.4 second delay)
4. **Check service status** - Autorotation service should be running

**Note**: Due to ultra-low sensitivity settings, rotations require:
- Significant movement (~15-20 degrees)
- Holding the position for ~1.4 seconds
- Small movements (1-8 degrees) are ignored

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

- **THRESHOLD**: Sensitivity for rotation detection (default: 2.5)
  - Higher values = less sensitive (requires more movement)
  - Lower values = more sensitive (responds to smaller movements)
  - Recommended range: 1.5-3.0

- **HYSTERESIS_THRESHOLD**: Threshold for switching back (default: 1.8)
  - Should be lower than THRESHOLD to prevent rapid switching
  - Recommended: 70-80% of THRESHOLD value

- **STABLE_THRESHOLD**: Consecutive readings required (default: 7)
  - Higher values = more stable (longer delay before rotation)
  - Lower values = more responsive (faster rotation)
  - Recommended range: 3-10

- **DISPLAY_NAME**: Your display name (default: "DSI-1")

## Manual Installation

If you choose Option 4 (Manual Installation), the script will create a `manual_installation` directory with all necessary files and detailed instructions.

### Manual Installation Steps

1. **Run the script and select Option 4:**
   ```bash
   ./apply_rotation_fixes.sh
   # Select option 4
   ```

2. **Navigate to the manual installation directory:**
   ```bash
   cd manual_installation
   ```

3. **Follow the instructions in `INSTALLATION_INSTRUCTIONS.md`**

### Manual Installation Files

The manual installation includes:

- **`kde-autorotate`** - Complete autorotation script
- **`kde-autorotate.service`** - Systemd service file
- **`grub_example.txt`** - GRUB configuration example
- **`INSTALLATION_INSTRUCTIONS.md`** - Step-by-step manual installation guide

### Manual Installation Benefits

- **Full control**: Install only what you need
- **Customization**: Modify files before installation
- **Understanding**: Learn exactly what each component does
- **Troubleshooting**: Easier to debug issues
- **Backup**: Keep original files for reference

## Files Created

The script creates these files (depending on selected options):

### Autorotation Files (Options 2, 3, or Manual)
- `~/.local/bin/kde-autorotate` - Main autorotation script
- `~/.config/systemd/user/kde-autorotate.service` - Systemd service

### GRUB Files (Options 1, 3, or Manual)
- `/etc/default/grub.backup` - Backup of original GRUB config

### Manual Installation Files (Option 4)
- `manual_installation/kde-autorotate` - Autorotation script
- `manual_installation/kde-autorotate.service` - Systemd service
- `manual_installation/grub_example.txt` - GRUB configuration example
- `manual_installation/INSTALLATION_INSTRUCTIONS.md` - Installation guide

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