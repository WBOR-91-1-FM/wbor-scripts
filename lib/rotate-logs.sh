#!/bin/bash
# Rotate logs when they exceed 10MB, keep 5 old versions

LOG_BASE="$HOME/Logs/wbor"
MAX_SIZE=10485760  # 10MB in bytes

rotate_log() {
    local log_file="$1"
    [ ! -f "$log_file" ] && return
    
    local size=$(stat -f%z "$log_file" 2>/dev/null || echo 0)
    if [ "$size" -gt "$MAX_SIZE" ]; then
        # Rotate: file.log -> file.log.1, file.log.1 -> file.log.2, etc.
        for i in 4 3 2 1; do
            [ -f "$log_file.$i" ] && mv "$log_file.$i" "$log_file.$((i+1))"
        done
        [ -f "$log_file" ] && mv "$log_file" "$log_file.1"
        touch "$log_file"
        echo "Rotated $log_file"
    fi
}

# Rotate all log files
find "$LOG_BASE" -name "*.log" -type f 2>/dev/null | while read -r log; do
    rotate_log "$log"
done