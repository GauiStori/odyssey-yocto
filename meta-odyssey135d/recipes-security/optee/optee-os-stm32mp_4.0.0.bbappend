# Match the active Buildroot defconfig exactly.
SRC_URI = "git://github.com/GauiStori/optee_os.git;protocol=https;nobranch=1"
SRCREV = "b01fad7b7aba97065a2a87794fec9b6d610059a3"

OPTEEMACHINE = "stm32mp1"
OPTEEOUTPUTMACHINE = "stm32mp1"

EXTRA_OEMAKE:append = " \
    PLATFORM_FLAVOR=135D_ODYSSEY \
    CFG_WITH_TUI=n \
    CFG_TEE_CORE_LOG_LEVEL=0 \
    CFG_TEE_TA_LOG_LEVEL=0 \
"
