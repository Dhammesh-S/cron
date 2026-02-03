#!/bin/bash
# =============================================================================
# BB20+RSI14 Daily Trading Strategy
# =============================================================================
# Purpose: Run the optimized SILVERBEES strategy (90% win rate from backtest)
# Schedule: 9:00 AM IST daily (Mon-Fri), auto-stops at 3:35 PM IST
# 
# Strategy: silverbees_bullish_alternative (BB20+RSI14)
# Timeframe: 1D (Daily)
# Expected: 90% win rate, PF 22.50, 3-4 trades/month
#
# This replaces the old EMA5+RSI14 on 15M strategy which had 0% win rate.
# =============================================================================

# Configuration
PROJECT_DIR="/root/TR3X"
VENV_PATH="/usr/local/src/Python-3.10.13/venv"
LOG_DIR="/root/cron/log"
LOG_FILE="$LOG_DIR/bb20_daily_trading.log"
LOCK_FILE="/tmp/bb20_daily_trading.lock"
STOP_TIME="15:35"

# Strategy settings
SYMBOL="SILVERBEES-EQ"
TIMEFRAME="1D"
STRATEGY="silverbees_bullish_alternative"
CAPITAL="100000.0"
RISK_PERCENT="2.0"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log_message() {
    echo "[$(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')] $1" | tee -a "$LOG_FILE"
}

# Check if another instance is already running
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        log_message "ERROR: Another instance is already running (PID: $LOCK_PID)"
        log_message "If this is incorrect, remove: $LOCK_FILE"
        exit 1
    else
        # Stale lock file, remove it
        rm -f "$LOCK_FILE"
        log_message "Removed stale lock file"
    fi
fi

# Create lock file with current PID
echo $$ > "$LOCK_FILE"

# Remove lock file on exit
trap "rm -f $LOCK_FILE" EXIT

# Function to stop trading at specified time
auto_shutdown() {
    while true; do
        sleep 60  # Check every minute
        
        CURRENT_TIME=$(TZ='Asia/Kolkata' date '+%H:%M')
        
        if [[ "$CURRENT_TIME" == "$STOP_TIME" ]] || [[ "$CURRENT_TIME" > "$STOP_TIME" ]]; then
            log_message "========================================="
            log_message "Auto-shutdown triggered at $CURRENT_TIME IST"
            log_message "Market close time reached: $STOP_TIME IST"
            log_message "Sending graceful shutdown signal..."
            log_message "========================================="
            
            # Find the paper.py process for this strategy
            PAPER_PID=$(pgrep -f "paper.py.*$SYMBOL.*$TIMEFRAME")
            if [ -n "$PAPER_PID" ]; then
                kill -SIGTERM "$PAPER_PID"
                log_message "SIGTERM sent to PID: $PAPER_PID"
                
                # Wait for graceful shutdown
                sleep 10
                
                if kill -0 "$PAPER_PID" 2>/dev/null; then
                    log_message "WARNING: Process still running, waiting..."
                    sleep 10
                fi
                
                if ! kill -0 "$PAPER_PID" 2>/dev/null; then
                    log_message "✓ Trading session stopped gracefully"
                fi
            else
                log_message "INFO: No trading process found to stop"
            fi
            
            break
        fi
    done
}

# Start auto-shutdown monitor in background
auto_shutdown &
SHUTDOWN_PID=$!

# Start execution
log_message "========================================="
log_message "BB20+RSI14 DAILY STRATEGY - SESSION START"
log_message "========================================="
log_message "Symbol:     $SYMBOL"
log_message "Timeframe:  $TIMEFRAME"
log_message "Strategy:   $STRATEGY"
log_message "Capital:    $CAPITAL"
log_message "Risk:       $RISK_PERCENT%"
log_message "Auto-stop:  $STOP_TIME IST"
log_message ""
log_message "Expected Performance (from walk-forward backtest):"
log_message "  Win Rate:      90%"
log_message "  Profit Factor: 22.50"
log_message "  Trades/Month:  3-4"
log_message "========================================="

# Activate virtual environment
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    log_message "Virtual environment activated"
else
    log_message "ERROR: Virtual environment not found at $VENV_PATH"
    kill $SHUTDOWN_PID 2>/dev/null
    exit 1
fi

# Change to project directory
if ! cd "$PROJECT_DIR"; then
    log_message "ERROR: Failed to change to $PROJECT_DIR"
    kill $SHUTDOWN_PID 2>/dev/null
    exit 1
fi

log_message "Working directory: $(pwd)"
log_message "Python: $(which python3)"

# Execute the trading script
log_message "Launching paper trading session..."
log_message ""

python3 execution/paper.py \
    --auto-run \
    --symbol "$SYMBOL" \
    --timeframe "$TIMEFRAME" \
    --strategy "$STRATEGY" \
    --capital "$CAPITAL" \
    --risk-percent "$RISK_PERCENT" \
    --resume \
    >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

# Kill the auto-shutdown monitor if still running
kill $SHUTDOWN_PID 2>/dev/null

# Log completion status
log_message ""
log_message "========================================="
if [ $EXIT_CODE -eq 0 ]; then
    log_message "✓ Trading session completed successfully"
else
    log_message "✗ Trading session failed with exit code: $EXIT_CODE"
fi
log_message "========================================="
log_message ""

exit $EXIT_CODE
