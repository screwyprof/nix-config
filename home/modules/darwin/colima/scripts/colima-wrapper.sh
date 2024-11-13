#!/bin/bash
set -euo pipefail

# Constants - initialize after arguments are checked
SCRIPT_NAME=""
LOCK_FILE=""
AGENT_PLIST=""
PROFILE=""
MODE=""

init_constants() {
    SCRIPT_NAME="$(basename "$0")"
    LOCK_FILE="/tmp/colima-${PROFILE:-unknown}.lock"
    AGENT_PLIST="${HOME}/Library/LaunchAgents/com.github.colima.nix.plist"
}

# Functions
show_help() {
    cat <<EOF
Usage: ${SCRIPT_NAME} <profile> <command>

Commands:
  daemon    - run as agent daemon
  start     - start colima
  stop      - stop colima
  status    - check status
  clean     - stop colima and clean state
  help      - show this help
EOF
}

log_info() {
    echo "INFO: $*" >&2
}

log_error() {
    echo "ERROR: $*" >&2
}

check_state() {
    # Check if colima is running
    colima_running=0
    if colima status -p "${PROFILE}" >/dev/null 2>&1; then
        colima_running=1
    fi

    # Check if agent plist exists
    agent_exists=0
    if [ -f "${AGENT_PLIST}" ]; then
        agent_exists=1
    fi

    # Check if agent is loaded
    agent_loaded=0
    if /bin/launchctl list | grep -q "com.github.colima.nix"; then
        agent_loaded=1
    fi

    echo "State: Colima=${colima_running} Agent_exists=${agent_exists} Agent_loaded=${agent_loaded}"
    echo "${colima_running}:${agent_exists}:${agent_loaded}"
}

start_colima() {
    log_info "Starting Colima..."
    colima --verbose -p "${PROFILE}" start --save-config=false
    wait_for_colima start
}

stop_colima() {
    log_info "Stopping Colima..."
    docker context use default || true
    colima stop -p "${PROFILE}"
    wait_for_colima stop
}

wait_for_colima() {
    action="$1"
    timeout=30

    for ((i=1; i<=timeout; i++)); do
        case "${action}" in
            "start")
                if colima status -p "${PROFILE}" >/dev/null 2>&1; then
                    log_info "Colima started"
                    return 0
                fi
                ;;
            "stop")
                if ! colima status -p "${PROFILE}" >/dev/null 2>&1; then
                    log_info "Colima stopped"
                    return 0
                fi
                ;;
        esac
        sleep 1
    done
    log_error "Timeout waiting for Colima to ${action}"
    return 1
}

clean_state() {
    log_info "Cleaning Colima state..."
    stop_colima || true
    colima delete -p "${PROFILE}" -f || true
    rm -f "${LOCK_FILE}" || true
    log_info "Cleanup complete"
}

run_daemon() {
    # Use proper file locking
    exec 9>"${LOCK_FILE}"
    if ! flock -n 9; then
        log_error "Another instance is running for profile ${PROFILE}"
        exit 1
    fi

    trap 'flock -u 9' EXIT
    trap 'stop_colima; exit 0' TERM INT QUIT

    state=$(check_state)
    colima_running=$(echo "${state}" | tail -n1 | cut -d: -f1)

    if [ "${colima_running}" = "1" ]; then
        log_info "Colima already running for profile ${PROFILE}"
    else
        start_colima
    fi

    # Keep running to handle signals
    while true; do
        sleep 1
    done
}

# Argument checking
if [ $# -lt 2 ]; then
    log_error "Not enough arguments"
    show_help
    exit 1
fi

PROFILE="$1"
MODE="$2"

# Initialize constants after arguments are set
init_constants

# Main
case "${MODE}" in
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
    *)
        log_error "Unknown mode: ${MODE}"
        show_help
        exit 1
        ;;
esac 