#!/bin/bash
# =============================================================================
# ADX TREND DAILY TRADING STRATEGY
# =============================================================================
# Purpose: Run the SILVERBEES ADX Trend strategy (TRENDING_UP regime, LONG only)
# Schedule: 9:15 AM IST daily (Mon-Fri), auto-stops at 3:30 PM IST
# 
# Strategy: silverbees_adx_trend
# Timeframe: 1D (Daily)
# Direction: LONG only
# Regime: TRENDING_UP only
#
# Backtest Results (3 years, Jan 2023 - Jan 2026):
#   Win Rate: 56.0%
#   Profit Factor: 3.71
#   Net P&L: Rs 135.58
#   Trades: 25 (~0.7/month)
#
# Created: 2026-02-03
# =============================================================================

# Configuration
PROJECT_DIR="/root/TR3X"
VENV_PATH="/usr/local/src/Python-3.10.13/venv"
LOG_DIR="/root/cron/log"
LOG_FILE="$LOG_DIR/adx_trend_daily.log"
LOCK_FILE="/tmp/adx_trend_daily.lock"
STOP_TIME="15:30"

# Strategy settings
SYMBOL="SILVERBEES-EQ"
TIMEFRAME="1D"
STRATEGY="silverbees_adx_trend"
CAPITAL="100000.0"
RISK_PERCENT="0.5"

# Deployment script path
DEPLOY_SCRIPT="$PROJECT_DIR/research/silverbees_study/deployment/deploy_adx_trend_daily.py"

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
            PAPER_PID=$(pgrep -f "paper.py.*$SYMBOL.*$TIMEFRAME.*$STRATEGY")
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
                    log_message "Trading session stopped gracefully"
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
log_message "ADX TREND DAILY STRATEGY - SESSION START"
log_message "========================================="
log_message "Symbol:     $SYMBOL"
log_message "Timeframe:  $TIMEFRAME"
log_message "Strategy:   $STRATEGY"
log_message "Capital:    Rs $CAPITAL"
log_message "Risk:       $RISK_PERCENT%"
log_message "Auto-stop:  $STOP_TIME IST"
log_message ""
log_message "Expected Performance (from 3-year backtest):"
log_message "  Win Rate:      56.0%"
log_message "  Profit Factor: 3.71"
log_message "  Trades/Month:  ~0.7"
log_message "  Regime:        TRENDING_UP only"
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

# Check for existing sessions to resume
log_message ""
log_message "Checking for existing sessions..."

EXISTING_SESSION=$(python3 execution/paper.py --list-sessions 2>/dev/null | \
    grep -E "SILVERBEES.*1D" | \
    grep -i "adx_trend\|silverbees_adx" | \
    head -1 | \
    awk '{print $1}')

if [ -n "$EXISTING_SESSION" ]; then
    log_message "Found existing session: $EXISTING_SESSION"
    log_message "Resuming session..."
    RESUME_FLAG="--resume"
else
    log_message "No existing session found. Starting fresh session."
    RESUME_FLAG=""
fi

# Execute the trading script using deployment script
log_message ""
log_message "Launching paper trading session..."
log_message ""

if [ -n "$RESUME_FLAG" ]; then
    python3 "$DEPLOY_SCRIPT" --run --resume >> "$LOG_FILE" 2>&1
else
    python3 "$DEPLOY_SCRIPT" --run >> "$LOG_FILE" 2>&1
fi

EXIT_CODE=$?

# Kill the auto-shutdown monitor if still running
kill $SHUTDOWN_PID 2>/dev/null

# Log completion status
log_message ""
log_message "========================================="
if [ $EXIT_CODE -eq 0 ]; then
    log_message "Trading session completed successfully"
else
    log_message "Trading session ended with exit code: $EXIT_CODE"
fi
log_message "========================================="
log_message ""

exit $EXIT_CODE
