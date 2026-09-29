# Use the known-working Odyssey OP-TEE fork and commit from the Buildroot
# defconfig instead of ST's default OP-TEE repository.
SRC_URI = "git://github.com/GauiStori/optee_os.git;protocol=https;branch=3.19.0-stm32mp-odyssey-xogium"
SRCREV = "b01fad7b7aba97065a2a87794fec9b6d610059a3"

S = "${WORKDIR}/git"

OPTEEMACHINE = "stm32mp1"
OPTEEOUTPUTMACHINE = "stm32mp1"

EXTRA_OEMAKE:append = " \
    PLATFORM_FLAVOR=135D_ODYSSEY \
    CFG_WITH_TUI=n \
    CFG_TEE_CORE_LOG_LEVEL=0 \
    CFG_TEE_TA_LOG_LEVEL=0 \
"
