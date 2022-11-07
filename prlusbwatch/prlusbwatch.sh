#!/bin/bash
# Script to set all currently attached USB devices with a supplied VID and PID to autoconnect to a Parallels guest. Designed to act like a VirtualBox USB device filter
#
# Args:
#   guest: string - Name or UUID of guest to connect USB devices to
#   VID: string - base 16 (0x....) or base 10 (.....) vendor ID
#   PID: string - base 16 (0x....) or base 10 (.....) product ID
#
# jbrengineering.co.uk - J.Whittington 2022
set -euo pipefail
ubin=/usr/local/bin

if [[ $# -ne 3 ]]; then
  echo "Not enough args: guest VID PID"
  exit 1
elif ! command -v $ubin/prlsrvctl &> /dev/null; then
  echo "prlsrvctl could not be found"
  exit 1
elif ! command -v $ubin/prlctl &> /dev/null; then
  echo "prlctl could not be found"
  exit 1
elif ! command -v $ubin/jq &> /dev/null; then
  echo "jq could not be found"
  exit 1
fi

guest=$1
vid=$2
pid=$3
echo "Running prlurbwatch for guest $guest on VID/PID $vid/$pid"
# get UUID of guest if not a UUID
if [[ "$guest" =~ ^[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}$ ]]; then
  uuid="\"$guest\""
else
  uuid=$($ubin/prlctl list -ja | $ubin/jq '.[] | select(.name == '"\"$guest\""') | .uuid')
  echo "guest UUID $uuid"
fi

if [[ -z $uuid ]]; then
  echo "Failed to get UUID of guest or not running"
  exit 0
fi

# convert to hex or strip leading head indicator as not used by parallels
if [[ "$vid" =~ ^0x[0-9a-zA-Z]{4}$ ]]; then
  vid=${vid/0x/}
else
  vid=$(printf '%04x' "$vid")
  echo "Converted VID to hex 0x$vid"
fi

# convert to hex or strip leading head indicator as not used by parallels
if [[ "$pid" =~ ^0x[0-9a-zA-Z]{4}$ ]]; then
  pid=${pid/0x/}
else
  pid=$(printf '%04x' "$pid")
  echo "Converted PID to hex 0x$pid"
fi

# make string match for prlsrvctl vid|pid in UUID
vidpid="\"$vid|$pid\""
IFS=$'\n'
# make array of devices matching VID/PID not already assigned to auto-connect and not autoconnect to guest (prevents background triggers when manual override), will capture Parallels UUID
devices=($($ubin/prlsrvctl usb list -j | $ubin/jq '.[] | select((."System name" | contains('"$vidpid"')) and (."Autoconnect-Vm-Uuid" != '"$uuid"') and (."Autoconnect-Action" != "guest")) | ."System name"'))

if (( "${#devices[@]}" != 0 )); then
  for i in "${devices[@]}"; do
    eval $ubin/prlsrvctl usb set "$i" "$uuid"
  done
fi
