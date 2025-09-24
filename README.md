# Chuwi Minibook X N100/N150 Fedora KDE Fixes

A comprehensive collection of fixes and optimizations for running Fedora Linux with KDE Plasma on Chuwi Minibook X N100/N150 devices.

## 📋 Table of Contents

- [Overview](#overview)
- [Device Compatibility](#device-compatibility)
- [Quick Start](#quick-start)
- [Available Fixes](#available-fixes)
- [Installation Guide](#installation-guide)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🖥️ Overview

This repository contains essential fixes and configurations to optimize the Chuwi Minibook X N100/N150 experience when running Fedora Linux with KDE Plasma desktop environment. The fixes address common issues including screen rotation, display orientation, and system stability.

## 🔧 Device Compatibility

- **Device**: Chuwi Minibook X N100/N150
- **OS**: Fedora Linux (tested on Fedora 40+)
- **Desktop Environment**: KDE Plasma
- **Architecture**: x86_64
- **Display**: DSI-1 panel with touch support

## 🚀 Quick Start

### Automated Installation

For the easiest setup, use our automated script:

```bash
# Clone the repository
git clone https://github.com/godorowski/Chuwi-Minibook-X-N100-N150-Fedora-KDE-Fixes.git
cd Chuwi-Minibook-X-N100-N150-Fedora-KDE-Fixes

# Make scripts executable
chmod +x apply_rotation_fixes.sh

# Run the automated fix
./apply_rotation_fixes.sh
```

### Manual Installation

Follow the detailed instructions in [Complete_Rotation_Fix_Instructions.md](Complete_Rotation_Fix_Instructions.md) for step-by-step manual configuration.

## 📁 Available Fixes

### 🔄 Screen Rotation Fixes

| File | Description | Status |
|------|-------------|--------|
| `apply_rotation_fixes.sh` | **Automated script** - Applies all rotation fixes automatically | ✅ Ready |
| `Complete_Rotation_Fix_Instructions.md` | **Comprehensive guide** - Manual installation instructions | ✅ Ready |
| `KDE_Autorotation_Setup_Instructions.txt` | **KDE autorotation** - Advanced autorotation setup | ✅ Ready |

#### What the rotation fixes address:

- **Downloads folder rotation issues** - Fixes incorrectly oriented file manager folders
- **GRUB boot screen rotation** - Corrects boot screen orientation with `video=dsi-1:panel_orientation=right_side_up fbcon=rotate:1`
- **Console text readability** - Ensures console text is readable during boot
- **Desktop environment rotation** - Sets proper display rotation in KDE Plasma
- **Persistent rotation settings** - Creates autostart entries for consistent behavior

## 📖 Installation Guide

### Prerequisites

- Fedora Linux installed on Chuwi Minibook X N100/N150
- KDE Plasma desktop environment
- Internet connection for downloading dependencies
- Sudo/root access for system modifications

### Step-by-Step Installation

1. **Download the fixes:**
   ```bash
   git clone https://github.com/godorowski/Chuwi-Minibook-X-N100-N150-Fedora-KDE-Fixes.git
   cd Chuwi-Minibook-X-N100-N150-Fedora-KDE-Fixes
   ```

2. **Review the documentation:**
   - Read `Complete_Rotation_Fix_Instructions.md` for detailed information
   - Check `KDE_Autorotation_Setup_Instructions.txt` for advanced features

3. **Run the automated fix:**
   ```bash
   chmod +x apply_rotation_fixes.sh
   ./apply_rotation_fixes.sh
   ```

4. **Reboot your system:**
   ```bash
   sudo reboot
   ```

5. **Verify the fixes:**
   - Check Downloads folder orientation
   - Verify boot screen appears correctly
   - Test console text readability

## 🔧 Configuration Details

### GRUB Boot Parameters

The fixes add the following parameters to your GRUB configuration:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash video=dsi-1:panel_orientation=right_side_up fbcon=rotate:1"
```

**Parameter explanations:**
- `video=dsi-1:panel_orientation=right_side_up`: Sets DSI-1 display panel orientation
- `fbcon=rotate:1`: Rotates framebuffer console by 90 degrees clockwise

### Display Rotation Settings

- **Desktop rotation**: Set to 90 degrees clockwise (right)
- **Autostart entry**: Created for persistent rotation across reboots
- **File manager cache**: Cleared to resolve folder orientation issues

## 🛠️ Troubleshooting

### Common Issues

#### Downloads Folder Still Rotated
```bash
# Clear file manager caches
rm -rf ~/.cache/dolphin/
rm -rf ~/.cache/thumbnails/

# Reset Dolphin configuration
rm -f ~/.config/dolphinrc

# Restart file manager
killall dolphin && dolphin &
```

#### GRUB Changes Not Applied
```bash
# Verify GRUB configuration
grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub

# Update GRUB manually
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

#### Display Rotation Not Working
```bash
# Check available displays
xrandr --query

# Set rotation manually
xrandr --output DSI-1 --rotate right
```

### Recovery Steps

If something goes wrong, you can restore the original configuration:

```bash
# Restore GRUB configuration
sudo cp /etc/default/grub.backup /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Reset Downloads folder
rm -rf ~/Downloads/.directory
rm -rf ~/.cache/dolphin/

# Reset display settings
xrandr --output DSI-1 --rotate normal
```

## 📊 System Requirements

- **Minimum RAM**: 4GB (8GB recommended)
- **Storage**: 32GB free space
- **Network**: Internet connection for updates
- **Graphics**: Integrated Intel graphics (N100/N150)

## 🔍 Testing

The fixes have been tested on:
- Chuwi Minibook X N100 with Fedora 40 KDE
- Chuwi Minibook X N150 with Fedora 41 KDE
- Various kernel versions (6.14+)

## 📝 Contributing

Contributions are welcome! Please feel free to:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Reporting Issues

When reporting issues, please include:
- Device model (N100 or N150)
- Fedora version
- Kernel version (`uname -r`)
- KDE Plasma version
- Steps to reproduce the issue

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Fedora Linux community for excellent hardware support
- KDE Plasma team for the amazing desktop environment
- Chuwi for creating innovative mini laptop devices
- Contributors who have tested and improved these fixes

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/godorowski/Chuwi-Minibook-X-N100-N150-Fedora-KDE-Fixes/issues)
- **Discussions**: [GitHub Discussions](https://github.com/godorowski/Chuwi-Minibook-X-N100-N150-Fedora-KDE-Fixes/discussions)

## 📈 Changelog

### v1.0.0 (Current)
- ✅ Initial release
- ✅ Screen rotation fixes
- ✅ GRUB configuration optimization
- ✅ Downloads folder orientation fix
- ✅ Automated installation script
- ✅ Comprehensive documentation

---

**⚠️ Disclaimer**: These fixes are provided as-is. Always backup your system before applying changes. The authors are not responsible for any data loss or system issues that may occur.

**💡 Tip**: For the best experience, ensure your system is fully updated before applying these fixes:
```bash
sudo dnf update
```