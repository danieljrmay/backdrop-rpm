#!/usr/bin/make -f
#
# backdrop-rpm GNU Makefile
#
# See: https://www.gnu.org/software/make/manual
#
# Copyright (c) 2022 Daniel J. R. May
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm

# Set this to true at the command line to enable exploring of the test
# container.
#
# > make test EXPLORE=true
EXPLORE=false

# Recipe parameters
backdrop_rpm_filename:=$(shell rpmspec -q --rpms src/backdrop/backdrop.spec).rpm
backdrop_rpm:=src/backdrop/$(backdrop_rpm_filename)
backdrop_systemd_rpm_filename:=$(shell rpmspec -q --rpms src/backdrop-systemd/backdrop-systemd.spec).rpm
backdrop_systemd_rpm:=src/backdrop-systemd/$(backdrop_systemd_rpm_filename)
image:=backdrop-rpm-test
image_flag:=test/$(image).image.created
requirements:=buildah diffutils gawk jq make mock podman rpm-build rpmlint ShellCheck wget zip

.PHONY: all
all: $(backdrop_rpm) $(backdrop_systemd_rpm)

.PHONY: lint
lint:
	make --directory=src/backdrop lint
	make --directory=src/backdrop-systemd lint
	shellcheck test/create-test-image.bash test/create-test-container.bash

$(backdrop_rpm):
	make --directory=src/backdrop

$(backdrop_systemd_rpm):
	make --directory=src/backdrop-systemd

.PHONY: test
test: $(image_flag)
	cd test; EXPLORE=$(EXPLORE) bash create-test-container.bash;

$(image_flag): test/create-test-image.bash $(backdrop_rpm) $(backdrop_systemd_rpm)
	cd test; bash create-test-image.bash;

.PHONY: clean
clean:
	make --directory=src/backdrop clean
	make --directory=src/backdrop-systemd clean

.PHONY: distclean
distclean: clean
	make --directory=src/backdrop distclean
	make --directory=src/backdrop-systemd distclean
	podman rmi -f $(image)
	rm -f $(image_flag)

.PHONY: requirements
requirements:
	dnf --assumeyes install $(requirements)

.PHONY: help
help:
	@echo 'Usage: make TARGET [VAR1=VALUE VAR2=VALUE]'
	@echo
	@echo 'Targets:'
	@echo '  all                    The default target, build the RPMs.'
	@echo '  lint                   Lint the source files.'
	@echo '  test                   Test the RPMs by installing in a container.'
	@echo '  clean                  Clean up all intermediate files.'
	@echo '  distclean              Clean up all generated files.'
	@echo '  requirements           Install all development and testing requirements, requires sudo.'
	@echo '  help                   Display this help message.'
	@echo '  printvars              Print variable values (useful for debugging).'
	@echo '  printmakevars          Print the Make variable values (useful for debugging).'
	@echo
	@echo 'Variables:'
	@echo '  EXPLORE                Set "true" to explore the test container (default: "false").'
	@echo
	@echo 'See https://github.com/danieljrmay/backdrop-rpm for more information.'

.PHONY: printvars
printvars:
	@echo 'EXPLORE=$(EXPLORE)'
	@echo 'backdrop_rpm_filename=$(backdrop_rpm_filename)'
	@echo 'backdrop_rpm=$(backdrop_rpm)'
	@echo 'backdrop_systemd_rpm_filename=$(backdrop_systemd_rpm_filename)'
	@echo 'backdrop_systemd_rpm=$(backdrop_systemd_rpm)'
	@echo 'image=$(image)'
	@echo 'image_flag=$(image_flag)'
	@echo 'requirements=$(requirements)'

.PHONY: printmakevars
printmakevars:
	@echo '$(.VARIABLES)'
