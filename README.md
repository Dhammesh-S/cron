# Termux Automation Scripts

Repository for automated scripts running in Termux environment.

## Structure

```
automation-scripts/
├── scripts/           # Executable automation scripts
├── logs/             # Centralized log files
├── config/           # Configuration files
└── README.md         # This file
```

## Scripts

### Daily Login Script
- **File**: `scripts/daily_login.sh`
- **Purpose**: Daily Shoonya API authentication via TR3X project
- **Schedule**: 9:03 AM daily (via cron)
- **Logs**: `logs/daily_login.log`
- **Notifications**: Success/failure via Termux API

#### Features:
- Runs `python3 -m config.files.login` from TR3X directory
- Sends single notification with result
- Comprehensive logging with timestamps
- Error handling and debug logging

## Setup Instructions

### Prerequisites
- Termux with Python 3
- Termux:API app installed
- TR3X repository with login module

### Installation
1. Clone/setup this repository in Termux home
2. Make scripts executable: `chmod +x scripts/*.sh`
3. Set up cron job: `crontab -e`
4. Add: `3 9 * * * /data/data/com.termux/files/home/automation-scripts/scripts/daily_login.sh`

### Usage
- **Manual run**: `./scripts/daily_login.sh`
- **Check logs**: `tail -f logs/daily_login.log`
- **Verify cron**: `crontab -l`

## Maintenance

### Log Management
Logs are appended daily. Clean up periodically:
```bash
# Keep last 30 days
find logs/ -name "*.log" -mtime +30 -delete
```

### Adding New Scripts
1. Place in `scripts/` directory
2. Make executable: `chmod +x`
3. Update this README
4. Add to cron if needed

## Troubleshooting

### Common Issues
- **No notifications**: Check Termux:API app permissions
- **Script not found**: Verify full path in crontab
- **Login fails**: Check TR3X repository and credentials

### Debug Commands
```bash
# Test notification
termux-notification --title "Test" --content "Hello"

# Test script manually
./scripts/daily_login.sh

# Check cron status
ps aux | grep crond
```
