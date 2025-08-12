#!/bin/bash

# Configuration
RABBITMQ_USER=""
RABBITMQ_PASS=""
RABBITMQ_HOST=""
RABBITMQ_PORT=""
RABBITMQ_PROTOCOL="http" # or "https" depending on the setup

echo "Sending 15-minute failsafe override..."

# Send 15-minute override command
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

echo -e "\n15-minute failsafe override sent"
echo "Running AzuraCast update..."
./docker.sh update

echo "Done!"