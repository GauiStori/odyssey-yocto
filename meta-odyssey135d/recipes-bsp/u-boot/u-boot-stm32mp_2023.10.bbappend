# Match the active Buildroot defconfig.  Buildroot selects this branch, not a
# fixed commit.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = "git://github.com/GauiStori/u-boot-st.git;protocol=https;branch=v2023.10-stm32mp-odyssey \
           file://uboot-emmc.fragment"
SRCREV = "${AUTOREV}"

UBOOT_CONFIG = "default_stm32mp13"
UBOOT_CONFIG[default_stm32mp13] = "stm32mp13_defconfig,,u-boot.dtb"
UBOOT_DEVICETREE[default_stm32mp13] = "stm32mp135d-odyssey"
UBOOT_MAKE_OPT[default_stm32mp13] = "DEVICE_TREE=stm32mp135d-odyssey"

# BR2_TARGET_UBOOT_CONFIG_FRAGMENT_FILES
do_generate_defconfig:append() {
    cat ${UNPACKDIR}/uboot-emmc.fragment >> ${S}/configs/stm32mp13_defconfig
}
