#! /bin/bash

set -e

SERIES="4.14 4.19 5.4 5.6"

find_latest() {
    VERSION=$1
    VMAJOR=`echo ${VERSION} | cut -d. -f1`
    curl -s https://cdn.kernel.org/pub/linux/kernel/v${VMAJOR}.x/sha256sums.asc | grep ChangeLog-${VERSION} | tail -n1 | cut -d'-' -f2
}

gen_recipe() {
    VERSION=$1
    VMAJOR=`echo ${VERSION} | cut -d. -f1`
    VMINOR=`echo ${VERSION} | cut -d. -f2`
    VPATCH=`echo ${VERSION} | cut -d. -f3`
    SRCREV=`git ls-remote https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git "v${VERSION}^{}" | cut -f1`
    SHA256=`curl -s https://cdn.kernel.org/pub/linux/kernel/v${VMAJOR}.x/sha256sums.asc | grep linux-${VERSION}.tar.xz | cut -d' ' -f1`

    cat << EOF
LINUX_VMAJOR = "${VMAJOR}"
LINUX_VMINOR = "${VMINOR}"
LINUX_VPATCH = "${VPATCH}"
LINUX_SRCREV = "${SRCREV}"
LINUX_SHA256 = "${SHA256}"

require kernel-dot-org.inc
EOF
}

gen_kas() {
    VERSION=$1

    cat << EOF
header:
  version: 8
  includes:
    - kas/test-base.yml

local_conf_header:
  linux_version: |
    PREFERRED_VERSION_linux = "${VERSION}"
EOF
}

echo "Updating recipes..."
for S in ${SERIES}; do
    VERSION=`find_latest ${S}`
    gen_recipe ${VERSION} > recipes-kernel/linux/linux_${S}.bb
    gen_kas ${VERSION} > kas/test-${S}.yml
    echo "    recipes-kernel/linux/linux_${S}.bb: v${VERSION}"
done
echo "Done."
