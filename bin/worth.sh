#!/data/data/com.termux/files/usr/bin/bash

# Termux Net Worth Notification Script
# Shows net worth in high priority notification

# Configuration
SCRIPT_DIR="$HOME/TR3X"
LOG_DIR="$HOME/.tr3x/logs"
LOG_FILE="$LOG_DIR/worth_notification.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to show notification
show_notification() {
    local title="$1"
    local message="$2"
    local priority="$3"
    
    # Use termux-notification if available
    if command -v termux-notification >/dev/null 2>&1; then
        termux-notification \
            --title "$title" \
            --content "$message" \
            --priority "$priority" \
            --id "networth" \
            --icon "trending_up"
    else
        log "ERROR: termux-notification not available"
        echo "$title: $message"
        exit 1
    fi
}

# Function to format Indian currency
format_currency() {
    local amount="$1"
    
    # Convert to integer for easier formatting
    local int_amount=$(printf "%.0f" "$amount")
    
    # Indian number formatting (lakhs and crores)
    if [ "$int_amount" -ge 10000000 ]; then
        # Crores
        local crores=$(echo "scale=2; $amount / 10000000" | bc)
        echo "₹${crores}Cr"
    elif [ "$int_amount" -ge 100000 ]; then
        # Lakhs
        local lakhs=$(echo "scale=2; $amount / 100000" | bc)
        echo "₹${lakhs}L"
    elif [ "$int_amount" -ge 1000 ]; then
        # Thousands
        local thousands=$(echo "scale=2; $amount / 1000" | bc)
        echo "₹${thousands}K"
    else
        echo "₹${int_amount}"
    fi
}

# Function to get net worth change (daily)
get_networth_change() {
    local current_networth="$1"
    local prev_file="$LOG_DIR/previous_networth.txt"
    
    if [ -f "$prev_file" ]; then
        local prev_networth=$(cat "$prev_file")
        local change=$(echo "scale=2; $current_networth - $prev_networth" | bc)
        local change_percent=$(echo "scale=2; ($change / $prev_networth) * 100" | bc)
        
        # Save current as previous
        echo "$current_networth" > "$prev_file"
        
        # Return change info
        if [ $(echo "$change > 0" | bc) -eq 1 ]; then
            echo "📈 +$(format_currency $change) (+${change_percent}%)"
        elif [ $(echo "$change < 0" | bc) -eq 1 ]; then
            echo "📉 $(format_currency $change) (${change_percent}%)"
        else
            echo "➖ No change"
        fi
    else
        # First run - save current value
        echo "$current_networth" > "$prev_file"
        echo "🎯 First calculation"
    fi
}

# Function to get weekly comparison (for weekends)
get_weekly_comparison() {
    local current_networth="$1"
    local csv_file="$LOG_DIR/worth_history.csv"
    local weekly_file="$LOG_DIR/weekly_networth.txt"
    
    # Check if we have historical data
    if [ ! -f "$csv_file" ]; then
        echo "📊 No weekly data yet"
        return
    fi
    
    # Get current week number
    local current_week=$(date +%Y-%U)
    local last_week=$(date -d "7 days ago" +%Y-%U)
    
    # Get last week's final value (Friday's value)
    local last_week_networth=""
    
    # Try to find last Friday's entry or the last entry from previous week
    for days_back in 1 2 3 4 5 6 7; do
        local check_date=$(date -d "$days_back days ago" +%Y-%m-%d)
        local last_entry=$(grep "^$check_date" "$csv_file" | tail -1 | cut -d',' -f2)
        
        if [ -n "$last_entry" ] && [ "$last_entry" != "networth" ]; then
            # Check if this entry is from previous week
            local entry_week=$(date -d "$check_date" +%Y-%U)
            if [ "$entry_week" = "$last_week" ]; then
                last_week_networth="$last_entry"
                break
            elif [ "$entry_week" != "$current_week" ]; then
                last_week_networth="$last_entry"
                break
            fi
        fi
    done
    
    if [ -n "$last_week_networth" ]; then
        local weekly_change=$(echo "scale=2; $current_networth - $last_week_networth" | bc)
        local weekly_change_percent=$(echo "scale=2; ($weekly_change / $last_week_networth) * 100" | bc)
        
        # Format the comparison
        local this_week_formatted=$(format_currency "$current_networth")
        local last_week_formatted=$(format_currency "$last_week_networth")
        
        if [ $(echo "$weekly_change > 0" | bc) -eq 1 ]; then
            echo "📊 Week: $last_week_formatted → $this_week_formatted
🚀 +$(format_currency $weekly_change) (+${weekly_change_percent}%)"
        elif [ $(echo "$weekly_change < 0" | bc) -eq 1 ]; then
            echo "📊 Week: $last_week_formatted → $this_week_formatted
📉 $(format_currency $weekly_change) (${weekly_change_percent}%)"
        else
            echo "📊 Week: No change ($this_week_formatted)"
        fi
    else
        echo "📊 Not enough weekly data yet"
    fi
}

# Main execution
main() {
    log "Starting net worth calculation"
    
    # Check if in correct directory
    if [ ! -d "$SCRIPT_DIR" ]; then
        log "ERROR: TR3X directory not found at $SCRIPT_DIR"
        show_notification "Net Worth Error" "TR3X directory not found" "high"
        exit 1
    fi
    
    # Change to script directory
    cd "$SCRIPT_DIR" || {
        log "ERROR: Cannot change to $SCRIPT_DIR"
        show_notification "Net Worth Error" "Cannot access TR3X directory" "high"
        exit 1
    }
    
    # Check if Python script exists
    if [ ! -f "worth.py" ]; then
        log "ERROR: worth.py not found in $SCRIPT_DIR"
        show_notification "Net Worth Error" "worth.py script not found" "high"
        exit 1
    fi
    
    # Get net worth (quiet mode returns just the number)
    log "Executing Python net worth calculation"
    local networth_output=$(python -m worth --quiet 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log "ERROR: Python script failed with exit code $exit_code"
        log "ERROR: Output: $networth_output"
        show_notification "Net Worth Error" "Failed to calculate net worth" "high"
        exit 1
    fi
    
    # Validate output is a number
    if ! [[ "$networth_output" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        log "ERROR: Invalid net worth output: $networth_output"
        show_notification "Net Worth Error" "Invalid calculation result" "high"
        exit 1
    fi
    
    local networth="$networth_output"
    log "Net worth calculated: ₹$networth"
    
    # Format the net worth
    local formatted_networth=$(format_currency "$networth")
    
    # Check if it's weekend for weekly comparison
    local day_of_week=$(date +%u)  # 1=Monday, 7=Sunday
    local change_info=""
    
    if [ "$day_of_week" -eq 6 ] || [ "$day_of_week" -eq 7 ]; then
        # Weekend - show weekly comparison
        change_info=$(get_weekly_comparison "$networth")
        local title="💰 Weekly Summary"
    else
        # Weekday - show daily change
        change_info=$(get_networth_change "$networth")
        local title="💰 Net Worth"
    fi
    
    # Create notification message
    local message="$formatted_networth
$change_info
Updated: $(date '+%H:%M %d/%m')"
    
    # Show high priority notification
    show_notification "$title" "$message" "high"
    
    log "Notification sent successfully: $formatted_networth"
    
    # Optional: Also log to a CSV for tracking
    local csv_file="$LOG_DIR/worth_history.csv"
    if [ ! -f "$csv_file" ]; then
        echo "timestamp,networth" > "$csv_file"
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$networth" >> "$csv_file"
}

# Error handling
set -e
trap 'log "Script failed at line $LINENO"' ERR

# Run main function
main "$@"
