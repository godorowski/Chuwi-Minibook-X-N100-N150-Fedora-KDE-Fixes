#!/bin/bash

# Chuwi Minibook X N100/N150 Fedora KDE Complete Rotation Fixes Script
# This script applies both GRUB boot parameter fixes and KDE autorotation setup
# Based on the working configuration from KDE_Autorotation_Setup_Instructions.txt
#
# UPDATED FIXES (v2.0):
# - Fixed GRUB configuration to properly handle GRUB_CMDLINE_LINUX_DEFAULT
# - Added Wayland environment variables to systemd service for proper kscreen-doctor operation
# - Enhanced autorotation script with better error handling and debugging output
# - Improved compatibility with Wayland + XWayland environments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to check if sudo is available
check_sudo() {
    if ! command -v sudo &> /dev/null; then
        print_error "sudo is not available. Please install sudo or run as root."
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check for required commands
    if ! command -v bc &> /dev/null; then
        missing_deps+=("bc")
    fi
    
    if ! command -v kscreen-doctor &> /dev/null; then
        missing_deps+=("kscreen-doctor")
    fi
    
    if ! command -v systemctl &> /dev/null; then
        missing_deps+=("systemd")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_status "Please install missing packages:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "bc")
                    echo "  sudo dnf install bc"
                    ;;
                "kscreen-doctor")
                    echo "  sudo dnf install plasma-workspace"
                    ;;
                "systemd")
                    echo "  sudo dnf install systemd"
                    ;;
            esac
        done
        exit 1
    fi
    
    # Check accelerometer
    if [[ ! -d "/sys/bus/iio/devices/iio:device0" ]]; then
        print_warning "Accelerometer device not found at /sys/bus/iio/devices/iio:device0"
        print_status "Checking for other accelerometer devices..."
        ls /sys/bus/iio/devices/ 2>/dev/null || print_warning "No IIO devices found"
    fi
    
    # Check iio-sensor-proxy service
    if ! systemctl is-active --quiet iio-sensor-proxy; then
        print_warning "iio-sensor-proxy service is not running"
        print_status "Starting iio-sensor-proxy service..."
        sudo systemctl start iio-sensor-proxy
        sudo systemctl enable iio-sensor-proxy
    fi
    
    print_success "Prerequisites check completed"
}

# Function to backup GRUB configuration
backup_grub() {
    print_status "Backing up current GRUB configuration..."
    
    if [[ -f /etc/default/grub ]]; then
        sudo cp /etc/default/grub /etc/default/grub.backup
        print_success "GRUB configuration backed up to /etc/default/grub.backup"
    else
        print_error "GRUB configuration file not found at /etc/default/grub"
        exit 1
    fi
}

# Function to modify GRUB configuration
modify_grub() {
    print_status "Modifying GRUB configuration for screen rotation..."
    
    # Check if the rotation parameters are already present
    if grep -q "video=dsi-1:panel_orientation=right_side_up" /etc/default/grub; then
        print_warning "GRUB rotation parameters already present. Skipping GRUB modification."
        return 0
    fi
    
    # Create a temporary file with the modified configuration
    temp_file=$(mktemp)
    grub_default_found=false
    
    # Process the GRUB file and add rotation parameters
    while IFS= read -r line; do
        if [[ $line == GRUB_CMDLINE_LINUX_DEFAULT=* ]]; then
            grub_default_found=true
            # Extract the current parameters
            current_params=$(echo "$line" | sed 's/GRUB_CMDLINE_LINUX_DEFAULT="//' | sed 's/"$//')
            
            # Add rotation parameters if not already present
            if [[ $current_params == *"video=dsi-1:panel_orientation=right_side_up"* ]]; then
                echo "$line" >> "$temp_file"
            else
                # Remove any existing rotation parameters to avoid duplicates
                current_params=$(echo "$current_params" | sed 's/video=DSI-1:panel_orientation=right_side_up fbcon=rotate:1//g' | sed 's/video=dsi-1:panel_orientation=right_side_up fbcon=rotate:1//g')
                new_params="${current_params} video=dsi-1:panel_orientation=right_side_up fbcon=rotate:1"
                echo "GRUB_CMDLINE_LINUX_DEFAULT=\"${new_params}\"" >> "$temp_file"
            fi
        elif [[ $line == GRUB_CMDLINE_LINUX=* ]]; then
            # Handle case where GRUB_CMDLINE_LINUX_DEFAULT doesn't exist but GRUB_CMDLINE_LINUX does
            if [[ $grub_default_found == false ]]; then
                current_params=$(echo "$line" | sed 's/GRUB_CMDLINE_LINUX="//' | sed 's/"$//')
                # Remove existing rotation parameters if they exist
                current_params=$(echo "$current_params" | sed 's/video=DSI-1:panel_orientation=right_side_up fbcon=rotate:1//g' | sed 's/video=dsi-1:panel_orientation=right_side_up fbcon=rotate:1//g')
                new_params="${current_params} video=dsi-1:panel_orientation=right_side_up fbcon=rotate:1"
                echo "GRUB_CMDLINE_LINUX_DEFAULT=\"${new_params}\"" >> "$temp_file"
                echo "$line" >> "$temp_file"
                grub_default_found=true
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
    done < /etc/default/grub
    
    # If no GRUB_CMDLINE_LINUX_DEFAULT was found, add it
    if [[ $grub_default_found == false ]]; then
        echo "GRUB_CMDLINE_LINUX_DEFAULT=\"video=dsi-1:panel_orientation=right_side_up fbcon=rotate:1\"" >> "$temp_file"
    fi
    
    # Replace the original file
    sudo cp "$temp_file" /etc/default/grub
    rm "$temp_file"
    
    print_success "GRUB configuration modified successfully"
}

