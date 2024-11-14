#!/bin/bash
set -euo pipefail

# Debug info
echo "Debug: VERBOSE=${VERBOSE:-}" >&2

# Constants and defaults
readonly DEFAULT_TIMEOUT=30
readonly VERBOSE_FLAG="${VERBOSE:+--verbose}"
readonly PROFILE="${1:-unknown}"
readonly CMD="${2:-help}"

# Create aliases for commands with verbose flag
alias docker="docker $VERBOSE_FLAG"
alias colima="colima $VERBOSE_FLAG -p ${PROFILE}"

# Logging functions
log() {
    local level="$1"
    shift
    echo "${level}: $*" >&2
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }

# Helper functions
is_colima_running() {
    if [[ -n "${VERBOSE_FLAG}" ]]; then
        colima status
    else
        colima status >/dev/null 2>&1
    fi
}

init_constants() {
    SCRIPT_NAME="$(basename "$0")"
    LOCK_FILE="/tmp/colima-${PROFILE:-unknown}.lock"
    [[ -n "${VERBOSE_FLAG}" ]] && log_info "Initialized constants: SCRIPT_NAME=${SCRIPT_NAME}, LOCK_FILE=${LOCK_FILE}"
}

acquire_lock() {
    exec 9>"${LOCK_FILE}"
    if ! flock -n 9; then
        log_error "Another instance is running for profile ${PROFILE}"
        exit 1
    fi
    trap 'release_lock' EXIT
}

release_lock() {
    flock -u 9 2>/dev/null || true
    rm -f$VERBOSE_FLAG "${LOCK_FILE}" || true
}

show_help() {
    cat <<EOF
Usage: ${SCRIPT_NAME} <profile> <command>

Commands:
  daemon    - run as daemon
  start     - start colima
  stop      - stop colima
  status    - check status
  clean     - clean state
  help      - show this help
EOF
}

check_status() {
    local -i colima_running=0
    is_colima_running && colima_running=1
    log_info "State: Colima=${colima_running}"
}

wait_for_colima() {
    local action="$1"
    local -i timeout="${DEFAULT_TIMEOUT}"

    log_info "Waiting for Colima to ${action}..."
    for ((i=1; i<=timeout; i++)); do
        case "${action}" in
            "start")
                is_colima_running && { log_info "Colima started"; return 0; }
                ;;
            "stop")
                ! is_colima_running && { log_info "Colima stopped"; return 0; }
                ;;
        esac
        sleep 1
    done
    log_error "Timeout waiting for Colima to ${action}"
    return 1
}

start_colima() {
    log_info "Starting Colima..."
    colima start --save-config=false
    wait_for_colima start
}

stop_colima() {
    log_info "Stopping Colima..."
    docker context use default >/dev/null 2>&1 || true
    colima stop
    wait_for_colima stop
}

clean_state() {
    log_info "Cleaning Colima state..."
    stop_colima || true
    colima delete -f || true
    log_info "Cleanup complete"
}

run_daemon() {
    acquire_lock
    trap 'stop_colima; exit 0' TERM INT QUIT

    if is_colima_running; then
        log_info "Colima already running for profile ${PROFILE}"
    else
        start_colima
    fi

    while true; do sleep 1; done
}

main() {
    if [[ $# -lt 2 ]]; then
        log_error "Not enough arguments"
        show_help
        exit 1
    fi

    init_constants

    case "${CMD}" in
        "daemon") run_daemon ;;
        "start") start_colima ;;
        "stop") stop_colima ;;
        "status") check_status ;;
        "clean") clean_state ;;
        "help") show_help ;;
        *)
            log_error "Unknown command: ${CMD}"
            show_help
            exit 1
            ;;
    esac 
}

main "$@" 