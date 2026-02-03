#!/bin/bash
# =============================================================================
# WEEKLY SUMMARY - ALL 3 SILVERBEES STRATEGIES
# =============================================================================
# Purpose: Generate comprehensive weekly performance report
# Schedule: Fridays 5:00 PM IST
# 
# Strategies covered:
#   1. BB20+RSI14 Daily (silverbees_bullish_alternative)
#   2. ADX Trend Daily (silverbees_adx_trend)
#   3. Volatility Scalper 1H (silverbees_volatility_scalper)
#
# Created: 2026-02-03
# =============================================================================

# Configuration
PROJECT_DIR="/root/TR3X"
VENV_PATH="/usr/local/src/Python-3.10.13/venv"
LOG_DIR="/root/cron/log"
SUMMARY_LOG="$LOG_DIR/weekly_summary_all.log"
SESSION_DIR="$PROJECT_DIR/paper_sessions"

# Strategy definitions
declare -A STRATEGIES
STRATEGIES[bb20]="silverbees_bullish_alternative|1D|BB20+RSI14 Daily|90.0|22.50|3.0"
STRATEGIES[adx]="silverbees_adx_trend|1D|ADX Trend Daily|56.0|3.71|0.7"
STRATEGIES[scalper]="silverbees_volatility_scalper|1H|Volatility Scalper 1H|52.9|1.87|8.7"

# Get current week info
WEEK_START=$(TZ='Asia/Kolkata' date -d "last monday" '+%Y-%m-%d' 2>/dev/null || TZ='Asia/Kolkata' date -v-monday '+%Y-%m-%d')
WEEK_END=$(TZ='Asia/Kolkata' date '+%Y-%m-%d')
WEEK_NUM=$(TZ='Asia/Kolkata' date '+%V')

# Logging function
log_message() {
    echo "$1" | tee -a "$SUMMARY_LOG"
}

# Create log directory
mkdir -p "$LOG_DIR"

# Header
log_message ""
log_message "==============================================================================="
log_message "   SILVERBEES TRADING - WEEKLY SUMMARY REPORT"
log_message "==============================================================================="
log_message "   Week: $WEEK_NUM ($WEEK_START to $WEEK_END)"
log_message "   Generated: $(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')"
log_message "==============================================================================="
log_message ""

# Activate virtual environment
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    cd "$PROJECT_DIR"
fi

# ===============================================================================
# STRATEGY 1: BB20+RSI14 Daily
# ===============================================================================
log_message "┌─────────────────────────────────────────────────────────────────────────────┐"
log_message "│ STRATEGY 1: BB20+RSI14 DAILY                                               │"
log_message "├─────────────────────────────────────────────────────────────────────────────┤"
log_message "│ Expected: Win Rate 90%, PF 22.50, ~3 trades/month                          │"
log_message "└─────────────────────────────────────────────────────────────────────────────┘"

# Check for BB20 log
BB20_LOG="$LOG_DIR/bb20_daily_trading.log"
if [ -f "$BB20_LOG" ]; then
    # Count this week's entries
    WEEK_ENTRIES=$(grep -c "$WEEK_START\|$(TZ='Asia/Kolkata' date -d '1 day ago' '+%Y-%m-%d')\|$(TZ='Asia/Kolkata' date -d '2 days ago' '+%Y-%m-%d')\|$(TZ='Asia/Kolkata' date -d '3 days ago' '+%Y-%m-%d')\|$(TZ='Asia/Kolkata' date -d '4 days ago' '+%Y-%m-%d')" "$BB20_LOG" 2>/dev/null || echo "0")
    WEEK_ENTRIES=$(echo "$WEEK_ENTRIES" | head -1 | tr -d '[:space:]')
    log_message "   Log entries this week: $WEEK_ENTRIES"
    
    # Check for errors
    ERRORS=$(tail -200 "$BB20_LOG" | grep -ci "error\|exception\|fail" 2>/dev/null || echo "0")
    ERRORS=$(echo "$ERRORS" | head -1 | tr -d '[:space:]')
    if [ "$ERRORS" -gt 0 ] 2>/dev/null; then
        log_message "   Errors in log: $ERRORS [!]"
    else
        log_message "   Errors in log: 0 [OK]"
    fi
    
    # Last entry
    LAST_ENTRY=$(tail -1 "$BB20_LOG")
    log_message "   Last log: ${LAST_ENTRY:0:70}..."
else
    log_message "   No log file found"
fi

