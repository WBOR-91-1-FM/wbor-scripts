#!/bin/bash

# Scheduled Reboot Script for macOS
# Runs every 48 hours at 4am, sends notification override before rebooting

# Configuration
RABBITMQ_USER=""
RABBITMQ_PASS=""
RABBITMQ_HOST="" # Without protocol, e.g., "localhost" or "rabbitmq.example.com"
RABBITMQ_PORT=""  # Usually 15672 for RabbitMQ management API
RABBITMQ_PROTOCOL="http" # or "https" depending on the setup

LOG_FILE="$HOME/Library/Logs/scheduled-reboot.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Wait 30 seconds for the override to take effect
log_message "Waiting 30 seconds for override to take effect..."
sleep 30

# Display notification to any logged-in users
/usr/bin/osascript -e 'display notification "System will reboot in 30 seconds for scheduled maintenance" with title "Scheduled Reboot" sound name "Glass"' 2>/dev/null || true

log_message "System reboot initiated - scheduled maintenance"

# Reboot the system - try multiple methods for different permission setups
log_message "Executing reboot command..."

# Method 1: Try osascript (works on most managed machines)
if /usr/bin/osascript -e 'tell app "System Events" to restart' 2>/dev/null; then
    log_message "✓ Reboot initiated via AppleScript"
# Method 2: Try shutdown command (may require admin)
elif /sbin/shutdown -r now "Scheduled maintenance reboot" 2>/dev/null; then
    log_message "✓ Reboot initiated via shutdown command"
# Method 3: Try reboot command
elif /sbin/reboot 2>/dev/null; then
    log_message "✓ Reboot initiated via reboot command"
else
    log_message "✗ Failed to initiate reboot - insufficient permissions"
    log_message "Manual intervention required: please reboot the system"
    # Send notification about manual reboot needed
    /usr/bin/osascript -e 'display notification "Scheduled reboot failed - manual restart required" with title "Reboot Error" sound name "Glass"' 2>/dev/null || true
    exit 1
fi

log_message "=== Reboot command executed ==="