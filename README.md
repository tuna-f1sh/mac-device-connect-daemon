Fork of [mac-device-connect-daemon](https://github.com/himbeles/mac-device-connect-daemon) that adds a Makefile and script for generating Parallels VID/PID USB device auto-watchers.

Parallels does not seem to feature USB device filtering based on VID/PID like VirtualBox - only on full device specifier including serial etc. This means one cannot filter and attach all instances of a particular device to a guest OS, each device must be manually added. For embedded development using lots of USB serial, programmers etc this can become quite frustrating!

I found it annoying enough to make this script. A LaunchAgent calls './prlusbwatch/prlusbwatch.sh' when a VID and PID defined in the LaunchAgent .plist file is attached. The script uses `prlsrvctrl` and `prlctl` to obtain the UUID of the passed guest (also in .plist) and check whether any connected USB devices with the that VID/PID are not configured to autoconnect to that VM. If found, they are set to autoconnect to the guest. Devices found to be set to autoconnect to the host are ignored to allow manual override.

# Usage

1. Make a .plist for a device one wishes to filter on VID/PID and attach to a guest. Here 'jlink' will be the device name use for the file naming and log file; 'Arch' is the guest name or can be UUID; followed by VID PID:

`./prlusbwatch/makeplist.sh jlink Arch 0x1366 0x1050`

2. Set execute permissions for scripts:
```
chmod +x ./prlusbwatch/prlusbwatch.sh
chmod +x ./prlusbwatch/makeplist.sh
```
3. Install: `make install`
4. Load: `make load`

One may get a notification of the xpc_set_event_stream_handler being added as a LaunchAgent.

Log files can be viewed at '/usr/local/var/log/prlusbwatch.jlink.log' in this example.

To uninstall: `make uninstall`

# Load/Unload

Once installed, to load/unload a specific device (such as 'jlink' in the example): `make load-jlink`/`make unload-jlink`

# Manual

The script './prlusbwatch/prlusbwatch.sh' can be used to manually set all devices with VID/PID listed by Parallels:

`./prlusbwatch/prlusbwatch.sh Arch 0x0fcf 0x1009`
