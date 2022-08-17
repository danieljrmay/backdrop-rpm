#!/usr/bin/make -f
#
# backdrop-systemd packaging GNU Makefile
#
# See: https://www.gnu.org/software/make/manual
#
# Copyright 2022 Daniel J. R. May
#

# Makefile command variables
DNF_INSTALL:=/usr/bin/dnf --assumeyes install
MOCK:=/usr/bin/mock
RPMLINT=/usr/bin/rpmlint
WGET=/usr/bin/wget

# Makefile parameter variables
requirements:=gawk make mock rpm-build rpmlint wget
spec:=backdrop-systemd.spec
version:=$(shell awk '/Version:/ { print $$2 }' $(spec))
tarball:=v$(version).tar.gz
mock_root:=default
mock_resultdir:=.
srpm:=$(subst noarch,src.rpm,$(shell rpmspec -q --srpm $(spec)))
rpm:=$(shell rpmspec -q --rpms $(spec)).rpm

.PHONY: all
all: $(rpm)
	$(info all:)

.PHONY: lint
lint:
	$(info lint:)
	$(RPMLINT) $(spec)

.PHONY: sources
sources: $(tarball)
	$(info Sources should have now been downloaded and prepared.)

$(tarball):
	$(WGET) https://github.com/danieljrmay/backdrop-systemd/archive/refs/tags/$(tarball)

.PHONY: srpm
srpm: $(srpm)

$(srpm): $(spec) $(tarball)
	$(MOCK) --root=$(mock_root) --resultdir=$(mock_resultdir) --buildsrpm \
		--spec $(spec) --sources $(tarball)

.PHONY: rpm
rpm: $(rpm)

$(rpm): $(srpm)
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
	rm -f *~ *.log *.rpm

.PHONY: cleansources
cleansources: distclean
	$(info cleansources:)
	rm -f $(tarball)

.PHONY: help
help:
	$(info help:)
	$(info Usage: make TARGET [VAR1=VALUE VAR2=VALUE])
	$(info )
	$(info Targets:)
	$(info   all                    The default target, build the RPM.)
	$(info   lint                   Lint some of the source files.)
	$(info   sources                Download the backdrop sources.)
	$(info   srpm                   Build the source RPM.)
	$(info   rpm                    Build the RPM.)
	$(info   clean                  Clean up all generated RPM files.)
	$(info   distclean              Clean up all generated files.)
	$(info   requirements           Install all packaging development and testing requirements, requires sudo.)
	$(info   help                   Display this help message.)
	$(info   printvars              Print variable values (useful for debugging).)
	$(info   printmakevars          Print the Make variable values (useful for debugging).)
	$(info )
	$(info For more information see the README.md file.)
	@:

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
	$(info tarball=$(tarball))
	$(info mock_root=$(mock_root))
	$(info mock_resultdir=$(mock_resultdir))
	$(info srpm=$(srpm))
	$(info rpm=$(rpm))
	@:

.PHONY: printmakevars
printmakevars:
	$(info printmakevars:)
	$(info $(.VARIABLES))
	@:
