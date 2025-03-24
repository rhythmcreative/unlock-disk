#!/bin/bash

# ======================================================
# ANSI Color Codes for pretty output
# ======================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
NC='\033[0m' # No Color

# ======================================================
# Icons for better readability
# ======================================================
CHECK_MARK="${GREEN}✓${NC}"
CROSS_MARK="${RED}✗${NC}"
INFO_MARK="${BLUE}ℹ${NC}"
WARN_MARK="${YELLOW}⚠${NC}"
WORKING_MARK="${CYAN}⟳${NC}"

# ======================================================
# Display functions
# ======================================================
print_header() {
    echo -e "\n${BOLD}${CYAN}$1${NC}\n${DIM}${CYAN}$(printf '=%.0s' {1..50})${NC}\n"
}

print_step() {
    echo -e "${BOLD}${BLUE}[$1/${STEPS}]${NC} ${CYAN}$2${NC}"
}

print_info() {
    echo -e "  ${INFO_MARK} $1"
}

print_success() {
    echo -e "  ${CHECK_MARK} ${GREEN}$1${NC}"
}

print_warning() {
    echo -e "  ${WARN_MARK} ${YELLOW}$1${NC}"
}

print_error() {
    echo -e "  ${CROSS_MARK} ${RED}$1${NC}"
}

print_working() {
    echo -e "  ${WORKING_MARK} ${CYAN}$1${NC}"
}

# ======================================================
# Error handling
# ======================================================
handle_error() {
    print_error "$1"
    if [ "$2" = "fatal" ]; then
        echo -e "\n${RED}${BOLD}Installation failed!${NC}"
        exit 1
    fi
}

# ======================================================
# Animation for visual feedback
# ======================================================
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    echo -en "  ${CYAN}"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        echo -en "\b\b\b\b\b\b"
        sleep $delay
    done
    echo -en "${NC}\n"
}

# ======================================================
# Main Installation Process
# ======================================================
SCRIPT_NAME="unlock_drive.sh"
INSTALL_DIR="/usr/local/bin"
COMPLETION_DIR="/etc/bash_completion.d"
STEPS=7

# Display welcome header
clear
echo -e "${BOLD}${MAGENTA}"
echo "██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     "
echo "██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     "
echo "██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     "
echo "██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     "
echo "██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗"
echo "╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"
echo -e "${NC}\n"
echo -e "${BOLD}${BLUE}LUKS Drive Manager Installer${NC}"
echo -e "${DIM}This will install the unlock_drive.sh utility on your system${NC}\n"

# Check if running with root privileges
print_header "Checking privileges"
if [ "$(id -u)" -ne 0 ]; then
    handle_error "This script must be run as root or with sudo privileges" "fatal"
fi
print_success "Running with appropriate privileges"

# Checking for required dependencies
print_step 1 "Checking dependencies"

DEPENDENCIES=("cryptsetup" "lsblk" "blkid" "mount" "umount" "sudo")
MISSING_DEPS=()

for dep in "${DEPENDENCIES[@]}"; do
    print_working "Checking for $dep..."
    if ! command -v "$dep" &> /dev/null; then
        print_error "$dep is not installed"
        MISSING_DEPS+=("$dep")
    else
        print_success "$dep is installed"
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    print_warning "The following dependencies are missing:"
    for dep in "${MISSING_DEPS[@]}"; do
        echo -e "    ${YELLOW}• $dep${NC}"
    done
    
    read -p "$(echo -e "${BOLD}${YELLOW}Would you like to install missing dependencies? [Y/n]${NC} ")" -n 1 -r REPLY
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_working "Installing missing dependencies..."
        
        # Detect package manager
        if command -v apt &> /dev/null; then
            PKG_MANAGER="apt"
            INSTALL_CMD="apt install -y"
        elif command -v dnf &> /dev/null; then
            PKG_MANAGER="dnf"
            INSTALL_CMD="dnf install -y"
        elif command -v yum &> /dev/null; then
            PKG_MANAGER="yum"
            INSTALL_CMD="yum install -y"
        elif command -v pacman &> /dev/null; then
            PKG_MANAGER="pacman"
            INSTALL_CMD="pacman -S --noconfirm"
        elif command -v zypper &> /dev/null; then
            PKG_MANAGER="zypper"
            INSTALL_CMD="zypper install -y"
        else
            handle_error "Unable to detect package manager. Please install dependencies manually." "fatal"
        fi
        
        for dep in "${MISSING_DEPS[@]}"; do
            print_working "Installing $dep..."
            if $INSTALL_CMD "$dep" &> /dev/null; then
                print_success "$dep installed successfully"
            else
                handle_error "Failed to install $dep"
            fi
        done
    else
        handle_error "Dependencies must be installed to continue" "fatal"
    fi
