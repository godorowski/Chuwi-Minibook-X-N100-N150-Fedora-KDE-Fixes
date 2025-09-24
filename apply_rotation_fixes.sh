#!/bin/bash

# Complete Screen Rotation Fix Script
# This script applies all rotation fixes including Downloads folder and GRUB configuration
# Created: $(date)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GRUB_CONFIG="/etc/default/grub"
GRUB_BACKUP="/etc/default/grub.backup"
GRUB_CFG="/boot/grub2/grub.cfg"
DISPLAY_NAME="DSI-1"
ROTATION_PARAMS="video=dsi-1:panel_orientation=right_side_up fbcon=rotate:1"

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
        print_error "This script should not be run as root. Please run as regular user with sudo privileges."
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

# Function to backup GRUB configuration
backup_grub() {
    print_status "Backing up GRUB configuration..."
    if sudo cp "$GRUB_CONFIG" "$GRUB_BACKUP"; then
        print_success "GRUB configuration backed up to $GRUB_BACKUP"
    else
        print_error "Failed to backup GRUB configuration"
        exit 1
    fi
}

# Function to check if GRUB parameters are already set
check_grub_params() {
    if grep -q "video=dsi-1:panel_orientation=right_side_up" "$GRUB_CONFIG" && \
       grep -q "fbcon=rotate:1" "$GRUB_CONFIG"; then
        return 0  # Parameters already exist
    else
        return 1  # Parameters need to be added
    fi
}

# Function to add GRUB parameters
add_grub_params() {
    print_status "Adding GRUB rotation parameters..."
    
    if check_grub_params; then
        print_warning "GRUB rotation parameters already exist. Skipping GRUB configuration."
        return 0
    fi
    
    # Create temporary file for modification
    local temp_file=$(mktemp)
    
    # Process the GRUB configuration
    while IFS= read -r line; do
        if [[ $line == GRUB_CMDLINE_LINUX_DEFAULT=* ]]; then
            # Extract the current parameters
            current_params=$(echo "$line" | sed 's/GRUB_CMDLINE_LINUX_DEFAULT="//' | sed 's/"$//')
            
            # Add rotation parameters if not already present
            if [[ $current_params != *"video=dsi-1:panel_orientation=right_side_up"* ]]; then
                current_params="$current_params video=dsi-1:panel_orientation=right_side_up"
            fi
            if [[ $current_params != *"fbcon=rotate:1"* ]]; then
                current_params="$current_params fbcon=rotate:1"
            fi
            
            echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$current_params\"" >> "$temp_file"
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$GRUB_CONFIG"
    
    # Replace original file with modified version
    if sudo cp "$temp_file" "$GRUB_CONFIG"; then
        print_success "GRUB parameters added successfully"
        rm "$temp_file"
    else
        print_error "Failed to modify GRUB configuration"
        rm "$temp_file"
        exit 1
    fi
}

# Function to update GRUB configuration
update_grub() {
    print_status "Updating GRUB configuration..."
    
    # Try different GRUB update commands based on system
    if command -v grub2-mkconfig &> /dev/null; then
        if sudo grub2-mkconfig -o "$GRUB_CFG"; then
            print_success "GRUB configuration updated successfully"
        else
            print_error "Failed to update GRUB configuration"
            exit 1
        fi
    elif command -v update-grub &> /dev/null; then
        if sudo update-grub; then
            print_success "GRUB configuration updated successfully"
        else
            print_error "Failed to update GRUB configuration"
            exit 1
        fi
    else
        print_warning "No GRUB update command found. Please manually run: sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
    fi
}

