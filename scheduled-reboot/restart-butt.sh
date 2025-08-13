#!/bin/bash

# BUTT Restart Script for macOS
# Restarts BUTT application every 48 hours at 4am with notification override

# Configuration
RABBITMQ_USER=""
RABBITMQ_PASS=""
RABBITMQ_HOST="" # Without protocol, e.g., "localhost" or "rabbitmq.example.com"
RABBITMQ_PORT=""  # Usually 15672 for RabbitMQ management API
RABBITMQ_PROTOCOL="http" # or "https" depending on the setup

LOG_FILE="$HOME/Library/Logs/butt-restart.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# BUTT application paths to try (common locations)
BUTT_PATHS=(
    "/Applications/butt.app"
    "$HOME/Applications/butt.app"
)

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to find BUTT application
find_butt_app() {
    for path in "${BUTT_PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

# Function to check if BUTT is running
is_butt_running() {
    pgrep -f "butt"
}

# Function to kill BUTT process
kill_butt() {
    pkill -f "butt"
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

log_message "=== BUTT Restart Script Started ==="

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

log_message "Waiting 5 seconds for override to take effect..."
sleep 5

# Find BUTT application
BUTT_APP_PATH=$(find_butt_app)
if [[ $? -ne 0 ]]; then
    log_message "✗ BUTT application not found in common locations:"
    for path in "${BUTT_PATHS[@]}"; do
        log_message "  - $path"
    done
    log_message "Please update BUTT_PATHS in the script"
    exit 1
fi

log_message "✓ Found BUTT application at: $BUTT_APP_PATH"

# Check if BUTT is currently running
if is_butt_running; then
    log_message "✓ BUTT is currently running"
    
    log_message "Waiting 5 seconds before restarting BUTT..."
    sleep 5
    
    log_message "Stopping BUTT..."
    kill_butt
else
    log_message "BUTT is not currently running"
fi

# Wait and verify BUTT started back up
sleep 5
if is_butt_running; then
    log_message "✓ BUTT restarted successfully"
else
    log_message "⚠ BUTT may not have started properly - please check manually"
fi

log_message "=== BUTT Restart Script Completed ==="