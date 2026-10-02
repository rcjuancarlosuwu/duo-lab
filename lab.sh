#!/usr/bin/env bash
set -uo pipefail

# Drives the iPhone Duo simulator through one labelled condition and records it.
#
#   lab.sh capture 03-inner-open-portrait
#   lab.sh pose closed|half|open
#   lab.sh orient "Portrait"|"Landscape Left"|"Landscape Right"|"Portrait Upside Down"
#   lab.sh key d|p|s|k|x|1|2|3|4
#
# Poses and orientation have no simctl equivalent in Xcode 27.1 beta, so they go
# through DeviceHub.app's accessibility tree.

export DEVELOPER_DIR=/Applications/Xcode-27.1-beta.app/Contents/Developer
DUO_UDID="${DUO_UDID:-AA16FBB4-F351-4AD9-BBF5-45562B10CFDD}"
WIN="iPhone Duo – iOS 27.1"
ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG="$ROOT/findings/run.log"

posebtn() {
  case "$1" in
    closed) echo 5 ;;
    half)   echo 6 ;;
    open)   echo 7 ;;
    *) echo "unknown pose: $1" >&2; exit 1 ;;
  esac
}

case "${1:?usage: lab.sh capture|pose|orient|key ...}" in

pose)
  idx=$(posebtn "${2:?pose needs closed|half|open}")
  osascript <<EOF
on findbar(el, depth)
  if depth > 6 then return missing value
  tell application "System Events"
    set kids to UI elements of el
    set nb to 0
    repeat with k in kids
      if role of k is "AXButton" then set nb to nb + 1
    end repeat
    if nb is 7 then return el
    repeat with k in kids
      if role of k is not "AXButton" then
        set hit to my findbar(k, depth + 1)
        if hit is not missing value then return hit
      end if
    end repeat
  end tell
  return missing value
end findbar

tell application "System Events"
  set frontmost of process "DeviceHub" to true
  delay 0.8
  set w to window "$WIN" of process "DeviceHub"
  set bar to my findbar(w, 0)
  if bar is missing value then error "pose toolbar not found"
  click button $idx of bar
end tell
EOF
  sleep 2
  echo "pose -> $2"
  ;;

do)
  # Drives the app by dropping a command in its sandbox tmp dir, which the app
  # polls. No GUI focus is taken, unlike DeviceHub's pose and rotation controls.
  #   do tab/2  dialog  datepicker  sheet  keyboard  dismiss
  #   do orient/portrait|landscape|free   do condition/<label>   do log
  container=$(xcrun simctl get_app_container "$DUO_UDID" com.example.duoProbe data)
  printf '%s' "${2:?do needs an action}" > "$container/tmp/duo_probe_command"
  sleep 2
  echo "do -> $2"
  ;;

capture)
  name="${2:?capture needs NN-name}"
  mkdir -p "$ROOT/findings"
  for disp in primary primary-1; do
    label=outer
    [ "$disp" = "primary-1" ] && label=inner
    xcrun simctl io "$DUO_UDID" screenshot --display=$disp \
      "$ROOT/findings/$name-$label.png" >/dev/null 2>&1 \
      && echo "  screenshot $label -> findings/$name-$label.png" \
      || echo "  screenshot $label -> UNAVAILABLE"
  done
  snap=$(grep '\[DUO_PROBE\] snapshot' "$LOG" 2>/dev/null | tail -1 || true)
  if [[ -n "$snap" ]]; then
    echo "${snap#*snapshot }" | python3 -m json.tool > "$ROOT/findings/$name.json"
    echo "  metrics    -> findings/$name.json"
    python3 - "$ROOT/findings/$name.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
s, p = d["size"], d["padding"]
print(f"  size={s['width']}x{s['height']} dpr={d['devicePixelRatio']} "
      f"pad=L{p['left']}/T{p['top']}/R{p['right']}/B{p['bottom']} "
      f"asym={d['paddingAsymmetric']} features={len(d['displayFeatures'])} "
      f"orient={d['orientation']} lifecycle={d['lifecycle']['state']}")
PY
  else
    echo "  metrics    -> NO SNAPSHOT IN LOG"
  fi
  ;;

*)
  echo "unknown command: $1" >&2; exit 1 ;;
esac
