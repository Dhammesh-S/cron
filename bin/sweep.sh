#!/bin/bash

SCRIPT_DIR="/data/data/com.termux/files/home/TR3X"
PYTHON_MODULE="sebi_payout"
LOG_FILE="$HOME/cron/log/sebi_payout.log"
NOTIFICATION_TITLE="SEBI Auto-Payout"

mkdir -p "$(dirname "$LOG_FILE")"

send_notification() {
    termux-notification --title "$1" --content "$2" --priority "$3"
}

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

cd "$SCRIPT_DIR" || {
    log_message "ERROR: cd to $SCRIPT_DIR failed"
    send_notification "$NOTIFICATION_TITLE" "cd failed" "high"
    exit 1
}

log_message "Starting SEBI payout process..."

if python3 -m "$PYTHON_MODULE" >>"$LOG_FILE" 2>&1; then
    log_message "SUCCESS: payout script completed"

    time=$(date '+%H:%M')
    # Extract last log segment for decision
    action=$(grep -E 'Decision:' "$LOG_FILE" | tail -1 | sed 's/^.*Decision: //g' | xargs)
    reason=$(grep -E 'Reason:' "$LOG_FILE" | tail -1 | sed 's/^.*Reason: //g' | xargs)
    amount=$(grep -E 'Amount:' "$LOG_FILE" | tail -1 | sed 's/^.*Amount: //g' | xargs)

    message="Time: $time
Decision: $action
Reason: $reason"
    [ -n "$amount" ] && message="$message
Amount: ₹$amount"

    send_notification "$NOTIFICATION_TITLE" "$message" "default"

else
    log_message "ERROR: payout script failed"

    time=$(date '+%H:%M')
    err=$(grep -E 'FAIL|ERROR' "$LOG_FILE" | tail -1 | sed -E 's/^.*(FAIL|ERROR)[: ]+//g' | xargs)

    message="Time: $time
Failure: $err"

    send_notification "$NOTIFICATION_TITLE" "$message" "high"
fi

log_message "SEBI payout process finished"