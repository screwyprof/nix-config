#!/bin/sh

PROFILE=${COLIMA_PROFILE:-docker}
LOCK_FILE="/tmp/colima-${PROFILE}.lock"

cleanup() {
  rm -rf "$LOCK_FILE"
}

stop_colima() {
  echo "Stopping Colima..."
  docker context use default || true
  colima stop -p $PROFILE
  wait_for_colima stop
}

# Ensure lock is removed on any exit
trap cleanup EXIT

# Handle termination signals
trap 'stop_colima; exit 0' SIGTERM SIGINT SIGQUIT

# Try to acquire lock
if ! mkdir "$LOCK_FILE" 2>/dev/null; then
  echo "Another instance is running for profile $PROFILE"
  # Monitor the lock file
  while [ -d "$LOCK_FILE" ]; do
    sleep 1
  done
  exit 0
fi

# Check if already running
if colima status -p $PROFILE >/dev/null 2>&1; then
  echo "Colima already running for profile $PROFILE"
  # Keep the process running to handle signals
  while true; do
    sleep 1
  done
fi

# Start Colima
echo "Starting Colima..."
colima --verbose -p $PROFILE start --save-config=false

if ! wait_for_colima start; then
  echo "Failed to start Colima"
  exit 1
fi

echo "Colima started successfully"

# Keep the process running to handle signals
while true; do
  sleep 1
done 