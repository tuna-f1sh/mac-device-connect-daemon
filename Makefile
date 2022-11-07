# base com path in plist files before DEVICE name
PLIST_BASE=com.prlusbwatch.
# path of source plist
PLIST_PATH=./prlusbwatch
# install to LaunchAgents as only need user permissions
INSTALL_AGENTS_PATH=~/Library/LaunchAgents
PLIST_FILES=$(wildcard ${PLIST_PATH}/*.plist)
PLIST_INSTALLS = $(addprefix $(INSTALL_AGENTS_PATH)/,$(notdir $(PLIST_FILES)))
# load of agents to load/unload into target 'load-DEVICE'
PLIST_LOADS = $(addprefix load-,$(patsubst %.plist,%,$(subst $(PLIST_BASE),,$(notdir $(PLIST_FILES)))))
PLIST_UNLOADS = $(addprefix unload-,$(patsubst %.plist,%,$(subst $(PLIST_BASE),,$(notdir $(PLIST_FILES)))))

.PHONY: install uninstall load unload reload

default: load

xpc_set_event_stream_handler: xpc_set_event_stream_handler.m
	gcc -framework Foundation -o xpc_set_event_stream_handler xpc_set_event_stream_handler.m

${INSTALL_AGENTS_PATH}/com.prlusbwatch.%.plist: ${PLIST_PATH}/com.prlusbwatch.%.plist
	cp -v $< $@

install: xpc_set_event_stream_handler $(PLIST_INSTALLS)
	cp -v xpc_set_event_stream_handler /usr/local/bin
	cp -v prlusbwatch/prlusbwatch.sh /usr/local/bin

uninstall: unload
	rm -v /usr/local/bin/xpc_set_event_stream_handler
	rm -v /usr/local/bin/prlusbwatch.sh
	rm -v ${PLIST_INSTALLS}

load-%: | ${PLIST_INSTALLS}
	launchctl load ${INSTALL_AGENTS_PATH}/$(PLIST_BASE)$*.plist

load: install $(PLIST_LOADS)

unload-%:
	launchctl unload ${INSTALL_AGENTS_PATH}/$(PLIST_BASE)$*.plist

unload: $(PLIST_UNLOADS)

reload:
	make unload
	make load
