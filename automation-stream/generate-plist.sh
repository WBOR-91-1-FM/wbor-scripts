#!/bin/bash
set -Eeuo pipefail

# Configuration variables
USERNAME="${USER}"
SCRIPT_NAME="stream-wbor.sh"
LABEL="com.wbor.streamwbor"
SERVICE_NAME="streamwbor"

# Paths (absolute, no shell expansion in plist files)
SCRIPT_PATH="${HOME}/.${SCRIPT_NAME}"
PLIST_NAME="${LABEL}.plist"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_NAME}"
LOG_DIR="${HOME}/Logs/wbor/automation-stream"
STDOUT_LOG="${LOG_DIR}/launchd.out.log"
STDERR_LOG="${LOG_DIR}/launchd.err.log"

# Logging helper
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

log "Generating plist for ${LABEL}"
cat > "${PLIST_PATH}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>

  <key>Label</key>
  <string>${LABEL}</string>

  <!-- Only run after log into the GUI -->
  <key>LimitLoadToSessionType</key>
  <string>Aqua</string>

  <!-- Launch script -->
  <key>ProgramArguments</key>
  <array>
    <string>${SCRIPT_PATH}</string>
  </array>

  <!-- Ensure Homebrew's mpv is found -->
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>

  <!-- Capture script output and errors -->
  <key>StandardOutPath</key>
  <string>${STDOUT_LOG}</string>
  <key>StandardErrorPath</key>
  <string>${STDERR_LOG}</string>

  <!-- Start at login and restart on crash -->
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>

</dict>
</plist>
EOF

log "Generated plist at ${PLIST_PATH}"

# Copy script to home directory if it exists in current directory
if [ -f "${SCRIPT_NAME}" ]; then
    cp "${SCRIPT_NAME}" "${SCRIPT_PATH}"
    chmod +x "${SCRIPT_PATH}"
    log "Copied and made executable: ${SCRIPT_PATH}"
else
    log "Warning: ${SCRIPT_NAME} not found in current directory"
fi

log "Setup complete!"
log ""
log "Next steps:"
log "1. Ensure the stream URL is configured:"
log "   echo 'https://your-stream-url' > ~/.config/wbor-stream-url"
log ""
log "2. Load the service:"
log "   launchctl bootstrap gui/\$(id -u) '${PLIST_PATH}'"
log "   launchctl enable gui/\$(id -u)/${LABEL}"
log ""
log "3. Check status:"
log "   launchctl print gui/\$(id -u)/${LABEL}"
log ""
log "4. View logs:"
log "   tail -f '${STDOUT_LOG}'"
log "   tail -f '${STDERR_LOG}'"