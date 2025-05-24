#!/usr/bin/env bash

readonly _LOG_FILE_PATH="${LOG_FILE_PATH:-./logs/stdout.log}"

set +C
exec 1> >(tee -a "$_LOG_FILE_PATH") 2>&1
set -C

function log() {
    local level=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    shift
    local message="$*"

    local green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m' reset=$'\e[0m'
    local color_code=""

    case "${level}" in
        INFO)  color_code=$green  ;;
        WARN)  color_code=$yellow ;;
        ERROR) color_code=$red    ;;
        *)     message="[INVALID_LEVEL:${level}] ${message}"
               level=INFO color_code="${green}" ;;
    esac

    local ts="$(date '+%Y-%m-%d %H:%M:%S %Z')"

    # NOTE: Use %b to interpret escape sequences
    if [[ "${level}" == ERROR ]]; then
        printf '%s %b[%s]%b %s\n' "${ts}" "${color_code}" "${level}" "${reset}" "${message}" >&2
    else
        printf '%s %b[%s]%b %s\n' "${ts}" "${color_code}" "${level}" "${reset}" "${message}"
    fi
}

printf '%s\n\n' "$(bash --version | head -n1)"
