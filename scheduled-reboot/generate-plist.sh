#!/bin/bash
set -Eeuo pipefail

# Configuration variables
USERNAME="${USER}"
SCRIPT_NAME="scheduled-reboot.sh"
LABEL="com.wbor.scheduledreboot"
SERVICE_NAME="scheduledreboot"

# Paths (absolute, no shell expansion in plist files)
SCRIPT_PATH="${PWD}/${SCRIPT_NAME}"
PLIST_NAME="${LABEL}.plist"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_NAME}"
LOG_DIR="${HOME}/Logs/wbor/scheduled-reboot"
STDOUT_LOG="${LOG_DIR}/launchd.log"
STDERR_LOG="${LOG_DIR}/launchd.log"

# Logging helper
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

log "Generating plist for ${LABEL}"
cat > "${PLIST_PATH}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPT_PATH}</string>
    </array>
    
    <key>StartCalendarInterval</key>
    <array>
        <dict>
            <key>Hour</key>
            <integer>4</integer>
            <key>Minute</key>
            <integer>0</integer>
            <key>Weekday</key>
            <integer>1</integer>
        </dict>
        <dict>
            <key>Hour</key>
            <integer>4</integer>
            <key>Minute</key>
            <integer>0</integer>
            <key>Weekday</key>
            <integer>3</integer>
        </dict>
        <dict>
            <key>Hour</key>
            <integer>4</integer>
            <key>Minute</key>
            <integer>0</integer>
            <key>Weekday</key>
            <integer>5</integer>
        </dict>
        <dict>
            <key>Hour</key>
            <integer>4</integer>
            <key>Minute</key>
            <integer>0</integer>
            <key>Weekday</key>
            <integer>0</integer>
        </dict>
    </array>
    
    <key>StandardOutPath</key>
    <string>${STDOUT_LOG}</string>
    
    <key>StandardErrorPath</key>
    <string>${STDERR_LOG}</string>
    
    <key>RunAtLoad</key>
    <false/>
    
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

log "Generated plist at ${PLIST_PATH}"

# Verify script exists and is executable
if [ -f "${SCRIPT_PATH}" ]; then
    chmod +x "${SCRIPT_PATH}"
    log "Made executable: ${SCRIPT_PATH}"
else
    log "Error: ${SCRIPT_PATH} not found!"
    exit 1
fi

log "Setup complete!"
log ""
log "Next steps:"
log "1. Test the script setup:"
log "   ./test-reboot-script.sh"
log ""
log "2. Load the service:"
log "   launchctl load '${PLIST_PATH}'"
log ""
log "3. Check status:"
log "   launchctl list | grep wbor"
log ""
log "4. View logs:"
log "   tail -f '${HOME}/Logs/wbor/scheduled-reboot/scheduled-reboot.log'"
log "   tail -f '${STDOUT_LOG}'"