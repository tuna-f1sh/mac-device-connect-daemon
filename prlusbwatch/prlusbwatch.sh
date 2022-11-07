#!/bin/bash
set -euo pipefail
ubin=/usr/local/bin

if [[ $# -ne 3 ]]; then
  echo "Not enough args: HOST VID PID"
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

host=$1
vid=$2
pid=$3
echo "Running prlurbwatch for host $host on VID/PID $vid/$pid"
# get UUID of host if not a UUID
if [[ "$host" =~ ^[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}$ ]]; then
  uuid="\"$host\""
else
  uuid=$($ubin/prlctl list -ja | $ubin/jq '.[] | select(.name == '"\"$host\""') | .uuid')
  echo "Host UUID $uuid"
fi

if [[ -z $uuid ]]; then
  echo "Failed to get UUID of host or not running"
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
# make array of devices matching VID/PID not already assigned to auto-connect and not autoconnect to host (prevents background triggers when manual override), will capture Parallels UUID
devices=($($ubin/prlsrvctl usb list -j | $ubin/jq '.[] | select((."System name" | contains('"$vidpid"')) and (."Autoconnect-Vm-Uuid" != '"$uuid"') and (."Autoconnect-Action" != "host")) | ."System name"'))

if (( "${#devices[@]}" != 0 )); then
  for i in "${devices[@]}"; do
    eval $ubin/prlsrvctl usb set "$i" "$uuid"
  done
fi
