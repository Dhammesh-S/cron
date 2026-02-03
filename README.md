# Cron Job Setup Guide

A comprehensive guide to setting up, configuring, and managing cron jobs for automated task execution.

## What is Cron?

Cron is a time-based job scheduler in Unix-like operating systems (Linux, macOS, etc.). It allows you to schedule scripts, commands, or applications to run automatically at specific times or intervals without manual intervention.

**Key Benefits:**
- Automate repetitive tasks
- Run scripts at specific times
- Schedule periodic maintenance
- Execute jobs in the background
- No need for manual execution

---

## Directory Structure

```
cron/
├── bin/                    # Executable scripts directory
│   ├── backup.sh          # Example: Database backup script
│   ├── cleanup.sh         # Example: Log cleanup script
│   └── update.sh          # Example: System update script
├── log/                   # Log files directory
│   ├── backup.log         # Backup job logs
│   ├── cleanup.log        # Cleanup job logs
│   └── update.log         # Update job logs
├── README.md              # This file
└── config/                # (Optional) Configuration files for scripts
    └── settings.conf      # Script configuration
```

---

## Step 1: Create Your Scripts

Before setting up cron jobs, create the scripts you want to run.

### Example 1: Simple Backup Script

Create `bin/backup.sh`:

```bash
#!/bin/bash

# Simple backup script
LOG_FILE="$HOME/cron/log/backup.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "Starting backup..."

# Your backup commands here
# Example: tar -czf backup_$(date +%Y%m%d).tar.gz /path/to/backup/

log_message "Backup completed successfully"
```

### Example 2: Log Cleanup Script

Create `bin/cleanup.sh`:

```bash
#!/bin/bash

# Cleanup old logs
LOG_DIR="$HOME/cron/log"
RETENTION_DAYS=30

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/cleanup.log"
}

log_message "Starting cleanup of logs older than $RETENTION_DAYS days"

# Remove files older than 30 days
find "$LOG_DIR" -name "*.log" -mtime +$RETENTION_DAYS -delete

log_message "Cleanup completed"
```

### Example 3: Custom Python Script Runner

Create `bin/python_runner.sh`:

```bash
#!/bin/bash

PROJECT_DIR="$HOME/my_project"
PYTHON_SCRIPT="$PROJECT_DIR/tasks.py"
LOG_FILE="$HOME/cron/log/python_runner.log"

mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "Starting Python script execution"

if cd "$PROJECT_DIR" && python3 "$PYTHON_SCRIPT" >> "$LOG_FILE" 2>&1; then
    log_message "Python script completed successfully"
else
    log_message "ERROR: Python script failed with exit code $?"
    exit 1
fi
```

---

## Step 2: Make Scripts Executable

Before cron can run your scripts, they must have executable permissions:

```bash
# Make a single script executable
chmod +x /root/cron/bin/backup.sh

# Make all scripts in bin directory executable
chmod +x /root/cron/bin/*.sh

# Verify permissions (should show 'x' for owner)
ls -l /root/cron/bin/
```

---

## Step 3: Understanding Cron Syntax

Cron uses a specific format to schedule jobs. Each line in the crontab follows this pattern:

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (0 = Sunday)
│ │ │ │ │
│ │ │ │ │
* * * * * /path/to/command
```

### Cron Field Meanings

| Field | Range | Meaning |
|-------|-------|---------|
| Minute | 0-59 | Which minute of the hour |
| Hour | 0-23 | Which hour of the day (24-hour format) |
| Day of Month | 1-31 | Which day of the month |
| Month | 1-12 | Which month of the year |
| Day of Week | 0-6 | Which day of the week (0=Sun, 1=Mon, etc.) |

### Special Characters

| Character | Meaning | Example |
|-----------|---------|---------|
| `*` | Any value / Every | `*` = every minute/hour/day |
| `,` | Multiple values | `1,15` = on the 1st and 15th |
| `-` | Range of values | `9-17` = 9 AM to 5 PM |
| `/` | Step values | `*/5` = every 5 minutes |
| `?` | No specific value | Use in day/weekday when other is specified |

### Common Cron Schedule Examples

| Schedule | Cron Syntax | Meaning |
|----------|------------|---------|
| Every minute | `* * * * *` | Runs every minute |
| Every 5 minutes | `*/5 * * * *` | Every 5 minutes |
| Every hour | `0 * * * *` | At the top of every hour |
| Daily at 9:03 AM | `3 9 * * *` | 9:03 AM every day |
| Twice daily (9 AM & 3 PM) | `0 9,15 * * *` | At 9 AM and 3 PM |
| Every weekday at 8 AM | `0 8 * * 1-5` | 8 AM Mon-Fri |
| Every Sunday at midnight | `0 0 * * 0` | 12:00 AM every Sunday |
| 1st of every month at 2 AM | `0 2 1 * *` | 2:00 AM on the 1st |
| Every 15th at 10:30 AM | `30 10 15 * *` | 10:30 AM on the 15th |

---

## Step 4: Edit Your Crontab

### Open the Crontab Editor

```bash
crontab -e
```

This opens your default text editor (usually `nano` or `vi`). If you've never edited crontab before, you may be prompted to choose an editor.

### Add Your Cron Jobs

Add one line per job. Use absolute paths for all files:

```bash
# Run backup script every day at 2 AM
0 2 * * * /root/cron/bin/backup.sh

