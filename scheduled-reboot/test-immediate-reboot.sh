#!/bin/bash

# Immediate Reboot Test Script
# WARNING: This will actually reboot your computer!
# Use this script to test the reboot functionality immediately

echo "======================================"
echo "⚠️  IMMEDIATE REBOOT TEST SCRIPT ⚠️"
echo "======================================"
echo ""
echo "This script will run the actual reboot script and"
echo "WILL REBOOT YOUR COMPUTER!"
echo ""
echo "Make sure you:"
echo "• Save all your work"
echo "• Close all applications"
echo "• Are ready for the system to restart"
echo ""

# Give user 5 seconds to cancel
echo -n "Starting in 5 seconds... Press Ctrl+C to cancel "
for i in {5..1}; do
    echo -n "$i "
    sleep 1
done
echo ""
echo ""

echo "🚀 Starting immediate reboot test..."
echo "Check ~/Library/Logs/scheduled-reboot.log for detailed logs"
echo ""

# Run the actual reboot script
./scheduled-reboot.sh

echo "Script completed. If you see this message, the reboot command may have failed."