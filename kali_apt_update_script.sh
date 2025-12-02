#!/bin/bash

# Kali Linux / Debian apt Package Update Checker
# Check and execute updates for apt (apt update && apt upgrade)

set -e  # Exit on error

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_note() {
    echo -e "${CYAN}[NOTE]${NC} $1"
}

log_security() {
    echo -e "${MAGENTA}[SECURITY]${NC} $1"
}

# Check root permission (for apt)
check_root_permission() {
    if [ "$EUID" -ne 0 ] && [ "$USE_SUDO" = true ]; then
        if ! command -v sudo &> /dev/null; then
            log_error "sudo command not found. Please run as root or install sudo."
            exit 1
        fi
        APT_CMD="sudo apt"
        APT_GET_CMD="sudo apt-get"
    elif [ "$EUID" -eq 0 ]; then
        APT_CMD="apt"
        APT_GET_CMD="apt-get"
    else
        log_error "apt requires root privileges or sudo."
        exit 1
    fi
}

# Check existence of apt
check_package_manager() {
    if ! command -v apt &> /dev/null; then
        log_error "apt command not found. Please run on Debian-based system."
        exit 1
    fi
    
    # Check if running on Kali Linux
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "kali" ]]; then
            log_info "Detected Kali Linux system."
            IS_KALI=true
        elif [[ "$ID_LIKE" == *"debian"* ]] || [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]]; then
            log_info "Detected Debian-based system: $PRETTY_NAME"
            IS_KALI=false
        else
            log_warning "Unknown system: $PRETTY_NAME"
            IS_KALI=false
        fi
    fi
}

# Display current system status
show_current_status() {
    log_info "Checking current system status..."
    echo ""
    
    # System information
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        log_note "OS: $PRETTY_NAME"
    fi
    
    # Kernel version
    log_note "Kernel version: $(uname -r)"
    
    # Installed package count
    INSTALLED_COUNT=$(dpkg -l | grep "^ii" | wc -l || echo "0")
    log_info "Installed packages: $INSTALLED_COUNT"
    
    # Disk usage
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
    log_info "Root filesystem usage: $DISK_USAGE"
    
    # APT cache size
    if [ -d "/var/cache/apt/archives" ]; then
        CACHE_SIZE=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1 || echo "unknown")
        log_info "APT cache size: $CACHE_SIZE"
    fi
    
    # Check for held packages
    HELD_COUNT=$(apt-mark showhold 2>/dev/null | wc -l || echo "0")
    if [ "$HELD_COUNT" -gt 0 ]; then
        log_warning "Held packages: $HELD_COUNT"
    fi
    
    echo ""
}

# Check upgradable packages
check_updates() {
    log_info "Checking for available updates..."
    
    # Update package list
    log_info "Updating package lists..."
    if ! $APT_CMD update &> /dev/null; then
        log_error "Failed to update package lists."
        return 1
    fi
    
    # Check upgradable packages
    UPGRADABLE_OUTPUT=$(apt list --upgradable 2>/dev/null | grep -v "Listing" || echo "")
    
    if [ -z "$UPGRADABLE_OUTPUT" ]; then
        log_success "All packages are up to date!"
        return 1
    else
        UPGRADABLE_COUNT=$(echo "$UPGRADABLE_OUTPUT" | grep -c "/" || echo "0")
        
        if [ "$UPGRADABLE_COUNT" -eq 0 ]; then
            log_success "All packages are up to date!"
            return 1
        else
            log_warning "Upgradable packages: $UPGRADABLE_COUNT"
            echo ""
            
            # Check for security updates
            SECURITY_COUNT=$(echo "$UPGRADABLE_OUTPUT" | grep -c "security" || echo "0")
            if [ "$SECURITY_COUNT" -gt 0 ]; then
                log_security "Security updates available: $SECURITY_COUNT"
            fi
            
            log_info "List of upgradable packages:"
            echo "$UPGRADABLE_OUTPUT" | head -20 | while read -r line; do
                if echo "$line" | grep -q "security"; then
                    echo -e "  ${MAGENTA}•${NC} $line"
                else
                    echo "  • $line"
                fi
            done
            
            if [ "$UPGRADABLE_COUNT" -gt 20 ]; then
                echo "  ... and $((UPGRADABLE_COUNT - 20)) more"
            fi
            
            echo ""
            return 0
        fi
    fi
}

