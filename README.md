# STM32MP135D Odyssey Yocto metadata

Prerequisites (Debian bookworm)
The Bookworm version can be installed in chroot if not
the main system.
Add 'contrib' to sources

```
apt install repo
```

Step by step instructions to build and flash.
This is done in a Debian bookworm (chroot if not main system).

```
export YOCTO_ODYSSEY=<my yocto dir>
mkdir -p ${YOCTO_ODYSSEY}
cd ${YOCTO_ODYSSEY}
repo init \
    -u https://github.com/STMicroelectronics/oe-manifest.git \
    -b refs/tags/openstlinux-6.6-yocto-scarthgap-mpu-v26.02.18

repo sync

git clone git@github.com:GauiStori/odyssey-yocto.git
```

Initialize and reenter the workspace root:

```bash
cd ${YOCTO_ODYSSEY}
source odyssey-yocto/setup-env.sh
```

Then build the minimal image:
```
cd ${YOCTO_ODYSSEY}
source odyssey-yocto/setup-env.sh
```

```
bitbake core-image-minimal
```

## Status

2026-10-15 System build and the step by step instructions above are verified. The instructions work for sdcard. EMMC is untested yet.
