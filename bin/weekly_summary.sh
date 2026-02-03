#!/bin/bash
# =============================================================================
# Weekly Summary Script
# =============================================================================
# Purpose: Generate comprehensive weekly trading summary
# Schedule: Friday 5:00 PM IST
# 
# Analyzes all sessions from the week and compares against expected performance.
# =============================================================================

# Configuration
PROJECT_DIR="/root/TR3X"
VENV_PATH="/usr/local/src/Python-3.10.13/venv"
LOG_DIR="/root/cron/log"
REPORT_DIR="/root/cron/log/reports"
DATE_STR=$(TZ='Asia/Kolkata' date '+%Y%m%d')
REPORT_FILE="$REPORT_DIR/weekly_summary_$DATE_STR.txt"
LOG_FILE="$LOG_DIR/weekly.log"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$REPORT_DIR"

# Logging function
log_message() {
    echo "[$(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')] $1" | tee -a "$LOG_FILE"
}

log_message "========================================="
log_message "Generating weekly summary report"
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

# Calculate week dates
WEEK_END=$(TZ='Asia/Kolkata' date '+%Y-%m-%d')
WEEK_START=$(TZ='Asia/Kolkata' date -d '7 days ago' '+%Y-%m-%d')

# Generate report header
cat > "$REPORT_FILE" << EOF
================================================================================
TR3X SILVERBEES TRADING - WEEKLY SUMMARY
================================================================================
Week: $WEEK_START to $WEEK_END
Generated: $(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')

Strategy: BB20+RSI14 (silverbees_bullish_alternative)
Timeframe: Daily (1D)

EXPECTED WEEKLY PERFORMANCE:
  Trades Expected: 0-1 (3-4 per month = ~1 per week)
  Win Rate Target: 90%
  
================================================================================

ALL SESSIONS THIS WEEK:
-----------------------

EOF

# Run session monitor for all sessions
python3 research/deployment/session_monitor.py \
    --symbol SILVERBEES \
    --all \
    >> "$REPORT_FILE" 2>&1

# Add data quality check
echo "" >> "$REPORT_FILE"
echo "DATA QUALITY CHECK:" >> "$REPORT_FILE"
echo "-------------------" >> "$REPORT_FILE"
python3 research/data_collection/shoonya_fetcher.py --symbol SILVERBEES-EQ --status >> "$REPORT_FILE" 2>&1

# Calculate weekly stats from logs
echo "" >> "$REPORT_FILE"
echo "LOG FILE SIZES THIS WEEK:" >> "$REPORT_FILE"
echo "-------------------------" >> "$REPORT_FILE"
ls -lh /root/cron/log/*.log 2>/dev/null | tail -10 >> "$REPORT_FILE"

# Add recommendations
cat >> "$REPORT_FILE" << EOF

================================================================================
RECOMMENDATIONS:
================================================================================
1. If win rate < 80%: Check for market regime change
2. If 0 trades: Normal for daily timeframe (expect 3-4/month)
3. If data gaps: Run manual data update script
4. If authentication errors: Check Shoonya credentials

Commands for troubleshooting:
  # Update data manually
  python research/data_collection/shoonya_fetcher.py --symbol SILVERBEES-EQ --days 7 --all-timeframes
  
  # Check session details
  python research/deployment/session_monitor.py --symbol SILVERBEES --all
  
  # View recent logs
  tail -100 /root/cron/log/bb20_daily_trading.log

================================================================================
END OF WEEKLY SUMMARY
================================================================================
EOF

log_message "Weekly summary generated: $REPORT_FILE"
log_message "========================================="
log_message ""

# Optional: Send notification
# cat "$REPORT_FILE" | mail -s "TR3X Weekly Summary - $WEEK_END" your@email.com

exit 0
