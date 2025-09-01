#!/bin/bash
set -Eeuo pipefail

# AzuraCast Override Update Script
#
# Sends a temporary failsafe override to suppress "stream down" alerts,
# and runs the AzuraCast update.
#
# Usage:
#   OVERRIDE_MINUTES=15 ./update-with-override.sh
#   ./update-with-override.sh 20            # 20-minute override
#   ./update-with-override.sh               # default 15 minutes
#
# Requires: curl

# Load RabbitMQ configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/rabbitmq-config.sh"
load_rabbitmq_config

echo "Sending 15-minute failsafe override..."
curl -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" \
    -H "Content-Type: application/json" \
    -X POST \
    "${RABBITMQ_PROTOCOL}://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api/exchanges/%2F/commands/publish" \
    -d '{
      "properties": {},
      "routing_key": "command.failsafe-override",
      "payload": "{\"action\": \"enable_override\", \"duration_minutes\": 15}",
      "payload_encoding": "string"
    }'

echo -e "\nOverride sent"
echo "Starting AzuraCast update..."
./docker.sh update
