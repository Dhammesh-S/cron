# Cron Schedule Update - January 27, 2026

## Changes Made

### ✅ Updated Schedule
- **Old:** Start at 8:30 AM, no auto-stop
- **New:** Start at 9:00 AM, auto-stop at 3:35 PM IST

### ✅ New Features

1. **Auto-Shutdown at 3:35 PM**
   - Gracefully stops trading session after market close
   - Sends SIGTERM to paper.py process
   - Waits for clean shutdown
   - Creates metadata.json automatically

2. **Background Shutdown Monitor**
   - Runs in background while trading
   - Checks time every minute
   - Triggers shutdown at 15:35 IST

3. **Improved Logging**
   - Logs auto-shutdown trigger
   - Confirms process termination
   - Records shutdown status

## Updated Crontab

```bash
# Runs every day at 9:00 AM IST
0 9 * * * /root/cron/bin/silverbees_trading.sh
```

## Script Behavior

### Timeline:
```
09:00 AM - Cron starts script
09:00 AM - Script checks for lock file (prevent duplicates)
09:00 AM - Activates Python venv
09:00 AM - Starts paper.py with SILVERBEES strategy
09:00 AM - Launches auto-shutdown monitor (background)
09:15 AM - Market opens, live trading begins
...
03:30 PM - Market closes
03:35 PM - Auto-shutdown monitor triggers
03:35 PM - Sends SIGTERM to paper.py
03:35 PM - paper.py gracefully shuts down
03:35 PM - Metadata saved, session ended
03:35 PM - Lock file removed
```

## Files Modified

1. `/root/cron/bin/silverbees_trading.sh` - Main script
   - Added auto-shutdown function
   - Added background monitor
   - Added STOP_TIME configuration

2. `/root/cron/bin/silverbees_trading_detached.sh` - Detached mode
   - Updated help text
   - Mentions auto-stop feature

3. Crontab
   - Changed from `30 8` to `0 9`

4. Documentation
   - `/root/cron/SILVERBEES_SETUP.md` - Updated timings

## Backup

Original script backed up to:
```
/root/cron/bin/silverbees_trading_backup.sh
```

## Testing Plan

### Before Tomorrow's Market (before 9:00 AM):

1. **Test auto-shutdown logic:**
   ```bash
   # Temporarily set STOP_TIME to current time + 2 minutes
   # Run script manually
   # Verify it stops at the specified time
   ```

2. **Test lock file:**
   ```bash
   # Run script once
   # Try to run again - should fail with lock message
   ```

3. **Test manual run:**
   ```bash
   /root/cron/bin/silverbees_trading_detached.sh
   tail -f /root/cron/log/silverbees_trading.log
   ```

4. **Verify cron schedule:**
   ```bash
   crontab -l | grep silverbees
   ```

## Rollback (if needed)

If auto-shutdown causes issues:
```bash
# Restore original script
cp /root/cron/bin/silverbees_trading_backup.sh /root/cron/bin/silverbees_trading.sh

# Update crontab back to 8:30 AM
crontab -e
# Change to: 30 8 * * * /root/cron/bin/silverbees_trading.sh
```

## Expected Behavior Tomorrow

1. Cron starts script at 9:00 AM
2. Script runs until 3:35 PM
3. Auto-shutdown triggers, session closes gracefully
4. Metadata files created
5. Next day at 9:00 AM - new session starts fresh

## Benefits

✅ No manual intervention needed
✅ Clean shutdown with metadata
✅ Consistent daily schedule
✅ No orphaned processes overnight
✅ Fresh session every trading day

---

**Update Applied:** 2026-01-27 19:40 IST
**Next Run:** 2026-01-28 09:00 IST
