# Scheduled Reboot System for macOS

Automatically reboots macOS every 48 hours at 4am, with [failsafe notification override](https://github.com/WBOR-91-1-FM/wbor-failsafe-notifier) support.

## Files

- `scheduled-reboot.sh` - Main reboot script with logging and notification override
- `com.wbor.scheduledreboot.plist` - Launchd configuration for scheduling
- `test-reboot-script.sh` - Test script to verify setup without rebooting
- `test-immediate-reboot.sh` - Test script that will actually reboot the system
- `restart-butt.sh` - Alternative script that only restarts [BUTT](https://danielnoethen.de/butt/) (not the system)
- `com.wbor.buttrestart.plist` - Launchd configuration for BUTT restart scheduling
- `test-butt-restart.sh` - Test script for BUTT restart without actually restarting

## Features

- **Automatic scheduling**: Runs every 48 hours at 4am
- **Notification override**: Sends failsafe override before reboot (configurable)
- **Comprehensive logging**: Logs all activities to `~/Library/Logs/scheduled-reboot.log`
- **User notification**: Shows macOS notification 30 seconds before reboot
- **Multiple reboot methods**: Tries AppleScript, shutdown, and reboot commands automatically
- **BUTT integration**: System reboot script gracefully quits BUTT before rebooting
- **BUTT-only restart**: Alternative script for restarting just BUTT without system reboot

## Setup Instructions

### 1. Configure RabbitMQ Credentials (Optional)

Edit `scheduled-reboot.sh` and fill in your RabbitMQ settings:

```bash
RABBITMQ_USER="your_username"
RABBITMQ_PASS="your_password"
RABBITMQ_HOST="your_host"
RABBITMQ_PORT="your_port"
RABBITMQ_PROTOCOL="http"  # or "https"
```

### 2. Test the Setup

Run the test script to verify everything is configured correctly:

```bash
./test-reboot-script.sh
```

This will test the script without actually rebooting the system.

#### Alternative: Test with Actual Reboot

```bash
./test-immediate-reboot.sh
```

This script will:

- Give you 5 seconds to cancel (Ctrl+C)
- Run the actual reboot script with all functionality

**Manual Testing Options:**

You can also test immediately by running the main script directly:

```bash
# Direct execution (will reboot in ~60 seconds)
./scheduled-reboot.sh
```

Or trigger via launchctl (if already installed):

```bash
# Trigger the scheduled job manually
launchctl start com.wbor.scheduledreboot
```

#### BUTT-Only Restart Testing

To test the [BUTT](https://danielnoethen.de/butt/) restart functionality:

```bash
./test-butt-restart.sh    # Safe test without restarting
./restart-butt.sh         # Actually restart BUTT
```

### 3. Install the Scheduled Job

#### Option A: System Reboot (Full System Restart)

1. Update `USERNAME` and `PROJECT_DIR` in `com.wbor.scheduledreboot.plist`
2. Copy and load the plist:

```bash
cp com.wbor.scheduledreboot.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist
```

#### Option B: BUTT-Only Restart (Application Only)

1. Update `USERNAME` and `PROJECT_DIR` in `com.wbor.buttrestart.plist`  
2. Copy and load the plist:

```bash
cp com.wbor.buttrestart.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.wbor.buttrestart.plist
```

**Note**: You can install both if you want different maintenance schedules.

### 4. Verify Installation

Check that the job(s) are loaded:

```bash
launchctl list | grep wbor
```

You should see:

- `com.wbor.scheduledreboot` (if system reboot is installed)
- `com.wbor.buttrestart` (if BUTT restart is installed)

## Schedule Details

The system is configured to run every 48 hours at 4:00 AM on:

- Monday (weekday 1)
- Wednesday (weekday 3)
- Friday (weekday 5)
- Sunday (weekday 0)

This creates a 48-hour cycle: Mon 4am → Wed 4am → Fri 4am → Sun 4am → Mon 4am...

## Logging

**System Reboot logs:**

- Script log: `~/Library/Logs/scheduled-reboot.log`
- Launchd log: `~/Library/Logs/scheduled-reboot-launchd.log`

**BUTT Restart logs:**

- Script log: `~/Library/Logs/butt-restart.log`
- Launchd log: `~/Library/Logs/butt-restart-launchd.log`

Log contents include:

- Script start/end timestamps
- Notification override status
- BUTT process handling (restart script)
- System reboot initiation (reboot script)
- Any errors or warnings

## Troubleshooting

### Job Not Running

- Check if job is loaded: `launchctl list | grep wbor`
- Check system logs: `log show --predicate 'subsystem == "com.apple.launchd"' --info`
- Verify plist syntax:
  - `plutil -lint ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist`
  - `plutil -lint ~/Library/LaunchAgents/com.wbor.buttrestart.plist`

### Script Errors

**System Reboot:**

- Check logs: `tail -f ~/Library/Logs/scheduled-reboot.log`
- Check launchd: `tail -f ~/Library/Logs/scheduled-reboot-launchd.log`
- Test safely: `./test-immediate-reboot.sh` (5-second cancel option)
- Test directly: `./scheduled-reboot.sh` (will reboot!)

**BUTT Restart:**

- Check logs: `tail -f ~/Library/Logs/butt-restart.log`
- Check launchd: `tail -f ~/Library/Logs/butt-restart-launchd.log`
- Test safely: `./test-butt-restart.sh` (dry run)
- Test directly: `./restart-butt.sh` (will restart BUTT)

### Notification Override Issues

- Verify RabbitMQ credentials are correct
- Test connection manually with curl
- Check RabbitMQ server status

## Uninstalling

To remove the scheduled job:

```bash
# Remove system reboot job
launchctl unload ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist
rm ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist

# Remove BUTT restart job  
launchctl unload ~/Library/LaunchAgents/com.wbor.buttrestart.plist
rm ~/Library/LaunchAgents/com.wbor.buttrestart.plist
```

## Notes

- **Reboot Methods**: Script tries multiple reboot methods automatically:
  1. **AppleScript**: `tell app "System Events" to restart` (works on most managed machines)
  2. **Shutdown command**: `/sbin/shutdown -r now` (requires admin privileges)
  3. **Reboot command**: `/sbin/reboot` (fallback method)
- **Permissions**: No admin privileges required if AppleScript method works
- **Credentials**: Stored in plain text - consider using environment variables or keychain

## Customization

### Change Schedule

Edit the `StartCalendarInterval` section in `com.wbor.scheduledreboot.plist` to modify timing.

### Modify Notification Time

Change the `sleep 30` value in `scheduled-reboot.sh` to adjust notification timing.

### Custom Override Duration

Modify the `duration_minutes` value in the RabbitMQ payload (default: 15 minutes).
