#!/bin/bash

# Test script to verify auto-shutdown works
# Sets shutdown time to 2 minutes from now

echo "=== Testing Auto-Shutdown Feature ==="
echo ""

# Calculate stop time (2 minutes from now)
STOP_TIME=$(TZ='Asia/Kolkata' date -d '+2 minutes' '+%H:%M')
echo "Current time: $(TZ='Asia/Kolkata' date '+%H:%M:%S')"
echo "Will trigger shutdown at: $STOP_TIME IST"
echo ""

# Create temporary test script
cat > /tmp/test_trading.sh << TESTSCRIPT
#!/bin/bash
LOG_FILE="/root/cron/log/test_autoshutdown.log"
mkdir -p "\$(dirname "\$LOG_FILE")"

log_message() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1" | tee -a "\$LOG_FILE"
}

# Auto-shutdown function
auto_shutdown() {
    while true; do
        sleep 30
        CURRENT_TIME=\$(TZ='Asia/Kolkata' date '+%H:%M')
        log_message "Monitor check: \$CURRENT_TIME (waiting for $STOP_TIME)"
        
        if [[ "\$CURRENT_TIME" == "$STOP_TIME" ]] || [[ "\$CURRENT_TIME" > "$STOP_TIME" ]]; then
            log_message "Auto-shutdown triggered!"
            pkill -f "sleep 600"
            break
        fi
    done
}

auto_shutdown &
log_message "Test started - will run for ~2 minutes"
sleep 600  # Simulate long-running process
log_message "Test completed"
TESTSCRIPT

chmod +x /tmp/test_trading.sh

echo "Starting test (will auto-stop in ~2 minutes)..."
/tmp/test_trading.sh &

echo ""
echo "Monitor with:"
echo "  tail -f /root/cron/log/test_autoshutdown.log"
echo ""
echo "Check after 2 minutes if it auto-stopped"
