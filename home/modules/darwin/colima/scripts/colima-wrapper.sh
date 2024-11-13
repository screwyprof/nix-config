#!/bin/sh
set -euo pipefail  # Strict mode
[ "${TRACE:-0}" = "1" ] && set -x  # Debug mode when TRACE=1

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly LOCK_FILE="/tmp/colima-${1:-unknown}.lock"
readonly AGENT_PLIST="${HOME}/Library/LaunchAgents/com.github.colima.nix.plist"

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

log_debug() {
    echo "DEBUG: $*" >&2
}

log_info() {
    echo "INFO: $*" >&2
}

log_error() {
    echo "ERROR: $*" >&2
}

check_state() {
    # Check if colima is running
    local colima_running=0
    if colima status -p "${PROFILE}" >/dev/null 2>&1; then
        colima_running=1
    fi

    # Check if agent plist exists
    local agent_exists=0
    if [ -f "${AGENT_PLIST}" ]; then
        agent_exists=1
    fi

    # Check if agent is loaded
    local agent_loaded=0
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
    local action=$1
    local timeout=30
    local i

    for i in $(seq 1 "${timeout}"); do
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
        log_debug "Waiting for Colima to ${action}... (${i}/${timeout})"
        sleep 1
    done
    log_error "Timeout waiting for Colima to ${action}"
    return 1
}

clean_state() {
    log_info "Cleaning Colima state..."
    stop_colima || true
    colima delete -p "${PROFILE}" -f || true
    rm -rf "${HOME}/.colima/*"
    rm -f "${LOCK_FILE}"
    log_info "Cleanup complete"
}

run_daemon() {
    # Try to acquire lock
    if ! mkdir "${LOCK_FILE}" 2>/dev/null; then
        log_error "Another instance is running for profile ${PROFILE}"
        exit 1
    fi

    trap 'rm -rf "${LOCK_FILE}"' EXIT
    trap 'stop_colima; exit 0' SIGTERM SIGINT SIGQUIT

    local state
    state=$(check_state)
    local colima_running
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

readonly PROFILE=$1
readonly MODE=$2

log_debug "SCRIPT_NAME='${SCRIPT_NAME}' PROFILE='${PROFILE}' MODE='${MODE}'"
log_debug "LOCK='${LOCK_FILE}' AGENT_PLIST='${AGENT_PLIST}'"

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
        log_error "Unknown mode: '${MODE}'"
        show_help
        exit 1
        ;;
esac 