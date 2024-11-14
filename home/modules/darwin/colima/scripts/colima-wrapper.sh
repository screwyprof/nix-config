#!/usr/bin/env bash

# Strict mode
set -euo pipefail
set -E  # inherit ERR trap by shell functions

# Constants - General
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly PROFILE="${1:-unknown}"
readonly CMD="${2:-help}"
readonly LOCK_FILE="/tmp/colima-${PROFILE}.lock"
readonly LOG_PREFIX="colima-wrapper[$$]"

# Constants - Return codes
declare -i RC_OK=0
declare -i RC_ERROR=1

# Constants - Timeouts (in seconds)
readonly TIMEOUT_STATUS=3      # How long to wait for status check
readonly TIMEOUT_STATE=5       # How long to wait for state changes
readonly TIMEOUT_HEALTH=30     # How long to wait between health checks

# Logging with return codes
log() {
    echo "${LOG_PREFIX} $1: $2" >&2
    return ${RC_OK}
}

info() { log "INFO" "$*"; }
error() { log "ERROR" "$*"; }
debug() { [[ -n "${VERBOSE_FLAG:-}" ]] && log "DEBUG" "$*"; }

# Error handling
trap 'error "Failed at line $LINENO. Exit code: $?"' ERR
trap 'cleanup' EXIT

# Helper functions
cleanup() {
    flock -u 9 2>/dev/null || true
    rm -f "${LOCK_FILE}" || true
}

# Status checking with proper error handling
check_colima_status() {
    debug "Checking Colima status" || true
    timeout ${TIMEOUT_STATUS} colima "${VERBOSE_FLAG:-}" -p "${PROFILE}" status >/dev/null 2>&1
}

is_colima_running() {
    if check_colima_status; then
        debug "Colima is running" || true
        return ${RC_OK}
    else
        debug "Colima is not running" || true
        return ${RC_ERROR}
    fi
}

wait_for_state() {
    local desired_state="$1"
    local -i timeout="${TIMEOUT_STATE}"
    local check_cmd="is_colima_running"
    [[ "${desired_state}" == "stopped" ]] && check_cmd="! is_colima_running"

    info "Waiting for Colima to be ${desired_state}..."
    for ((i=1; i<=timeout; i++)); do
        if eval "${check_cmd}"; then
            info "Colima is ${desired_state}"
            return ${RC_OK}
        fi
        sleep 1
    done
    error "Timeout waiting for Colima to be ${desired_state}"
    return ${RC_ERROR}
}

acquire_lock() {
    exec 9>"${LOCK_FILE}"
    if ! flock -n 9; then
        error "Another instance is running for profile ${PROFILE}"
        return 1
    fi
}

# Core functions
start_colima() {
    info "Starting Colima..."
    colima "${VERBOSE_FLAG:-}" -p "${PROFILE}" start --save-config=false
    wait_for_state "running"
}

stop_colima() {
    info "Stopping Colima..."
    docker context use default >/dev/null 2>&1 || true
    colima "${VERBOSE_FLAG:-}" -p "${PROFILE}" stop >/dev/null 2>&1 || true
    wait_for_state "stopped"
    colima "${VERBOSE_FLAG:-}" -p "${PROFILE}" stop -f >/dev/null 2>&1 || true
}

clean_state() {
    info "Cleaning up Colima state..."
    stop_colima || true
    colima "${VERBOSE_FLAG:-}" -p "${PROFILE}" delete -f 2>/dev/null || true
}

run_daemon() {
    info "Starting daemon mode" || true
    acquire_lock || exit ${RC_ERROR}

    # Handle signals
    trap 'info "Received stop signal" || true; stop_colima; exit ${RC_OK}' TERM INT QUIT

    # Initial state check and startup
    if is_colima_running; then
        info "Colima already running" || true
    else
        info "Starting Colima" || true
        start_colima || exit ${RC_ERROR}
    fi

    # Main monitoring loop
    info "Entering monitoring loop" || true
    while true; do
        if is_colima_running; then
            debug "Health check passed" || true
        else
            error "Colima stopped unexpectedly, restarting..." || true
            start_colima || {
                error "Failed to restart Colima" || true
                exit ${RC_ERROR}
            }
        fi
        sleep ${TIMEOUT_HEALTH}
    done
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

Environment:
  VERBOSE_FLAG  - set by home-manager for verbose output
EOF
}

main() {
    if [[ $# -lt 2 ]]; then
        error "Not enough arguments"
        show_help
        exit 1
    fi

    case "${CMD}" in
        "daemon") run_daemon ;;
        "start") start_colima ;;
        "stop") stop_colima ;;
        "status") is_colima_running ;;
        "clean") clean_state ;;
        "help") show_help ;;
        *)
            error "Unknown command: ${CMD}"
            show_help
            exit 1
            ;;
    esac
}

main "$@" 