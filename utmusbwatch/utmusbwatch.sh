#!/bin/bash
# Script to connect supplied USB devices to a UTM guest. Designed to act like a VirtualBox USB device filter
#
# Args:
#   guest: string - Name or UUID of guest to connect USB devices to
#   VID: string - base 16 (0x....) or base 10 (.....) vendor ID
#   PID: string - base 16 (0x....) or base 10 (.....) product ID
#
# jbrengineering.co.uk - J.Whittington 2022
set -euo pipefail
ubin=/opt/homebrew/bin

if [[ $# -ne 3 ]]; then
  echo "Not enough args: guest VID PID"
  exit 1
elif ! command -v $ubin/utmctl &> /dev/null; then
  echo "utmctl could not be found"
  exit 1
fi

guest=$1
vid=$2
pid=$3
echo "Running utmusbwatch for guest $guest on VID/PID $vid/$pid"
# get UUID of guest if not a UUID
if [[ "$guest" =~ ^[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}$ ]]; then
  uuid="\"$guest\""
else
  uuid=$($ubin/utmctl list | grep 'ArchLinux' | awk '{print $1}')
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

# make string match for utmctl vid:pid in UUID
vidpid="\"$vid:$pid\""
eval $ubin/utmctl usb connect $uuid $vidpid