fi

print_success "All dependencies satisfied"

# Checking if unlock_drive.sh exists in current directory
print_step 2 "Locating unlock_drive.sh"
if [ ! -f "./${SCRIPT_NAME}" ]; then
    handle_error "Could not find ${SCRIPT_NAME} in current directory" "fatal"
fi
print_success "Found ${SCRIPT_NAME} in current directory"

# Create a backup of existing script if it exists
print_step 3 "Backing up existing installation"
if [ -f "${INSTALL_DIR}/${SCRIPT_NAME}" ]; then
    print_working "Creating backup of existing installation..."
    BACKUP_FILE="${INSTALL_DIR}/${SCRIPT_NAME}.backup-$(date +%Y%m%d%H%M%S)"
    if cp "${INSTALL_DIR}/${SCRIPT_NAME}" "${BACKUP_FILE}"; then
        print_success "Backup created at ${BACKUP_FILE}"
    else
        handle_error "Failed to create backup" "fatal"
    fi
else
    print_info "No existing installation found, skipping backup"
fi

# Installing script to target directory
print_step 4 "Installing ${SCRIPT_NAME}"
print_working "Copying ${SCRIPT_NAME} to ${INSTALL_DIR}..."

if cp "./${SCRIPT_NAME}" "${INSTALL_DIR}/"; then
    print_success "${SCRIPT_NAME} copied to ${INSTALL_DIR}"
else
    handle_error "Failed to copy ${SCRIPT_NAME} to ${INSTALL_DIR}" "fatal"
fi

# Setting permissions
print_step 5 "Setting permissions"
print_working "Setting executable permissions..."
if chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"; then
    print_success "Executable permissions set for ${INSTALL_DIR}/${SCRIPT_NAME}"
else
    handle_error "Failed to set executable permissions" "fatal"
fi

# Creating command completion
print_step 6 "Setting up command completion"
if [ -d "$COMPLETION_DIR" ]; then
    print_working "Creating bash completion script..."
    
    # Create a basic completion script
    cat > "${COMPLETION_DIR}/unlock-disk" << 'EOF'
#!/bin/bash
_unlock_disk_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Basic options based on unlock_drive.sh capabilities
    opts="list unlock lock backup help"
    
    # Complete with basic options
    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "--help --version --quiet --verbose" -- ${cur}) )
        return 0
    fi
    
    # Complete with commands
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _unlock_disk_completions unlock-disk
EOF
    
    if [ $? -eq 0 ]; then
        chmod +x "${COMPLETION_DIR}/unlock-disk"
        print_success "Command completion installed"
        
        # Source the completion script for immediate use
        print_info "To use completion in current session, run: source ${COMPLETION_DIR}/unlock-disk"
    else
        print_warning "Failed to create completion script, continuing anyway"
    fi
else
    print_warning "Bash completion directory not found, skipping completion setup"
fi

# Create a symbolic link without .sh extension for easier use
print_working "Creating symbolic link for easier access..."
if ln -sf "${INSTALL_DIR}/${SCRIPT_NAME}" "${INSTALL_DIR}/unlock-disk"; then
    print_success "Created symbolic link: ${INSTALL_DIR}/unlock-disk"
else
    print_warning "Failed to create symbolic link, continuing anyway"
fi

# Final status and verification
print_step 7 "Verifying installation"
if [ -x "${INSTALL_DIR}/${SCRIPT_NAME}" ]; then
    print_success "Installation completed successfully!"
    echo -e "\n${GREEN}${BOLD}✅ LUKS Drive Manager is now installed!${NC}"
    echo -e "\n${CYAN}You can now run:${NC}"
    echo -e "  ${BOLD}${BLUE}unlock-disk${NC} - to use the tool"
    echo -e "  ${BOLD}${BLUE}unlock-disk help${NC} - to see available options"
    echo -e "\n${YELLOW}Note: You may need to restart your terminal or source your .bashrc/.zshrc for completion to work${NC}\n"
else
    handle_error "Installation verification failed" "fatal"
fi

exit 0

