# SILVERBEES Trading Strategy - Cron Setup Complete ✅

## What Was Created

**Script Location:** `/root/cron/bin/silverbees_trading.sh`

**Log Location:** `/root/cron/log/silverbees_trading.log`

## Configuration

- **Symbol:** SILVERBEES-EQ
- **Timeframe:** 15M
- **Strategy:** silverbees_bullish
- **Mode:** Paper trading with auto-run
- **Start Time:** 9:00 AM IST (daily via cron)
- **Stop Time:** 3:35 PM IST (automatic graceful shutdown)

## Script Features

✅ Automatically activates Python virtual environment
✅ Changes to TR3X project directory
✅ Executes trading strategy with proper parameters
✅ Logs all output with timestamps
✅ Error handling and exit code reporting
✅ **Lock file prevents multiple instances from running**
✅ **Auto-shutdown at 3:35 PM IST (graceful close)**
✅ **Runs continuously during market hours (9:15 AM - 3:30 PM)**

## How to Schedule (Crontab)

```bash
# Edit crontab
crontab -e

# Add this line to run daily at 9:00 AM IST:
0 9 * * * /root/cron/bin/silverbees_trading.sh

# Save and exit
# In nano: Ctrl+O, Enter, Ctrl+X
# In vi: Esc, :wq, Enter
```

**Note:** Script will auto-stop at 3:35 PM IST daily (graceful shutdown)

## Verify Crontab

```bash
# List scheduled jobs
crontab -l
```

## Manual Testing

### Option 1: Direct Run (will stop if terminal closes)
```bash
# Run the script manually
/root/cron/bin/silverbees_trading.sh
```

### Option 2: Detached Mode (keeps running after terminal closes) ✅ RECOMMENDED
```bash
# Run in detached mode - won't stop when terminal closes
/root/cron/bin/silverbees_trading_detached.sh

# Monitor logs in real-time
tail -f /root/cron/log/silverbees_trading.log

# Check last 50 lines of logs
tail -50 /root/cron/log/silverbees_trading.log

# Search for errors
grep ERROR /root/cron/log/silverbees_trading.log
```

**Note:** When run via cron, the script will NOT receive SIGHUP and will run continuously.

## Check Running Status

```bash
# See if script is running
ps aux | grep paper.py

# Check lock file
cat /tmp/silverbees_trading.lock 2>/dev/null && echo "Lock file exists"

# Stop a running script (if needed)
pkill -f "paper.py.*SILVERBEES"

# Remove stale lock file (only if process is not running)
rm -f /tmp/silverbees_trading.lock
```

## Current Status

✅ Script created and tested successfully
✅ Virtual environment activation working
✅ Script runs and waits for market hours
✅ Logging working properly
✅ Detached mode script created for manual testing
✅ Lock file mechanism prevents duplicate instances

## Known Issues (In Progress)

⚠️ **Websocket Reconnection Loop** - When broker connection drops, paper.py reconnects too aggressively (3/sec)
- **Impact:** Noisy logs, but trading data still collected correctly
- **Fix:** Add exponential backoff to websocket handler (planned for tomorrow)
- **Workaround:** Sessions continue working despite noise

**Important:** The script will shut down if terminal closes (receives SIGHUP). 
- Use `/root/cron/bin/silverbees_trading_detached.sh` for manual testing
- Cron execution will NOT have this issue

## Next Market Session

The script will:
1. Start at 9:00 AM when triggered by cron
2. Wait until market opens (9:15 AM IST)
3. Execute trades based on silverbees_bullish strategy
4. Run continuously until 3:35 PM IST
5. Auto-shutdown gracefully at 3:35 PM
6. Save session metadata and state files
7. Log all activity to the log file

## Shoonya Credentials Setup (REQUIRED)

Before running, you must configure your Shoonya credentials:

### 1. Create the .env file
```bash
cp /root/TR3X/brokers/shoonya/.env.example /root/TR3X/brokers/shoonya/.env
```

### 2. Edit with your credentials
```bash
nano /root/TR3X/brokers/shoonya/.env
```

### 3. Fill in these required fields:
```bash
SHOONYA_USER_ID=your_actual_user_id
SHOONYA_PASSWORD=your_actual_password
SHOONYA_TOTP_SECRET=your_actual_totp_secret
SHOONYA_VENDOR_CODE=your_actual_vendor_code
SHOONYA_API_SECRET=your_actual_api_secret
SHOONYA_IMEI=your_actual_imei
SHOONYA_ENV=paper
```

⚠️ **SECURITY**: Never commit the .env file to git! It's already in .gitignore.

## Notes

- The script uses the Python virtual environment at `/usr/local/src/Python-3.10.13/venv`
- All dependencies (NorenRestApiPy, etc.) are available in the venv
- The script will run in the background when started by cron
- Check logs regularly to monitor trading activity
- **Credentials must be set in `/root/TR3X/brokers/shoonya/.env` before first run**
