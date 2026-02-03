#!/bin/bash
# =============================================================================
# MONITOR VOLATILITY SCALPER 1H STRATEGY
# =============================================================================
# Purpose: Check status and performance of Volatility Scalper 1H strategy
# Usage: Run manually anytime to check strategy status
#
# Created: 2026-02-03
# =============================================================================

# Configuration
PROJECT_DIR="/root/TR3X"
VENV_PATH="/usr/local/src/Python-3.10.13/venv"
LOG_DIR="/root/cron/log"
STRATEGY_LOG="$LOG_DIR/volatility_scalper_1h.log"
MONITOR_LOG="$LOG_DIR/monitor_volatility_scalper.log"
SESSION_DIR="$PROJECT_DIR/paper_sessions"

# Strategy settings
SYMBOL="SILVERBEES-EQ"
TIMEFRAME="1H"
STRATEGY="silverbees_volatility_scalper"

# Expected performance (from backtest)
EXPECTED_WIN_RATE="52.9"
EXPECTED_PF="1.87"
EXPECTED_TRADES_PER_MONTH="8.7"
EXPECTED_AVG_PNL="15.17"

# Logging function
log_message() {
    echo "[$(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')] $1" | tee -a "$MONITOR_LOG"
}

print_header() {
    echo ""
    echo "=============================================="
    echo "  VOLATILITY SCALPER 1H - STATUS REPORT"
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
    
    # Check if within trading hours (8:50 AM - 12:00 PM IST)
    CURRENT_HOUR=$(TZ='Asia/Kolkata' date '+%H')
    if [ "$CURRENT_HOUR" -ge 9 ] && [ "$CURRENT_HOUR" -lt 12 ]; then
        echo "   [NOTE] Within trading window (9-12) but not running!"
    else
        echo "   [OK] Outside trading window (9-12 AM)"
    fi
fi
echo ""

# 2. Check lock file
echo "2. LOCK FILE"
echo "   ---------"
LOCK_FILE="/tmp/volatility_scalper_1h.lock"
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

# 3. Trading window status
echo "3. TRADING WINDOW"
echo "   ---------------"
CURRENT_TIME=$(TZ='Asia/Kolkata' date '+%H:%M')
CURRENT_HOUR=$(TZ='Asia/Kolkata' date '+%H')
echo "   Current Time: $CURRENT_TIME IST"
echo "   Strategy Hours: 9:00 - 11:00 AM (entry)"
echo "   Cron Window: 8:50 AM - 12:00 PM"

if [ "$CURRENT_HOUR" -ge 9 ] && [ "$CURRENT_HOUR" -lt 11 ]; then
    echo "   Window Status: ACTIVE (can take new trades)"
elif [ "$CURRENT_HOUR" -ge 11 ] && [ "$CURRENT_HOUR" -lt 12 ]; then
    echo "   Window Status: CLOSING (managing existing trades)"
else
    echo "   Window Status: CLOSED"
fi
echo ""

# 4. Latest log entries
echo "4. RECENT LOG ENTRIES"
echo "   -------------------"
if [ -f "$STRATEGY_LOG" ]; then
    echo "   Last 10 lines of $STRATEGY_LOG:"
    tail -10 "$STRATEGY_LOG" | sed 's/^/   /'
else
    echo "   No log file found"
fi
echo ""

# 5. Session information
echo "5. SESSION INFO"
echo "   ------------"
if [ -d "$SESSION_DIR" ]; then
    # Activate venv to use paper.py
    if [ -f "$VENV_PATH/bin/activate" ]; then
        source "$VENV_PATH/bin/activate"
        cd "$PROJECT_DIR"
        
        echo "   Existing sessions:"
        python3 execution/paper.py --list-sessions 2>/dev/null | \
            grep -E "SILVERBEES.*1H" | \
            grep -i "volatility_scalper\|scalper" | \
            head -5 | \
            sed 's/^/   /'
        
        if [ -z "$(python3 execution/paper.py --list-sessions 2>/dev/null | grep -E 'SILVERBEES.*1H' | grep -i 'volatility_scalper\|scalper')" ]; then
            echo "   No sessions found"
        fi
    else
        echo "   Cannot check sessions (venv not found)"
    fi
else
    echo "   Session directory not found"
fi
echo ""

# 6. Expected vs Actual Performance
echo "6. PERFORMANCE COMPARISON"
echo "   ----------------------"
echo "   Expected (from 10-month backtest):"
echo "     Win Rate:      $EXPECTED_WIN_RATE%"
echo "     Profit Factor: $EXPECTED_PF"
echo "     Trades/Month:  $EXPECTED_TRADES_PER_MONTH"
echo "     Avg P&L/Trade: Rs $EXPECTED_AVG_PNL"
echo ""
echo "   Trading Notes:"
echo "     - Risk: Rs 50/trade (0.1% of Rs 50,000)"
echo "     - Target: ~Rs 150/trade (1:3 R:R)"
echo "     - Max hold: 1 bar (1 hour)"
echo "     - Regime: VOLATILE only"
echo ""
echo "   Actual: (check session trades.csv for details)"
echo ""

# 7. Quick health check
echo "7. HEALTH CHECK"
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
