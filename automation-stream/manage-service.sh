#!/bin/bash
set -Eeuo pipefail

LABEL="com.wbor.streamwbor"
PLIST_PATH="${HOME}/Library/LaunchAgents/${LABEL}.plist"
USER_ID=$(id -u)

# Logging helper
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Show usage
usage() {
    echo "Usage: $0 {load|unload|start|stop|restart|status|logs}"
    echo ""
    echo "Commands:"
    echo "  load     - Bootstrap and enable the service (modern macOS)"
    echo "  unload   - Disable and unregister the service"
    echo "  start    - Start the service"
    echo "  stop     - Stop the service"
    echo "  restart  - Stop and start the service"
    echo "  status   - Show service status"
    echo "  logs     - Follow service logs"
    exit 1
}

# Check if plist exists
check_plist() {
    if [ ! -f "$PLIST_PATH" ]; then
        log "Error: Plist not found at $PLIST_PATH"
        log "Run './generate-plist.sh' first"
        exit 1
    fi
}

case "${1:-}" in
    load)
        check_plist
        log "Loading service $LABEL..."
        launchctl bootstrap "gui/${USER_ID}" "$PLIST_PATH"
        launchctl enable "gui/${USER_ID}/${LABEL}"
        log "Service loaded and enabled"
        ;;
    
    unload)
        log "Unloading service $LABEL..."
        launchctl disable "gui/${USER_ID}/${LABEL}" 2>/dev/null || true
        launchctl bootout "gui/${USER_ID}" "$PLIST_PATH" 2>/dev/null || true
        log "Service unloaded"
        ;;
    
    start)
        log "Starting service $LABEL..."
        launchctl kickstart "gui/${USER_ID}/${LABEL}"
        ;;
    
    stop)
        log "Stopping service $LABEL..."
        launchctl kill SIGTERM "gui/${USER_ID}/${LABEL}"
        ;;
    
    restart)
        log "Restarting service $LABEL..."
        launchctl kill SIGTERM "gui/${USER_ID}/${LABEL}"
        sleep 2
        launchctl kickstart "gui/${USER_ID}/${LABEL}"
        ;;
    
    status)
        echo "Service status for $LABEL:"
        launchctl print "gui/${USER_ID}/${LABEL}"
        ;;
    
    logs)
        LOG_DIR="${HOME}/Logs/streamwbor"
        echo "Following logs (Ctrl+C to stop)..."
        echo "stdout: tail -f ${LOG_DIR}/launchd.out.log"
        echo "stderr: tail -f ${LOG_DIR}/launchd.err.log"
        echo "mpv:    tail -f ${LOG_DIR}/mpv.log"
        echo ""
        tail -f "${LOG_DIR}/launchd.out.log" "${LOG_DIR}/launchd.err.log" "${LOG_DIR}/mpv.log" 2>/dev/null || {
            echo "Log files not found. Service may not be running."
            exit 1
        }
        ;;
    
    *)
        usage
        ;;
esac