# Check session
BB20_SESSION=$(python3 execution/paper.py --list-sessions 2>/dev/null | grep -E "SILVERBEES.*1D" | grep -i "bullish_alt\|bb20" | head -1 | awk '{print $1}')
if [ -n "$BB20_SESSION" ]; then
    log_message "   Session: $BB20_SESSION"
    # Try to read trades from session
    TRADES_FILE="$SESSION_DIR/$BB20_SESSION/trades.csv"
    if [ -f "$TRADES_FILE" ]; then
        TRADE_COUNT=$(wc -l < "$TRADES_FILE")
        TRADE_COUNT=$((TRADE_COUNT - 1))  # Subtract header
        log_message "   Total trades in session: $TRADE_COUNT"
    fi
else
    log_message "   Session: Not found"
fi
log_message ""

# ===============================================================================
# STRATEGY 2: ADX Trend Daily
# ===============================================================================
log_message "┌─────────────────────────────────────────────────────────────────────────────┐"
log_message "│ STRATEGY 2: ADX TREND DAILY                                                │"
log_message "├─────────────────────────────────────────────────────────────────────────────┤"
log_message "│ Expected: Win Rate 56%, PF 3.71, ~0.7 trades/month (TRENDING_UP only)     │"
log_message "└─────────────────────────────────────────────────────────────────────────────┘"

ADX_LOG="$LOG_DIR/adx_trend_daily.log"
if [ -f "$ADX_LOG" ]; then
    WEEK_ENTRIES=$(grep -c "$(TZ='Asia/Kolkata' date '+%Y-%m-%d')\|$(TZ='Asia/Kolkata' date -d '1 day ago' '+%Y-%m-%d' 2>/dev/null)" "$ADX_LOG" 2>/dev/null || echo "0")
    log_message "   Log entries this week: $WEEK_ENTRIES"
    
    ERRORS=$(tail -200 "$ADX_LOG" | grep -ci "error\|exception\|fail" || echo "0")
    if [ "$ERRORS" -gt 0 ]; then
        log_message "   Errors in log: $ERRORS [!]"
    else
        log_message "   Errors in log: 0 [OK]"
    fi
    
    LAST_ENTRY=$(tail -1 "$ADX_LOG")
    log_message "   Last log: ${LAST_ENTRY:0:70}..."
else
    log_message "   No log file found (strategy may not have run yet)"
fi

ADX_SESSION=$(python3 execution/paper.py --list-sessions 2>/dev/null | grep -E "SILVERBEES.*1D" | grep -i "adx_trend" | head -1 | awk '{print $1}')
if [ -n "$ADX_SESSION" ]; then
    log_message "   Session: $ADX_SESSION"
    TRADES_FILE="$SESSION_DIR/$ADX_SESSION/trades.csv"
    if [ -f "$TRADES_FILE" ]; then
        TRADE_COUNT=$(wc -l < "$TRADES_FILE")
        TRADE_COUNT=$((TRADE_COUNT - 1))
        log_message "   Total trades in session: $TRADE_COUNT"
    fi
else
    log_message "   Session: Not found"
fi
log_message ""

# ===============================================================================
# STRATEGY 3: Volatility Scalper 1H
# ===============================================================================
log_message "┌─────────────────────────────────────────────────────────────────────────────┐"
log_message "│ STRATEGY 3: VOLATILITY SCALPER 1H                                          │"
log_message "├─────────────────────────────────────────────────────────────────────────────┤"
log_message "│ Expected: Win Rate 52.9%, PF 1.87, ~8.7 trades/month (9-11 AM, VOLATILE)  │"
log_message "└─────────────────────────────────────────────────────────────────────────────┘"

SCALPER_LOG="$LOG_DIR/volatility_scalper_1h.log"
if [ -f "$SCALPER_LOG" ]; then
    WEEK_ENTRIES=$(grep -c "$(TZ='Asia/Kolkata' date '+%Y-%m-%d')\|$(TZ='Asia/Kolkata' date -d '1 day ago' '+%Y-%m-%d' 2>/dev/null)" "$SCALPER_LOG" 2>/dev/null || echo "0")
    log_message "   Log entries this week: $WEEK_ENTRIES"
    
    ERRORS=$(tail -200 "$SCALPER_LOG" | grep -ci "error\|exception\|fail" || echo "0")
    if [ "$ERRORS" -gt 0 ]; then
        log_message "   Errors in log: $ERRORS [!]"
    else
        log_message "   Errors in log: 0 [OK]"
    fi
    
    LAST_ENTRY=$(tail -1 "$SCALPER_LOG")
    log_message "   Last log: ${LAST_ENTRY:0:70}..."
else
    log_message "   No log file found (strategy may not have run yet)"
