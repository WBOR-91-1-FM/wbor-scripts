# WBOR Automation Streaming

Automatically streams WBOR automation feed permanently in the background of macOS. Handles reconnections and logs output. Designed to run continuously 24/7, handling system reboots and network interruptions.

Streams using `mpv` [(docs)](https://mpv.io/).

## File Overview

| File                                               | Purpose                                  |
|----------------------------------------------------|------------------------------------------|
| `generate-plist.sh`                                | Automated plist generator and installer  |
| `manage-service.sh`                                | Service management utility               |
| `~/.stream-wbor.sh`                                | Main streaming script with mpv loop      |
| `~/Library/LaunchAgents/com.wbor.streamwbor.plist` | LaunchAgent to autostart on login        |
| `~/Logs/streamwbor/mpv.log`                        | Main mpv and script log output           |
| `~/Logs/streamwbor/launchd.out.log`                | LaunchAgent stdout capture               |
| `~/Logs/streamwbor/launchd.err.log`                | LaunchAgent stderr capture               |

## Setup

1. **Install `mpv` if needed**:

   ```bash
   brew install mpv
   ```

2. **Install the script**:

   ```bash
   cp stream-wbor.sh ~/.stream-wbor.sh
   chmod +x ~/.stream-wbor.sh
   ```

3. **Generate and install the service**:

   ```bash
   ./generate-plist.sh
   ```

4. **Set stream URL**:

   ```bash
   mkdir -p ~/.config
   echo "https://your-stream-url-here" > ~/.config/wbor-stream-url
   ```

5. **Load the service**:

   ```bash
   ./manage-service.sh load
   ```

6. **Monitor logs**:

   ```bash
   ./manage-service.sh logs
   ```

## Service Management

```bash
# Check service status / if service is running
./manage-service.sh status

# View all logs in real-time
./manage-service.sh logs

# Start/stop the service
./manage-service.sh start
./manage-service.sh stop
./manage-service.sh restart

# Load/unload the service
./manage-service.sh load
./manage-service.sh unload
```

## Important Notes

- **Session Dependency**: The service uses `LimitLoadToSessionType = Aqua`, meaning it only runs when the user is logged into the macOS **desktop** environment (no [headless](https://en.wikipedia.org/wiki/Headless_computer) operation).
- **Auto-login Required**: macOS should be configured for automatic login (login without requiring password) to ensure it starts sucessfully without user intervention. After initial login, it will continue to run in the background even if the screen is sleeping or locked.
- **No System Boot**: Again - streaming will NOT start on system boot if no user is logged into the GUI

## Troubleshooting Guide

### Service Shows as Running but No Audio

1. **Check all logs**:

   ```bash
   ./manage-service.sh logs
   # or individually:
   tail -F ~/Logs/streamwbor/mpv.log
   tail -F ~/Logs/streamwbor/launchd.err.log
   ```

2. **Verify audio device** is connected and selected as output

3. **Test stream URL accessibility**:

   ```bash
   curl -I $(cat ~/.config/wbor-stream-url)
   # Should return HTTP/2 200 along with other headers
   ```

4. **Test `mpv` manually**:

   ```bash
   mpv --no-video $(cat ~/.config/wbor-stream-url)
   ```

### Service Not Starting on Login

1. **Check service status**:

   ```bash
   ./manage-service.sh status
   ```

2. **Verify files exist**:

   ```bash
   ls -la ~/.stream-wbor.sh
   ls -la ~/Library/LaunchAgents/com.wbor.streamwbor.plist
   ```

3. **Check plist syntax**:

   ```bash
   plutil -lint ~/Library/LaunchAgents/com.wbor.streamwbor.plist
   ```

4. **Load manually to test**:

   ```bash
   ./manage-service.sh load
   ```

5. **Check running processes**:

   ```bash
   ps aux | grep stream-wbor
   ```