# Function to update GRUB
update_grub() {
    print_status "Updating GRUB configuration..."
    
    # Try different GRUB update commands based on the system
    if command -v grub2-mkconfig &> /dev/null; then
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
        print_success "GRUB configuration updated using grub2-mkconfig"
    elif command -v update-grub &> /dev/null; then
        sudo update-grub
        print_success "GRUB configuration updated using update-grub"
    else
        print_error "No GRUB update command found. Please update GRUB manually."
        exit 1
    fi
}

# Function to verify GRUB changes
verify_grub() {
    print_status "Verifying GRUB configuration changes..."
    
    if grep -q "video=dsi-1:panel_orientation=right_side_up" /etc/default/grub; then
        print_success "GRUB rotation parameters verified"
        echo "Current GRUB_CMDLINE_LINUX_DEFAULT:"
        grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub
    else
        print_error "GRUB rotation parameters not found. Please check the configuration."
        exit 1
    fi
}

# Function to create KDE autorotation script
create_kde_autorotation_script() {
    print_status "Creating KDE autorotation script..."
    
    # Create local bin directory
    mkdir -p ~/.local/bin
    
    # Create the autorotation script based on the working configuration
    cat > ~/.local/bin/kde-autorotate << 'EOF'
#!/bin/bash

# KDE Auto-rotation script for Chuwi Minibook X
# Monitors accelerometer and rotates screen based on device orientation
# Based on working configuration from KDE_Autorotation_Setup_Instructions.txt

# Configuration
ACCEL_DEVICE="/sys/bus/iio/devices/iio:device0"
SCALE=$(cat "$ACCEL_DEVICE/in_accel_scale" 2>/dev/null || echo "0.0009765625")
THRESHOLD=2.5  # Sensitivity threshold for rotation detection (ultra-low sensitivity - requires ~15-20 degrees movement)
HYSTERESIS_THRESHOLD=1.8  # Lower threshold for switching back (prevents rapid switching between orientations)
ORIENTATION_OFFSET=0  # No offset - direct accelerometer reading (working config)
CURRENT_ROTATION=""
DISPLAY_NAME="DSI-1"  # Chuwi Minibook X display name
STABLE_COUNT=0  # Counter for stable readings before changing rotation
STABLE_THRESHOLD=7  # Number of consecutive stable readings required (about 1.4 seconds delay)

# Function to get current rotation value
get_current_rotation() {
    kscreen-doctor -o | grep "Rotation:" | awk '{print $2}' 2>/dev/null || echo "none"
}

# Function to set rotation
set_rotation() {
    local rotation=$1
    echo "Setting rotation to: $rotation"
    kscreen-doctor "output.$DISPLAY_NAME.rotation.$rotation" 2>&1
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Warning: kscreen-doctor failed with exit code $exit_code"
        echo "Display: $DISPLAY_NAME, Rotation: $rotation"
    fi
}

# Function to read accelerometer values
read_accelerometer() {
    local x_raw=$(cat "$ACCEL_DEVICE/in_accel_x_raw" 2>/dev/null || echo "0")
    local y_raw=$(cat "$ACCEL_DEVICE/in_accel_y_raw" 2>/dev/null || echo "0")
    local z_raw=$(cat "$ACCEL_DEVICE/in_accel_z_raw" 2>/dev/null || echo "0")
    
    # Convert to actual values using scale
    local x=$(echo "$x_raw * $SCALE" | bc -l)
    local y=$(echo "$y_raw * $SCALE" | bc -l)
    local z=$(echo "$z_raw * $SCALE" | bc -l)
    
    echo "$x $y $z"
}

# Function to determine orientation with hysteresis
determine_orientation() {
    local x=$1
    local y=$2
    local z=$3
    local current_orientation=$4
    
    # Apply orientation offset (similar to GNOME's setting)
    if [ "$ORIENTATION_OFFSET" = "1" ]; then
        # Offset by 90 degrees clockwise
        local temp=$x
        x=$y
        y=$(echo "-$temp" | bc -l)
    elif [ "$ORIENTATION_OFFSET" = "2" ]; then
        # Offset by 180 degrees
        x=$(echo "-1 * $x" | bc -l)
        y=$(echo "-1 * $y" | bc -l)
    elif [ "$ORIENTATION_OFFSET" = "3" ]; then
        # Offset by 90 degrees counter-clockwise
        local temp=$x
        x=$(echo "-1 * $y" | bc -l)
        y=$temp
    fi
    
    # Determine orientation based on accelerometer values with hysteresis
    # Working configuration for Chuwi Minibook X:
    # X positive → "left" rotation
    # X negative → "right" rotation  
    # Y positive → "inverted" rotation
    # Y negative → "none" rotation
    
    # Use different thresholds based on current orientation (hysteresis)
    local threshold_to_use=$THRESHOLD
    if [ -n "$current_orientation" ] && [ "$current_orientation" != "none" ]; then
        threshold_to_use=$HYSTERESIS_THRESHOLD
    fi
    
    local x_gt_threshold=$(echo "$x > $threshold_to_use" | bc -l)
    local x_lt_neg_threshold=$(echo "$x < -$threshold_to_use" | bc -l)
    local y_gt_threshold=$(echo "$y > $threshold_to_use" | bc -l)
    local y_lt_neg_threshold=$(echo "$y < -$threshold_to_use" | bc -l)
    
    if [ "$x_gt_threshold" = "1" ]; then
        echo "left"
    elif [ "$x_lt_neg_threshold" = "1" ]; then
        echo "right"
    elif [ "$y_gt_threshold" = "1" ]; then
        echo "inverted"
    elif [ "$y_lt_neg_threshold" = "1" ]; then
        echo "none"
    else
        echo "none"  # Default to normal orientation
    fi
}

# Check if accelerometer is available
if [[ ! -f "$ACCEL_DEVICE/in_accel_x_raw" ]]; then
    echo "Error: Accelerometer device not found at $ACCEL_DEVICE"
    echo "Please ensure iio-sensor-proxy is running and accelerometer is available"
    exit 1
fi

# Main loop
echo "KDE Auto-rotation started for Chuwi Minibook X"
echo "Monitoring accelerometer: $ACCEL_DEVICE"
echo "Display: $DISPLAY_NAME"
echo "Orientation offset: $ORIENTATION_OFFSET"
echo "Threshold: $THRESHOLD (hysteresis: $HYSTERESIS_THRESHOLD)"
echo "Stability requirement: $STABLE_THRESHOLD consecutive readings (~1.4 seconds)"
echo "Check interval: 0.2 seconds"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    # Read accelerometer values
    read x y z <<< $(read_accelerometer)
    
    # Determine orientation with hysteresis
    orientation=$(determine_orientation "$x" "$y" "$z" "$CURRENT_ROTATION")
    
    # Check if orientation has changed
    if [ "$orientation" != "$CURRENT_ROTATION" ]; then
        # Increment stable count for new orientation
        STABLE_COUNT=$((STABLE_COUNT + 1))
        
        # Only change rotation after stable readings
        if [ $STABLE_COUNT -ge $STABLE_THRESHOLD ]; then
            echo "$(date): Rotating to $orientation (x=$x, y=$y, z=$z) [stable for $STABLE_COUNT readings]"
            set_rotation "$orientation"
            CURRENT_ROTATION="$orientation"
            STABLE_COUNT=0  # Reset counter after successful rotation
        else
            echo "$(date): Detected $orientation but waiting for stability (x=$x, y=$y, z=$z) [stable: $STABLE_COUNT/$STABLE_THRESHOLD]"
        fi
    else
        # Reset stable count if orientation hasn't changed
        STABLE_COUNT=0
    fi
    
    # Sleep for a short interval
    sleep 0.2
done
EOF
    
    # Make the script executable
    chmod +x ~/.local/bin/kde-autorotate
    
    print_success "KDE autorotation script created at ~/.local/bin/kde-autorotate"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd user service for KDE autorotation..."
    
    # Create systemd user service directory
    mkdir -p ~/.config/systemd/user
    
    # Create service file
    cat > ~/.config/systemd/user/kde-autorotate.service << EOF
[Unit]
Description=KDE Auto-rotation Service for Chuwi Minibook X
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/kde-autorotate
Restart=always
RestartSec=5
Environment=DISPLAY=:0
Environment=XDG_SESSION_TYPE=wayland
Environment=WAYLAND_DISPLAY=wayland-0

[Install]
WantedBy=default.target
EOF
    
    print_success "Systemd service created at ~/.config/systemd/user/kde-autorotate.service"
}

