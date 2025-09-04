#!/usr/bin/env bash
# SwiftBar / xbar plugin: Caffeinate Toggle (stateful)
# Keeps your Mac awake for SSH while letting the display sleep.
# - Tracks its own caffeinate PID (no collateral pkill)
# - Supports timed sessions with live countdown
# - Warns if running on battery
# - Uses SF Symbols for crisp icons in the menu bar

set -euo pipefail
IFS=$'\n\t'

CAFFEINATE="/usr/bin/caffeinate"
PGREP="/usr/bin/pgrep"
PMSET="/usr/bin/pmset"
NOHUP="/usr/bin/nohup"
DATE="/bin/date"
PS="/bin/ps"
GREP="/usr/bin/grep"
CUT="/usr/bin/cut"
AWK="/usr/bin/awk"
SED="/usr/bin/sed"
BASENAME="/usr/bin/basename"
MKDIR="/bin/mkdir"
RM="/bin/rm"
CAT="/bin/cat"
TR="/usr/bin/tr"

# Colors for SF Symbols
COLOR_AWAKE="#34C759"     # green
COLOR_SLEEP="#9AA0A6"     # gray
COLOR_EXTERNAL="#0A84FF"  # blue
COLOR_BATTERY="#FF9500"   # orange

# Persistent state
STATE_DIR="${HOME}/Library/Application Support/SwiftBar/Caffeinate"
STATE_FILE="${STATE_DIR}/state.env"

ensure_state_dir() { $MKDIR -p "$STATE_DIR"; }

write_state() {
  ensure_state_dir
  {
    echo "PID=${1}"
    echo "MODE=${2}"         # "indefinite" | "timed"
    if [[ "${3:-}" != "" ]]; then
      echo "UNTIL=${3}"      # epoch seconds
    fi
  } > "$STATE_FILE"
}

read_state() {
  [[ -f "$STATE_FILE" ]] || return 1
  # shellcheck disable=SC1090
  source "$STATE_FILE"
}

clear_state() { [[ -f "$STATE_FILE" ]] && $RM -f "$STATE_FILE" || true; }

is_pid_running() {
  local pid="$1"
  [[ -n "$pid" ]] || return 1
  if kill -0 "$pid" 2>/dev/null; then return 0; else return 1; fi
}

start_indefinite() {
  $NOHUP "$CAFFEINATE" -imsu >/dev/null 2>&1 &
  local pid=$!
  write_state "$pid" "indefinite"
}

start_timed() {
  local seconds="$1"
  local until=$(( $($DATE +%s) + seconds ))
  $NOHUP "$CAFFEINATE" -imsu -t "$seconds" >/dev/null 2>&1 &
  local pid=$!
  write_state "$pid" "timed" "$until"
}

stop_if_ours() {
  if read_state 2>/dev/null; then
    if is_pid_running "${PID:-}"; then
      kill "${PID}"
      sleep 0.1
    fi
  fi
  clear_state
}

remaining_human() {
  local now=$($DATE +%s)
  local until="$1"
  if (( until <= now )); then echo "0m"; return; fi
  local rem=$(( until - now ))
  local h=$(( rem / 3600 ))
  local m=$(( (rem % 3600) / 60 ))
  if (( h > 0 )); then
    printf "%dh%02dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

on_battery() {
  # pmset -g batt | head -1 -> "Now drawing from 'AC Power'" or "Battery Power"
  local line
  line="$($PMSET -g batt | head -1 | $TR -d '\r')"
  echo "$line" | $GREP -qi "battery power"
}

# Handle actions from menu
if [[ "${1:-}" == "--action" ]]; then
  case "${2:-}" in
    toggle)
      if read_state 2>/dev/null && is_pid_running "${PID:-}"; then
        stop_if_ours
      else
        start_indefinite
      fi
      exit 0
      ;;
    start1h)            stop_if_ours; start_timed 3600; exit 0 ;;
    start4h)            stop_if_ours; start_timed 14400; exit 0 ;;
    start8h)            stop_if_ours; start_timed 28800; exit 0 ;;
    stop)               stop_if_ours; exit 0 ;;
    displayoff)         /usr/bin/pmset displaysleepnow; exit 0 ;;
    stop_and_off)       stop_if_ours; /usr/bin/pmset displaysleepnow; exit 0 ;;
    restart_indefinite) stop_if_ours; start_indefinite; exit 0 ;;
  esac
fi

# ===== Determine state for UI =====
running=false
countdown=""
subtitle="Enable Keep Awake - Indefinite"
sficon="moon.fill"
color="$COLOR_SLEEP"

if read_state 2>/dev/null && is_pid_running "${PID:-}"; then
  running=true
  sficon="bolt.fill"
  color="$COLOR_AWAKE"
  if [[ "${MODE:-}" == "timed" && -n "${UNTIL:-}" ]]; then
    countdown=" $(remaining_human "$UNTIL")"
  fi
  subtitle="Disable Keep Awake"
else
  # If our state file is missing but a manual caffeinate is running, detect it
  if $PGREP -x caffeinate >/dev/null 2>&1; then
    sficon="bolt.fill"
    color="$COLOR_EXTERNAL"
    subtitle="Managed outside plugin"
  fi
fi

# Battery override (only if our session is running)
if $running && on_battery; then
  color="$COLOR_BATTERY"
fi

# ===== Menu bar (SF Symbol icon + optional countdown text) =====
# Use an empty title with only sficon, and append countdown if present.
if [[ -n "$countdown" ]]; then
  echo " $countdown | sfimage=$sficon color=$color"
else
  echo " | sfimage=$sficon color=$color"
fi

echo "---"

# ===== Dropdown =====
if $running; then
  echo "Toggle ($subtitle) | bash='$0' param1=--action param2=toggle terminal=false refresh=true"
  echo "Stop Keep Awake | bash='$0' param1=--action param2=stop terminal=false refresh=true"
  echo "Stop & Turn Display Off Now | bash='$0' param1=--action param2=stop_and_off terminal=false refresh=true"
  echo "---"
  echo "Restart Indefinite | bash='$0' param1=--action param2=restart_indefinite terminal=false refresh=true"
  echo "Timed Sessions"
  echo "• 1 hour | bash='$0' param1=--action param2=start1h terminal=false refresh=true"
  echo "• 4 hours | bash='$0' param1=--action param2=start4h terminal=false refresh=true"
  echo "• 8 hours | bash='$0' param1=--action param2=start8h terminal=false refresh=true"
else
  echo "Toggle ($subtitle) | bash='$0' param1=--action param2=toggle terminal=false refresh=true"
  echo "---"
  echo "Timed Sessions"
  echo "• 1 hour | bash='$0' param1=--action param2=start1h terminal=false refresh=true"
  echo "• 4 hours | bash='$0' param1=--action param2=start4h terminal=false refresh=true"
  echo "• 8 hours | bash='$0' param1=--action param2=start8h terminal=false refresh=true"
fi

echo "---"
echo "Turn Display Off Now | bash='$0' param1=--action param2=displayoff terminal=false refresh=true"

if $running && on_battery; then
  echo "---"
  echo "⚠️ Running on battery — consider plugging in."
fi