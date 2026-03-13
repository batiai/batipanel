#!/usr/bin/env bash
# batipanel logger - structured logging with levels and rotation

BATIPANEL_LOG_DIR="${BATIPANEL_HOME}/logs"
BATIPANEL_LOG_FILE="${BATIPANEL_LOG_DIR}/batipanel.log"
BATIPANEL_LOG_LEVEL="${BATIPANEL_LOG_LEVEL:-info}"
BATIPANEL_LOG_RETENTION_DAYS="${BATIPANEL_LOG_RETENTION_DAYS:-30}"

# log level numeric values (lower = more verbose)
_log_level_num() {
  case "$1" in
    debug) echo 0 ;;
    info)  echo 1 ;;
    warn)  echo 2 ;;
    error) echo 3 ;;
    *)     echo 1 ;;
  esac
}

# core log function
_log() {
  local level="$1"
  shift
  local msg="$*"

  local current_level_num
  current_level_num=$(_log_level_num "$BATIPANEL_LOG_LEVEL")
  local msg_level_num
  msg_level_num=$(_log_level_num "$level")

  # skip if message level is below configured threshold
  (( msg_level_num < current_level_num )) && return 0

  # ensure log directory exists
  mkdir -p "$BATIPANEL_LOG_DIR" 2>/dev/null || return 0

  local timestamp
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')

  local upper_level
  upper_level=$(echo "$level" | tr '[:lower:]' '[:upper:]')

  # write to log file
  printf '%s [%-5s] %s\n' "$timestamp" "$upper_level" "$msg" >> "$BATIPANEL_LOG_FILE" 2>/dev/null || true

  # also output to stderr for debug level when BATIPANEL_DEBUG is set
  if [[ "$level" == "debug" && "${BATIPANEL_DEBUG:-0}" == "1" ]]; then
    echo -e "${YELLOW}[debug]${NC} $msg" >&2
  fi
}

# public logging functions
log_debug() { _log debug "$@"; }
log_info()  { _log info "$@"; }
log_warn()  { _log warn "$@"; }
log_error() { _log error "$@"; }

# rotate logs: remove files older than retention period
log_rotate() {
  [ -d "$BATIPANEL_LOG_DIR" ] || return 0

  # rotate main log if > 5MB
  if [ -f "$BATIPANEL_LOG_FILE" ]; then
    local size
    size=$(stat -f%z "$BATIPANEL_LOG_FILE" 2>/dev/null \
      || stat -c%s "$BATIPANEL_LOG_FILE" 2>/dev/null \
      || echo 0)
    if (( size > 5242880 )); then
      local rotated
      rotated="${BATIPANEL_LOG_FILE}.$(date '+%Y%m%d%H%M%S')"
      mv "$BATIPANEL_LOG_FILE" "$rotated"
      log_info "Log rotated: $(basename "$rotated")"
    fi
  fi

  # remove old rotated logs
  local cutoff_days="${BATIPANEL_LOG_RETENTION_DAYS}"
  find "$BATIPANEL_LOG_DIR" -name "batipanel.log.*" -mtime +"$cutoff_days" -delete 2>/dev/null || true
}

# initialize logging (called once at startup)
_init_logger() {
  mkdir -p "$BATIPANEL_LOG_DIR" 2>/dev/null || return 0
  log_rotate
}

_init_logger
