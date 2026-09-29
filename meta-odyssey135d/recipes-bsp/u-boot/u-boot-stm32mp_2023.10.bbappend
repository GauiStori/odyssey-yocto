FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Follow the same moving branch selected by the Buildroot defconfig.
SRC_URI = "git://github.com/GauiStori/u-boot-st.git;protocol=https;branch=v2023.10-stm32mp-odyssey \
           file://fragment-07-odyssey-sdcard.cfg;subdir=fragments/features"
SRCREV = "${AUTOREV}"

# Keep ST's STM32MP13 recipe machinery, but select the Odyssey U-Boot DT.
UBOOT_DEVICETREE[default_stm32mp13] = "stm32mp135d-odyssey"
