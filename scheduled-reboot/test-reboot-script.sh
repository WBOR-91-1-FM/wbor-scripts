#!/bin/bash

# Test script for scheduled reboot setup
# This will test the logging and notification without actually rebooting

echo "Testing scheduled reboot script setup..."

# Test 1: Check if script exists and is executable
SCRIPT_PATH="./scheduled-reboot.sh"
if [[ -x "$SCRIPT_PATH" ]]; then
    echo "✓ Reboot script exists and is executable"
else
    echo "✗ Reboot script not found or not executable at: $SCRIPT_PATH"
    exit 1
fi

# Test 2: Check if plist file exists
PLIST_PATH="./com.wbor.scheduledreboot.plist"
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

# Test 4: Create a modified version of the script for testing (without reboot)
TEST_SCRIPT="/tmp/test-scheduled-reboot.sh"
sed 's|/sbin/shutdown -r now|echo "REBOOT COMMAND WOULD EXECUTE HERE"|' "$SCRIPT_PATH" > "$TEST_SCRIPT"
chmod +x "$TEST_SCRIPT"

echo "Running test version of the script (without actual reboot)..."
bash "$TEST_SCRIPT"

# Test 5: Check if log file was created
LOG_FILE="$HOME/Library/Logs/scheduled-reboot.log"
if [[ -f "$LOG_FILE" ]]; then
    echo "✓ Log file created successfully"
    echo "Recent log entries:"
    tail -5 "$LOG_FILE"
else
    echo "✗ Log file was not created"
fi

# Test 6: Instructions for setting up the launchd job
echo -e "\nTo install the scheduled reboot job:"
echo "1. Copy the plist to ~/Library/LaunchAgents/:"
echo "   cp ./com.wbor.scheduledreboot.plist ~/Library/LaunchAgents/"
echo ""
echo "2. Load the job:"
echo "   launchctl load ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist"
echo ""
echo "3. To verify it's loaded:"
echo "   launchctl list | grep wbor"
echo ""
echo "4. To unload the job (if needed):"
echo "   launchctl unload ~/Library/LaunchAgents/com.wbor.scheduledreboot.plist"
echo ""
echo "Note: Configure RabbitMQ credentials in scheduled-reboot.sh before use"

# Clean up test script
rm -f "$TEST_SCRIPT"

echo -e "\nTest completed successfully!"