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
MOCK=/usr/bin/mock
PODMAN=/usr/bin/podman
RPMLINT=/usr/bin/rpmlint
WGET=/usr/bin/wget

# Makefile parameter variables
requirements:=buildah diffutils gawk jq make mock podman rpm-build rpmlint wget zip
spec:=src/backdrop.spec
version:=$(shell awk '/Version:/ { print $$2 }' $(spec))
mock_root:=default
mock_resultdir:=.
srpm:=$(subst noarch,src.rpm,$(shell rpmspec -q --srpm $(spec)))
rpm:=$(shell rpmspec -q --rpms $(spec)).rpm
image:=$(subst .noarch,,$(shell rpmspec -q --rpms $(spec)))-rpm-test
container:=$(subst .noarch,,$(shell rpmspec -q --rpms $(spec)))-rpm-test

.PHONY: all
all: $(rpm)
	$(info all:)

.PHONY: lint
lint:
	$(info lint:)
	$(RPMLINT) $(spec)

.PHONY: sources
sources:
	$(WGET) --output-document=src/backdrop.zip https://github.com/backdrop/backdrop/releases/download/$(version)/backdrop.zip

src/system.core.json.patch: src/backdrop.zip
	unzip src/backdrop.zip
	cp -R backdrop backdrop.original
	jq --indent 4 '.file_private_path = "/var/lib/backdrop/private_files"' backdrop.original/core/modules/system/config/system.core.json > backdrop/core/modules/system/config/system.core.json
	-diff -urN backdrop.original/core/modules/system/config/system.core.json backdrop/core/modules/system/config/system.core.json > src/system.core.json.patch

.PHONY: srpm
srpm: $(srpm)

$(srpm): $(spec) src/backdrop.zip src/backdrop-vhost.conf.example
	$(MOCK) --root=$(mock_root) --resultdir=$(mock_resultdir) --buildsrpm \
		--spec $(spec) --sources src
.PHONY: rpm
rpm: $(rpm)

$(rpm): $(srpm)
	$(MOCK) --root=$(mock_root) --resultdir=$(mock_resultdir) --rebuild $(srpm)

.PHONY: test-image
test-image: delete-test-image $(rpm) test/backdrop-firstboot.service test/backdrop-firstboot.bash
	$(BUILDAH) pull 'registry.fedoraproject.org/fedora:latest'
	$(BUILDAH) from --name "$(image)" 'registry.fedoraproject.org/fedora:latest'
	$(BUILDAH) run "$(image)" -- dnf --assumeyes update
	$(BUILDAH) copy "$(image)" $(rpm) /root
	$(BUILDAH) run "$(image)" -- dnf --assumeyes install /root/$(rpm)
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
	$(info clean:)
	rm -f *.rpm

.PHONY: distclean
distclean: clean delete-container delete-test-image
	$(info distclean:)
	rm -f *~ *.log
	rm -rf backdrop backdrop.original

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
	$(info MOCK=$(MOCK))
	$(info PODMAN=$(PODMAN))
	$(info RPMLINT=$(RPMLINT))
	$(info WGET=$(WGET))
	$(info requirements=$(requirements))
	$(info spec=$(spec))
	$(info version=$(version))
	$(info mock_root=$(mock_root))
	$(info mock_resultdir=$(mock_resultdir))
	$(info srpm=$(srpm))
	$(info rpm=$(rpm))
	$(info image=$(image))
	$(info container=$(container))
	@:

.PHONY: printmakevars
printmakevars:
	$(info printmakevars:)
	$(info $(.VARIABLES))
	@:
