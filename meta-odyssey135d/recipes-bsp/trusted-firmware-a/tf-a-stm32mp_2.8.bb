require recipes-bsp/trusted-firmware-a/tf-a-stm32mp-common.inc
require recipes-bsp/trusted-firmware-a/tf-a-stm32mp.inc

SUMMARY = "Trusted Firmware-A for STM32MP135D Odyssey"

TFA_PLATFORM = "stm32mp1"
TFA_ARM_MAJOR = "7"
TFA_ARM_ARCH = "aarch32"

# Verbose TF-A diagnostics for board bring-up.
ST_TF_A_DEBUG = "1"
ST_TF_A_DEBUG_TRACE = "1"
ST_TF_A_LOG_LEVEL_DEBUG = "50"

# This is the same TF-A repository and revision selected by the Buildroot
# defconfig.  The board DT is part of this source tree.
# Buildroot selects the tagged revision, not a branch.  nobranch=1 is
# required because the tag is not named v2.8-stm32mp-odyssey.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    git://git.xogium.me/git/xogium/st-arm-trusted-firmware.git;protocol=https;nobranch=1 \
    file://0001-stm32mp13-use-odyssey-debug-uart-pin.patch \
"
SRCREV = "v2.8-stm32mp-odyssey-r1"

TF_A_VERSION = "2.8"
TF_A_SUBVERSION = ""
TF_A_TARGET = "stm32mp"
TF_A_RELEASE = "odyssey-r1"
PV = "${TF_A_VERSION}-${TF_A_TARGET}-${TF_A_RELEASE}"

S = "${WORKDIR}/git"

# Match BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES.  The SD-card
# configuration adds STM32MP_SDMMC=1 through tf-a-stm32mp-config.inc.
TF_A_CONFIG_OPTS_optee:stm32mp1common = " \
    AARCH32_SP=optee \
    STM32MP_EMMC=1 \
    STM32MP_EMMC_BOOT=1 \
    STM32MP_USB_PROGRAMMER=1 \
"

DEFAULT_PREFERENCE = "-1"
