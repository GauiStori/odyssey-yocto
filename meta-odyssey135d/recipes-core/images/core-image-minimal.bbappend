# The Odyssey WIC has one rootfs partition and U-Boot loads both files from
# /boot on that partition.  Copy the deployed kernel artifacts explicitly;
# this avoids relying on ST's separate bootfs/package layout.

do_rootfs[depends] += "virtual/kernel:do_deploy"

ROOTFS_POSTPROCESS_COMMAND:append = " odyssey_install_bootfiles;"

odyssey_install_bootfiles() {
    install -d ${IMAGE_ROOTFS}/boot
    install -m 0644 ${DEPLOY_DIR_IMAGE}/zImage \
        ${IMAGE_ROOTFS}/boot/zImage
    install -m 0644 ${DEPLOY_DIR_IMAGE}/stm32mp135d-odyssey.dtb \
        ${IMAGE_ROOTFS}/boot/stm32mp135d-odyssey.dtb
}
