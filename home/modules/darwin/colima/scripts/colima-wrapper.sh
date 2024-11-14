#!/bin/bash
set -euo pipefail

# Constants and defaults
readonly DEFAULT_TIMEOUT=30
readonly VALID_MODES=("daemon" "start" "stop" "status" "clean" "help")

# Variables - initialized after argument checking
declare SCRIPT_NAME=""
declare LOCK_FILE=""
declare PROFILE=""
declare MODE=""

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
    colima status -p "${PROFILE}" >/dev/null 2>&1
}

init_constants() {
    SCRIPT_NAME="$(basename "$0")"
    LOCK_FILE="/tmp/colima-${PROFILE:-unknown}.lock"
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
    rm -f "${LOCK_FILE}" || true
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

check_state() {
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
    colima --verbose -p "${PROFILE}" start --save-config=false
    wait_for_colima start
}

stop_colima() {
    log_info "Stopping Colima..."
    docker context use default || true
    colima stop -p "${PROFILE}"
    wait_for_colima stop
}

clean_state() {
    log_info "Cleaning Colima state..."
    stop_colima || true
    colima delete -p "${PROFILE}" -f || true
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

    PROFILE="$1"
    MODE="$2"
    
    init_constants

    case "${MODE}" in
        "daemon") run_daemon ;;
        "start") start_colima ;;
        "stop") stop_colima ;;
        "status") check_state ;;
        "clean") clean_state ;;
        "help") show_help ;;
        *)
            log_error "Unknown mode: ${MODE}"
            show_help
            exit 1
            ;;
    esac 
}

main "$@" 