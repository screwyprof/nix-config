#!/bin/sh

PROFILE=${1:-$COLIMA_PROFILE}
PROFILE=${PROFILE:-docker}
LOCK_FILE="/tmp/colima-${PROFILE}.lock"
AGENT_PLIST="${HOME}/Library/LaunchAgents/com.github.colima.nix.plist"

MODE=${2:-help}

check_state() {
  # Check if colima is running
  COLIMA_RUNNING=0
  if colima status -p $PROFILE >/dev/null 2>&1; then
    COLIMA_RUNNING=1
  fi

  # Check if agent plist exists
  AGENT_EXISTS=0
  if [ -f "$AGENT_PLIST" ]; then
    AGENT_EXISTS=1
  fi

  # Check if agent is loaded
  AGENT_LOADED=0
  if /bin/launchctl list | grep -q "com.github.colima.nix"; then
    AGENT_LOADED=1
  fi

  echo "State: Colima=$COLIMA_RUNNING Agent_exists=$AGENT_EXISTS Agent_loaded=$AGENT_LOADED"
  
  # Return state for external use
  echo "$COLIMA_RUNNING:$AGENT_EXISTS:$AGENT_LOADED"
}

start_colima() {
  echo "Starting Colima..."
  colima --verbose -p $PROFILE start --save-config=false
  wait_for_colima start
}

stop_colima() {
  echo "Stopping Colima..."
  docker context use default || true
  colima stop -p $PROFILE
  wait_for_colima stop
}

wait_for_colima() {
  local action=$1
  local timeout=30
  
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
  rm -rf "$LOCK_FILE"
}

run_daemon() {
  # Try to acquire lock
  if ! mkdir "$LOCK_FILE" 2>/dev/null; then
    echo "Another instance is running for profile $PROFILE"
    exit 1
  fi

  trap cleanup EXIT
  trap 'stop_colima; exit 0' SIGTERM SIGINT SIGQUIT

  STATE=$(check_state)
  COLIMA_RUNNING=$(echo "$STATE" | cut -d: -f1)

  if [ "$COLIMA_RUNNING" = "1" ]; then
    echo "Colima already running for profile $PROFILE"
  else
    start_colima
  fi

  while true; do
    sleep 1
  done
}

show_help() {
  echo "Usage: $0 [profile] <command>"
  echo "Commands:"
  echo "  daemon    - run as agent daemon"
  echo "  start     - start colima"
  echo "  stop      - stop colima"
  echo "  status    - check status"
  echo "  clean     - stop colima and clean state"
  echo "  help      - show this help"
}

clean_state() {
  stop_colima
  colima --verbose -p docker delete -f
  rm -f "$LOCK_FILE"
}

case "$MODE" in
  "daemon")
    run_daemon
    ;;
  "start")
    start_colima
    ;;
  "stop")
    stop_colima
    ;;
  "status")
    check_state
    ;;
  "clean")
    clean_state
    ;;
  "help"|*)
    show_help
    ;;
esac 