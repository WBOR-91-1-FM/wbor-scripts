#!/bin/bash
set -Eeuo pipefail

# Define log paths first
LOGDIR="$HOME/Logs/streamwbor"
LOGFILE="$LOGDIR/mpv.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

if ! command -v mpv >/dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: mpv not found in PATH" >> "$LOGFILE"
    exit 1
fi

# Try multiple sources for stream URL (config file takes precedence)
# Config file should contain just the URL, no quotes or extra whitespace
# Example: echo "https://stream.wbor.org/automation" > ~/.config/wbor-stream-url
URL=""
if [ -f "$HOME/.config/wbor-stream-url" ]; then
    URL=$(cat "$HOME/.config/wbor-stream-url" | tr -d '\n\r' | xargs)
fi
# Fall back to environment variable if no config file
if [ -z "$URL" ]; then
    URL="${AUTOMATION_STREAM_URL:-}"
fi
if [ -z "$URL" ]; then
    log "Error: No stream URL found in config file or AUTOMATION_STREAM_URL"
    exit 1
fi

mkdir -p "$LOGDIR"

log "starting mpv with URL: $URL"
while true; do
  mpv \
    --no-video \
    --input-terminal=no \
    --cache=yes \
    --demuxer-max-bytes=100M \
    --demuxer-max-back-bytes=10M \
    --network-timeout=60 \
    --stream-lavf-o=reconnect_streamed=1 \
    --stream-lavf-o=reconnect_delay_max=30 \
    --stream-lavf-o=reconnect_on_network_error=1 \
    --cache-secs=300 \
    --term-status-msg="A: \${=time-pos} / \${=duration} (\${=percent-pos}%) Cache: \${=cache-buffering-state}s/\${=demuxer-cache-duration}KB" \
    --log-file="$LOGFILE" \
    "$URL"
  log "mpv exited with status $?, restarting in 5s"
  sleep 5
done

# Arguments optimized for maximum uptime
# - `--no-video`: Disable video playback, audio-only for bandwidth efficiency
# - `--input-terminal=no`: Disable terminal input to prevent blocking
# - `--cache=yes`: Enable stream caching for buffering during network issues
# - `--demuxer-max-bytes=100M`: Large forward buffer (hours of audio) for extended outages
# - `--demuxer-max-back-bytes=10M`: Backward buffer for seeking capability
# - `--network-timeout=60`: Patient 60-second timeout for slow/unstable connections
# - `--stream-lavf-o=reconnect_streamed=1`: Enable automatic reconnection for streams
# - `--stream-lavf-o=reconnect_delay_max=30`: 30-second max delay between reconnect attempts
# - `--stream-lavf-o=reconnect_on_network_error=1`: Reconnect specifically on network errors
# - `--cache-secs=300`: Maintain 5 minutes of buffered content when possible
# - `--term-status-msg`: Display playback time, duration, and cache status for monitoring
# - `--log-file`: Write all mpv output to log file for debugging
# - `"$URL"`: The WBOR automation stream URL from environment variable
