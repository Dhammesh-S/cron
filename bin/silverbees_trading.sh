#!/bin/bash

# SILVERBEES Trading Strategy Auto-Execution Script
# Starts: 9:00 AM IST daily
# Stops: 3:35 PM IST daily (auto-shutdown)
# Strategy: silverbees_bullish on 15M timeframe

# Configuration
PROJECT_DIR="/root/TR3X"
SCRIPT_PATH="$PROJECT_DIR/execution/paper.py"
LOG_DIR="/root/cron/log"
LOG_FILE="$LOG_DIR/silverbees_trading.log"
VENV_PATH="/usr/local/src/Python-3.10.13/venv"
LOCK_FILE="/tmp/silverbees_trading.lock"
STOP_TIME="15:35"  # Market close + 5 min buffer

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
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
            
            # Find the paper.py process and send SIGTERM
            PAPER_PID=$(pgrep -f "paper.py.*SILVERBEES")
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
                log_message "INFO: No trading process found"
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
log_message "Starting SILVERBEES trading strategy"
log_message "Symbol: SILVERBEES-EQ"
log_message "Timeframe: 15M"
log_message "Strategy: silverbees_bullish"
log_message "Auto-shutdown scheduled: $STOP_TIME IST"
log_message "========================================="

# Activate virtual environment
if [ -f "$VENV_PATH/bin/activate" ]; then
    log_message "Activating virtual environment: $VENV_PATH"
    source "$VENV_PATH/bin/activate"
else
    log_message "WARNING: Virtual environment not found at $VENV_PATH"
fi

# Change to project directory
if ! cd "$PROJECT_DIR"; then
    log_message "ERROR: Failed to change directory to $PROJECT_DIR"
    kill $SHUTDOWN_PID 2>/dev/null
    exit 1
fi

log_message "Changed directory to: $(pwd)"
log_message "Using Python: $(which python3)"

# Execute the trading script
log_message "Executing trading script..."

python3 "$SCRIPT_PATH" \
    --auto-run \
    --symbol "SILVERBEES-EQ" \
    --timeframe 15M \
    --strategy silverbees_bullish \
    >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

# Kill the auto-shutdown monitor if still running
kill $SHUTDOWN_PID 2>/dev/null

# Log completion status
if [ $EXIT_CODE -eq 0 ]; then
    log_message "✓ Trading script completed successfully"
else
    log_message "✗ ERROR: Trading script failed with exit code $EXIT_CODE"
fi

log_message "========================================="
log_message ""

exit $EXIT_CODE
