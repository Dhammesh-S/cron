#!/bin/bash

# Daily Login Script
# Configuration
SCRIPT_DIR="/data/data/com.termux/files/home/TR3X"
PYTHON_MODULE="config.files.login"
LOG_FILE="/data/data/com.termux/files/home/cron/log/daily_login.log"

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

# ANSI Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    
    case "$level" in
        "OK")    color="$GREEN" ;;
        "ERROR") color="$RED" ;;
        *)       color="$CYAN" ;;
    esac
    
    # Log to file (no colors)
    echo "[$timestamp] $level: $message" >> "$LOG_FILE"
    
    # Display with colors
    echo -e "${color}[$timestamp] $level:${NC} $message"
}

# Notification function
send_notification() {
    local status="$1"
    local message="$2"
    
    if command -v termux-notification >/dev/null 2>&1; then
        case "$status" in
            "success")
                termux-notification --title "Login OK" --content "$message"
                ;;
            "failed")
                termux-notification --title "Login Failed" --content "$message" --priority high
                ;;
        esac
    fi
}

# Main execution
log_message "INFO" "Starting login"

# Change directory
if ! cd "$SCRIPT_DIR"; then
    log_message "ERROR" "Directory not found"
    send_notification "failed" "Directory error"
    exit 1
fi

# Execute login
if python3 -m "$PYTHON_MODULE" >> "$LOG_FILE" 2>&1; then
    log_message "OK" "Login successful"
    send_notification "success" "$(date '+%H:%M')"
else
    log_message "ERROR" "Login failed"
    send_notification "failed" "Check logs"
    exit 1
fi