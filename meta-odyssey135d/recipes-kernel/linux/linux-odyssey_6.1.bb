SUMMARY = "Linux kernel for the STM32MP135D Odyssey"
SECTION = "kernel"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

LINUX_VERSION = "6.1"
LINUX_SUBVERSION = ""
LINUX_TARGET = "stm32mp-odyssey"
LINUX_RELEASE = "r4"
PV = "${LINUX_VERSION}-${LINUX_TARGET}-${LINUX_RELEASE}"

inherit kernel

DEPENDS += "rsync-native"

# Set these after inheriting kernel.bbclass; it supplies a shared staging
# default for S which is not appropriate for this fetched source tree.
S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

SRC_URI = " \
    git://github.com/xogium/st-linux.git;protocol=https;nobranch=1 \
    file://linux.config \
"
SRCREV = "v6.1-stm32mp-odyssey-r4"

# Use the Buildroot board configuration verbatim.  kernel.bbclass copies this
# into the out-of-tree build directory and runs olddefconfig.
KERNEL_CONFIG_COMMAND = "oe_runmake -C ${S} O=${B} olddefconfig"

KERNEL_DEVICETREE = "stm32mp135d-odyssey.dtb"
KERNEL_IMAGETYPE = "zImage"
# The ST machine include may append zImage to this list.  Keep one entry so
# kernel.bbclass creates kernel-image-zimage only once.
KERNEL_IMAGETYPES = "zImage"
COMPATIBLE_MACHINE = "stm32mp135d-odyssey"

# ST image recipes depend on this package name.  The standard kernel class
# does not create it automatically, unlike linux-stm32mp.
PACKAGES =+ "${KERNEL_PACKAGE_NAME}-headers"
FILES:${KERNEL_PACKAGE_NAME}-headers = "${exec_prefix}/src/linux*"

do_install:append() {
    oe_runmake -C ${S} headers_install \
        INSTALL_HDR_PATH=${D}${prefix}/src/linux-headers-${LINUX_VERSION}
}

do_configure:prepend() {
    install -m 0644 ${WORKDIR}/linux.config ${B}/.config
}

DEFAULT_PREFERENCE = "-1"

python __anonymous() {
    packages = (d.getVar("PACKAGES") or "").split()
    d.setVar("PACKAGES", " ".join(dict.fromkeys(packages)))
}