# Function to fix Downloads folder rotation
fix_downloads_folder() {
    print_status "Fixing Downloads folder rotation..."
    
    # Check if Downloads folder exists
    if [[ ! -d "$HOME/Downloads" ]]; then
        print_warning "Downloads folder not found. Creating it..."
        mkdir -p "$HOME/Downloads"
    fi
    
    # Navigate to Downloads folder
    cd "$HOME/Downloads" || {
        print_error "Cannot access Downloads folder"
        return 1
    }
    
    # Remove any custom directory settings
    if [[ -f ".directory" ]]; then
        rm -f ".directory"
        print_success "Removed custom directory settings"
    fi
    
    # Clear file manager caches
    print_status "Clearing file manager caches..."
    
    # Clear Dolphin cache (KDE)
    if [[ -d "$HOME/.cache/dolphin" ]]; then
        rm -rf "$HOME/.cache/dolphin"
        print_success "Cleared Dolphin cache"
    fi
    
    # Clear thumbnails cache
    if [[ -d "$HOME/.cache/thumbnails" ]]; then
        rm -rf "$HOME/.cache/thumbnails"
        print_success "Cleared thumbnails cache"
    fi
    
    # Reset Dolphin configuration if it exists
    if [[ -f "$HOME/.config/dolphinrc" ]]; then
        rm -f "$HOME/.config/dolphinrc"
        print_success "Reset Dolphin configuration"
    fi
    
    print_success "Downloads folder rotation fix applied"
}

# Function to set display rotation
set_display_rotation() {
    print_status "Setting display rotation..."
    
    # Check if xrandr is available
    if command -v xrandr &> /dev/null; then
        # Check if display exists
        if xrandr --query | grep -q "$DISPLAY_NAME"; then
            # Set rotation to right (90 degrees clockwise)
            if xrandr --output "$DISPLAY_NAME" --rotate right; then
                print_success "Display rotation set to right (90 degrees clockwise)"
            else
                print_warning "Failed to set display rotation with xrandr"
            fi
        else
            print_warning "Display $DISPLAY_NAME not found. Available displays:"
            xrandr --query | grep " connected"
        fi
    else
        print_warning "xrandr not available. Skipping display rotation."
    fi
}

# Function to create autostart entry for display rotation
create_autostart_entry() {
    print_status "Creating autostart entry for display rotation..."
    
    # Create autostart directory if it doesn't exist
    mkdir -p "$HOME/.config/autostart"
    
    # Create desktop entry
    cat > "$HOME/.config/autostart/display-rotation-fix.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Display Rotation Fix
Comment=Automatically apply display rotation on startup
Exec=xrandr --output $DISPLAY_NAME --rotate right
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
    
    print_success "Autostart entry created"
}

# Function to verify changes
verify_changes() {
    print_status "Verifying changes..."
    
    # Check GRUB configuration
    if check_grub_params; then
        print_success "GRUB rotation parameters verified"
    else
        print_error "GRUB rotation parameters not found"
    fi
    
    # Check Downloads folder
    if [[ -d "$HOME/Downloads" ]]; then
        print_success "Downloads folder accessible"
    else
        print_error "Downloads folder not accessible"
    fi
    
    # Check autostart entry
    if [[ -f "$HOME/.config/autostart/display-rotation-fix.desktop" ]]; then
        print_success "Autostart entry created"
    else
        print_warning "Autostart entry not created"
    fi
}

# Function to show summary
show_summary() {
    echo
    print_status "=== ROTATION FIX SUMMARY ==="
    echo
    print_success "The following fixes have been applied:"
    echo "  ✓ Downloads folder rotation fix"
    echo "  ✓ GRUB boot parameters added"
    echo "  ✓ GRUB configuration updated"
    echo "  ✓ Display rotation set"
    echo "  ✓ Autostart entry created"
    echo
    print_warning "IMPORTANT: A reboot is required for GRUB changes to take effect."
    echo
    print_status "To verify changes after reboot:"
    echo "  1. Check Downloads folder orientation"
    echo "  2. Verify boot screen appears correctly"
    echo "  3. Test console text readability"
    echo
    print_status "To revert changes if needed:"
    echo "  sudo cp $GRUB_BACKUP $GRUB_CONFIG"
    echo "  sudo grub2-mkconfig -o $GRUB_CFG"
    echo
}

# Main execution
main() {
    echo "=========================================="
    echo "    Complete Screen Rotation Fix Script"
    echo "=========================================="
    echo
    
    # Pre-flight checks
    check_root
    check_sudo
    
    # Apply fixes
    backup_grub
    add_grub_params
    update_grub
    fix_downloads_folder
    set_display_rotation
    create_autostart_entry
    
    # Verify and summarize
    verify_changes
    show_summary
    
    print_success "All rotation fixes have been applied successfully!"
}

# Run main function
main "$@"