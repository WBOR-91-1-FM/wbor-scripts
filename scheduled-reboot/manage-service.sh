#!/bin/bash
set -Eeuo pipefail

LABEL="com.wbor.scheduledreboot"
PLIST_PATH="${HOME}/Library/LaunchAgents/${LABEL}.plist"
USER_ID=$(id -u)

# Logging helper
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Show usage
usage() {
    echo "Usage: $0 {load|unload|start|stop|status|logs|test}"
    echo ""
    echo "Commands:"
    echo "  load     - Load the scheduled reboot service"
    echo "  unload   - Unload the scheduled reboot service"
    echo "  start    - Manually trigger the scheduled reboot (WARNING: Will reboot!)"
    echo "  stop     - Stop any running reboot process"
    echo "  status   - Show service status and next scheduled run"
    echo "  logs     - Show service logs"
    echo "  test     - Run the test script (safe, no reboot)"
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
        log "Loading scheduled reboot service $LABEL..."
        launchctl load "$PLIST_PATH"
        log "Service loaded. Will run at scheduled times (Mon/Wed/Fri/Sun at 4:00 AM)"
        ;;
    
    unload)
        log "Unloading scheduled reboot service $LABEL..."
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
        log "Service unloaded"
        ;;
    
    start)
        echo "⚠️  WARNING: This will manually trigger the reboot script!"
        echo "This will REBOOT your computer immediately!"
        echo ""
        read -p "Are you sure you want to continue? (Y/n): " confirm
        confirm=${confirm:-Y}  # Default to Y if empty
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Manually starting scheduled reboot service..."
            launchctl start "$LABEL"
        else
            log "Manual reboot cancelled"
            exit 0
        fi
        ;;
    
    stop)
        log "Attempting to stop scheduled reboot service..."
        launchctl stop "$LABEL" 2>/dev/null || true
        # Also try to stop the actual reboot script if it's running
        pkill -f "scheduled-reboot.sh" 2>/dev/null || true
        log "Stop command sent"
        ;;
    
    status)
        echo "Service status for $LABEL:"
        echo "================================"
        
        # Check if service is loaded
        if launchctl list | grep -q "$LABEL"; then
            echo "✓ Service is loaded"
            
            # Show detailed status
            echo ""
            echo "Detailed status:"
            launchctl list "$LABEL" 2>/dev/null || echo "Unable to get detailed status"
            
            # Show next scheduled run times
            echo ""
            echo "Scheduled run times: Monday, Wednesday, Friday, Sunday at 4:00 AM"
            
        else
            echo "✗ Service is not loaded"
            echo "Run '$0 load' to load the service"
        fi
        
        echo ""
        echo "Recent log entries:"
        tail -5 "${HOME}/Library/Logs/scheduled-reboot.log" 2>/dev/null || echo "No log file found"
        ;;
    
    logs)
        LOG_FILE="${HOME}/Library/Logs/scheduled-reboot.log"
        LAUNCHD_LOG="${HOME}/Library/Logs/scheduled-reboot-launchd.log"
        
        echo "Scheduled Reboot Service Logs"
        echo "============================="
        echo ""
        
        if [ -f "$LOG_FILE" ]; then
            echo "Main script log (last 20 lines):"
            tail -20 "$LOG_FILE"
        else
            echo "Main script log not found at: $LOG_FILE"
        fi
        
        echo ""
        echo "---"
        echo ""
        
        if [ -f "$LAUNCHD_LOG" ]; then
            echo "LaunchAgent log (last 10 lines):"
            tail -10 "$LAUNCHD_LOG"
        else
            echo "LaunchAgent log not found at: $LAUNCHD_LOG"
        fi
        
        echo ""
        echo "To follow logs in real-time:"
        echo "  tail -f '$LOG_FILE'"
        echo "  tail -f '$LAUNCHD_LOG'"
        ;;
    
    test)
        log "Running test script (safe, no reboot)..."
        if [ -f "./test-reboot-script.sh" ]; then
            ./test-reboot-script.sh
        else
            log "Error: test-reboot-script.sh not found in current directory"
            exit 1
        fi
        ;;
    
    *)
        usage
        ;;
esac