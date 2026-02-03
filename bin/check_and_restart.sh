#!/bin/bash

# Script to check if trading session is stuck and restart if needed

LOG_FILE="/root/cron/log/silverbees_trading.log"
CHECK_LOG="/root/cron/log/health_check.log"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$CHECK_LOG"
}

# Get last tick count from logs
LAST_TICK_LINE=$(tail -100 "$LOG_FILE" | grep "Session active" | tail -1)
CURRENT_TICK=$(echo "$LAST_TICK_LINE" | grep -oP 'received \K[0-9]+' || echo "0")

log_msg "Current tick count: $CURRENT_TICK"

# Check if session is stuck (no new ticks in last check)
STATE_FILE="/root/TR3X/output/paper/sessions/20260128_092249_SILVERBEES_EQ_15M/state.json"

if [ -f "$STATE_FILE" ]; then
    SAVED_TIME=$(cat "$STATE_FILE" | python3 -c "import sys,json; print(json.load(sys.stdin)['saved_at'])" 2>/dev/null)
    log_msg "Last save: $SAVED_TIME"
    
    # If tick count hasn't changed in multiple checks, session might be stuck
    if [ -f /tmp/last_tick_count ]; then
        LAST_COUNT=$(cat /tmp/last_tick_count)
        if [ "$CURRENT_TICK" == "$LAST_COUNT" ]; then
            log_msg "⚠️  WARNING: Tick count unchanged - websocket may be stuck"
            log_msg "   Consider manual restart if this persists"
        else
            log_msg "✅ Session healthy - tick count increasing"
        fi
    fi
    
    echo "$CURRENT_TICK" > /tmp/last_tick_count
else
    log_msg "❌ Session state file not found"
fi

# Check if process is running
if ps aux | grep "paper.py.*SILVERBEES" | grep -v grep > /dev/null; then
    log_msg "✅ Process is running"
else
    log_msg "❌ Process is NOT running"
fi
