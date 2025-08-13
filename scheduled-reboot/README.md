# Scheduled Reboot System for macOS

Automatically reboots macOS every 48 hours at 4am, with [failsafe notification override](https://github.com/WBOR-91-1-FM/wbor-failsafe-notifier) support.

## Files

- `scheduled-reboot.sh` - Main reboot script with logging and notification override
- `com.wbor.scheduledreboot.plist` - Launchd configuration for scheduling
- `test-reboot-script.sh` - Test script to verify setup without rebooting
- `test-immediate-reboot.sh` - Test script that will actually reboot the system

## Features

- **Automatic scheduling**: Runs every 48 hours at 4am
- **Notification override**: Sends failsafe override before reboot (configurable)
- **Comprehensive logging**: Logs all activities to `~/Library/Logs/scheduled-reboot.log`
- **User notification**: Shows macOS notification 30 seconds before reboot
- No admin privileges required

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

### 3. Install the Scheduled Job

Change `USERNAME` and copy the`.plist` file to your `LaunchAgents` directory:

```bash
cp com.wbor.scheduledreboot.plist ~/Library/LaunchAgents/
```

Load the job with launchctl:

```bash
launchctl load ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist
```

### 4. Verify Installation

Check that the job is loaded:

```bash
launchctl list | grep wbor
```

You should see `com.wbor.scheduledreboot` in the output.

## Schedule Details

The system is configured to run every 48 hours at 4:00 AM on:

- Monday (weekday 1)
- Wednesday (weekday 3)
- Friday (weekday 5)
- Sunday (weekday 0)

This creates a 48-hour cycle: Mon 4am → Wed 4am → Fri 4am → Sun 4am → Mon 4am...

## Logging

All activities are logged to: `~/Library/Logs/scheduled-reboot.log`

The log includes:

- Script start/end timestamps
- Notification override status
- System reboot initiation
- Any errors or warnings

Additional launchd output is logged to: `~/Library/Logs/scheduled-reboot-launchd.log`

## Troubleshooting

### Job Not Running

- Check if job is loaded: `launchctl list | grep wbor`
- Check system logs: `log show --predicate 'subsystem == "com.apple.launchd"' --info`
- Verify plist syntax: `plutil -lint ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist`

### Script Errors

- Check the main log: `tail -f ~/Library/Logs/scheduled-reboot.log`
- Check launchd log: `tail -f ~/Library/Logs/scheduled-reboot-launchd.log`
- Test manually: `./test-immediate-reboot.sh` (safe with 15-second cancel option)
- Direct test: `./scheduled-reboot.sh` (immediate execution - will reboot!)

### Notification Override Issues

- Verify RabbitMQ credentials are correct
- Test connection manually with curl
- Check RabbitMQ server status

## Uninstalling

To remove the scheduled job:

```bash
launchctl unload ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist
rm ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist
```

## Notes

- Script runs as current user (no sudo required)
- Credentials are stored in plain text - consider using environment variables or keychain
- Reboot command uses standard system shutdown without admin privileges

## Customization

### Change Schedule

Edit the `StartCalendarInterval` section in `com.wbor.scheduledreboot.plist` to modify timing.

### Modify Notification Time

Change the `sleep 30` value in `scheduled-reboot.sh` to adjust notification timing.

### Custom Override Duration

Modify the `duration_minutes` value in the RabbitMQ payload (default: 15 minutes).
