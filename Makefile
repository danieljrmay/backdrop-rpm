#!/usr/bin/make -f
#
# backdrop-rpm GNU Makefile
#
# See: https://www.gnu.org/software/make/manual
#
# Copyright (c) 2021 Daniel J. R. May
#

# Makefile command variables
DNF_INSTALL=/usr/bin/dnf --assumeyes install
MOCK=/usr/bin/mock
RPMLINT=/usr/bin/rpmlint
WGET=/usr/bin/wget

# Makefile parameter variables
requirements:=awk make mock rpm-build rpmlint wget
spec:=src/backdrop.spec
version:=$(shell awk '/Version:/ { print $$2 }' $(spec))
mock_root:=default
mock_resultdir:=.
srpm:=$(subst noarch,src.rpm, $(shell rpmspec -q --srpm $(spec)))

.PHONY: all
all:
	$(info all:)

.PHONY: lint
lint:
	$(info lint:)
	$(RPMLINT) $(spec)

.PHONY: sources
sources:
	$(WGET) --output-document=src/backdrop.zip https://github.com/backdrop/backdrop/releases/download/$(version)/backdrop.zip

.PHONY: srpm
srpm: $(srpm)

$(srpm): $(spec) src/backdrop.zip src/backdrop.conf
	$(MOCK) --root=$(mock_root) --resultdir=$(mock_resultdir) --buildsrpm \
		--spec $(spec) --sources src
.PHONY: rpm
rpm: $(srpm)
	$(MOCK) --root=$(mock_root) --resultdir=$(mock_resultdir) --rebuild $(srpm)

.PHONY: requirements
requirements:
	$(DNF_INSTALL) $(requirements)

.PHONY: clean
clean:
	$(info clean:)
	rm -f *.rpm 

.PHONY: distclean
distclean: clean
	$(info distclean:)
	rm -f *~ *.log

.PHONY: help
help:
	$(info help:)
	$(info Usage: make TARGET [VAR1=VALUE VAR2=VALUE])
	$(info )
	$(info Targets:)
	$(info   all              The default target, builds all files.)
	$(info   lint             Lint some of the source files.)
	$(info   sources          Download the backdrop sources.)
	$(info   srpm             Build the source RPM.)
	$(info   rpm              Build the RPM.)
	$(info   clean            Clean up all generated RPM files.)
	$(info   distclean        Clean up all generated files.)
	$(info   requirements     Install all packaging development requirements, requires sudo.)
	$(info   help             Display this help message.)
	$(info   printvars        Print variable values (useful for debugging).)
	$(info   printmakevars    Print the Make variable values (useful for debugging).)
	$(info )
	$(info For more information read the Makefile and see http://www.gnu.org/software/make/manual/html_node/index.html)

.PHONY: printvars
printvars:
	$(info printvars:)
	$(info DNF_INSTALL=$(DNF_INSTALL))
	$(info MOCK=$(MOCK))
	$(info RPMLINT=$(RPMLINT))
	$(info WGET=$(WGET))
	$(info requirements=$(requirements))
	$(info spec=$(spec))
	$(info version=$(version))
	$(info mock_root=$(mock_root))
	$(info mock_resultdir=$(mock_resultdir))
	$(info srpm=$(srpm))

.PHONY: printmakevars
printmakevars:
	$(info printmakevars:)
	$(info $(.VARIABLES))
