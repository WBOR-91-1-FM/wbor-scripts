#!/bin/bash

# Centralized RabbitMQ configuration loader for calling scripts
#
# Sources ~/.config/wbor-rabbitmq-config
#
# Config file should contain one key=value pair per line
#
# Example ~/.config/wbor-rabbitmq-config:
#   RABBITMQ_USER=myuser
#   RABBITMQ_PASS=mypass
#   RABBITMQ_HOST=localhost
#   RABBITMQ_PORT=15672
#   RABBITMQ_PROTOCOL=http

load_rabbitmq_config() {
    RABBITMQ_USER=""
    RABBITMQ_PASS=""
    RABBITMQ_HOST=""
    RABBITMQ_PORT=""
    RABBITMQ_PROTOCOL="http"

    if [ -f "$HOME/.config/wbor-rabbitmq-config" ]; then
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove quotes and whitespace from value
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")
            
            case "$key" in
                RABBITMQ_USER) RABBITMQ_USER="$value" ;;
                RABBITMQ_PASS) RABBITMQ_PASS="$value" ;;
                RABBITMQ_HOST) RABBITMQ_HOST="$value" ;;
                RABBITMQ_PORT) RABBITMQ_PORT="$value" ;;
                RABBITMQ_PROTOCOL) RABBITMQ_PROTOCOL="$value" ;;
            esac
        done < "$HOME/.config/wbor-rabbitmq-config"
    fi

    # Fall back to environment variables if config file values are empty
    [ -z "$RABBITMQ_USER" ] && RABBITMQ_USER="${RABBITMQ_USER}"
    [ -z "$RABBITMQ_PASS" ] && RABBITMQ_PASS="${RABBITMQ_PASS}"
    [ -z "$RABBITMQ_HOST" ] && RABBITMQ_HOST="${RABBITMQ_HOST}"
    [ -z "$RABBITMQ_PORT" ] && RABBITMQ_PORT="${RABBITMQ_PORT}"
    [ -z "$RABBITMQ_PROTOCOL" ] && RABBITMQ_PROTOCOL="${RABBITMQ_PROTOCOL:-http}"

    export RABBITMQ_USER
    export RABBITMQ_PASS
    export RABBITMQ_HOST
    export RABBITMQ_PORT
    export RABBITMQ_PROTOCOL
}