#!/bin/bash

SCRIPT_DIR="/data/data/com.termux/files/home/TR3X"
PYTHON_MODULE="sipvo"
LOG_FILE="$HOME/cron/log/sipvo.log"
NOTIFICATION_TITLE="SIPVO Auto-SIP"

mkdir -p "$(dirname "$LOG_FILE")"

send_notification() {
    termux-notification --title "$1" --content "$2" --priority "$3"
}

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

get_sip_summary() {
    # Extract key information from the log
    local temp_log="/tmp/sipvo_current.log"
    
    # Get current run logs (last 50 lines should be enough)
    tail -50 "$LOG_FILE" > "$temp_log"
    
    local mode=""
    local orders_placed=""
    local total_amount=""
    local retry_count=""
    local fund_status=""
    
    # Check if running in test mode
    if grep -q "Running in TEST MODE" "$temp_log"; then
        mode="TEST"
    else
        mode="LIVE"
    fi
    
    # Get orders placed count
    orders_placed=$(grep -c "Placed order:\|Simulated order:" "$temp_log")
    
    # Get total amount from orders
    total_amount=$(grep -oE "₹[0-9]+\.[0-9]+" "$temp_log" | grep -v "available\|buffer" | tail -1)
    
    # Get retry information
    retry_count=$(grep -oE "Retrying [0-9]+ pending orders" "$temp_log" | grep -oE "[0-9]+")
    
    # Check fund status
    if grep -q "Insufficient liquid funds" "$temp_log"; then
        fund_status="INSUFFICIENT"
    elif grep -q "Sufficient funds available" "$temp_log"; then
        fund_status="SUFFICIENT"
    fi
    
    # Build summary message
    local message="Mode: $mode"
    
    if [ "$orders_placed" -gt 0 ]; then
        message="$message
Orders: $orders_placed placed"
        [ -n "$total_amount" ] && message="$message ($total_amount)"
    else
        message="$message
Orders: None placed"
    fi
    
    [ -n "$retry_count" ] && message="$message
Retries: $retry_count pending"
    
    [ -n "$fund_status" ] && message="$message
Funds: $fund_status"
    
    echo "$message"
    
    rm -f "$temp_log"
}

check_if_sip_day() {
    # Check if today is a SIP day by looking for the skip message
    if tail -10 "$LOG_FILE" | grep -q "is NOT a SIP day"; then
        return 1  # Not a SIP day
    fi
    return 0  # Is a SIP day
}

cd "$SCRIPT_DIR" || {
    log_message "ERROR: cd to $SCRIPT_DIR failed"
    send_notification "$NOTIFICATION_TITLE" "Directory change failed" "high"
    exit 1
}

# Parse command line arguments to pass through to Python module
PYTHON_ARGS=""
TEST_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --test|-t)
            PYTHON_ARGS="$PYTHON_ARGS --test"
            TEST_MODE=true
            shift
            ;;
        --config|-c)
            PYTHON_ARGS="$PYTHON_ARGS --config $2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--test] [--config CONFIG_FILE]"
            exit 1
            ;;
    esac
done

log_message "Starting SIPVO process with args: $PYTHON_ARGS"

if python3 -m "$PYTHON_MODULE" $PYTHON_ARGS >>"$LOG_FILE" 2>&1; then
    log_message "SUCCESS: SIPVO script completed"

    time=$(date '+%H:%M')
    
    # Check if it was a SIP day
    if ! check_if_sip_day; then
        # Not a SIP day - send minimal notification
        tomorrow=$(date -d '+1 day' '+%d')
        message="Time: $time
Status: Not SIP day
Tomorrow: ${tomorrow}th"
        
        # Check if tomorrow might be SIP day (1st or 15th)
        if [[ "$tomorrow" == "1" ]] || [[ "$tomorrow" == "15" ]]; then
            message="$message
⚠️ Prepare funds!"
            send_notification "$NOTIFICATION_TITLE" "$message" "default"
        else
            send_notification "$NOTIFICATION_TITLE" "$message" "low"
        fi
    else
        # Was a SIP day - send detailed summary
        summary=$(get_sip_summary)
        
        message="Time: $time
$summary"

        # Determine notification priority
        priority="default"
        if echo "$summary" | grep -q "INSUFFICIENT"; then
            priority="high"
        elif echo "$summary" | grep -q "TEST"; then
            priority="low"
        fi

        send_notification "$NOTIFICATION_TITLE" "$message" "$priority"
    fi

else
    log_message "ERROR: SIPVO script failed"

    time=$(date '+%H:%M')
    
    # Extract error information
    error_line=$(grep -E 'ERROR|FAILED|Exception' "$LOG_FILE" | tail -1)
    error_msg="Script execution failed"
    
    if [ -n "$error_line" ]; then
        # Clean up the error message
        error_msg=$(echo "$error_line" | sed -E 's/^[0-9-]+ [0-9:]+.*?(ERROR|FAILED)[: ]*//g' | head -c 100)
    fi

    message="Time: $time
Status: FAILED
Error: $error_msg"

    send_notification "$NOTIFICATION_TITLE" "$message" "high"
    exit 1
fi

log_message "SIPVO process finished"