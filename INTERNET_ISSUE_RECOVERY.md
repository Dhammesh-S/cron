# Internet Connection Issue - Recovery Options

## Current Situation

**Status:** Script is RUNNING but experiencing connectivity issues

### What's Happening:
- ✅ Process is alive (PID 5575)
- ✅ Auto-shutdown monitor active (will stop at 3:35 PM)
- ✅ State being saved every 60 seconds
- ⚠️  Websocket disconnecting frequently
- ⚠️  Tick count stuck at 3545 (not receiving new data)
- ⚠️  Last reconnect: 10:31 IST

### Disconnection Pattern:
```
10:22 - Connection lost
10:23 - Reconnected ✅
10:24 - Connection lost
10:25 - Reconnected ✅
10:27 - Connection lost (stuck here)
10:31 - Reconnected but no new ticks
```

---

## Option 1: Wait It Out (Let Auto-Recovery Work)

**When to use:** If internet is temporarily unstable

```bash
# Just monitor - script will keep trying to reconnect
tail -f /root/cron/log/silverbees_trading.log

# The script has built-in retry logic
# It will reconnect when internet stabilizes
```

**Pros:**
- No manual intervention
- Preserves current session data
- Will auto-stop at 3:35 PM anyway

**Cons:**
- May miss trading opportunities during downtime
- Stuck tick count means no new candles

---

## Option 2: Restart the Script Now (Fresh Start)

**When to use:** If connection keeps failing and you want fresh session

### Step 1: Stop current session gracefully
```bash
# Send graceful shutdown signal
pkill -SIGTERM -f "paper.py.*SILVERBEES"

# Wait for shutdown (10-15 seconds)
sleep 15

# Verify it stopped
ps aux | grep paper.py
```

### Step 2: Remove lock file
```bash
rm -f /tmp/silverbees_trading.lock
```

### Step 3: Start fresh session
```bash
/root/cron/bin/silverbees_trading_detached.sh
```

**Pros:**
- Fresh websocket connection
- Clean start with current market data
- Will still auto-stop at 3:35 PM

**Cons:**
- Loses current session (but it has 0 trades anyway)
- Need manual intervention

---

## Option 3: Do Nothing (Safest)

**When to use:** If you want to preserve today's session data

- Script will auto-stop at 3:35 PM IST
- Tomorrow at 9:00 AM, cron starts fresh automatically
- Current session data is being saved

**Recommendation:** Since current session has:
- 0 trades executed
- Connection issues
- Only collecting partial data

**It's safe to restart fresh if internet is now stable.**

---

## Quick Decision Guide

### Is Internet Stable Now?

**Check with:**
```bash
ping -c 5 8.8.8.8
```

**If YES (internet stable):**
→ Option 2: Restart for fresh connection

**If NO (still unstable):**
→ Option 1: Wait it out or Option 3: Do nothing

---

## Restart Commands (If Choosing Option 2)

```bash
# 1. Stop gracefully
pkill -SIGTERM -f "paper.py.*SILVERBEES"

# 2. Wait and verify
sleep 15
ps aux | grep paper.py | grep -v grep || echo "Stopped successfully"

# 3. Remove lock
rm -f /tmp/silverbees_trading.lock

# 4. Start fresh
/root/cron/bin/silverbees_trading_detached.sh

# 5. Monitor
tail -f /root/cron/log/silverbees_trading.log
```

---

## What Happens Tomorrow

✅ **Automatic Fresh Start**
- Cron runs at 9:00 AM IST
- New session starts
- Clean websocket connection
- Lock file prevents duplicates

No manual intervention needed tomorrow!

---

**Created:** 2026-01-28 10:42 IST
**Current Time:** 10:42 IST  
**Auto-Stop:** 3:35 PM IST (in 5 hours)
