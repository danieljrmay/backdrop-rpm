#!/usr/bin/make -f
#
# backdrop-rpm GNU Makefile
#
# See: https://www.gnu.org/software/make/manual
#
# Copyright (c) 2022 Daniel J. R. May
#

# Makefile command variables
BUILDAH=/usr/bin/buildah
DNF_INSTALL=/usr/bin/dnf --assumeyes install
PODMAN=/usr/bin/podman

# Makefile parameter variables
requirements:=buildah make podman rpm-build
backdrop_rpm:=$(shell rpmspec -q --rpms src/backdrop/backdrop.spec)
backdrop_systemd_rpm:=$(shell rpmspec -q --rpms src/backdrop-systemd/backdrop-systemd.spec)
image:=$(subst .noarch,,$(shell rpmspec -q --rpms src/backdrop/backdrop.spec))-rpm-test
container:=$(subst .noarch,,$(shell rpmspec -q --rpms src/backdrop/backdrop.spec))-rpm-test

.PHONY: all
all: src/backdrop/$(backdrop_rpm) src/backdrop-systemd/$(backdrop_systemd_rpm)

src/backdrop/$(backdrop_rpm):
	$(MAKE) --directory=src/backdrop

src/backdrop-systemd/$(backdrop_systemd_rpm):
	$(MAKE) --directory=src/backdrop-systemd

.PHONY: test-image
test-image: delete-test-image $(rpm) test/backdrop-firstboot.service test/backdrop-firstboot.bash
	$(BUILDAH) pull 'registry.fedoraproject.org/fedora:latest'
	$(BUILDAH) from --name "$(image)" 'registry.fedoraproject.org/fedora:latest'
	$(BUILDAH) run "$(image)" -- dnf --assumeyes update
	$(BUILDAH) copy "$(image)" $(rpm) /root
	$(BUILDAH) run "$(image)" -- dnf --assumeyes install mariadb-server /root/$(rpm) 
	$(BUILDAH) copy "$(image)" test/backdrop-firstboot.service /etc/systemd/system/backdrop-firstboot.service
	$(BUILDAH) copy "$(image)" test/backdrop-firstboot.bash /usr/local/bin/backdrop-firstboot
	$(BUILDAH) run "$(image)" -- chmod a+x /usr/local/bin/backdrop-firstboot
	$(BUILDAH) copy "$(image)" test/backdrop-install.service /etc/systemd/system/backdrop-install.service
	$(BUILDAH) copy "$(image)" test/backdrop-install.bash /usr/local/bin/backdrop-install
	$(BUILDAH) run "$(image)" -- chmod a+x /usr/local/bin/backdrop-install
	$(BUILDAH) run "$(image)" -- systemctl enable httpd.service mariadb.service php-fpm.service backdrop-firstboot.service backdrop-install.service
	$(BUILDAH) config --port 80 "$(image)"
	$(BUILDAH) config --cmd "/usr/sbin/init" "$(image)"
	$(BUILDAH) commit "$(image)" "$(image)"
	$(BUILDAH) rm "$(image)"

.PHONY: delete-test-image
delete-test-image: 
	-$(BUILDAH) rmi $(image)

.PHONY: container
container: delete-container test/backdrop-firstboot.secrets
	$(PODMAN) image exists $(image)
	$(PODMAN) secret create backdrop-firstboot test/backdrop-firstboot.secrets
	$(PODMAN) run --name "$(container)" --secret source=backdrop-firstboot,type=mount,mode=400,target=backdrop-firstboot \
	--publish "48080:80" --hostname "backdrop-rpm-test" --detach $(image)
	@echo 'You should be able to complete your backdrop container installation at http://localhost:48080'

.PHONY: delete-container
delete-container: 
	-$(PODMAN) stop $(container)
	-$(PODMAN) rm $(container)
	-$(PODMAN) secret rm backdrop-firstboot

.PHONY: explore-container
explore-container: 
	$(PODMAN) exec --interactive --tty $(container) /usr/bin/bash

.PHONY: requirements
requirements:
	$(DNF_INSTALL) $(requirements)

.PHONY: clean
clean:
	$(MAKE) --directory=src/backdrop clean
	$(MAKE) --directory=src/backdrop-systemd clean

.PHONY: distclean
distclean: delete-container delete-test-image
	$(MAKE) --directory=src/backdrop distclean
	$(MAKE) --directory=src/backdrop-systemd distclean

.PHONY: help
help:
	$(info help:)
	$(info Usage: make TARGET [VAR1=VALUE VAR2=VALUE])
	$(info )
	$(info Targets:)
	$(info   all                    The default target, build the RPM.)
	$(info   test-image             Build the $(image) container image.)
	$(info   container              Build the $(container) container.)
	$(info   delete-test-image      Deletes any pre-existing $(image) container image.)
	$(info   delete-container       Deletes and pre-existing $(container) container.)
	$(info   explore-container      Explore a $(container) container via a bash shell.)
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
	$(info BUILDAH=$(BUILDAH))
	$(info DNF_INSTALL=$(DNF_INSTALL))
	$(info PODMAN=$(PODMAN))
	$(info requirements=$(requirements))
	$(info backdrop_rpm=$(backdrop_rpm))
	$(info image=$(image))
	$(info container=$(container))
	@:

.PHONY: printmakevars
printmakevars:
	$(info printmakevars:)
	$(info $(.VARIABLES))
	@:
