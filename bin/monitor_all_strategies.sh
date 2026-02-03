#!/bin/bash
# =============================================================================
# MONITOR ALL STRATEGIES - QUICK STATUS CHECK
# =============================================================================
# Purpose: Quick overview of all 3 SILVERBEES trading strategies
# Usage: Run manually anytime: /root/cron/bin/monitor_all_strategies.sh
#
# Created: 2026-02-03
# =============================================================================

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
LOG_DIR="/root/cron/log"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║     SILVERBEES TRADING STRATEGIES - QUICK STATUS                          ║"
echo "╠═══════════════════════════════════════════════════════════════════════════╣"
echo "║     Time: $(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')                               ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Function to check strategy status
check_strategy() {
    local NAME="$1"
    local PATTERN="$2"
    local LOG_FILE="$3"
    local STOP_TIME="$4"
    
    echo "┌───────────────────────────────────────────────────────────────────────────┐"
    printf "│ %-73s │\n" "$NAME"
    echo "└───────────────────────────────────────────────────────────────────────────┘"
    
    # Check process
    PID=$(pgrep -f "$PATTERN" 2>/dev/null)
    if [ -n "$PID" ]; then
        echo -e "   Process:   ${GREEN}RUNNING${NC} (PID: $PID)"
    else
        echo -e "   Process:   ${YELLOW}NOT RUNNING${NC}"
    fi
    
    # Check lock file
    LOCK_FILE="/tmp/${LOG_FILE%.log}.lock"
    if [ -f "$LOCK_FILE" ]; then
        LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
            echo "   Lock:      Active (PID: $LOCK_PID)"
        else
            echo -e "   Lock:      ${RED}STALE${NC}"
        fi
    else
        echo "   Lock:      None"
    fi
    
    # Check log file
    LOG_PATH="$LOG_DIR/$LOG_FILE"
    if [ -f "$LOG_PATH" ]; then
        LAST_MOD=$(stat -c %Y "$LOG_PATH" 2>/dev/null || stat -f %m "$LOG_PATH" 2>/dev/null)
        NOW=$(date +%s)
        DIFF_HOURS=$(( (NOW - LAST_MOD) / 3600 ))
        if [ $DIFF_HOURS -lt 24 ]; then
            echo -e "   Log:       ${GREEN}Updated${NC} (${DIFF_HOURS}h ago)"
        else
            echo -e "   Log:       ${YELLOW}Stale${NC} (${DIFF_HOURS}h ago)"
        fi
        
        # Check for recent errors
        ERRORS=$(tail -20 "$LOG_PATH" | grep -ci "error\|exception" 2>/dev/null || echo "0")
        ERRORS=$(echo "$ERRORS" | head -1 | tr -d '[:space:]')
        if [ "$ERRORS" -gt 0 ] 2>/dev/null; then
            echo -e "   Errors:    ${RED}$ERRORS in last 20 lines${NC}"
        else
            echo -e "   Errors:    ${GREEN}None${NC}"
        fi
    else
        echo "   Log:       Not found"
    fi
    
    echo "   Auto-stop: $STOP_TIME IST"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK ALL 3 STRATEGIES
# ═══════════════════════════════════════════════════════════════════════════════

# Strategy 1: BB20+RSI14 Daily
check_strategy \
    "BB20+RSI14 DAILY (silverbees_bullish_alternative)" \
    "paper.py.*SILVERBEES.*1D.*bullish_alt" \
    "bb20_daily_trading.log" \
    "3:35 PM"

# Strategy 2: ADX Trend Daily
check_strategy \
    "ADX TREND DAILY (silverbees_adx_trend)" \
    "paper.py.*SILVERBEES.*1D.*adx_trend" \
    "adx_trend_daily.log" \
    "3:30 PM"

# Strategy 3: Volatility Scalper 1H
check_strategy \
    "VOLATILITY SCALPER 1H (silverbees_volatility_scalper)" \
    "paper.py.*SILVERBEES.*1H.*volatility_scalper" \
    "volatility_scalper_1h.log" \
    "12:00 PM"

# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEM STATUS
# ═══════════════════════════════════════════════════════════════════════════════

echo "┌───────────────────────────────────────────────────────────────────────────┐"
echo "│ SYSTEM STATUS                                                             │"
echo "└───────────────────────────────────────────────────────────────────────────┘"

# Cron status
CRON_STATUS=$(systemctl is-active crond 2>/dev/null || systemctl is-active cron 2>/dev/null || echo "unknown")
if [ "$CRON_STATUS" = "active" ]; then
    echo -e "   Cron:      ${GREEN}$CRON_STATUS${NC}"
else
    echo -e "   Cron:      ${RED}$CRON_STATUS${NC}"
fi

# Python processes
PAPER_COUNT=$(pgrep -f "paper.py" 2>/dev/null | wc -l || echo "0")
PAPER_COUNT=$(echo "$PAPER_COUNT" | tr -d '[:space:]')
echo "   Paper.py:  $PAPER_COUNT process(es) running"

# Disk
DISK=$(df -h /root | tail -1 | awk '{print $5 " used of " $2}')
echo "   Disk:      $DISK"

# Memory
MEM=$(free -h | grep Mem | awk '{print $7 " available"}')
echo "   Memory:    $MEM"

echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# TRADING WINDOW STATUS
# ═══════════════════════════════════════════════════════════════════════════════

echo "┌───────────────────────────────────────────────────────────────────────────┐"
echo "│ TRADING WINDOW                                                            │"
echo "└───────────────────────────────────────────────────────────────────────────┘"

CURRENT_HOUR=$(TZ='Asia/Kolkata' date '+%H')
CURRENT_MIN=$(TZ='Asia/Kolkata' date '+%M')
CURRENT_TIME="$CURRENT_HOUR:$CURRENT_MIN"
DAY_OF_WEEK=$(TZ='Asia/Kolkata' date '+%u')  # 1=Monday, 7=Sunday

echo "   Current:   $CURRENT_TIME IST ($(TZ='Asia/Kolkata' date '+%A'))"

# Check if market day
if [ "$DAY_OF_WEEK" -ge 6 ]; then
    echo -e "   Market:    ${YELLOW}WEEKEND - Closed${NC}"
else
    # Check market hours (9:15 AM - 3:30 PM)
    if [ "$CURRENT_HOUR" -lt 9 ]; then
        echo -e "   Market:    ${YELLOW}Pre-market${NC}"
    elif [ "$CURRENT_HOUR" -eq 9 ] && [ "$CURRENT_MIN" -lt 15 ]; then
        echo -e "   Market:    ${YELLOW}Pre-market${NC}"
    elif [ "$CURRENT_HOUR" -ge 15 ] && [ "$CURRENT_MIN" -ge 30 ]; then
        echo -e "   Market:    ${YELLOW}Closed${NC}"
    elif [ "$CURRENT_HOUR" -gt 15 ]; then
        echo -e "   Market:    ${YELLOW}Closed${NC}"
    else
        echo -e "   Market:    ${GREEN}OPEN${NC}"
    fi
    
    # Check scalper window (9-11 AM)
    if [ "$CURRENT_HOUR" -ge 9 ] && [ "$CURRENT_HOUR" -lt 11 ]; then
        echo -e "   Scalper:   ${GREEN}ACTIVE (9-11 AM)${NC}"
    elif [ "$CURRENT_HOUR" -ge 11 ] && [ "$CURRENT_HOUR" -lt 12 ]; then
        echo -e "   Scalper:   ${YELLOW}Closing positions${NC}"
    else
        echo -e "   Scalper:   ${YELLOW}Outside window${NC}"
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# QUICK COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

echo "┌───────────────────────────────────────────────────────────────────────────┐"
echo "│ QUICK COMMANDS                                                            │"
echo "└───────────────────────────────────────────────────────────────────────────┘"
echo "   View logs:"
echo "     tail -f /root/cron/log/bb20_daily_trading.log"
echo "     tail -f /root/cron/log/adx_trend_daily.log"
echo "     tail -f /root/cron/log/volatility_scalper_1h.log"
echo ""
echo "   Individual status:"
echo "     /root/cron/bin/monitor_adx_trend.sh"
echo "     /root/cron/bin/monitor_volatility_scalper.sh"
echo ""
echo "   Weekly summary:"
echo "     /root/cron/bin/weekly_summary_all.sh"
echo ""
echo "   List sessions:"
echo "     cd /root/TR3X && python3 execution/paper.py --list-sessions"
echo ""

# Log that this was run
echo "[$(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M:%S IST')] Status check completed" >> "$LOG_DIR/monitor_all_strategies.log"
