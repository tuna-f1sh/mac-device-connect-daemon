#!/bin/bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Not enough args: DEVICE HOST VID PID"
  exit 1
fi

device=$1
host=$2
vid=$3
pid=$4

if [[ "$vid" =~ ^0x[0-9a-zA-Z]{4}$ ]]; then
  vid_hex=$vid
  vid_dec=$((16#$vid))
else
  vid_dec=$vid
  vid_hex=$(printf '%04x' "$vid")
fi

if [[ "$pid" =~ ^0x[0-9a-zA-Z]{4}$ ]]; then
  pid_hex=$pid
  pid_dec=$((16#$pid))
else
  pid_dec=$pid
  pid_hex=$(printf '%04x' "$pid")
fi

# get UUID of host if not a UUID now rather than every call to script
if ! [[ "$host" =~ ^[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}$ ]]; then
  uuid=$(prlctl list -ja | jq '.[] | select(.name == '\""$host"\"') | .uuid')
  uuid=$(echo $uuid | sed 's/\"//g')
  if [[ -z $host ]]; then
    echo "Failed to get host UUID"
    exit 1
  else
    echo "Host UUID $host"
  fi
else
  uuid=$host
fi

cp prlusbwatch/com.prlusbwatch.template prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$VID_DEC/$vid_dec/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$PID_DEC/$pid_dec/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$VID_HEX/0x$vid_hex/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$PID_HEX/0x$pid_hex/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$HOST/$uuid/g" prlusbwatch/com.prlusbwatch."$device".plist
sed -i '' "s/\$DEV/$device/g" prlusbwatch/com.prlusbwatch."$device".plist
echo "Made prlusbwatch/com.prlusbwatch.$device.plist to auto-connect VID/PID 0x$vid_hex/0x$pid_hex ($device) to $host"
