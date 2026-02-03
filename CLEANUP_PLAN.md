# Paper Trading Cleanup & Prevention Plan
# Run this AFTER market closes (after 15:30 IST)

## Step 1: Let current sessions finish naturally
# Wait for market to close at 15:30 IST
# Sessions should auto-stop

## Step 2: Clean up any remaining processes (after 16:00)
# Check if still running:
ps aux | grep "paper.py.*SILVERBEES" | grep -v grep

# If still running after market hours, stop them:
pkill -f "paper.py.*SILVERBEES"

# Remove lock file:
rm -f /tmp/silverbees_trading.lock

## Step 3: Fix paper.py websocket reconnection (TOMORROW)
# Location: /root/TR3X/execution/paper.py
# We'll add exponential backoff to websocket reconnection logic
# This is a surgical fix - won't break existing functionality

## Step 4: Test updated script
# Tomorrow before market (before 8:30 AM):
# Test the fixed script manually
# Let cron start it at 8:30 AM
# Monitor that only ONE instance runs (lock file will prevent duplicates)

## Data Preservation:
# Your data is safe in:
# - Session 2: /root/TR3X/output/paper/sessions/20260127_094135_SILVERBEES_EQ_15M/
# - Session 3: /root/TR3X/output/paper/sessions/20260127_140008_SILVERBEES_EQ_15M/
# Both sessions are collecting valid trading data despite the noise
