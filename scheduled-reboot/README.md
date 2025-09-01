# Scheduled Reboot

Automatically reboots macOS every 48 hours at 4 AM. Sends notification override to streaming system before reboot.

Done to mitigate a macOS audio driver issue affecting live broadcasts over extended periods of time.

## File Overview

| File                                                 | Purpose                                         |
|------------------------------------------------------|-------------------------------------------------|
| `generate-plist.sh`                                  | Automated plist generator and installer        |
| `manage-service.sh`                                  | Service management utility                      |
| `scheduled-reboot.sh`                                | Main reboot script with failsafe override      |
| `test-reboot-script.sh`                              | Test script for setup validation (no reboot)   |
| `test-immediate-reboot.sh`                           | Immediate test script (WILL reboot)            |
| `~/Library/LaunchAgents/com.wbor.scheduledreboot.plist` | LaunchAgent for scheduled execution        |
| `~/Library/Logs/scheduled-reboot.log`                | Main script log output                         |
| `~/Library/Logs/scheduled-reboot-launchd.log`        | LaunchAgent stdout/stderr capture              |

## Setup

1. **Configure RabbitMQ credentials**:

   ```bash
   mkdir -p ~/.config
   cat > ~/.config/wbor-rabbitmq-config << EOF
   RABBITMQ_USER=your_username
   RABBITMQ_PASS=your_password
   RABBITMQ_HOST=your_host
   RABBITMQ_PORT=15672
   RABBITMQ_PROTOCOL=http
   EOF
   ```

2. **Make scripts executable**:

   ```bash
   chmod +x scheduled-reboot.sh test-*.sh
   ```

3. **Generate and install the service**:

   ```bash
   ./generate-plist.sh
   ```

4. **Test the setup** (without rebooting):

   ```bash
   ./test-reboot-script.sh
   ```

5. **Load the service**:

   ```bash
   ./manage-service.sh load
   ```

## Schedule

The system will reboot at **4:00 AM** on:

- **Sunday** (Weekday 0)
- **Monday** (Weekday 1)
- **Wednesday** (Weekday 3)
- **Friday** (Weekday 5)

This provides reboots every 48 hours while avoiding prime broadcasting times.

## Reboot Process

1. **Failsafe Override**: Sends 15-minute override command to streaming system via RabbitMQ
2. **Application Termination**: Force quits BUTT (Broadcast Using This Tool) and other applications
3. **User Notification**: Displays 30-second countdown notification
4. **System Reboot**: Executes forced reboot using multiple fallback methods

## Testing

### Safe Testing (No Reboot)

```bash
./test-reboot-script.sh
```

### Full Testing (WILL REBOOT!)

```bash
./test-immediate-reboot.sh
```

## Service Management

```bash
# Check service status
./manage-service.sh status

# View all logs
./manage-service.sh logs

# Load/unload the service
./manage-service.sh load
./manage-service.sh unload

# Test the setup (safe, no reboot)
./manage-service.sh test

# Manual trigger (WARNING: WILL REBOOT!)
./manage-service.sh start

# Stop running reboot process
./manage-service.sh stop
```

## Important Notes

- **Force Quit**: Script will forcibly terminate applications to prevent reboot interference
- **BUTT Restart**: BUTT application should be configured as a startup/login item to automatically restart after reboot