# Function to enable and start the service
enable_autorotation_service() {
    print_status "Enabling and starting KDE autorotation service..."
    
    # Reload systemd daemon
    systemctl --user daemon-reload
    
    # Enable the service
    systemctl --user enable kde-autorotate.service
    
    # Start the service
    systemctl --user start kde-autorotate.service
    
    print_success "KDE autorotation service enabled and started"
}

# Function to verify autorotation setup
verify_autorotation() {
    print_status "Verifying autorotation setup..."
    
    # Check if script exists and is executable
    if [[ -x ~/.local/bin/kde-autorotate ]]; then
        print_success "Autorotation script is executable"
    else
        print_error "Autorotation script not found or not executable"
        return 1
    fi
    
    # Check if service exists
    if [[ -f ~/.config/systemd/user/kde-autorotate.service ]]; then
        print_success "Systemd service file exists"
    else
        print_error "Systemd service file not found"
        return 1
    fi
    
    # Check service status
    if systemctl --user is-active --quiet kde-autorotate.service; then
        print_success "Autorotation service is running"
    else
        print_warning "Autorotation service is not running"
        print_status "Service status:"
        systemctl --user status kde-autorotate.service --no-pager
    fi
    
    # Check accelerometer
    if [[ -f "/sys/bus/iio/devices/iio:device0/in_accel_x_raw" ]]; then
        print_success "Accelerometer device is available"
    else
        print_warning "Accelerometer device not found"
    fi
    
    # Check kscreen-doctor
    if command -v kscreen-doctor &> /dev/null; then
        print_success "kscreen-doctor is available"
        print_status "Current display configuration:"
        kscreen-doctor -o | head -10
    else
        print_warning "kscreen-doctor not available"
    fi
}

