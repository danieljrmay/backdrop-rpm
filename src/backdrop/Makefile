#!/usr/bin/make -f
#
# backdrop GNU Makefile
#
# See: https://www.gnu.org/software/make/manual
#
# Copyright 2022 Daniel J. R. May
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm

# Recipe parameters
spec:=backdrop.spec
version:=$(shell awk '/Version:/ { print $$2 }' $(spec))
mock_root:=default
mock_resultdir:=.
srpm:=$(subst noarch,src.rpm,$(shell rpmspec -q --srpm $(spec)))
rpm:=$(shell rpmspec -q --rpms $(spec)).rpm

.PHONY: all
all: $(rpm)

.PHONY: lint
lint:
	rpmlint $(spec)

.PHONY: sources
sources: backdrop.zip system.core.json.patch

backdrop.zip:
	wget --output-document=backdrop.zip https://github.com/backdrop/backdrop/releases/download/$(version)/backdrop.zip

system.core.json.patch: backdrop.zip
	unzip backdrop.zip
	cp -R backdrop backdrop.original
	jq --indent 4 '.file_private_path = "/var/lib/backdrop/private_files"' backdrop.original/core/modules/system/config/system.core.json > backdrop/core/modules/system/config/system.core.json
	-diff -urN backdrop.original/core/modules/system/config/system.core.json backdrop/core/modules/system/config/system.core.json > system.core.json.patch

.PHONY: srpm
srpm: $(srpm)

$(srpm): $(spec) backdrop.zip backdrop-vhost.conf.example system.core.json.patch
	mock --root=$(mock_root) --resultdir=$(mock_resultdir) --buildsrpm \
		--spec $(spec) --sources .

.PHONY: rpm
rpm: $(rpm)

$(rpm): $(srpm)
	mock --root=$(mock_root) --resultdir=$(mock_resultdir) --rebuild $(srpm)

.PHONY: clean
clean:
	rm -f *~ *.log
	rm -rf backdrop backdrop.original

.PHONY: distclean
distclean: clean
	rm -f *.rpm

.PHONY: sourcesclean
sourcesclean: distclean
	rm -f backdrop.zip system.core.json.patch

.PHONY: help
help:
	@echo 'Usage: make TARGET [VAR1=VALUE VAR2=VALUE]'
	@echo
	@echo 'Targets:'
	@echo '  all                    The default target, build the RPM.'
	@echo '  lint                   Lint the source files.'
	@echo '  sources                Download the backdrop sources.'
	@echo '  srpm                   Build the source RPM.)'
	@echo '  rpm                    Build the RPM.'
	@echo '  clean                  Clean up all intermediate files.'
	@echo '  distclean              Clean up all generated files.'
	@echo '  sourcesclean           Clean up the downloaded and generated sources.'
	@echo '  help                   Display this help message.'
	@echo '  printvars              Print variable values (useful for debugging).'
	@echo '  printmakevars          Print the Make variable values (useful for debugging).'
	@echo
	@echo 'See https://github.com/danieljrmay/backdrop-rpm for more information.'

.PHONY: printvars
printvars:
	@echo 'spec=$(spec)'
	@echo 'version=$(version)'
	@echo 'mock_root=$(mock_root)'
	@echo 'mock_resultdir=$(mock_resultdir)'
	@echo 'srpm=$(srpm)'
	@echo 'rpm=$(rpm)'

.PHONY: printmakevars
printmakevars:
	@echo '$(VARIABLES)'