# Run cleanup script every Sunday at 3 AM
0 3 * * 0 /root/cron/bin/cleanup.sh

# Run Python runner every weekday at 9 AM
0 9 * * 1-5 /root/cron/bin/python_runner.sh

# Run task every 30 minutes
*/30 * * * * /root/cron/bin/quick_task.sh
```

### Save and Exit

- **In nano**: Press `Ctrl+O`, then `Enter`, then `Ctrl+X`
- **In vi**: Press `Esc`, type `:wq`, then `Enter`

---

## Step 5: Verify Your Crontab

### View Your Scheduled Jobs

```bash
# View all cron jobs for current user
crontab -l

# View cron jobs for a specific user (requires root)
sudo crontab -u username -l
```

### Check Cron Service Status

```bash
# Check if cron daemon is running
ps aux | grep crond

# On systems with systemd
systemctl status cron
# or
systemctl status crond
```

---

## Best Practices

### 1. Use Absolute Paths
Always use full paths to avoid "command not found" errors:

```bash
# ❌ Bad - relative paths
* * * * * bin/backup.sh

# ✅ Good - absolute paths
* * * * * /root/cron/bin/backup.sh
```

### 2. Redirect Output to Logs
Capture both stdout and stderr:

```bash
# Redirect to log file
0 2 * * * /root/cron/bin/backup.sh >> /root/cron/log/backup.log 2>&1

# Send errors via email (if configured)
0 2 * * * /root/cron/bin/backup.sh 2>&1 | mail -s "Backup Report" admin@example.com
```

### 3. Use Explicit Shebangs
Always include a shebang line in your scripts:

```bash
#!/bin/bash          # For bash scripts
#!/bin/sh            # For POSIX shell (more portable)
#!/usr/bin/python3   # For Python scripts
```

### 4. Add Comments
Use comments in your crontab for clarity:

```bash
# Database backups
0 2 * * * /root/cron/bin/backup.sh >> /root/cron/log/backup.log 2>&1

# Weekly log rotation
0 0 * * 0 /root/cron/bin/cleanup.sh >> /root/cron/log/cleanup.log 2>&1
```

### 5. Log Everything
Always log your jobs to help with debugging:

```bash
#!/bin/bash
LOG_FILE="/root/cron/log/myjob.log"

{
    echo "Job started at $(date)"
    # Your commands here
    echo "Job ended at $(date)"
} >> "$LOG_FILE" 2>&1
```

### 6. Test Your Scripts First
Always test scripts manually before scheduling:

```bash
# Test the script
/root/cron/bin/backup.sh

# Check the output
tail -f /root/cron/log/backup.log
```

### 7. Use Consistent Logging Format
Standardize your log format for easier analysis:

```bash
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "Job started"
log_message "Processing data..."
log_message "Job completed"
```

---

## Troubleshooting

### Problem: Cron Job Not Running

**Possible causes:**
1. Script doesn't have execute permissions
2. Script path is not absolute
3. Cron daemon not running
4. Syntax error in crontab

**Solutions:**

```bash
# 1. Check execute permissions
ls -l /root/cron/bin/backup.sh
chmod +x /root/cron/bin/backup.sh

