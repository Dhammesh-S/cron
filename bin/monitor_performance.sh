#!/bin/bash
# =============================================================================
# Daily Performance Monitoring Script
# =============================================================================
# Purpose: Generate daily performance reports for SILVERBEES trading
# Schedule: 4:00 PM IST daily (Mon-Fri), 30 min after market close
# 
# Compares actual performance against expected (90% win rate, PF 22.50)
# Generates report file and optionally sends notifications.
# =============================================================================

# Configuration
PROJECT_DIR="/root/TR3X"
VENV_PATH="/usr/local/src/Python-3.10.13/venv"
LOG_DIR="/root/cron/log"
REPORT_DIR="/root/cron/log/reports"
DATE_STR=$(TZ='Asia/Kolkata' date '+%Y%m%d')
REPORT_FILE="$REPORT_DIR/daily_report_$DATE_STR.txt"
LOG_FILE="$LOG_DIR/monitor.log"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$REPORT_DIR"

# Logging function
log_message() {
    echo "[$(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')] $1" | tee -a "$LOG_FILE"
}

log_message "========================================="
log_message "Generating daily performance report"
log_message "========================================="

# Activate virtual environment
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
else
    log_message "ERROR: Virtual environment not found"
    exit 1
fi

# Change to project directory
cd "$PROJECT_DIR" || exit 1

# Generate report header
cat > "$REPORT_FILE" << EOF
================================================================================
TR3X SILVERBEES TRADING - DAILY PERFORMANCE REPORT
================================================================================
Report Date: $(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')
Strategy: BB20+RSI14 (silverbees_bullish_alternative)
Timeframe: Daily (1D)

EXPECTED PERFORMANCE (from walk-forward backtest):
  Win Rate:      90%
  Profit Factor: 22.50
  Trades/Month:  3-4
  Max Drawdown:  0.43%
================================================================================

EOF

# Run session monitor and append to report
python3 research/deployment/session_monitor.py \
    --symbol SILVERBEES \
    --limit 10 \
    >> "$REPORT_FILE" 2>&1

# Add database status
echo "" >> "$REPORT_FILE"
echo "DATABASE STATUS:" >> "$REPORT_FILE"
echo "----------------" >> "$REPORT_FILE"
python3 research/data_collection/shoonya_fetcher.py --symbol SILVERBEES-EQ --status >> "$REPORT_FILE" 2>&1

# Add footer
cat >> "$REPORT_FILE" << EOF

================================================================================
END OF REPORT
Report saved to: $REPORT_FILE
================================================================================
EOF

log_message "Report generated: $REPORT_FILE"

# Display report summary in log
TOTAL_TRADES=$(grep -c "LONG @\|SHORT @" "$REPORT_FILE" 2>/dev/null || echo "0")
log_message "Total trades in recent sessions: $TOTAL_TRADES"

# Optional: Send notification
# Uncomment and configure one of these options:

# Option 1: Email notification (requires mailutils)
# cat "$REPORT_FILE" | mail -s "TR3X Daily Report - $(date '+%Y-%m-%d')" your@email.com

# Option 2: Telegram notification (requires curl and bot token)
# TELEGRAM_BOT_TOKEN="your_bot_token"
# TELEGRAM_CHAT_ID="your_chat_id"
# curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
#     -d chat_id="$TELEGRAM_CHAT_ID" \
#     -d text="$(head -50 $REPORT_FILE)"

log_message "========================================="
log_message ""

exit 0
