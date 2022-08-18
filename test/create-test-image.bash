#!/usr/bin/bash
#
# create-test-image
#
# Author: Daniel J. R. May
#
# This script creates a container image for testing the backdrop-rpm
# codebase.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm

declare -r image=backdrop-rpm-test
declare -r working_container=$image-tmp
declare -r image_flag=$image.image.created
backdrop_rpm_path=$(realpath ../src/backdrop/backdrop-*.noarch.rpm)
backdrop_systemd_rpm_path=$(realpath ../src/backdrop-systemd/backdrop-systemd-*.noarch.rpm)
backdrop_rpm=$(basename "$backdrop_rpm_path")
backdrop_systemd_rpm=$(basename "$backdrop_systemd_rpm_path")

echo "image=$image"
echo "working_container=$working_container"
echo "image_flag=$image_flag"
echo "backdrop_rpm_path=$backdrop_rpm_path"
echo "backdrop_systemd_rpm_path=$backdrop_systemd_rpm_path"
echo "backdrop_rpm=$backdrop_rpm"
echo "backdrop_systemd_rpm=$backdrop_systemd_rpm"

trap 'podman rm -f $working_container; podman rmi -f $image; rm -f $image_flag; echo "ERROR: Failed to create image."; exit 100;' ERR

podman image exists "$image" && buildah rmi "$image"
buildah pull 'registry.fedoraproject.org/fedora:latest'
buildah from --name "$working_container" 'registry.fedoraproject.org/fedora:latest'
buildah run "$working_container" -- dnf --assumeyes update
buildah copy "$working_container" "$backdrop_rpm_path" /root
buildah copy "$working_container" "$backdrop_systemd_rpm_path" /root
buildah run "$working_container" -- dnf --assumeyes install mariadb-server /root/"$backdrop_rpm" /root/"$backdrop_systemd_rpm"
buildah run "$working_container" -- systemctl enable \
	httpd.service \
	mariadb.service \
	php-fpm.service \
	backdrop-configure-httpd \
	backdrop-configure-mariadb \
	backdrop-install
buildah config --port 80 "$working_container"
buildah config --cmd "/usr/sbin/init" "$working_container"
buildah commit "$working_container" "$image"
buildah rm "$working_container"

cat <<EOF >"$image_flag"
This file was created by the test/create-test-image.bash script after
it has completed creating a container image suitable for testing the
backdrop-rpm codebase. It is used by the Makefile to ensure that an
up-to-date image is available for testing.

You can delete it if you want, all that will happen is that the
test/create-test-image.bash will be re-run when it might not have been
required.
EOF
