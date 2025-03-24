#!/bin/bash

# unlock_drive.sh - A script to manage encrypted drives
# This script provides a menu-driven interface to list and unlock encrypted devices
# Enhanced with visual elements and animations
# Supports both interactive menu and command-line arguments

# Script version
VERSION="2.1"

# Terminal color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
NC='\033[0m' # No Color
# Print stylized title
print_title() {
    clear
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    echo -e "${BLUE}"
    echo '

    ╔════════════════════════════════════════════╗
    ║                                            ║
    ║  ██████╗ ██████╗ ██╗   ██╗██████╗ ████████╗║
    ║  ██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝║
    ║  ██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   ║
    ║  ██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   ║
    ║  ╚██████╗██║  ██║   ██║   ██║        ██║   ║
    ║   ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝   ║
    ║                                            ║
    ║        ENCRYPTED DRIVE MANAGER             ║
    ║                                            ║
    ╚════════════════════════════════════════════╝
    '
    echo -e "${NC}"

    echo -e "${CYAN}=======================================================================${NC}"
    echo -e "                ${BOLD}Encrypted Drive Management Tool${NC}"
    echo -e "${CYAN}=======================================================================${NC}"
    echo ""
}

# Create a spinning animation function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Progress bar function
show_progress() {
    local duration=$1
    local prefix=$2
    local size=40
    local completed=0
    local full_count=0
    
    # Calculate time per character
    local char_time=$(echo "$duration / $size" | bc -l)
    
    echo -ne "${prefix} ["
    for ((i=0; i<size; i++)); do
        echo -ne "${CYAN}▒${NC}"
    done
    echo -ne "] 0%"
    
    for ((i=0; i<size; i++)); do
        sleep $char_time
        completed=$(echo "scale=2; ($i + 1) * 100 / $size" | bc)
        full_count=$((i + 1))
        echo -ne "\r${prefix} ["
        
        for ((j=0; j<full_count; j++)); do
            echo -ne "${GREEN}█${NC}"
        done
        
        for ((j=full_count; j<size; j++)); do
            echo -ne "${CYAN}▒${NC}"
        done
        
        echo -ne "] ${completed}%"
    done
    echo -e "\n"
}

# Function to draw a menu box
draw_menu_box() {
    local options=("$@")
    local width=60
    local padding=4
    
    # Top border
    echo -e "${BLUE}╔$(printf '═%.0s' $(seq 1 $width))╗${NC}"
    
    # Empty line
    echo -e "${BLUE}║${NC}$(printf ' %.0s' $(seq 1 $width))${BLUE}║${NC}"
    
    # Print each menu option
    for i in "${!options[@]}"; do
        local number=$((i + 1))
        local text="${options[$i]}"
        # Left padding
        echo -ne "${BLUE}║${NC}$(printf ' %.0s' $(seq 1 $padding))"
        # Option number with styling
        echo -ne "${YELLOW}${number}.${NC} ${WHITE}${text}${NC}"
        # Fill remaining space and right border
        local remaining=$((width - ${#text} - $padding - 3))
        echo -e "$(printf ' %.0s' $(seq 1 $remaining))${BLUE}║${NC}"
    done
    
    # Empty line
    echo -e "${BLUE}║${NC}$(printf ' %.0s' $(seq 1 $width))${BLUE}║${NC}"
    
    # Bottom border
    echo -e "${BLUE}╚$(printf '═%.0s' $(seq 1 $width))╝${NC}"
}

# Function to print section headers
print_section() {
    local title="$1"
    echo -e "\n${CYAN}╔═$(printf '═%.0s' $(seq 1 ${#title}))═╗${NC}"
    echo -e "${CYAN}║ ${WHITE}${BOLD}${title}${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚═$(printf '═%.0s' $(seq 1 ${#title}))═╝${NC}\n"
}

# Confirmation dialog function
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    local prompt
    if [ "$default" = "y" ]; then
        prompt="Y/n"
    else
        prompt="y/N"
    fi
    
    echo -e "${YELLOW}⚠ ${BOLD}CONFIRMATION REQUIRED:${NC} $message"
    read -p "$(echo -e "${YELLOW}?${NC} Proceed? [$prompt]: ")" answer
    
    # Default value if empty
    if [ -z "$answer" ]; then
        answer="$default"
    fi
    
    case "$answer" in
        [yY]|[yY][eE][sS]) 
            return 0
            ;;
        *) 
            return 1
            ;;
    esac
}

# Function to display help information for each operation
show_help() {
    local operation="$1"
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}Help: $operation${NC}$(printf ' %.0s' $(seq 1 $((50 - ${#operation}))))${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    case "$operation" in
        "List encrypted devices")
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Scans your system for encrypted LUKS volumes          ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Shows both unlocked and locked encrypted devices      ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Displays detailed information about each device       ${CYAN}║${NC}"
            ;;
        "Unlock encrypted device")
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Allows you to unlock a LUKS-encrypted device         ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} You will need to provide the device passphrase        ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Options to mount the unlocked device automatically    ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Shows detailed device information before unlocking    ${CYAN}║${NC}"
            ;;
        "Lock encrypted device")
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Closes and secures an open encrypted device          ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Will attempt to unmount if the device is mounted      ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Checks for active processes using the device          ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Returns the device to a secure locked state           ${CYAN}║${NC}"
            ;;
        "Backup LUKS header")
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Creates a backup of the LUKS header of a device      ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Critical for recovery if the header gets corrupted   ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Stores the backup in a specified location            ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Security permissions are set on the backup file      ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${YELLOW}!${NC} ${BOLD}IMPORTANT:${NC} Keep this backup secure, it contains     ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   sensitive information about your encrypted volume    ${CYAN}║${NC}"
            ;;
        *)
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Use this tool to manage encrypted LUKS devices       ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Select options from the menu to perform operations    ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Each operation has detailed help information          ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC} ${BLUE}•${NC} Press 'h' on any screen for contextual help           ${CYAN}║${NC}"
            ;;
    esac
    
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Success and error message functions
success_msg() {
    echo -e "${GREEN}✓ ${BOLD}SUCCESS:${NC} $1"
}

error_msg() {
    echo -e "${RED}✗ ${BOLD}ERROR:${NC} $1"
}

info_msg() {
    echo -e "${BLUE}ℹ ${BOLD}INFO:${NC} $1"
}

warn_msg() {
    echo -e "${YELLOW}⚠ ${BOLD}WARNING:${NC} $1"
}
# Check if script is run with sudo privileges
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        error_msg "This script requires sudo privileges to access encrypted devices."
        warn_msg "Please run with sudo."
        exit 1
    fi
}

list_encrypted_devices() {
    local return_status=0
    
    print_section "ENCRYPTED DEVICE SCANNER"
    
    # Progress indicator for initial scan
    show_progress 1 "Initializing device scanner"
    
    # Arrays for storing device information
    local -a locked_devices=()
    local -a unlocked_devices=()
    declare -A device_details
    
    # Step 1: Find all block devices
    echo -ne "${BLUE}ℹ${NC} Discovering block devices... "
    local all_devices
    mapfile -t all_devices < <(lsblk -pndo NAME,TYPE | grep -E 'disk|part' | awk '{print $1}')
    echo -e "${GREEN}✓${NC}"
    
    # Step 2: Scan for LUKS devices
    echo -ne "${BLUE}ℹ${NC} Scanning for LUKS encrypted devices... "
    for device in "${all_devices[@]}"; do
        if cryptsetup isLuks "$device" 2>/dev/null; then
            # Get basic device information
            local uuid=$(cryptsetup luksUUID "$device" 2>/dev/null)
            local size=$(lsblk -ndo SIZE "$device" 2>/dev/null)
            local label=$(blkid -s LABEL -o value "$device" 2>/dev/null || echo "No Label")
            local fs_type=$(lsblk -ndo FSTYPE "$device" 2>/dev/null)
            
            # Store device details
            device_details["$device,uuid"]=$uuid
            device_details["$device,size"]=$size
            device_details["$device,label"]=$label
            device_details["$device,fs_type"]=$fs_type
            
            locked_devices+=("$device")
        fi
    done
    echo -e "${GREEN}✓${NC}"
    
    # Step 3: Find mapped (unlocked) devices
    echo -ne "${BLUE}ℹ${NC} Checking for unlocked volumes... "
    while read -r mapper_device; do
        if [[ -n "$mapper_device" && "$mapper_device" != "control" ]]; then
            local full_path="/dev/mapper/$mapper_device"
            if [[ -e "$full_path" ]]; then
                unlocked_devices+=("$full_path")
                
                # Get additional details for mapped devices
                local backing_dev=$(dmsetup deps -o blkdevname "$full_path" 2>/dev/null | grep -o '[^()]*' | tail -n1 | xargs)
                local mount_point=$(findmnt -n -o TARGET "$full_path" 2>/dev/null || echo "Not mounted")
                local size=$(lsblk -ndo SIZE "$full_path" 2>/dev/null)
                
                device_details["$full_path,backing"]="/dev/$backing_dev"
                device_details["$full_path,mount"]=$mount_point
                device_details["$full_path,size"]=$size
            fi
        fi
    done < <(ls /dev/mapper/ 2>/dev/null)
    echo -e "${GREEN}✓${NC}\n"
    
    # Display Results
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}ENCRYPTED DEVICE REPORT${NC}$(printf ' %.0s' $(seq 1 33))${CYAN}║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    
    # Display Locked Devices
    if ((${#locked_devices[@]} > 0)); then
        echo -e "${CYAN}║${NC} ${RED}${BOLD}LOCKED DEVICES${NC}$(printf ' %.0s' $(seq 1 47))${CYAN}║${NC}"
        echo -e "${CYAN}╟────────────────────────────────────────────────────────────╢${NC}"
        for device in "${locked_devices[@]}"; do
            # Skip if device is actually mapped
            if [[ " ${unlocked_devices[@]} " =~ " ${device} " ]]; then
                continue
            fi
            echo -e "${CYAN}║${NC} ${RED}•${NC} Device: ${WHITE}${device}${NC}"
            echo -e "${CYAN}║${NC}   ├─ Size: ${device_details["$device,size"]}$(printf ' %.0s' $(seq 1 $((40 - ${#device_details["$device,size"]}))))${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   ├─ Label: ${device_details["$device,label"]}$(printf ' %.0s' $(seq 1 $((39 - ${#device_details["$device,label"]}))))${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   ├─ UUID: ${device_details["$device,uuid"]}$(printf ' %.0s' $(seq 1 $((40 - ${#device_details["$device,uuid"]}))))${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   └─ Type: LUKS $(printf ' %.0s' $(seq 1 41))${CYAN}║${NC}"
        done
        echo -e "${CYAN}╟────────────────────────────────────────────────────────────╢${NC}"
    fi
    
    # Display Unlocked Devices
    if ((${#unlocked_devices[@]} > 0)); then
        echo -e "${CYAN}║${NC} ${GREEN}${BOLD}UNLOCKED DEVICES${NC}$(printf ' %.0s' $(seq 1 45))${CYAN}║${NC}"
        echo -e "${CYAN}╟────────────────────────────────────────────────────────────╢${NC}"
        for device in "${unlocked_devices[@]}"; do
            echo -e "${CYAN}║${NC} ${GREEN}•${NC} Device: ${WHITE}${device}${NC}"
            echo -e "${CYAN}║${NC}   ├─ Size: ${device_details["$device,size"]}$(printf ' %.0s' $(seq 1 $((40 - ${#device_details["$device,size"]}))))${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   ├─ Backing: ${device_details["$device,backing"]}$(printf ' %.0s' $(seq 1 $((37 - ${#device_details["$device,backing"]}))))${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   └─ Mount: ${device_details["$device,mount"]}$(printf ' %.0s' $(seq 1 $((39 - ${#device_details["$device,mount"]}))))${CYAN}║${NC}"
        done
        echo -e "${CYAN}╟────────────────────────────────────────────────────────────╢${NC}"
    fi
    
    # Display Summary
    # Function to format cell text with proper width and ellipsis if needed
# Function to calculate visible length of text (excluding color codes)
get_visible_length() {
    local text="$1"
    echo "${#text}"
}

# Define column widths
declare -r col_device=20
declare -r col_type=10
declare -r col_fs=12
declare -r col_size=10
declare -r col_mount=20
declare -r col_label=15
declare -r col_status=10

# Function to format cell text with proper width and ellipsis if needed
format_cell() {
    local text="$1"
    local width="$2"
    local color="${3:-$WHITE}"
    
    # Replace empty values with dash
    if [ -z "$text" ] || [ "$text" == "null" ]; then
        text="-"
    fi
    
    # Calculate visible length (excluding color codes)
    local visible_length=$(get_visible_length "$text")
    
    # Truncate with ellipsis if too long
    if [ $visible_length -gt $((width - 2)) ]; then
        text="${text:0:$((width - 5))}..."
        visible_length=$((width - 2))
    fi
    
    # Return formatted cell with proper width
    echo -ne "${color}${text}${NC}$(printf " %.0s" $(seq 1 $((width - visible_length))))"
}
    for device in "${unlocked_devices[@]}"; do
        # Parse device information with better error handling
        dev_name=$(echo "$device" | awk '{print $1}' 2>/dev/null || echo "unknown")
        dev_type=$(echo "$device" | awk '{print $2}' 2>/dev/null || echo "unknown")
        dev_fstype=$(echo "$device" | awk '{print $3}' 2>/dev/null || echo "-")
        dev_size=$(echo "$device" | awk '{print $4}' 2>/dev/null || echo "-")
        dev_mountpoint=$(echo "$device" | awk '{print $5}' 2>/dev/null || echo "-")
        dev_label=$(echo "$device" | awk '{print $6}' 2>/dev/null || echo "-")
        
        # Format for empty fields
        [ -z "$dev_fstype" ] && dev_fstype="-"
        [ -z "$dev_mountpoint" ] || [ "$dev_mountpoint" == "" ] && dev_mountpoint="-"
        [ -z "$dev_label" ] && dev_label="-"
        
        # Format row cells with consistent width
        formatted_name=$(format_cell "$dev_name" $col_device)
        formatted_type=$(format_cell "$dev_type" $col_type)
        formatted_fs=$(format_cell "$dev_fstype" $col_fs)
        formatted_size=$(format_cell "$dev_size" $col_size)
        formatted_mount=$(format_cell "$dev_mountpoint" $col_mount)
        formatted_label=$(format_cell "$dev_label" $col_label)
        formatted_status=$(format_cell "UNLOCKED" $col_status "${GREEN}${BOLD}")
        
        # Output formatted row
        echo -e "${CYAN}║${NC} ${formatted_name}${CYAN}║${NC} ${formatted_type}${CYAN}║${NC} ${formatted_fs}${CYAN}║${NC} ${formatted_size}${CYAN}║${NC} ${formatted_mount}${CYAN}║${NC} ${formatted_label}${CYAN}║${NC} ${formatted_status}${CYAN}║${NC}"
    done
    
    # Add a divider if both locked and unlocked devices are present
    if [ ${#unlocked_devices[@]} -gt 0 ] && [ ${#locked_devices[@]} -gt 0 ]; then
        echo -e "${CYAN}╠$(printf '═%.0s' $(seq 1 $col_device))╬$(printf '═%.0s' $(seq 1 $col_type))╬$(printf '═%.0s' $(seq 1 $col_fs))╬$(printf '═%.0s' $(seq 1 $col_size))╬$(printf '═%.0s' $(seq 1 $col_mount))╬$(printf '═%.0s' $(seq 1 $col_label))╬$(printf '═%.0s' $(seq 1 $col_status))╣${NC}"
    fi
    
    # Display locked devices with red status
    for device in "${locked_devices[@]}"; do
        # Parse device information with error handling
        dev_name=$(echo "$device" | awk '{print $1}' 2>/dev/null || echo "unknown")
        dev_type=$(echo "$device" | awk '{print $2}' 2>/dev/null || echo "unknown")
        dev_fstype=$(echo "$device" | awk '{print $3}' 2>/dev/null || echo "crypto_LUKS")
        dev_size=$(echo "$device" | awk '{print $4}' 2>/dev/null || echo "-")
        dev_mountpoint=$(echo "$device" | awk '{print $5}' 2>/dev/null || echo "-")
        dev_label=$(echo "$device" | awk '{print $6}' 2>/dev/null || echo "-")
        
        # Format for empty fields
        [ -z "$dev_fstype" ] && dev_fstype="crypto_LUKS"
        [ -z "$dev_mountpoint" ] || [ "$dev_mountpoint" == "" ] && dev_mountpoint="-"
        [ -z "$dev_label" ] && dev_label="-"
        
        # Format row cells with consistent width
        formatted_name=$(format_cell "$dev_name" $col_device)
        formatted_type=$(format_cell "$dev_type" $col_type)
        formatted_fs=$(format_cell "$dev_fstype" $col_fs)
        formatted_size=$(format_cell "$dev_size" $col_size)
        formatted_mount=$(format_cell "$dev_mountpoint" $col_mount)
        formatted_label=$(format_cell "$dev_label" $col_label)
        formatted_status=$(format_cell "LOCKED" $col_status "${RED}${BOLD}")
        
        # Output formatted row
        echo -e "${CYAN}║${NC} ${formatted_name}${CYAN}║${NC} ${formatted_type}${CYAN}║${NC} ${formatted_fs}${CYAN}║${NC} ${formatted_size}${CYAN}║${NC} ${formatted_mount}${CYAN}║${NC} ${formatted_label}${CYAN}║${NC} ${formatted_status}${CYAN}║${NC}"
    done
    
    # Add bottom border with dynamic column widths
    echo -e "${CYAN}╚$(printf '═%.0s' $(seq 1 $col_device))╩$(printf '═%.0s' $(seq 1 $col_type))╩$(printf '═%.0s' $(seq 1 $col_fs))╩$(printf '═%.0s' $(seq 1 $col_size))╩$(printf '═%.0s' $(seq 1 $col_mount))╩$(printf '═%.0s' $(seq 1 $col_label))╩$(printf '═%.0s' $(seq 1 $col_status))╝${NC}"
    
    echo ""
    
    # Display detailed UUID information
    print_section "Detailed UUID Information"
    
    # Display table header for UUID info
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}${WHITE}DEVICE UUID DETAILS${NC}$(printf ' %.0s' $(seq 1 60))${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════╦═══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}DEVICE${NC}$(printf ' %.0s' $(seq 1 5))${BLUE}║${NC} ${BOLD}UUID${NC}$(printf ' %.0s' $(seq 1 61))${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════╬═══════════════════════════════════════════════════════════════════╣${NC}"
    
    # Get devices with UUID information
    local uuid_info=$(blkid -o list | grep -E "crypto_LUKS|crypt" || echo "")
    
    if [ -z "$uuid_info" ]; then
        echo -e "${BLUE}║${NC} ${YELLOW}No UUID information available for encrypted devices${NC}$(printf ' %.0s' $(seq 1 20))${BLUE}║${NC}"
    else
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                # Parse device and UUID
                dev_path=$(echo "$line" | awk '{print $1}')
                dev_uuid=$(echo "$line" | grep -o 'UUID="[^"]*"' | cut -d '"' -f 2)
                dev_label=$(echo "$line" | grep -o 'LABEL="[^"]*"' | cut -d '"' -f 2 || echo "-")
                
                # If no UUID found, try to get LUKS UUID for crypto devices
                if [ -z "$dev_uuid" ] && [[ "$line" == *"crypto_LUKS"* ]]; then
                    dev_uuid=$(cryptsetup luksDump "$dev_path" 2>/dev/null | grep "UUID" | awk '{print $2}' || echo "-")
                fi
                
                # If still no UUID, mark it
                [ -z "$dev_uuid" ] && dev_uuid="-"
                
                # Get device status
                if [[ "$line" == *"crypto_LUKS"* ]]; then
                    status="${RED}${BOLD}LOCKED${NC}"
                else
                    status="${GREEN}${BOLD}UNLOCKED${NC}"
                fi
                
                # Format device name for display
                short_dev=$(basename "$dev_path")
                [ ${#short_dev} -gt 11 ] && short_dev="${short_dev:0:8}..."
                # Format UUID for display
                [ ${#dev_uuid} -gt 65 ] && dev_uuid="${dev_uuid:0:62}..."
                
                # Display the device information with its UUID
                echo -e "${BLUE}║${NC} ${WHITE}${short_dev}${NC}$(printf ' %.0s' $(seq 1 $((13 - ${#short_dev}))))${BLUE}║${NC} ${WHITE}${dev_uuid}${NC}$(printf ' %.0s' $(seq 1 $((65 - ${#dev_uuid}))))${BLUE}║${NC}"
            fi
        done < <(echo "$uuid_info")
    fi
    
    echo -e "${BLUE}╚═══════════════╩═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Add summary information
    print_section "Encrypted Device Summary"
    
    # Count devices
    local locked_count=${#locked_devices[@]}
    local unlocked_count=${#unlocked_devices[@]}
    local total_count=$((locked_count + unlocked_count))
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}System Encryption Status:${NC}$(printf ' %.0s' $(seq 1 30))${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${BLUE}•${NC} ${WHITE}Total encrypted devices:${NC} ${BOLD}${total_count}${NC}$(printf ' %.0s' $(seq 1 $((34 - ${#total_count}))))${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${BLUE}•${NC} ${WHITE}Unlocked devices:${NC} ${GREEN}${BOLD}${unlocked_count}${NC}$(printf ' %.0s' $(seq 1 $((38 - ${#unlocked_count}))))${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${BLUE}•${NC} ${WHITE}Locked devices:${NC} ${RED}${BOLD}${locked_count}${NC}$(printf ' %.0s' $(seq 1 $((40 - ${#locked_count}))))${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    if [ $total_count -gt 0 ]; then
        info_msg "Use option 2 to unlock devices or option 3 to lock devices."
        echo ""
        return 0
    else
        warn_msg "No encrypted devices found on this system."
        echo ""
        return 1
    fi
    
    # Final status message with colored summary
    if [ $unlocked_count -gt 0 ] && [ $locked_count -gt 0 ]; then
        info_msg "Your system has both locked and unlocked encrypted devices."
        echo -e "${BLUE}ℹ${NC} ${BOLD}Recommendation:${NC} Keep sensitive data encrypted when not in use."
    elif [ $unlocked_count -gt 0 ] && [ $locked_count -eq 0 ]; then
        warn_msg "All your encrypted devices are currently unlocked."
        echo -e "${YELLOW}⚠${NC} ${BOLD}Security note:${NC} Consider locking devices when not needed."
    elif [ $unlocked_count -eq 0 ] && [ $locked_count -gt 0 ]; then
        info_msg "All your encrypted devices are currently locked."
        echo -e "${GREEN}✓${NC} ${BOLD}Security status:${NC} Your encrypted data is secure."
    fi
    
    return $return_status
}

# Function to unlock an encrypted LUKS device
unlock_device() {
    local return_status=0
    print_section "Unlock Encrypted Device"
    
    info_msg "Scanning for available devices..."
    show_progress 1 "Scanning system"
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}Available devices:${NC}$(printf ' %.0s' $(seq 1 35))${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Display available devices in a nicely formatted table
    local device_info=$(lsblk -o NAME,TYPE,FSTYPE,SIZE | grep -E "part|disk")
    echo "$device_info" | while read line; do
        echo -e "${CYAN}║${NC} ${YELLOW}→${NC} ${WHITE}$line${NC}$(printf ' %.0s' $(seq 1 $((55 - ${#line}))))${CYAN}║${NC}"
    done
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    read -p "$(echo -e "${YELLOW}?${NC} Enter device path (e.g. /dev/sda1): ")" device_path
    
    # Check if device exists
    if [ ! -b "$device_path" ]; then
        error_msg "Device $device_path does not exist or is not a block device."
        return_status=1
        return $return_status
    fi
    
    # Check if device is a LUKS encrypted device
    if ! cryptsetup isLuks "$device_path" 2>/dev/null; then
        error_msg "$device_path is not a LUKS encrypted device."
        return_status=1
        return $return_status
    fi
    
    success_msg "Valid LUKS device detected!"
    show_progress 0.5 "Analyzing LUKS header"
    
    # Get LUKS device info with animation
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}LUKS Device Information:${NC}$(printf ' %.0s' $(seq 1 30))${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    cryptsetup luksDump "$device_path" | grep -E "Version|UUID|Cipher|Hash" | while read line; do
        echo -e "${CYAN}║${NC} ${BLUE}ℹ${NC} ${WHITE}$line${NC}$(printf ' %.0s' $(seq 1 $((55 - ${#line}))))${CYAN}║${NC}"
    done
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    # Get mapper name
    read -p "$(echo -e "${YELLOW}?${NC} Enter name for the mapped device: ")" mapper_name
    
    # Check if mapper name is already in use
    if [ -e "/dev/mapper/$mapper_name" ]; then
        error_msg "A device with name $mapper_name already exists."
        return_status=1
        return $return_status
    fi
    
    # Attempt to unlock the device with fancy animation
    info_msg "Attempting to unlock device $device_path..."
    echo -e "${MAGENTA}${BLINK}⚠${NC} ${YELLOW}You will be prompted for the passphrase${NC}"
    
    # Call cryptsetup to unlock the device
    if cryptsetup open "$device_path" "$mapper_name"; then
        success_msg "Device unlocked successfully!"
        # Create a pulsing animation for success
        echo -ne "${GREEN}"
        for i in {1..3}; do
            echo -ne "${BOLD}✓ UNLOCKED${NC}${GREEN} "
            sleep 0.3
            echo -ne "\r           \r"
            sleep 0.3
        done
        echo -e "${BOLD}✓ UNLOCKED${NC}"
        
        # Ask if the user wants to mount the device
        read -p "$(echo -e "${YELLOW}?${NC} Do you want to mount this device? (y/n): ")" mount_answer
        
        if [[ "$mount_answer" == "y" || "$mount_answer" == "Y" ]]; then
            # Determine filesystem type
            info_msg "Detecting filesystem type..."
            show_progress 0.7 "Analyzing filesystem"
            FS_TYPE=$(blkid -o value -s TYPE "/dev/mapper/$mapper_name")
            
            if [ -z "$FS_TYPE" ]; then
                warn_msg "Could not detect filesystem type. Using auto."
                FS_TYPE="auto"
            else
                success_msg "Detected filesystem: $FS_TYPE"
            fi
            
            # Ask for mount point
            read -p "$(echo -e "${YELLOW}?${NC} Enter mount point (e.g. /mnt/data): ")" mount_point
            
            # Create mount point if it doesn't exist
            if [ ! -d "$mount_point" ]; then
                info_msg "Creating mount point $mount_point..."
                mkdir -p "$mount_point"
            fi
            
            # Mount the device
            if mount -t "$FS_TYPE" "/dev/mapper/$mapper_name" "$mount_point"; then
                success_msg "Device mounted successfully at $mount_point"
                
                # Display mount information
                echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║${NC} ${BOLD}${WHITE}Mount Information:${NC}$(printf ' %.0s' $(seq 1 35))${CYAN}║${NC}"
                echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
                df -h "$mount_point" | while read line; do
                    echo -e "${CYAN}║${NC} ${GREEN}✓${NC} ${WHITE}$line${NC}$(printf ' %.0s' $(seq 1 $((55 - ${#line}))))${CYAN}║${NC}"
                done
                echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
            else
                error_msg "Failed to mount device at $mount_point"
            fi
        else
            info_msg "Device unlocked but not mounted. Access it at /dev/mapper/$mapper_name"
        fi
    else
        error_msg "Failed to unlock device. Check your passphrase."
        return_status=1
    fi
    
    echo ""
    return $return_status
}
# Function to lock/close an encrypted LUKS device
lock_device() {
    local return_status=0
    print_section "Lock Encrypted Device"
    
    info_msg "Scanning for open encrypted devices..."
    show_progress 1 "Scanning system"
    
    # Get list of mapped devices
    mapfile -t mapped_devices < <(ls -1 /dev/mapper/ | grep -v "control" || true)
    
    if [ ${#mapped_devices[@]} -eq 0 ]; then
        error_msg "No open encrypted devices found."
        return_status=1
        return $return_status
    fi
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}Open encrypted devices:${NC}$(printf ' %.0s' $(seq 1 33))${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Display available devices in a nicely formatted table
    for ((i=0; i<${#mapped_devices[@]}; i++)); do
        device="${mapped_devices[$i]}"
        # Get mount point if available
        mount_point=$(findmnt -n -o TARGET "/dev/mapper/$device" 2>/dev/null || echo "Not mounted")
        echo -e "${CYAN}║${NC} ${YELLOW}$((i+1)).${NC} ${WHITE}$device${NC} ${BLUE}→${NC} ${WHITE}$mount_point${NC}$(printf ' %.0s' $(seq 1 $((53 - ${#device} - ${#mount_point}))))${CYAN}║${NC}"
    done
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    read -p "$(echo -e "${YELLOW}?${NC} Enter device number to lock (1-${#mapped_devices[@]}), or 0 to cancel: ")" device_num
    
    # Check if user wants to cancel
    if [[ "$device_num" == "0" ]]; then
        info_msg "Operation cancelled."
        return $return_status
    fi
    
    # Validate input
    if ! [[ "$device_num" =~ ^[0-9]+$ ]] || [ "$device_num" -lt 1 ] || [ "$device_num" -gt ${#mapped_devices[@]} ]; then
        error_msg "Invalid selection. Please enter a number between 1 and ${#mapped_devices[@]}."
        return_status=1
        return $return_status
    fi
    # Get selected device
    selected_device="${mapped_devices[$((device_num-1))]}"
    device_path="/dev/mapper/$selected_device"
    
    # Check if device is mounted
    mount_point=$(findmnt -n -o TARGET "$device_path" 2>/dev/null)
    
    if [ -n "$mount_point" ]; then
        warn_msg "Device is mounted at $mount_point"
        read -p "$(echo -e "${YELLOW}?${NC} Unmount before closing? (y/n): ")" unmount_answer
        
        if [[ "$unmount_answer" == "y" || "$unmount_answer" == "Y" ]]; then
            info_msg "Unmounting $device_path from $mount_point..."
            
            # Check if any processes are using the mount point
            if lsof "$mount_point" &>/dev/null; then
                warn_msg "Some processes are using the mount point."
                echo -e "${YELLOW}Process list:${NC}"
                lsof "$mount_point" | head -10
                read -p "$(echo -e "${YELLOW}?${NC} Force unmount anyway? (y/n): ")" force_answer
                
                if [[ "$force_answer" == "y" || "$force_answer" == "Y" ]]; then
                    if ! umount -f "$mount_point"; then
                        error_msg "Failed to force unmount. Device remains open."
                        return_status=1
                        return $return_status
                    fi
                    success_msg "Forced unmount successful."
                else
                    warn_msg "Abort. Device will remain mounted."
                    return 1
                fi
            else
                # Device is not mounted, proceed with closing
                info_msg "Device is not mounted. Proceeding with closing..."
            fi
        else
            # User chose not to unmount
            info_msg "Continuing without unmounting."
        fi
    fi
    
    # Attempt to close the device with animation
    info_msg "Closing encrypted device $selected_device..."
    show_progress 0.7 "Closing device"
    
    if cryptsetup close "$selected_device"; then
        success_msg "Device closed successfully!"
        # Create a pulsing animation for success
        echo -ne "${GREEN}"
        for i in {1..3}; do
            echo -ne "${BOLD}✓ LOCKED${NC}${GREEN} "
            sleep 0.3
            echo -ne "\r          \r"
            sleep 0.3
        done
        echo -e "${BOLD}✓ LOCKED${NC}"
    else
        error_msg "Failed to close device $selected_device."
        return_status=1
    fi
    
    echo ""
    return $return_status
}

# Function to backup LUKS header
backup_luks_header() {
    print_section "Backup LUKS Header"
    
    info_msg "Scanning for LUKS devices..."
    show_progress 1 "Scanning system"
    
    # Create an array to store LUKS devices
    mapfile -t luks_devices < <(lsblk -o NAME,TYPE,FSTYPE,SIZE,PATH | grep "crypto_LUKS" | awk '{print $NF}' || true)
    
    if [ ${#luks_devices[@]} -eq 0 ]; then
        warn_msg "No LUKS devices detected."
        info_msg "Checking devices manually..."
        
        # Get list of block devices for manual checking
        mapfile -t block_devices < <(lsblk -o PATH | grep -E "^/dev/sd|^/dev/nvme|^/dev/vd" | sort || true)
        
        # Check each block device manually
        local found_luks=false
        local validated_luks=()
        
        for device in "${block_devices[@]}"; do
            echo -ne "Checking ${YELLOW}$device${NC}... "
            if cryptsetup isLuks "$device" 2>/dev/null; then
                echo -e "${GREEN}LUKS${NC}"
                validated_luks+=("$device")
                found_luks=true
            else
                echo -e "${RED}Not LUKS${NC}"
            fi
        done
        
        if [ "$found_luks" = false ]; then
            error_msg "No LUKS encrypted devices found."
            return 1
        else
            luks_devices=("${validated_luks[@]}")
        fi
    fi
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}Available LUKS devices:${NC}$(printf ' %.0s' $(seq 1 31))${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Display available devices in a nicely formatted table
    for ((i=0; i<${#luks_devices[@]}; i++)); do
        device="${luks_devices[$i]}"
        device_info=$(lsblk -n -o SIZE "$device" 2>/dev/null)
        echo -e "${CYAN}║${NC} ${YELLOW}$((i+1)).${NC} ${WHITE}$device${NC} ${BLUE}→${NC} ${WHITE}$device_info${NC}$(printf ' %.0s' $(seq 1 $((53 - ${#device} - ${#device_info}))))${CYAN}║${NC}"
    done
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    read -p "$(echo -e "${YELLOW}?${NC} Enter device number to backup (1-${#luks_devices[@]}), or 0 to cancel: ")" device_num
    
    # Check if user wants to cancel
    if [[ "$device_num" == "0" ]]; then
        info_msg "Operation cancelled."
        return 0
    fi
    
    # Validate input
    if ! [[ "$device_num" =~ ^[0-9]+$ ]] || [ "$device_num" -lt 1 ] || [ "$device_num" -gt ${#luks_devices[@]} ]; then
        error_msg "Invalid selection. Please enter a number between 1 and ${#luks_devices[@]}."
        return 1
    fi
    
    # Get selected device
    selected_device="${luks_devices[$((device_num-1))]}"
    
    # Get device LUKS header info
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}LUKS Header Information:${NC}$(printf ' %.0s' $(seq 1 30))${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    cryptsetup luksDump "$selected_device" | grep -E "Version|UUID|Cipher|Hash" | while read line; do
        echo -e "${CYAN}║${NC} ${BLUE}ℹ${NC} ${WHITE}$line${NC}$(printf ' %.0s' $(seq 1 $((55 - ${#line}))))${CYAN}║${NC}"
    done
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    # Ask for backup location
    uuid=$(cryptsetup luksDump "$selected_device" | grep "UUID" | awk '{print $2}')
    default_filename="luks-header-${uuid}-$(date +%Y%m%d).bin"
    
    read -p "$(echo -e "${YELLOW}?${NC} Enter backup file path [${BOLD}$HOME/$default_filename${NC}]: ")" backup_path
    backup_path="${backup_path:-$HOME/$default_filename}"
    
    # Backup header with animation
    info_msg "Backing up LUKS header to $backup_path..."
    warn_msg "This operation is critical. Please wait..."
    show_progress 2 "Backing up LUKS header"
    
    if cryptsetup luksHeaderBackup "$selected_device" --header-backup-file "$backup_path"; then
        success_msg "LUKS header backed up successfully to $backup_path"
        chmod 600 "$backup_path" # Secure the backup file
        
        # Display additional info about the backup
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC} ${BOLD}${WHITE}Backup Information:${NC}$(printf ' %.0s' $(seq 1 33))${CYAN}║${NC}"
        echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC} ${GREEN}✓${NC} ${WHITE}File: $backup_path${NC}$(printf ' %.0s' $(seq 1 $((50 - ${#backup_path}))))${CYAN}║${NC}"
    
        file_size=$(du -h "$backup_path" | awk '{print $1}')
        echo -e "${CYAN}║${NC} ${GREEN}✓${NC} ${WHITE}Size: $file_size${NC}$(printf ' %.0s' $(seq 1 $((50 - ${#file_size}))))${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} ${GREEN}✓${NC} ${WHITE}Permissions: $(ls -l "$backup_path" | awk '{print $1}')${NC}$(printf ' %.0s' $(seq 1 33))${CYAN}║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        
        warn_msg "IMPORTANT: Store this backup in a secure location."
        info_msg "This backup can be used to restore the LUKS header if it gets corrupted."
    else
        error_msg "Failed to back up LUKS header."
        return 1
    fi
    
    echo ""
}

# Function to show the main menu
show_menu() {
    print_title
    
    echo -e "${CYAN}${BOLD}Welcome to the Encrypted Drive Management Tool${NC}"
    echo -e "${YELLOW}This tool helps you manage your encrypted drives securely.${NC}"
    echo -e "${CYAN}=======================================================================${NC}"
    echo ""
    
    # Draw the menu box with options
    draw_menu_box "${menu_options[@]}"
    
    # Show help hint
    echo -e "${BLUE}ℹ${NC} Type '${YELLOW}h${NC}' for help or '${YELLOW}q${NC}' to quit"
    
    # Get user input with styled prompt
    echo ""
    read -p "$(echo -e "${YELLOW}?${NC} Enter your choice [${BOLD}1-${#menu_options[@]}${NC}]: ")" choice
    echo ""
    
    # Process user selection with visual feedback
    case $choice in
        [hH]|[hH][eE][lL][pP])
            # Show general help
            show_help
            ;;
        1) 
            info_msg "Loading device list..."
            sleep 0.5
            list_encrypted_devices 
            ;;
        2) 
            info_msg "Preparing unlock interface..."
            sleep 0.5
            unlock_device 
            ;;
        3) 
            info_msg "Preparing lock interface..."
            sleep 0.5
            lock_device 
            ;;
        4) 
            info_msg "Preparing backup interface..."
            sleep 0.5
            backup_luks_header 
            ;;
        5|[qQ]|[eE][xX][iI][tT]) 
            if confirm_action "Are you sure you want to exit?" "n"; then
                echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║${NC}$(printf ' %.0s' $(seq 1 20))${YELLOW}Exiting...${NC}$(printf ' %.0s' $(seq 1 20))${CYAN}║${NC}"
                echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
                # Perform cleanup tasks before exit
                echo -e "${BLUE}ℹ${NC} Performing cleanup..."
                show_progress 0.7 "Cleaning up"
                echo -e "${GREEN}✓${NC} Thank you for using the Encrypted Drive Manager!"
                exit 0
            fi
            ;;
        *)
            error_msg "Invalid option: $choice"
            warn_msg "Please enter a number between 1 and ${#menu_options[@]}"
            ;;
    esac
}

# Display usage information
show_usage() {
    echo -e "${CYAN}╔═════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}USAGE: $(basename "$0") [OPTION]${NC}$(printf ' %.0s' $(seq 1 30))${CYAN}║${NC}"
    echo -e "${CYAN}╠═════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Run without options for interactive menu mode                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Options:${NC}                                                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}1${NC} or ${GREEN}list${NC}     List all encrypted devices                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}2${NC} or ${GREEN}unlock${NC}   Unlock an encrypted device                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}3${NC} or ${GREEN}lock${NC}     Lock an encrypted device                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}4${NC} or ${GREEN}backup${NC}   Backup LUKS header of a device                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}help${NC}        Show this help message                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Examples:${NC}                                                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   $(basename "$0") list                                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   $(basename "$0") unlock                                         ${CYAN}║${NC}"
    echo -e "${CYAN}╚═════════════════════════════════════════════════════════════════════╝${NC}"
}

# Process command-line arguments
process_args() {
    local command="$1"
    
    case "$command" in
        1|list)
            check_sudo
            list_encrypted_devices
            return $?
            ;;
        2|unlock)
            check_sudo
            unlock_device
            return $?
            ;;
        3|lock)
            check_sudo
            lock_device
            return $?
            ;;
        4|backup)
            check_sudo
            backup_luks_header
            return $?
            ;;
        help|-h|--help)
            show_usage
            return 0
            ;;
        "")
            # No argument provided, run in interactive mode
            return 255
            ;;
        *)
            error_msg "Invalid option: $command"
            show_usage
            return 1
            ;;
    esac
}

main() {
    # Check if running in command-line mode
    if [ $# -gt 0 ]; then
        process_args "$1"
        exit_code=$?
        
        # If process_args returns 255, continue to interactive mode
        if [ $exit_code -ne 255 ]; then
            exit $exit_code
        fi
    fi
    
    # Interactive mode initialization
    # Initial animation
    clear
    echo -e "${BLUE}${BOLD}"
    echo "Initializing Encrypted Drive Management Tool..."
    echo -e "${NC}"
    
    # Startup progress animation
    show_progress 1.5 "Loading resources"
    
    # Check for sudo privileges with animation
    echo -ne "${YELLOW}Checking permissions...${NC} "
    sleep 0.5
    check_sudo
    success_msg "Sudo privileges confirmed"
    
    # Check dependencies with animation
    echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${WHITE}Checking dependencies:${NC}$(printf ' %.0s' $(seq 1 31))${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    # Check for cryptsetup
    echo -ne "${BLUE}ℹ${NC} Checking for cryptsetup... "
    sleep 0.7
    if ! command -v cryptsetup &>/dev/null; then
        echo -e "${RED}✗ NOT FOUND${NC}"
        error_msg "cryptsetup is not installed."
        warn_msg "Please install it using your package manager."
        info_msg "For example: sudo apt install cryptsetup"
        exit 1
    else
        echo -e "${GREEN}✓ FOUND${NC}"
    fi
    
    # Check for other optional dependencies
    echo -ne "${BLUE}ℹ${NC} Checking for lsblk... "
    sleep 0.5
    if command -v lsblk &>/dev/null; then
        echo -e "${GREEN}✓ FOUND${NC}"
    else
        echo -e "${YELLOW}⚠ NOT FOUND${NC}"
        warn_msg "lsblk not found. Some features may be limited."
    fi
    
    echo -ne "${BLUE}ℹ${NC} Checking for blkid... "
    sleep 0.5
    if command -v blkid &>/dev/null; then
        echo -e "${GREEN}✓ FOUND${NC}"
    else
        echo -e "${YELLOW}⚠ NOT FOUND${NC}"
        warn_msg "blkid not found. Filesystem detection may be limited."
    fi

    # Add a small delay before showing the menu for the first time
    echo -e "\n${CYAN}Starting menu interface...${NC}"
    sleep 1.5

    # Initialize menu options
    menu_options=(
        "List encrypted devices"
        "Unlock encrypted device"
        "Lock encrypted device"
        "Backup LUKS header"
        "Exit"
    )

    # Main program loop
    while true; do
        show_menu
        # Add prompt to continue after operations
        if [[ $choice != 5 ]]; then
            echo ""
            read -p "$(echo -e "${YELLOW}?${NC} Press Enter to continue...")" dummy
        fi
    done
}

# Start the script with arguments
main "$@"