# Function to show final instructions
show_final_instructions() {
    echo
    print_success "Complete rotation fixes have been applied successfully!"
    echo
    echo "Applied fixes:"
    echo "1. ✅ GRUB boot parameters for login screen rotation"
    echo "2. ✅ KDE autorotation script with accelerometer monitoring"
    echo "3. ✅ Systemd service for automatic autorotation startup"
    echo "4. ✅ Wayland environment compatibility fixes"
    echo "5. ✅ Enhanced error handling and debugging output"
    echo
    echo "Next steps:"
    echo "1. Reboot your system: sudo reboot"
    echo "2. After reboot, check if the boot screen appears correctly oriented"
    echo "3. Verify that KDE desktop automatically rotates based on device orientation"
    echo "4. Test rotating your device to confirm autorotation works"
    echo
    echo "Service management commands:"
    echo "- Check status: systemctl --user status kde-autorotate.service"
    echo "- Stop autorotation: systemctl --user stop kde-autorotate.service"
    echo "- Start autorotation: systemctl --user start kde-autorotate.service"
    echo "- View logs: journalctl --user -u kde-autorotate.service -f"
    echo "- Disable auto-start: systemctl --user disable kde-autorotate.service"
    echo
    echo "Configuration files:"
    echo "- Autorotation script: ~/.local/bin/kde-autorotate"
    echo "- Systemd service: ~/.config/systemd/user/kde-autorotate.service"
    echo "- GRUB backup: /etc/default/grub.backup"
    echo
    print_warning "A reboot is required for GRUB changes to take effect."
    print_status "Autorotation will start automatically after login."
}

# Main execution
main() {
    echo "=========================================="
    echo "Chuwi Minibook X Complete Rotation Fixes"
    echo "=========================================="
    echo "This script applies both GRUB fixes and KDE autorotation"
    echo "Based on working configuration from KDE_Autorotation_Setup_Instructions.txt"
    echo
    
    # Pre-flight checks
    check_root
    check_sudo
    check_prerequisites
    
    # Apply GRUB fixes
    backup_grub
    modify_grub
    update_grub
    verify_grub
    
    # Setup KDE autorotation
    create_kde_autorotation_script
    create_systemd_service
    enable_autorotation_service
    verify_autorotation
    
    # Show final instructions
    show_final_instructions
}

# Run main function
main "$@"