fi

SCALPER_SESSION=$(python3 execution/paper.py --list-sessions 2>/dev/null | grep -E "SILVERBEES.*1H" | grep -i "volatility_scalper\|scalper" | head -1 | awk '{print $1}')
if [ -n "$SCALPER_SESSION" ]; then
    log_message "   Session: $SCALPER_SESSION"
    TRADES_FILE="$SESSION_DIR/$SCALPER_SESSION/trades.csv"
    if [ -f "$TRADES_FILE" ]; then
        TRADE_COUNT=$(wc -l < "$TRADES_FILE")
        TRADE_COUNT=$((TRADE_COUNT - 1))
        log_message "   Total trades in session: $TRADE_COUNT"
    fi
else
    log_message "   Session: Not found"
fi
log_message ""

# ===============================================================================
# SYSTEM HEALTH
# ===============================================================================
log_message "┌─────────────────────────────────────────────────────────────────────────────┐"
log_message "│ SYSTEM HEALTH                                                              │"
log_message "└─────────────────────────────────────────────────────────────────────────────┘"

# Check cron is running
CRON_STATUS=$(systemctl is-active crond 2>/dev/null || systemctl is-active cron 2>/dev/null || echo "unknown")
log_message "   Cron service: $CRON_STATUS"

# Check disk space
DISK_USAGE=$(df -h /root | tail -1 | awk '{print $5}')
log_message "   Disk usage: $DISK_USAGE"

# Check memory
MEM_FREE=$(free -h | grep Mem | awk '{print $7}')
log_message "   Memory available: $MEM_FREE"

# Active Python processes
PYTHON_PROCS=$(pgrep -f python3 2>/dev/null | wc -l || echo "0")
PYTHON_PROCS=$(echo "$PYTHON_PROCS" | tr -d '[:space:]')
log_message "   Python processes: $PYTHON_PROCS"

# Paper trading processes
PAPER_PROCS=$(pgrep -f "paper.py" 2>/dev/null | wc -l || echo "0")
PAPER_PROCS=$(echo "$PAPER_PROCS" | tr -d '[:space:]')
log_message "   Paper trading: $PAPER_PROCS running"

log_message ""

# ===============================================================================
# RECOMMENDATIONS
# ===============================================================================
log_message "┌─────────────────────────────────────────────────────────────────────────────┐"
log_message "│ RECOMMENDATIONS                                                            │"
log_message "└─────────────────────────────────────────────────────────────────────────────┘"

# Check if any strategy had errors
TOTAL_ERRORS=0
if [ -f "$BB20_LOG" ]; then
    BB20_ERRORS=$(tail -200 "$BB20_LOG" | grep -ci "error\|exception" 2>/dev/null || echo "0")
    BB20_ERRORS=$(echo "$BB20_ERRORS" | head -1 | tr -d '[:space:]')
    TOTAL_ERRORS=$((TOTAL_ERRORS + BB20_ERRORS))
fi
if [ -f "$ADX_LOG" ]; then
    ADX_ERRORS=$(tail -200 "$ADX_LOG" | grep -ci "error\|exception" 2>/dev/null || echo "0")
    ADX_ERRORS=$(echo "$ADX_ERRORS" | head -1 | tr -d '[:space:]')
    TOTAL_ERRORS=$((TOTAL_ERRORS + ADX_ERRORS))
fi
if [ -f "$SCALPER_LOG" ]; then
    SCALPER_ERRORS=$(tail -200 "$SCALPER_LOG" | grep -ci "error\|exception" 2>/dev/null || echo "0")
    SCALPER_ERRORS=$(echo "$SCALPER_ERRORS" | head -1 | tr -d '[:space:]')
    TOTAL_ERRORS=$((TOTAL_ERRORS + SCALPER_ERRORS))
fi

if [ "$TOTAL_ERRORS" -gt 0 ]; then
    log_message "   [!] Review error logs - $TOTAL_ERRORS errors detected across strategies"
else
    log_message "   [OK] No errors detected in strategy logs"
fi

# Check if strategies are generating trades
log_message "   "
log_message "   Next week actions:"
log_message "   - Review trade logs in paper_sessions/ directory"
log_message "   - Compare actual vs expected win rates"
log_message "   - Monitor regime detection accuracy"
log_message "   - Check WebSocket connection stability"

log_message ""
log_message "==============================================================================="
log_message "   END OF WEEKLY SUMMARY - Week $WEEK_NUM"
log_message "==============================================================================="
log_message ""

echo ""
echo "Weekly summary saved to: $SUMMARY_LOG"
echo ""
