#!/bin/bash
# Make a LaunchAgent .plist for use with utmusbwatch.sh
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
  uuid=$(utmctl list | grep 'ArchLinux' | awk '{print $1}')
  if [[ -z $uuid ]]; then
    echo "Failed to get guest UUID"
    exit 1
  else
    echo "guest UUID $uuid"
  fi
else
  uuid=$guest
fi

# requires GNU sed!
cp utmusbwatch/com.utmusbwatch.template utmusbwatch/com.utmusbwatch."$device".plist
sed -i "s/\$VID_DEC/$vid_dec/g" utmusbwatch/com.utmusbwatch."$device".plist
sed -i "s/\$PID_DEC/$pid_dec/g" utmusbwatch/com.utmusbwatch."$device".plist
sed -i "s/\$VID_HEX/$vid_hex/g" utmusbwatch/com.utmusbwatch."$device".plist
sed -i "s/\$PID_HEX/$pid_hex/g" utmusbwatch/com.utmusbwatch."$device".plist
sed -i "s/\$GUEST/$uuid/g" utmusbwatch/com.utmusbwatch."$device".plist
sed -i "s/\$DEV/$device/g" utmusbwatch/com.utmusbwatch."$device".plist
echo "Made utmusbwatch/com.utmusbwatch.$device.plist to auto-connect VID/PID 0x$vid_hex/0x$pid_hex ($device) to $guest"
