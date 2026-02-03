#!/bin/bash
# =============================================================================
# MONITOR ADX TREND DAILY STRATEGY
# =============================================================================
# Purpose: Check status and performance of ADX Trend Daily strategy
# Usage: Run manually anytime to check strategy status
#
# Created: 2026-02-03
# =============================================================================

# Configuration
PROJECT_DIR="/root/TR3X"
VENV_PATH="/usr/local/src/Python-3.10.13/venv"
LOG_DIR="/root/cron/log"
STRATEGY_LOG="$LOG_DIR/adx_trend_daily.log"
MONITOR_LOG="$LOG_DIR/monitor_adx_trend.log"
SESSION_DIR="$PROJECT_DIR/paper_sessions"

# Strategy settings
SYMBOL="SILVERBEES-EQ"
TIMEFRAME="1D"
STRATEGY="silverbees_adx_trend"

# Expected performance (from backtest)
EXPECTED_WIN_RATE="56.0"
EXPECTED_PF="3.71"
EXPECTED_TRADES_PER_MONTH="0.7"

# Logging function
log_message() {
    echo "[$(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')] $1" | tee -a "$MONITOR_LOG"
}

print_header() {
    echo ""
    echo "=============================================="
    echo "  ADX TREND DAILY - STATUS REPORT"
    echo "=============================================="
    echo "  Generated: $(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')"
    echo "=============================================="
    echo ""
}

# Print header
print_header

# 1. Check if process is running
echo "1. PROCESS STATUS"
echo "   ---------------"
PAPER_PID=$(pgrep -f "paper.py.*$SYMBOL.*$TIMEFRAME.*$STRATEGY" 2>/dev/null)
if [ -n "$PAPER_PID" ]; then
    echo "   Status: RUNNING"
    echo "   PID: $PAPER_PID"
    echo "   Started: $(ps -o lstart= -p $PAPER_PID 2>/dev/null || echo 'Unknown')"
    echo "   Memory: $(ps -o rss= -p $PAPER_PID 2>/dev/null | awk '{printf "%.1f MB", $1/1024}' || echo 'Unknown')"
else
    echo "   Status: NOT RUNNING"
fi
echo ""

# 2. Check lock file
echo "2. LOCK FILE"
echo "   ---------"
LOCK_FILE="/tmp/adx_trend_daily.lock"
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "   Lock: ACTIVE (PID: $LOCK_PID)"
    else
        echo "   Lock: STALE (PID: $LOCK_PID - not running)"
    fi
else
    echo "   Lock: NONE"
fi
echo ""

# 3. Latest log entries
echo "3. RECENT LOG ENTRIES"
echo "   -------------------"
if [ -f "$STRATEGY_LOG" ]; then
    echo "   Last 10 lines of $STRATEGY_LOG:"
    tail -10 "$STRATEGY_LOG" | sed 's/^/   /'
else
    echo "   No log file found"
fi
echo ""

# 4. Session information
echo "4. SESSION INFO"
echo "   ------------"
if [ -d "$SESSION_DIR" ]; then
    # Activate venv to use paper.py
    if [ -f "$VENV_PATH/bin/activate" ]; then
        source "$VENV_PATH/bin/activate"
        cd "$PROJECT_DIR"
        
        echo "   Existing sessions:"
        python3 execution/paper.py --list-sessions 2>/dev/null | \
            grep -E "SILVERBEES.*1D" | \
            grep -i "adx_trend\|silverbees_adx" | \
            head -5 | \
            sed 's/^/   /'
        
        if [ -z "$(python3 execution/paper.py --list-sessions 2>/dev/null | grep -E 'SILVERBEES.*1D' | grep -i 'adx_trend\|silverbees_adx')" ]; then
            echo "   No sessions found"
        fi
    else
        echo "   Cannot check sessions (venv not found)"
    fi
else
    echo "   Session directory not found"
fi
echo ""

# 5. Expected vs Actual Performance
echo "5. PERFORMANCE COMPARISON"
echo "   ----------------------"
echo "   Expected (from 3-year backtest):"
echo "     Win Rate:      $EXPECTED_WIN_RATE%"
echo "     Profit Factor: $EXPECTED_PF"
echo "     Trades/Month:  $EXPECTED_TRADES_PER_MONTH"
echo ""
echo "   Actual: (check session trades.csv for details)"
echo ""

# 6. Quick health check
echo "6. HEALTH CHECK"
echo "   ------------"
HEALTH_ISSUES=0

# Check if log was updated today
if [ -f "$STRATEGY_LOG" ]; then
    LAST_UPDATE=$(stat -c %Y "$STRATEGY_LOG" 2>/dev/null || stat -f %m "$STRATEGY_LOG" 2>/dev/null)
    NOW=$(date +%s)
    DIFF=$((NOW - LAST_UPDATE))
    if [ $DIFF -gt 86400 ]; then
        echo "   [WARN] Log not updated in 24+ hours"
        HEALTH_ISSUES=$((HEALTH_ISSUES + 1))
    else
        echo "   [OK] Log updated within 24 hours"
    fi
else
    echo "   [WARN] No log file exists"
    HEALTH_ISSUES=$((HEALTH_ISSUES + 1))
fi

# Check for errors in recent log
if [ -f "$STRATEGY_LOG" ]; then
    RECENT_ERRORS=$(tail -50 "$STRATEGY_LOG" | grep -i "error\|exception\|fail" | wc -l)
    if [ "$RECENT_ERRORS" -gt 0 ]; then
        echo "   [WARN] $RECENT_ERRORS error(s) in recent log"
        HEALTH_ISSUES=$((HEALTH_ISSUES + 1))
    else
        echo "   [OK] No errors in recent log"
    fi
fi

echo ""
if [ $HEALTH_ISSUES -eq 0 ]; then
    echo "   Overall: HEALTHY"
else
    echo "   Overall: $HEALTH_ISSUES issue(s) found"
fi

echo ""
echo "=============================================="
echo "  END OF REPORT"
echo "=============================================="
echo ""

# Log that monitoring was run
log_message "Status check completed. Health issues: $HEALTH_ISSUES"
