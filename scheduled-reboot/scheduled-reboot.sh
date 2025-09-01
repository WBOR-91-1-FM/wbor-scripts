#!/bin/bash

# Scheduled Reboot Script for macOS
# Runs every 48 hours at 4am, sends notification override before rebooting

# Load RabbitMQ configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/rabbitmq-config.sh"
load_rabbitmq_config

LOG_FILE="$HOME/Logs/wbor/scheduled-reboot/scheduled-reboot.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

log_message "=== Scheduled Reboot Script Started ==="

# Check if RabbitMQ credentials are configured
if [[ -z "$RABBITMQ_USER" || -z "$RABBITMQ_PASS" || -z "$RABBITMQ_HOST" || -z "$RABBITMQ_PORT" ]]; then
    log_message "WARNING: RabbitMQ credentials not configured. Skipping notification override."
else
    log_message "Sending 15-minute failsafe override..."
    
    # Send 15-minute override command
    RESPONSE=$(curl -s -w "%{http_code}" -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" \
         -H "Content-Type: application/json" \
         -X POST \
         "${RABBITMQ_PROTOCOL}://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api/exchanges/%2F/commands/publish" \
         -d '{
           "properties": {},
           "routing_key": "command.failsafe-override",
           "payload": "{\"action\": \"enable_override\", \"duration_minutes\": 15}",
           "payload_encoding": "string"
         }' 2>&1)
    
    HTTP_CODE="${RESPONSE: -3}"
    RESPONSE_BODY="${RESPONSE%???}"
    
    if [[ "$HTTP_CODE" == "200" ]]; then
        log_message "✓ 15-minute failsafe override sent successfully"
    else
        log_message "✗ Failed to send failsafe override. HTTP Code: $HTTP_CODE, Response: $RESPONSE_BODY"
    fi
fi

log_message "Waiting 15 seconds for override to take effect..."
sleep 15

# Force quit all applications before reboot
log_message "Force quitting all applications..."

# Get all running GUI applications and quit them
osascript -e 'tell application "System Events" to set appList to name of every process whose background only is false' 2>/dev/null | tr ',' '\n' | while IFS= read -r app; do
    app=$(echo "$app" | xargs)  # trim whitespace
    if [[ "$app" != "Finder" && "$app" != "System Events" && "$app" != "loginwindow" ]]; then
        log_message "Quitting application: $app"
        osascript -e "tell application \"$app\" to quit" 2>/dev/null || true
    fi
done

sleep 3

# Force quit BUTT specifically (may resist normal quit attempts during broadcast)
if pgrep -xf ".*[Bb][Uu][Tt][Tt].*" >/dev/null 2>&1; then
    log_message "Force quitting BUTT..."
    pkill -xf ".*[Bb][Uu][Tt][Tt].*" || true
    sleep 2
    
    if pgrep -xf ".*[Bb][Uu][Tt][Tt].*" >/dev/null 2>&1; then
        log_message "⚠ BUTT still running after force quit attempts"
        killall -9 "BUTT" 2>/dev/null || true
        killall -9 "butt" 2>/dev/null || true
    else
        log_message "✓ BUTT quit successfully"
    fi
else
    log_message "BUTT is not running"
fi

log_message "System reboot initiated - scheduled maintenance"

# Reboot the system with force flag - try multiple methods for different permission setups
log_message "Executing forced reboot command..."

# Method 1: Try shutdown with force flag (most reliable for forced reboot)
if /sbin/shutdown -r -f now "Scheduled maintenance reboot" 2>/dev/null; then
    log_message "✓ Forced reboot initiated via shutdown command"
# Method 2: Try osascript with immediate restart
elif /usr/bin/osascript -e 'tell app "System Events" to restart' 2>/dev/null; then
    log_message "✓ Reboot initiated via AppleScript"
# Method 3: Try reboot command
elif /sbin/reboot -f 2>/dev/null; then
    log_message "✓ Forced reboot initiated via reboot command"
else
    log_message "✗ Failed to initiate reboot - insufficient permissions"
    log_message "Manual intervention required: please reboot the system"
    exit 1
fi

log_message "=== Reboot command executed ==="