# Websocket Reconnection Issue - Root Cause & Fix

## Problem Analysis

### What's Happening:
1. ✅ Websocket connects successfully
2. ✅ Subscribes to symbol (NSE|8080)
3. ✅ Receives ticks (3545 ticks received)
4. ❌ Internet drops → "Connection to remote host was lost"
5. ✅ Websocket reconnects automatically (library feature)
6. ❌ **BUT subscription is NOT re-established**
7. ❌ Result: Connected but receiving no data

### Root Cause:

**The paper.py script subscribes ONCE at startup:**
```python
# Line 1173-1205 in paper.py
ws_result = broker.start_websocket(
    subscribe_callback=lambda tick: self._on_live_tick(...)
)
# ... then subscribes
broker.subscribe_websocket([subscribe_symbol])
```

**When websocket reconnects:**
- NorenAPI library auto-reconnects (good!)
- But it doesn't re-subscribe (bad!)
- Need to add `socket_open_callback` to re-subscribe

## The Fix

### Option 1: Add Reconnection Callback (Best)

Modify `paper.py` to add `socket_open_callback`:

```python
# Store subscription info
self.subscribe_symbol = None

def _on_websocket_open(self):
    """Called when websocket opens/reopens"""
    if self.subscribe_symbol:
        logger.info(f"Websocket (re)opened - resubscribing to {self.subscribe_symbol}")
        broker.subscribe_websocket([self.subscribe_symbol])

# When starting websocket:
ws_result = broker.start_websocket(
    subscribe_callback=lambda tick: self._on_live_tick(...),
    socket_open_callback=lambda: self._on_websocket_open()  # ADD THIS
)

# Store for reconnection
self.subscribe_symbol = subscribe_symbol
broker.subscribe_websocket([self.subscribe_symbol])
```

### Option 2: Periodic Re-subscription (Workaround)

Add a background thread that re-subscribes periodically:

```python
import threading
import time

def periodic_resubscribe():
    while trading_active:
        time.sleep(30)  # Every 30 seconds
        try:
            if broker and subscribe_symbol:
                broker.subscribe_websocket([subscribe_symbol])
                logger.debug("Periodic resubscribe sent")
        except:
            pass

threading.Thread(target=periodic_resubscribe, daemon=True).start()
```

### Option 3: Monitor & Restart (Current Workaround)

Monitor tick count and restart if stuck:

```bash
# Cron job to check every 5 minutes
*/5 * * * * /root/cron/bin/check_stuck_session.sh
```

## Implementation Plan

### Immediate Fix (Today):
Use Option 3 - monitoring script (already created)

### Permanent Fix (Tomorrow):
Modify paper.py to add `socket_open_callback` (Option 1)

## Files to Modify

### 1. /root/TR3X/execution/paper.py

**Location:** Around line 1173

**Change:**
```python
# BEFORE:
ws_result = broker.start_websocket(
    subscribe_callback=lambda tick: self._on_live_tick(
        tick, strategy_executor, session_start_time
    )
)

# AFTER:
# Store symbol for reconnection
_subscribe_symbol_ref = [None]  # Use list to avoid closure issues

def _on_socket_open():
    """Re-subscribe when websocket opens/reconnects"""
    if _subscribe_symbol_ref[0]:
        logger.info(f"🔄 Websocket (re)opened - resubscribing to {_subscribe_symbol_ref[0]}")
        try:
            broker.subscribe_websocket([_subscribe_symbol_ref[0]])
            logger.info("✅ Resubscription successful")
        except Exception as e:
            logger.error(f"❌ Resubscription failed: {e}")

ws_result = broker.start_websocket(
    subscribe_callback=lambda tick: self._on_live_tick(
        tick, strategy_executor, session_start_time
    ),
    socket_open_callback=_on_socket_open  # ADD THIS LINE
)

# Later, when subscribing:
subscribe_symbol = f"{exchange}|{token}"
_subscribe_symbol_ref[0] = subscribe_symbol  # Store for reconnection
subscribe_result = broker.subscribe_websocket([subscribe_symbol])
```

## Testing the Fix

### 1. Test Internet Disconnection
```bash
# Simulate network drop
sudo iptables -A OUTPUT -j DROP
sleep 30
sudo iptables -F  # Restore

# Check logs - should see:
# "Websocket (re)opened - resubscribing"
# "Resubscription successful"
```

### 2. Monitor Tick Count
```bash
# Should see increasing tick count after reconnection
tail -f /root/cron/log/silverbees_trading.log | grep "Session active"
```

## Alternative: External Monitoring

Create a health check that restarts on stuck sessions:

```bash
#!/bin/bash
# /root/cron/bin/monitor_websocket.sh

LAST_TICK=0
STUCK_COUNT=0

while true; do
    sleep 60
    
    CURRENT_TICK=$(tail -100 /root/cron/log/silverbees_trading.log | 
                   grep "Session active" | tail -1 | 
                   grep -oP 'received \K[0-9]+' || echo "0")
    
    if [ "$CURRENT_TICK" == "$LAST_TICK" ]; then
        ((STUCK_COUNT++))
        if [ $STUCK_COUNT -ge 3 ]; then
            echo "⚠️  Session stuck for 3 minutes - restarting"
            pkill -SIGTERM -f "paper.py.*SILVERBEES"
            sleep 15
            rm -f /tmp/silverbees_trading.lock
            /root/cron/bin/silverbees_trading_detached.sh
            STUCK_COUNT=0
        fi
    else
        STUCK_COUNT=0
    fi
    
    LAST_TICK=$CURRENT_TICK
done
```

## Summary

**Root Cause:** Missing `socket_open_callback` in paper.py

**Impact:** Websocket reconnects but doesn't re-subscribe to symbol

**Fix:** Add socket_open_callback to re-subscribe on reconnection

**Timeframe:** 
- Today: Use monitoring/manual restart
- Tomorrow: Apply permanent fix to paper.py

---

**Created:** 2026-01-28 11:15 IST
**Priority:** HIGH (affects live trading reliability)
**Complexity:** LOW (10-line code change)
