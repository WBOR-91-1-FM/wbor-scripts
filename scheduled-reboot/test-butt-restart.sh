#!/bin/bash

# Test script for BUTT restart setup
# This will test the logging and process handling without restarting BUTT

echo "Testing BUTT restart script setup..."

# Test 1: Check if script exists and is executable
SCRIPT_PATH="./restart-butt.sh"
if [[ -x "$SCRIPT_PATH" ]]; then
    echo "✓ BUTT restart script exists and is executable"
else
    echo "✗ BUTT restart script not found or not executable at: $SCRIPT_PATH"
    exit 1
fi

# Test 2: Check if plist file exists
PLIST_PATH="./com.wbor.buttrestart.plist"
if [[ -f "$PLIST_PATH" ]]; then
    echo "✓ Launchd plist file exists"
else
    echo "✗ Launchd plist file not found at: $PLIST_PATH"
    exit 1
fi

# Test 3: Validate plist syntax
if plutil -lint "$PLIST_PATH" >/dev/null 2>&1; then
    echo "✓ Plist file syntax is valid"
else
    echo "✗ Plist file syntax is invalid"
    exit 1
fi

# Test 4: Check for BUTT application
BUTT_PATHS=(
    "/Applications/butt.app"
    "$HOME/Applications/butt.app"
)

BUTT_FOUND=false
for path in "${BUTT_PATHS[@]}"; do
    if [[ -d "$path" ]]; then
        echo "✓ Found BUTT application at: $path"
        BUTT_FOUND=true
        break
    fi
done

if [[ "$BUTT_FOUND" == false ]]; then
    echo "⚠ BUTT application not found in common locations:"
    for path in "${BUTT_PATHS[@]}"; do
        echo "  - $path"
    done
fi

# Test 5: Check if BUTT is currently running
if pgrep -f "butt"; then
    echo "✓ BUTT is currently running"
else
    echo "ℹ BUTT is not currently running"
fi

# Test 6: Create a test version of the script (dry run)
echo ""
echo "Creating test version of restart script..."
TEST_SCRIPT="/tmp/test-butt-restart.sh"

# Create a modified version that doesn't actually restart BUTT
cat > "$TEST_SCRIPT" << 'EOF'
#!/bin/bash

# Test version - modified to not actually restart BUTT
LOG_FILE="$HOME/Library/Logs/butt-restart.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$(dirname "$LOG_FILE")"

log_message "=== BUTT Restart Script Started (TEST MODE) ==="
log_message "WARNING: RabbitMQ credentials not configured. Skipping notification override."
log_message "Waiting 5 seconds for override to take effect..."
sleep 5

# Check for BUTT without actually stopping it
if pgrep -f "butt"; then
    log_message "✓ BUTT is currently running (would restart in real mode)"
else
    log_message "BUTT is not currently running (would start in real mode)"
fi

log_message "TEST MODE: Skipping actual BUTT restart"
log_message "=== BUTT Restart Script Completed (TEST MODE) ==="
EOF

chmod +x "$TEST_SCRIPT"
echo "Running test version..."
bash "$TEST_SCRIPT"

# Test 7: Check if log file was created
LOG_FILE="$HOME/Library/Logs/butt-restart.log"
if [[ -f "$LOG_FILE" ]]; then
    echo "✓ Log file created successfully"
    echo "Recent log entries:"
    tail -5 "$LOG_FILE"
else
    echo "✗ Log file was not created"
fi

echo ""
echo "=== Installation Instructions ==="
echo "To install the scheduled BUTT restart job:"
echo ""
echo "1. Configure RabbitMQ credentials in restart-butt.sh (optional)"
echo "2. Update USERNAME and PROJECT_DIR in com.wbor.buttrestart.plist"
echo "3. Copy the plist to ~/Library/LaunchAgents/:"
echo "   cp ./com.wbor.buttrestart.plist ~/Library/LaunchAgents/"
echo ""
echo "4. Load the job:"
echo "   launchctl load ~/Library/LaunchAgents/com.wbor.buttrestart.plist"
echo ""
echo "5. To verify it's loaded:"
echo "   launchctl list | grep buttrestart"
echo ""
echo "6. To test immediately (will actually restart BUTT):"
echo "   ./restart-butt.sh"
echo ""
echo "7. To unload the job (if needed):"
echo "   launchctl unload ~/Library/LaunchAgents/com.wbor.buttrestart.plist"

# Clean up test script
rm -f "$TEST_SCRIPT"

echo ""
echo "Test completed successfully!"