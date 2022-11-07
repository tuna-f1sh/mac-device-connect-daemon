PLIST_PATH=./prlusbwatch
INSTALL_AGENTS_PATH=~/Library/LaunchAgents
PLIST_FILES=$(wildcard ${PLIST_PATH}/*.plist)
PLIST_INSTALLS = $(addprefix $(INSTALL_AGENTS_PATH)/,$(notdir $(PLIST_FILES)))
PLIST_LOADS = $(addprefix load-,$(notdir $(PLIST_FILES)))
PLIST_UNLOADS = $(addprefix unload-,$(notdir $(PLIST_FILES)))

xpc_set_event_stream_handler: xpc_set_event_stream_handler.m
	gcc -framework Foundation -o xpc_set_event_stream_handler xpc_set_event_stream_handler.m

${INSTALL_AGENTS_PATH}/com.prlusbwatch.%.plist: ${PLIST_PATH}/com.prlusbwatch.%.plist
	cp -v $< $@

install: xpc_set_event_stream_handler $(PLIST_INSTALLS)
	cp -v xpc_set_event_stream_handler /usr/local/bin
	cp -v prlusbwatch/prlusbwatch.sh /usr/local/bin

uninstall:
	rm -v /usr/local/bin/xpc_set_event_stream_handler
	rm -v /usr/local/bin/prlusbwatch.sh
	rm -v ${PLIST_INSTALLS}

load-%: ${PLIST_INSTALLS}
	launchctl load $<

load: $(PLIST_LOADS)

unload-%: ${PLIST_INSTALLS}
	launchctl unload $<

unload: $(PLIST_UNLOADS)

reload:
	make unload
	make load
