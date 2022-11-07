#!/bin/bash
# Make a LaunchAgent .plist for use with prlusbwatch.sh
#
# Args:
#   device: string - Name of device for file naming
#   guest: string - Name or UUID of guest to connect USB devices to
#   VID: string - base 16 (0x....) or base 10 (.....) vendor ID
#   PID: string - base 16 (0x....) or base 10 (.....) product ID
#
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Not enough args: DEVICE GUEST VID PID"
  exit 1
fi

device=$1
guest=$2
vid=$3
pid=$4

if [[ "$vid" =~ ^0x[0-9a-zA-Z]{4}$ ]]; then
  vid_hex=$vid
  vid_dec=$((16#${vid//0x/}))
else
  vid_dec=$vid
  vid_hex=$(printf '0x%04x' "$vid")
fi

if [[ "$pid" =~ ^0x[0-9a-zA-Z]{4}$ ]]; then
  pid_hex=$pid
  pid_dec=$((16#${pid//0x/}))
else
  pid_dec=$pid
  pid_hex=$(printf '0x%04x' "$pid")
fi

# get UUID of guest if not a UUID now rather than every call to script
if ! [[ "$guest" =~ ^[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}$ ]]; then
  uuid=$(prlctl list -ja | jq '.[] | select(.name == '\""$guest"\"') | .uuid')
  uuid=$(echo $uuid | sed 's/\"//g')
  if [[ -z $guest ]]; then
    echo "Failed to get guest UUID"
    exit 1
  else
    echo "guest UUID $uuid"
  fi
else
  uuid=$guest
fi

cp prlusbwatch/com.prlusbwatch.template prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$VID_DEC/$vid_dec/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$PID_DEC/$pid_dec/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$VID_HEX/$vid_hex/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$PID_HEX/$pid_hex/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$GUEST/$uuid/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$DEV/$device/g" prlusbwatch/com.prlusbwatch."$device".plist
echo "Made prlusbwatch/com.prlusbwatch.$device.plist to auto-connect VID/PID 0x$vid_hex/0x$pid_hex ($device) to $guest"