# 2. Verify cron is running
ps aux | grep crond

# 3. Check for syntax errors
crontab -l

# 4. Manually test the script
/root/cron/bin/backup.sh
```

### Problem: Script Runs but Produces No Output

**Possible causes:**
1. Environment variables not set in cron context
2. Relative paths in script
3. Missing dependencies (Python modules, etc.)

**Solutions:**

```bash
#!/bin/bash
# Set environment variables explicitly
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export HOME="/root"

# Use absolute paths
cd /root/my_project || exit 1
/usr/bin/python3 /root/my_project/script.py
```

### Problem: Permission Denied Error

**Solution:**

```bash
# Make script executable
chmod +x /root/cron/bin/backup.sh

# Verify permissions
ls -l /root/cron/bin/backup.sh
# Should show: -rwxr-xr-x (or similar with 'x')
```

### Problem: Cron Logs Not Appearing

**Check system logs:**

```bash
# On Linux with systemd
journalctl -u cron --tail=50

# Or check syslog
tail -f /var/log/syslog | grep CRON

# Check mail for cron output (if configured)
mail
```

---

## Advanced: Cron Environment Setup

Create a wrapper script to set up the environment properly:

```bash
#!/bin/bash
# File: /root/cron/bin/env_wrapper.sh

# Set environment
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export HOME="/root"
export SHELL="/bin/bash"

# Source user profile if needed
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
[ -f "$HOME/.profile" ] && source "$HOME/.profile"

# Run the actual script
exec "$@"
```

Use in crontab:

```bash
0 2 * * * /root/cron/bin/env_wrapper.sh /root/cron/bin/backup.sh
```

---

## Managing Logs

### View Logs in Real-Time

```bash
# Watch log file as it's written
tail -f /root/cron/log/backup.log

# Last 20 lines
tail -20 /root/cron/log/backup.log

# Search for errors
grep ERROR /root/cron/log/backup.log
```

### Rotate Logs Periodically

Create a log rotation cron job:

```bash
# In crontab: rotate logs every Sunday at 1 AM
0 1 * * 0 /root/cron/bin/rotate_logs.sh
```

Script content:

```bash
#!/bin/bash
LOG_DIR="/root/cron/log"

# Archive logs older than 7 days
for logfile in "$LOG_DIR"/*.log; do
    if [ -f "$logfile" ]; then
        tar -czf "$logfile.$(date +%Y%m%d).gz" "$logfile"
        > "$logfile"  # Clear the file
    fi
done

# Delete archives older than 30 days
find "$LOG_DIR" -name "*.log.*.gz" -mtime +30 -delete
```

---

## Quick Reference

### Essential Commands

```bash
# Edit crontab
crontab -e

# List your cron jobs
crontab -l

# Remove all cron jobs
crontab -r

# Install crontab from file
crontab /path/to/crontab_file

# Test a script before scheduling
/root/cron/bin/backup.sh

# Check cron status
ps aux | grep crond

# View recent cron activity
sudo tail -f /var/log/syslog | grep CRON
```

---

## Example: Complete Setup

### 1. Create directory structure

```bash
mkdir -p ~/cron/{bin,log}
```

### 2. Create a sample script

```bash
# File: ~/cron/bin/sample.sh
#!/bin/bash
LOG_FILE="$HOME/cron/log/sample.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }
log "Script executed successfully"
```

### 3. Make it executable

```bash
chmod +x ~/cron/bin/sample.sh
```

### 4. Schedule it

```bash
crontab -e
# Add: 0 * * * * /root/cron/bin/sample.sh
```

### 5. Verify

```bash
crontab -l
tail -f ~/cron/log/sample.log
```

---

## Resources

- **Cron Manual**: `man cron`, `man crontab`
- **Online Tools**: Crontab.guru (visual cron expression builder)
- **Debugging**: Check `/var/log/syslog` or `journalctl` for cron activity

---

## Summary

Cron is a powerful tool for automation. Key takeaways:

✅ Always use absolute paths
✅ Make scripts executable with `chmod +x`
✅ Log all output for debugging
✅ Test scripts manually first
✅ Use `*/` for intervals (e.g., `*/5` for every 5 minutes)
✅ Check cron daemon is running
✅ Monitor logs regularly for issues
