#!/bin/sh

PROFILE=${COLIMA_PROFILE:-docker}
LOCK_FILE="/tmp/colima-${PROFILE}.lock"

# Try to acquire lock
if ! mkdir "$LOCK_FILE" 2>/dev/null; then
  echo "Another instance is running for profile $PROFILE"
  # Monitor the lock file
  while [ -d "$LOCK_FILE" ]; do
    sleep 1
  done
  exit 0
fi

# Ensure lock is removed on exit
trap 'rm -rf "$LOCK_FILE"' EXIT

wait_for_colima() {
  local action=$1
  local timeout=10
  
  for i in $(seq 1 $timeout); do
    case $action in
      "start")
        if colima status -p $PROFILE >/dev/null 2>&1; then
          return 0
        fi
        ;;
      "stop")
        if ! colima status -p $PROFILE >/dev/null 2>&1; then
          return 0
        fi
        ;;
    esac
    echo "Waiting for Colima to $action... ($i/$timeout)"
    sleep 1
  done
  return 1
}

cleanup() {
  # Only stop colima if we're the main instance
  if [ -d "$LOCK_FILE" ]; then
    echo "Stopping Colima..."
    docker context use default || true
    colima stop -p $PROFILE
    wait_for_colima stop
  fi
  exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

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
colima --verbose -p $PROFILE start

if ! wait_for_colima start; then
  echo "Failed to start Colima"
  exit 1
fi

echo "Colima started successfully"

# Keep the process running to handle signals
while true; do
  sleep 1
done 