# Check for distribution upgrades
check_dist_upgrade() {
    log_info "Checking for distribution upgrades..."
    
    DIST_UPGRADE_OUTPUT=$($APT_GET_CMD --simulate dist-upgrade 2>/dev/null | grep "^Inst\|^Remv" || echo "")
    
    if [ -n "$DIST_UPGRADE_OUTPUT" ]; then
        DIST_UPGRADE_COUNT=$(echo "$DIST_UPGRADE_OUTPUT" | wc -l)
        log_warning "Distribution upgrade will affect $DIST_UPGRADE_COUNT packages"
        
        if [ "$SHOW_DIST_DETAILS" = true ]; then
            echo ""
            log_note "Distribution upgrade details:"
            echo "$DIST_UPGRADE_OUTPUT" | head -10
            if [ "$DIST_UPGRADE_COUNT" -gt 10 ]; then
                echo "  ... and $((DIST_UPGRADE_COUNT - 10)) more"
            fi
            echo ""
        fi
    fi
}

# Execute apt update and upgrade
perform_update() {
    log_info "Starting package update..."
    echo ""
    
    START_TIME=$(date)
    log_info "Executing apt update && apt upgrade..."
    echo ""
    
    # Execute update
    if $APT_CMD update; then
        echo ""
        log_success "Package lists updated successfully."
        echo ""
        
        # Execute upgrade
        if [ "$DIST_UPGRADE_MODE" = true ]; then
            log_info "Executing apt dist-upgrade..."
            if $APT_CMD dist-upgrade -y; then
                echo ""
                log_success "Distribution upgrade completed!"
            else
                log_error "Error occurred during dist-upgrade."
                return 1
            fi
        else
            log_info "Executing apt upgrade..."
            if $APT_CMD upgrade -y; then
                echo ""
                log_success "Package upgrade completed!"
            else
                log_error "Error occurred during upgrade."
                return 1
            fi
        fi
        
        END_TIME=$(date)
        echo ""
        log_info "Start time: $START_TIME"
        log_info "End time: $END_TIME"
        return 0
    else
        log_error "Failed to update package lists."
        return 1
    fi
}

# Execute full upgrade (dist-upgrade)
perform_full_upgrade() {
    log_info "Starting full system upgrade (dist-upgrade)..."
    echo ""
    
    START_TIME=$(date)
    log_info "Executing apt update && apt full-upgrade..."
    echo ""
    
    if $APT_CMD update && $APT_CMD full-upgrade -y; then
        echo ""
        log_success "Full system upgrade completed!"
        END_TIME=$(date)
        echo ""
        log_info "Start time: $START_TIME"
        log_info "End time: $END_TIME"
        return 0
    else
        log_error "Error occurred during full upgrade."
        return 1
    fi
}

# Suggest cleanup options
suggest_cleanup() {
    echo ""
    log_note "System cleanup options:"
    echo "Remove unnecessary packages: $APT_CMD autoremove"
    echo "Clear package cache: $APT_CMD clean"
    echo "Remove old kernel versions: $APT_CMD autoremove --purge"
    
    # Check autoremovable packages
    AUTOREMOVE_COUNT=$($APT_GET_CMD --simulate autoremove 2>/dev/null | grep -c "^Remv" || echo "0")
    
    if [ "$AUTOREMOVE_COUNT" -gt 0 ]; then
        echo ""
        log_warning "Unnecessary packages can be removed: $AUTOREMOVE_COUNT"
        read -p "Remove unnecessary packages? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $APT_CMD autoremove -y && log_success "Unnecessary packages removed."
        fi
    fi
    
    # Offer to clean cache
    if [ -d "/var/cache/apt/archives" ]; then
        CACHE_SIZE=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1 || echo "unknown")
        echo ""
        log_info "Current cache size: $CACHE_SIZE"
        read -p "Clean APT cache? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $APT_CMD clean && log_success "APT cache cleaned."
        fi
    fi
}

