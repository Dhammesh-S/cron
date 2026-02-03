#!/bin/bash

# SILVERBEES Trading Strategy - Detached Mode
# Use this for manual testing without SIGHUP interruption
# Auto-stops at 3:35 PM IST

echo "Starting SILVERBEES trading in detached mode..."
echo "Logs: /root/cron/log/silverbees_trading.log"
echo "Auto-shutdown: 3:35 PM IST"
echo ""

# Run with nohup to prevent SIGHUP signal
nohup /root/cron/bin/silverbees_trading.sh > /dev/null 2>&1 &

PID=$!
echo "Started with PID: $PID"
echo ""
echo "To monitor logs:"
echo "  tail -f /root/cron/log/silverbees_trading.log"
echo ""
echo "To check if running:"
echo "  ps aux | grep paper.py"
echo ""
echo "To stop manually before 3:35 PM:"
echo "  pkill -SIGTERM -f 'paper.py.*SILVERBEES'"
echo ""
echo "Note: Will auto-stop gracefully at 3:35 PM IST"
echo ""
