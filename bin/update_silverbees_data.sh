#!/bin/bash
# =============================================================================
# SILVERBEES Data Update Script
# =============================================================================
# Purpose: Fetch latest OHLCV data from Shoonya API and update SQLite database
# Schedule: 8:30 AM IST daily (Mon-Fri), before market open
# 
# This ensures the trading strategy has fresh data for warmup indicators.
# Fetches 7 days of data to cover weekend gaps and any missing candles.
# =============================================================================

# Configuration
PROJECT_DIR="/root/TR3X"
VENV_PATH="/usr/local/src/Python-3.10.13/venv"
LOG_DIR="/root/cron/log"
LOG_FILE="$LOG_DIR/data_update.log"
SYMBOL="SILVERBEES-EQ"
DAYS_TO_FETCH=7

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log_message() {
    echo "[$(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')] $1" | tee -a "$LOG_FILE"
}

# Start
log_message "========================================="
log_message "SILVERBEES Data Update Starting"
log_message "Symbol: $SYMBOL"
log_message "Fetching: Last $DAYS_TO_FETCH days"
log_message "========================================="

# Activate virtual environment
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    log_message "Virtual environment activated"
else
    log_message "ERROR: Virtual environment not found at $VENV_PATH"
    exit 1
fi

# Change to project directory
if ! cd "$PROJECT_DIR"; then
    log_message "ERROR: Failed to change to $PROJECT_DIR"
    exit 1
fi

# Show database status before update
log_message "Database status BEFORE update:"
python3 research/data_collection/shoonya_fetcher.py --symbol "$SYMBOL" --status >> "$LOG_FILE" 2>&1

# Fetch data from Shoonya API
log_message "Fetching data from Shoonya API..."
python3 research/data_collection/shoonya_fetcher.py \
    --symbol "$SYMBOL" \
    --days "$DAYS_TO_FETCH" \
    --all-timeframes \
    >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

# Show database status after update
log_message "Database status AFTER update:"
python3 research/data_collection/shoonya_fetcher.py --symbol "$SYMBOL" --status >> "$LOG_FILE" 2>&1

# Log result
if [ $EXIT_CODE -eq 0 ]; then
    log_message "✓ Data update completed successfully"
else
    log_message "✗ Data update failed with exit code: $EXIT_CODE"
fi

log_message "========================================="
log_message ""

exit $EXIT_CODE