# Help message
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -f, --force          Execute updates without confirmation"
    echo "  -c, --check          Check only (do not update)"
    echo "  -d, --dist-upgrade   Use dist-upgrade instead of upgrade"
    echo "  -F, --full-upgrade   Use full-upgrade (same as dist-upgrade)"
    echo "  -s, --security-only  Show security updates only"
    echo "  -n, --no-sudo        Do not use sudo (assume root execution)"
    echo "  -q, --quiet          Suppress detailed output"
    echo "  --auto-cleanup       Automatically run autoremove and clean after update"
    echo ""
}

# Command line argument processing
FORCE_UPDATE=false
CHECK_ONLY=false
DIST_UPGRADE_MODE=false
FULL_UPGRADE_MODE=false
SECURITY_ONLY=false
USE_SUDO=true
QUIET_MODE=false
AUTO_CLEANUP=false
SHOW_DIST_DETAILS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE_UPDATE=true
            shift
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -d|--dist-upgrade)
            DIST_UPGRADE_MODE=true
            SHOW_DIST_DETAILS=true
            shift
            ;;
        -F|--full-upgrade)
            FULL_UPGRADE_MODE=true
            shift
            ;;
        -s|--security-only)
            SECURITY_ONLY=true
            shift
            ;;
        -n|--no-sudo)
            USE_SUDO=false
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        --auto-cleanup)
            AUTO_CLEANUP=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main processing
main() {
    if [ "$QUIET_MODE" = false ]; then
        echo "========================================"
        echo "    Kali Linux / Debian apt Updater"
        echo "========================================"
        echo ""
    fi
    
    # Check permissions and package manager
    check_root_permission
    check_package_manager
    
    # Show current status (unless in quiet mode)
    if [ "$QUIET_MODE" = false ]; then
        show_current_status
    fi
    
    # Check for updates
    HAS_UPDATES=false
    if check_updates; then
        HAS_UPDATES=true
    fi
    
    # Check for dist-upgrade differences
    if [ "$DIST_UPGRADE_MODE" = true ] || [ "$FULL_UPGRADE_MODE" = true ]; then
        check_dist_upgrade
    fi
    
    # Execute updates
    if [ "$HAS_UPDATES" = true ]; then
        if [ "$CHECK_ONLY" = true ]; then
            log_info "Check-only mode. Updates will not be executed."
            exit 0
        fi
        
        if [ "$FORCE_UPDATE" = true ]; then
            log_info "Force update mode: executing updates..."
        else
            echo ""
            if [ "$FULL_UPGRADE_MODE" = true ]; then
                read -p "Execute full-upgrade? (y/N): " -n 1 -r
            elif [ "$DIST_UPGRADE_MODE" = true ]; then
                read -p "Execute dist-upgrade? (y/N): " -n 1 -r
            else
                read -p "Execute updates? (y/N): " -n 1 -r
            fi
            echo ""
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Update cancelled."
                exit 0
            fi
        fi
        
        # Execute appropriate update command
        if [ "$FULL_UPGRADE_MODE" = true ]; then
            perform_full_upgrade
        else
            perform_update
        fi
        
        # Auto cleanup if requested
        if [ "$AUTO_CLEANUP" = true ]; then
            echo ""
            log_info "Running automatic cleanup..."
            $APT_CMD autoremove -y &> /dev/null && log_success "Autoremove completed."
            $APT_CMD clean &> /dev/null && log_success "Cache cleaned."
        elif [ "$QUIET_MODE" = false ] && [ "$FORCE_UPDATE" = false ]; then
            # Suggest cleanup
            suggest_cleanup
        fi
        
    else
        log_success "All packages are up to date!"
    fi
    
    if [ "$QUIET_MODE" = false ]; then
        echo ""
        log_info "Script completed."
    fi
}

# Interrupt handling
trap 'log_error "Script interrupted."; exit 130' INT

# Execute script
main "$@"