# STM32MP135D Odyssey: Yocto Scarthgap minimal image

This document describes a conservative first bring-up of **Yocto/OpenSTLinux Scarthgap** for the Seeed **ODYSSEY STM32MP135D**, using the working Buildroot configuration from:

- Repository: `https://github.com/GauiStori/buildroot-stm32mp135d-odyssey`
- Branch: `odyssey-2023-10`
- Defconfig: `configs/stm32mp135d_odyssey_defconfig`

The main objective is not to modernize the BSP immediately. The objective is to reproduce the already-working boot chain under Yocto first.

The first milestone is:

```text
ROM -> TF-A -> OP-TEE -> U-Boot -> Linux -> core-image-minimal -> ttySTM0 login
```

Do not add Weston, nginx, Python packages, MQTT, or application software until this boots reliably from SD card.

All commands in this document are intended to be run inside the Debian 12
Bookworm chroot. Buildroot is a temporary reference tool only. It is used to
read the working defconfig, DTS, fragments and image layout; it is not a
Yocto dependency and must not remain in the Yocto build after those files have
been copied into `layers/meta-odyssey135d`.

The only Yocto directory that must be saved in the project Git repository is:

```text
layers/meta-odyssey135d/
```

That directory contains the machine configuration, recipes, patches, copied
configuration/DTS files and WIC file. Do **not** commit `build-odyssey/`,
`downloads/`, `sstate-cache/`, `tmp*/`, cloned source trees, the Buildroot
checkout, or the generated image files. Save the exact source revisions in
the layer documentation or in a separate manifest if reproducibility requires
it.

---

## 1. Known-working source references from Buildroot

The `odyssey-2023-10` Buildroot branch uses the following sources.

### Linux

```text
Repository: https://github.com/xogium/st-linux
Revision:   v6.1-stm32mp-odyssey-r4
```

Buildroot also supplies its own complete kernel configuration and its own Odyssey DTS:

```text
board/stm32mp135d-odyssey/configs/linux.config
board/stm32mp135d-odyssey/dts/stm32mp135d-odyssey-grove.dts (optional Grove variant)
```

### TF-A

```text
Repository: https://git.xogium.me/git/xogium/st-arm-trusted-firmware.git
Revision:   v2.8-stm32mp-odyssey-r1
Platform:   stm32mp1
```

Additional Buildroot TF-A variables are:

```text
STM32MP_EMMC=1
STM32MP_EMMC_BOOT=1
STM32MP_SDMMC=1
AARCH32_SP=optee
DTB_FILE_NAME=stm32mp135d-odyssey.dtb
BL33_CFG=<u-boot.dtb>
STM32MP_USB_PROGRAMMER=1
```

### OP-TEE

This is important: the `odyssey-2023-10` branch does **not** use the old Xogium OP-TEE tag.

It uses Gudjon's ST-based fork:

```text
Repository: https://github.com/GauiStori/optee_os.git
Commit:     b01fad7b7aba97065a2a87794fec9b6d610059a3
Platform:   stm32mp1
Flavor:     135D_ODYSSEY
```

Additional settings are:

```text
CFG_WITH_TUI=n
CFG_TEE_CORE_LOG_LEVEL=0
CFG_TEE_TA_LOG_LEVEL=0
```

Expected OP-TEE images include:

```text
tee.bin
tee-header_v2.bin
tee-pager_v2.bin
tee-pageable_v2.bin
```

### U-Boot

The branch also does **not** use the old Xogium U-Boot tag. The current
Buildroot defconfig tracks a branch rather than a fixed commit.

It uses:

```text
Repository: https://github.com/GauiStori/u-boot-st.git
Branch:     v2023.10-stm32mp-odyssey
Base:       U-Boot 2023.10 STM32MP
Defconfig:  stm32mp13_defconfig
DT:         stm32mp135d-odyssey
```

The branch currently identifies itself as:

```text
2023.10-stm32mp-r3.1-rc3
```

This is useful because Scarthgap's STM32MP BSP also uses the U-Boot 2023.10 generation.

---

## 2. Known-working U-Boot boot command

The Buildroot tree has storage-specific U-Boot fragments:

```text
uboot-sdcard.fragment  -> mmc 0:5, root=/dev/mmcblk0p5
uboot-emmc.fragment    -> mmc 1:2, root=/dev/mmcblk1p2
```

This document follows the SD-card flow, so it uses `uboot-sdcard.fragment`.
The current Buildroot defconfig selects `uboot-emmc.fragment`; do not combine
that eMMC fragment with the SD-card WIC layout below.

The SD-card U-Boot fragment uses:

```text
CONFIG_DEFAULT_DEVICE_TREE="stm32mp135d-odyssey"
CONFIG_BOOTDELAY=3
CONFIG_BOOTCOMMAND="ext4load mmc 0:5 ${kernel_addr_r} /boot/zImage; ext4load mmc 0:5 ${fdt_addr_r} /boot/stm32mp135d-odyssey.dtb; setenv bootargs \"root=/dev/mmcblk0p5 rootwait rw console=ttySTM0,115200n8 earlycon\"; bootz ${kernel_addr_r} - ${fdt_addr_r}"
```

The important assumptions are therefore:

```text
root filesystem partition: /dev/mmcblk0p5
console:                  ttySTM0,115200n8
kernel:                   /boot/zImage
kernel DTB:               /boot/stm32mp135d-odyssey.dtb
```

For the first Yocto image we should preserve these assumptions.

---

## 3. Known-working SD-card partition layout

The Buildroot `genimage.cfg` uses GPT and the following order:

```text
1 MiB offset

partition 1: fsbl1       1 MiB  tf-a-stm32mp135d-odyssey.stm32
partition 2: fsbl2       1 MiB  tf-a-stm32mp135d-odyssey.stm32
partition 3: fip         4 MiB  fip.bin
partition 4: u-boot-env  2 MiB
partition 5: rootfs             ext4
```

The Linux command line consequently uses:

```text
root=/dev/mmcblk0p5
```

Do not change the partition order during first bring-up.

---

# Part A - Install OpenSTLinux Scarthgap

## 4. Build host

Debian 12 Bookworm is a good choice for this first build.

Install the standard dependencies:

```bash
sudo apt update
sudo apt install -y \
    bc \
    bison \
    build-essential \
    chrpath \
    cpio \
    debianutils \
    diffstat \
    file \
    flex \
    gawk \
    gcc \
    git \
    iputils-ping \
    libacl1 \
    liblz4-tool \
    libssl-dev \
    locales \
    lz4 \
    python3 \
    python3-git \
    python3-jinja2 \
    python3-pexpect \
    python3-pip \
    python3-subunit \
    repo \
    socat \
    texinfo \
    unzip \
    wget \
    xz-utils \
    zstd
```

Check UTF-8:

```bash
locale -a | grep -i en_US.utf8
```

If required:

```bash
sudo locale-gen en_US.UTF-8
```

### Bookworm chroot runtime requirements

Before running `bitbake-layers` or BitBake, the chroot must have a writable
POSIX shared-memory mount. Python uses this area for the multiprocessing
semaphores required by BitBake. Check it with:

```bash
findmnt /dev/shm
ls -ld /dev/shm
```

The mount must be writable and the directory should normally be `1777`, for
example:

```text
tmpfs on /dev/shm type tmpfs (rw,nosuid,nodev,mode=1777)
drwxrwxrwt ... /dev/shm
```

If `/dev/shm` is read-only or has mode `755`, fix the chroot from its host
environment as root, then re-enter it:

```bash
mount -o remount,rw /chroots/bookworm/dev/shm
chmod 1777 /chroots/bookworm/dev/shm
```

If the chroot has no separate mount there, mount a tmpfs at that path:

```bash
mount -t tmpfs -o nosuid,nodev,mode=1777 tmpfs \
    /chroots/bookworm/dev/shm
```

Do not work around this with `sudo bitbake`; BitBake should run as the normal
build user. After correcting `/dev/shm`, start a fresh shell in the chroot and
source the Yocto environment again.

---

## 5. Create the Yocto workspace inside the Bookworm chroot

Use the same layout as the previous STM32MP Yocto work. This is the Yocto
workspace, not the Git repository that will hold the board layer:

```bash
mkdir -p ~/nb/o
cd ~/nb/o
```

Fetch ST's official Scarthgap distribution using the OpenSTLinux 6.2.0 tag:

```bash
repo init \
    -u https://github.com/STMicroelectronics/oe-manifest.git \
    -b refs/tags/openstlinux-6.6-yocto-scarthgap-mpu-v26.02.18

repo sync
```

export PATH="$PATH:$HOME/nb/o/layers/openembedded-core/bitbake/bin"

After synchronization there should be a directory structure similar to:

```text
~/nb/o/
├── layers/
│   ├── meta-openembedded/
│   ├── meta-st/
│   │   ├── meta-st-stm32mp/
│   │   ├── meta-st-openstlinux/
│   │   └── scripts/
│   └── ...
└── ...
```

Do not modify ST's layers directly.

---

# Part B - Use Buildroot temporarily, then remove it

## 6. Use the Buildroot Makefile only to initialize the reference configuration

Buildroot's Makefile cannot initialize a Yocto build. Yocto is initialized by
ST's `envsetup.sh` in the later section. If the Buildroot defconfig needs to
be expanded or checked, use Buildroot's Makefile only for that configuration
step, inside a temporary directory:

```bash
cd ~/nb/o

# Create the Yocto layer before copying reference files into it.
cd layers/openembedded-core
source oe-init-build-env ~/nb/o/build-odyssey
cd ~/nb/o/layers
bitbake-layers create-layer meta-odyssey135d
cd ~/nb/o

mkdir -p .temporary-buildroot
git clone \
    -b odyssey-2023-10 \
    https://github.com/GauiStori/buildroot-stm32mp135d-odyssey.git \
    .temporary-buildroot/buildroot-odyssey-reference

git clone \
    https://github.com/buildroot/buildroot.git \
    .temporary-buildroot/buildroot

make -C .temporary-buildroot/buildroot \
    BR2_EXTERNAL="$PWD/.temporary-buildroot/buildroot-odyssey-reference" \
    stm32mp135d_odyssey_defconfig
```

The last command initializes Buildroot's `.config`; it does not build an
image. Copy only the required reference files into the Yocto layer, for
example:

```bash
mkdir -p layers/meta-odyssey135d/recipes-kernel/linux/files
cp .temporary-buildroot/buildroot-odyssey-reference/board/stm32mp135d-odyssey/configs/linux.config \
   layers/meta-odyssey135d/recipes-kernel/linux/files/linux.config
# The board DTS is already present in the pinned st-linux source tree.  The
# optional Grove DTS is not copied because this image does not use Grove.
```

The Yocto layer contains its own SD-card fragment at
`layers/meta-odyssey135d/recipes-bsp/u-boot/files/fragment-07-odyssey-sdcard.cfg`.
This copied fragment is the only Buildroot U-Boot configuration artifact
needed by the Yocto recipe.

Use `genimage.cfg` only as the reference when writing the Yocto WIC file. Do
not make Yocto depend on `BR2_EXTERNAL`, Buildroot paths, or Buildroot output.
After all required files have been copied and their contents reviewed, remove
the complete temporary checkout:

```bash
rm -rf ~/nb/o/.temporary-buildroot
```

This is the only removal in the procedure and is intentional: the resulting
Yocto build must work without Buildroot being present.

## 7. Confirm the layer layout

The layer was created before the temporary reference files were copied. The
desired structure will eventually look like:

```text
meta-odyssey135d/
├── conf/
│   ├── layer.conf
│   └── machine/
│       └── stm32mp135d-odyssey.conf
├── recipes-bsp/
│   ├── trusted-firmware-a/
│   └── u-boot/
├── recipes-kernel/
│   └── linux/
├── recipes-security/
│   └── optee/
└── wic/
```

---

## 8. Record the working source revisions

Do not keep a Buildroot checkout beside the Yocto layers. Record the exact
source revisions used by the Yocto recipes in the layer README and put copied
board files under `layers/meta-odyssey135d/`.

---

# Part C - Create the machine configuration

## 9. Start from ST's STM32MP13 Discovery machine

Do not create the machine file from scratch. Start from ST's Scarthgap STM32MP13 machine because it already contains the correct STM32MP13 architecture, boot/FIP integration and image classes.

Find it:

```bash
find ~/nb/o/layers/meta-st -name 'stm32mp13-disco.conf'
```

Copy it:

```bash
mkdir -p ~/nb/o/layers/meta-odyssey135d/conf/machine

cp \
    $(find ~/nb/o/layers/meta-st -name 'stm32mp13-disco.conf' | head -1) \
    ~/nb/o/layers/meta-odyssey135d/conf/machine/stm32mp135d-odyssey.conf
```

Edit:

```bash
$EDITOR ~/nb/o/layers/meta-odyssey135d/conf/machine/stm32mp135d-odyssey.conf
```

Keep the STM32MP13 common includes and Cortex-A7 tuning from ST.

Change board-specific DT selections from STM32MP135F-DK to Odyssey.

The important values are conceptually:

```bitbake
# Board identity
MACHINEOVERRIDES =. "stm32mp1common:stm32mp13common:"

# Cortex-A7
DEFAULTTUNE = "cortexa7thf-neon-vfpv4"

# Boot scheme
BOOTSCHEME_LABELS = "optee"
BOOTDEVICE_LABELS = "sdcard"

# Console
SERIAL_CONSOLES = "115200;ttySTM0"
```

Do not blindly remove ST variables that deal with TF-A, FIP, OP-TEE, FlashLayout or STM32 image generation.

The point of copying the ST machine file is to retain that infrastructure.

---

# Part D - Prepare exact source trees

## 10. Clone all four known-working sources

```bash
mkdir -p ~/nb/o/sources
cd ~/nb/o/sources
```

### Linux

```bash
git clone https://github.com/xogium/st-linux.git
cd st-linux
git checkout v6.1-stm32mp-odyssey-r4
cd ..
```

Record the exact commit:

```bash
git -C st-linux rev-parse HEAD
```

### TF-A

```bash
git clone https://git.xogium.me/git/xogium/st-arm-trusted-firmware.git
cd st-arm-trusted-firmware
git checkout v2.8-stm32mp-odyssey-r1
cd ..
```

Record the exact commit:

```bash
git -C st-arm-trusted-firmware rev-parse HEAD
```

### OP-TEE

```bash
git clone https://github.com/GauiStori/optee_os.git
cd optee_os
git checkout b01fad7b7aba97065a2a87794fec9b6d610059a3
cd ..
```

Verify:

```bash
git -C optee_os rev-parse HEAD
```

Expected:

```text
b01fad7b7aba97065a2a87794fec9b6d610059a3
```

### U-Boot

```bash
git clone --branch v2023.10-stm32mp-odyssey \
    https://github.com/GauiStori/u-boot-st.git
cd u-boot-st
git branch --show-current
cd ..
```

Expected:

```text
v2023.10-stm32mp-odyssey
```

Record the resolved branch tip for traceability:

```bash
git -C u-boot-st rev-parse HEAD
```

Record the resolved SHA for traceability, but do not use it as the Yocto
recipe revision; the Buildroot configuration follows the branch.

Verify the U-Boot version:

```bash
grep -E '^(VERSION|PATCHLEVEL|EXTRAVERSION)' u-boot-st/Makefile
```

Expected approximately:

```text
VERSION = 2023
PATCHLEVEL = 10
EXTRAVERSION = -stm32mp-r3.1-rc3
```

---

# Part E - Bring up the Yocto environment

## 11. Initialize the Odyssey machine directly

Do not initialize `stm32mp13-disco`; it is a different board. Initialize the
Odyssey machine directly:

```bash
cd ~/nb/o

DISTRO=openstlinux-weston \
META_LAYER_ROOT=layers \
BUILD_DIR=build-openstlinuxweston-stm32mp135d-odyssey \
MACHINE=stm32mp135d-odyssey \
source layers/meta-st/scripts/envsetup.sh
```

Then check:

```bash
bitbake-layers show-layers
```

---

## 12. Re-enter with the Odyssey machine and the complete layer root

ST's `envsetup.sh` normally searches only `layers/meta-st` for machine files.
The Odyssey machine is in `layers/meta-odyssey135d`, so the default command
fails with:

```text
Not able to find stm32mp135d-odyssey.conf in layers/meta-st
```

Set `META_LAYER_ROOT=layers` so the script searches all layers. It will find
the machine file and add `meta-odyssey135d` to `bblayers.conf` automatically:

```bash
cd ~/nb/o

META_LAYER_ROOT=layers \
BUILD_DIR=build-openstlinuxweston-stm32mp135d-odyssey \
DISTRO=openstlinux-weston \
MACHINE=stm32mp135d-odyssey \
source layers/meta-st/scripts/envsetup.sh
```

Check:

```bash
bitbake-layers show-layers
```

### Re-entering the same build in a new shell

Whenever a new chroot shell is opened, initialize the same build directory
again before using `bitbake` or `bitbake-layers`:

```bash
cd ~/nb/o

META_LAYER_ROOT=layers \
BUILD_DIR=build-openstlinuxweston-stm32mp135d-odyssey \
DISTRO=openstlinux-weston \
MACHINE=stm32mp135d-odyssey \
source layers/meta-st/scripts/envsetup.sh
```

Use the same four values every time for this build. Do not replace the machine
with `stm32mp13-disco`; that is a different board.

---

Verify:

```bash
bitbake -e core-image-minimal | grep '^MACHINE='
```

Expected:

```text
MACHINE="stm32mp135d-odyssey"
```

Also inspect:

```bash
bitbake -e core-image-minimal | grep -E \
'^(DEFAULTTUNE|BOOTSCHEME_LABELS|BOOTDEVICE_LABELS|SERIAL_CONSOLES)='
```

---

# Part F - Integrate U-Boot first

## 13. Why U-Boot is the easiest firmware component to start with

Scarthgap already uses the U-Boot 2023.10 generation, and the known-working Odyssey fork is also based on 2023.10.

The layer contains:

```text
meta-odyssey135d/recipes-bsp/u-boot/u-boot-stm32mp_2023.10.bbappend
```

A practical first override is:

```bitbake
SRC_URI = "git://github.com/GauiStori/u-boot-st.git;protocol=https;branch=v2023.10-stm32mp-odyssey"
SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git"
```

This intentionally follows the moving `v2023.10-stm32mp-odyssey` branch, as
the Buildroot defconfig does. If reproducible releases are required later,
record the resolved SHA and replace `${AUTOREV}` with that SHA at release
time.

The board must use:

```text
stm32mp13_defconfig
DEVICE_TREE=stm32mp135d-odyssey
```

The SD-card fragment is stored directly in the custom layer. Verify it exists;
do not copy the eMMC fragment for this SD-card procedure:

```bash
test -f ~/nb/o/layers/meta-odyssey135d/recipes-bsp/u-boot/files/fragment-07-odyssey-sdcard.cfg
```

Then extend the `.bbappend`:

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " file://fragment-07-odyssey-sdcard.cfg;subdir=fragments/features"
```

ST's U-Boot recipe already has its own fragment mechanism. Inspect the effective variables first:

```bash
bitbake -e u-boot-stm32mp | grep -i fragment
```

The `*.cfg` fragment is merged automatically by ST's U-Boot recipe because it
is placed under `fragments/features`. Do not use a `.fragment` filename here;
the recipe only discovers configuration fragments with the `.cfg` suffix.

Build only U-Boot:

```bash
bitbake -c clean u-boot-stm32mp
bitbake u-boot-stm32mp
```

Verify that the source really came from the Gudjon fork:

```bash
bitbake -e u-boot-stm32mp | grep -E '^(SRC_URI|SRCREV|S)='
```

Verify the Odyssey U-Boot DTs in the deploy directory:

```bash
find tmp*/deploy/images/stm32mp135d-odyssey/u-boot \
    -name 'u-boot-stm32mp135d-odyssey-*.dtb' -print
```

Expected at least:

```text
u-boot-stm32mp135d-odyssey-default.dtb
u-boot-stm32mp135d-odyssey-programmer.dtb
```

Do not continue until U-Boot builds.

---

# Part G - Integrate OP-TEE

## 14. Override Scarthgap OP-TEE with the known-working fork

Scarthgap uses OP-TEE 4.0.0 for STM32MP, which is close to the generation of the working Gudjon fork.

The layer contains:

```text
meta-odyssey135d/recipes-security/optee/optee-os-stm32mp_4.0.0.bbappend
```

Its source selection is:

```bitbake
SRC_URI = "git://github.com/GauiStori/optee_os.git;protocol=https;branch=master"
SRCREV = "b01fad7b7aba97065a2a87794fec9b6d610059a3"
S = "${WORKDIR}/git"
```

Set the STM32 platform:

```bitbake
OPTEEMACHINE = "stm32mp1"
```

The Buildroot configuration also requires the board flavor:

```text
PLATFORM_FLAVOR=135D_ODYSSEY
```

The append supplies the platform-specific make variables. Inspect the
effective values before building:

```bash
bitbake -e optee-os-stm32mp | grep -E \
'OPTEE|PLATFORM|EXTRA_OEMAKE'
```

The effective values should include:

```text
PLATFORM=stm32mp1
PLATFORM_FLAVOR=135D_ODYSSEY
CFG_WITH_TUI=n
CFG_TEE_CORE_LOG_LEVEL=0
CFG_TEE_TA_LOG_LEVEL=0
```

using ST's existing recipe variables.

Build OP-TEE only:

```bash
bitbake -c clean optee-os-stm32mp
bitbake optee-os-stm32mp
```

Verify these files are produced:

```bash
find tmp* \( \
    -name 'tee-header_v2.bin' -o \
    -name 'tee-pager_v2.bin' -o \
    -name 'tee-pageable_v2.bin' \
\)
```

Do not continue until they exist.

---

# Part H - Integrate Linux 6.1

## 15. Do not force the Odyssey 6.1 DTS into Scarthgap Linux 6.6

This was one of the main problems in the previous attempt.

The Buildroot configuration uses:

```text
Linux source: v6.1-stm32mp-odyssey-r4
DTS:          stm32mp135d-odyssey.dts
```

Use that source for the first Yocto boot.

Scarthgap normally selects `linux-stm32mp_6.6`. Do not simply add the 6.1 DTS to the Scarthgap 6.6 tree and fix compiler errors one by one.

Create a separate recipe in the Odyssey layer named, for example:

```text
meta-odyssey135d/recipes-kernel/linux/linux-odyssey_6.1.bb
```

Use ST's `linux-stm32mp` recipe as the structural reference, but use the complete known-working source tree and configuration.

The key source settings are:

```bitbake
SUMMARY = "Known-working STM32MP135D Odyssey Linux kernel"

SRC_URI = "git://github.com/xogium/st-linux.git;protocol=https;nobranch=1"
SRCREV = "v6.1-stm32mp-odyssey-r4"
S = "${WORKDIR}/git"

LINUX_VERSION = "6.1"
```

Determine the exact commit once:

```bash
git -C ~/nb/o/sources/st-linux rev-parse v6.1-stm32mp-odyssey-r4^{commit}
```

Put that SHA into `SRCREV`.

The complete known-working kernel configuration and DTS are committed in the
Odyssey layer; they are not read from Buildroot during a Yocto build.
Verify that they are now independent of Buildroot:

```bash
test -f ~/nb/o/layers/meta-odyssey135d/recipes-kernel/linux/files/linux.config
test -f ~/nb/o/sources/st-linux/arch/arm/boot/dts/stm32mp135d-odyssey.dts
```

For the first bring-up it is acceptable either to:

1. use the DTS already present in the known-working kernel tree if it is identical, or
2. copy the Buildroot DTS into the kernel source during `do_configure:prepend()`.

Prefer option 1 if possible.

Select the custom kernel provider from the machine configuration:

```bitbake
PREFERRED_PROVIDER_virtual/kernel = "linux-odyssey"
PREFERRED_VERSION_linux-odyssey = "6.1%"
```

Build only the kernel:

```bash
bitbake -c clean linux-odyssey
bitbake linux-odyssey
```

Verify:

```bash
find tmp* -name 'zImage' -o -name 'stm32mp135d-odyssey.dtb'
```

Do not continue until both are produced.

---

# Part I - Integrate TF-A 2.8

## 16. Keep the known-working TF-A initially

Scarthgap normally uses TF-A 2.10, but the Buildroot Odyssey configuration uses:

```text
v2.8-stm32mp-odyssey-r1
```

For the first boot, preserve that exact firmware because TF-A contains board-specific STM32MP boot details and the FIP construction depends on it.

The Odyssey layer now provides:

```text
meta-odyssey135d/recipes-bsp/trusted-firmware-a/tf-a-stm32mp_2.8.bb
```

Use ST's `tf-a-stm32mp` recipe as the structural reference, but set:

```bitbake
SRC_URI = "git://git.xogium.me/git/xogium/st-arm-trusted-firmware.git;protocol=https;nobranch=1"
SRCREV = "v2.8-stm32mp-odyssey-r1"
S = "${WORKDIR}/git"

TFA_PLATFORM = "stm32mp1"
```

The tag is the same version selected by Buildroot:

```bash
git -C ~/nb/o/sources/st-arm-trusted-firmware \
    rev-parse v2.8-stm32mp-odyssey-r1^{commit}
```

The effective TF-A make arguments must contain the equivalent of:

```text
PLAT=stm32mp1
STM32MP_EMMC=1
STM32MP_EMMC_BOOT=1
STM32MP_SDMMC=1
AARCH32_SP=optee
DTB_FILE_NAME=stm32mp135d-odyssey.dtb
STM32MP_USB_PROGRAMMER=1
```

and FIP generation must use:

```text
BL32 = OP-TEE
BL33 = U-Boot
BL33_CFG = u-boot.dtb
```

The final deploy output needs:

```text
tf-a-stm32mp135d-odyssey.stm32
fip.bin
```

The machine selects this recipe with `PREFERRED_VERSION_tf-a-stm32mp = "2.8"`.
`EXTERNAL_DT_ENABLED = "0"` also makes TF-A use the board DT shipped in the
pinned source tree, just as Buildroot does.

Inspect the standard machine first:

```bash
bitbake -e tf-a-stm32mp | grep -E \
'^(PROVIDES|PREFERRED_PROVIDER|TFA_|TF_A_|EXTRA_OEMAKE)'
```

Then build TF-A only.

---

# Part J - Reproduce the SD partition layout

## 17. Create an Odyssey WIC file

We want the same partition numbering as the working Buildroot image.

The resulting GPT must be:

```text
p1  fsbl1       1 MiB
p2  fsbl2       1 MiB
p3  fip         4 MiB
p4  u-boot-env  2 MiB
p5  rootfs
```

This matters because U-Boot currently boots:

```text
root=/dev/mmcblk0p5
```

Create:

```bash
mkdir -p ~/nb/o/layers/meta-odyssey135d/wic
```

Then create:

```text
meta-odyssey135d/wic/stm32mp135d-odyssey.wks.in
```

Use ST's STM32MP13 WIC/FlashLayout files as the syntax reference, but preserve the Buildroot offsets and partition order.

Do not invent new UUIDs or boot offsets if ST's existing STM32MP WIC helper already handles STM32 FSBL/FIP partitions. Reuse the ST mechanism where possible.

The first image must result in rootfs being partition 5.

After generating the image, always verify with:

```bash
sgdisk -p <image.wic>
```

or after writing the card:

```bash
lsblk -o NAME,SIZE,FSTYPE,PARTLABEL /dev/sdX
```

---

# Part K - Minimal root filesystem

## 18. Use `core-image-minimal` for the minimal image

`core-image-minimal` is the correct minimal Yocto image recipe for this
machine. However, the image recipe alone does not make a bootable Odyssey
SD-card image. The machine layer must first select the Odyssey kernel/DT,
U-Boot, OP-TEE, TF-A and WIC configuration described in the following
sections.

With the layer in its current scaffolded state, `core-image-minimal` only
validates the minimal root filesystem and may use ST's default providers or
Discovery board settings. Do not flash its output or call it a working
Odyssey image until these checks show the custom components:

```bash
bitbake -e core-image-minimal | grep -E \
'^(MACHINE|PREFERRED_PROVIDER_virtual/kernel|KERNEL_DEVICETREE|IMAGE_FSTYPES)='
```

The expected result must include the Odyssey machine and DTB, the custom
kernel provider, and eventually `wic` after the Odyssey WIC file is enabled.

For first boot, keep userspace minimal.

Do not add `openssh`, `i2c-tools`, `strace`, systemd overrides, or application
packages yet. Do not build `st-image-weston` or another OpenSTLinux desktop
image. The `openstlinux-weston` distro name selects ST's distro policy; it does
not make `core-image-minimal` a Weston image.

Confirm that the target parses without starting a build:

```bash
bitbake -p core-image-minimal
```

Build:

```bash
bitbake core-image-minimal
```

---

# Part L - Verify deploy artifacts

## 19. Inspect deploy directory

```bash
find tmp* -path '*deploy/images/stm32mp135d-odyssey*' -maxdepth 1 -type f | sort
```

At minimum we want equivalents of:

```text
tf-a-stm32mp135d-odyssey.stm32
fip.bin
zImage
stm32mp135d-odyssey.dtb
core-image-minimal-*.ext4
core-image-minimal-*.wic
```

Also make sure the rootfs contains the kernel and DTB where the Buildroot U-Boot command expects them:

```text
/boot/zImage
/boot/stm32mp135d-odyssey.dtb
```

If Yocto deploys them somewhere else, either install them into `/boot` or later replace the fixed U-Boot `CONFIG_BOOTCOMMAND` with `extlinux`.

For the first boot, preserving the working Buildroot command is simpler.

---

# Part M - Write SD card

## 20. Write the WIC image

Assuming the SD card is `/dev/sdb`:

```bash
sudo umount /dev/sdb?* 2>/dev/null || true
```

Then:

```bash
sudo dd \
    if=<path-to-core-image-minimal.wic> \
    of=/dev/sdb \
    bs=8M \
    conv=fsync \
    status=progress
```

Then:

```bash
sync
sudo sgdisk -v /dev/sdb
lsblk -o NAME,SIZE,FSTYPE,PARTLABEL /dev/sdb
```

Verify that rootfs is `/dev/sdb5`.

---

# Part N - First boot

## 21. Serial console

Use the same serial port that works with Buildroot:

```text
115200 baud
8 data bits
no parity
1 stop bit
```

For example:

```bash
picocom -b 115200 /dev/ttyUSB0
```

Expected boot sequence:

```text
NOTICE: CPU: STM32MP135D
...
OP-TEE
...
U-Boot 2023.10...
...
Starting kernel ...
...
ttySTM0
...
login:
```

---

# Part O - Debug one stage at a time

## 22. If the board does not boot

Do not change multiple components at once.

Use the last visible stage:

```text
No serial output
  -> ROM / TF-A / UART / SD layout

TF-A output but no OP-TEE
  -> FIP / BL32 / OP-TEE platform flavor

OP-TEE output but no U-Boot
  -> FIP / BL33 / U-Boot binary / U-Boot DT

U-Boot starts but cannot load files
  -> partition numbering / ext4 / /boot paths

"Starting kernel ..." then nothing
  -> kernel DT / console / load address

Kernel starts but cannot mount root
  -> root=/dev/mmcblk0p5 / rootfs partition / filesystem driver

Login prompt appears
  -> first milestone complete
```

Useful inspection commands:

```bash
bitbake -e u-boot-stm32mp | grep -E '^(SRC_URI|SRCREV|S|PV)='

bitbake -e optee-os-stm32mp | grep -E '^(SRC_URI|SRCREV|S|PV)='

bitbake -e virtual/kernel | grep -E '^(PN|PV|SRC_URI|SRCREV|S)='

bitbake -e virtual/trusted-firmware-a | grep -E '^(PN|PV|SRC_URI|SRCREV|S)='
```

The values shown by `bitbake -e` are the truth. Do not rely only on what is written in a `.conf` or `.bbappend` file.

---

# Part P - Recommended bring-up order

Use this order exactly:

```text
1. Install official OpenSTLinux Scarthgap in the Bookworm chroot
2. Create the Yocto layer
3. Use Buildroot's Makefile only for the temporary defconfig/reference step
4. Copy the required files into meta-odyssey135d and remove Buildroot
5. Create stm32mp135d-odyssey machine
6. Verify stm32mp13-disco and the custom machine parse
7. Build custom U-Boot 2023.10
8. Build custom OP-TEE
9. Build known-working Linux 6.1
10. Build known-working TF-A 2.8
11. Verify fip.bin
12. Create SD layout with rootfs as partition 5
13. Build core-image-minimal
14. Write SD card
15. Boot to ttySTM0 login
```

Do not begin by building the complete image. Build each firmware component separately so failures are isolated.

---

# Part Q - What to save in Git

Commit the board-specific Yocto layer only:

```text
layers/meta-odyssey135d/
├── conf/
├── recipes-bsp/
├── recipes-kernel/
├── recipes-security/
├── recipes-example/        # remove the generated example if unused
├── wic/
├── README
└── COPYING.MIT
```

Before committing, remove the generated example recipe if it is not used and
check that no recipe refers to `.temporary-buildroot`, `buildroot-odyssey-reference`,
`BR2_EXTERNAL`, `build-odyssey`, `tmp`, `downloads` or `sstate-cache`.

The following are local/generated and must stay outside Git:

```text
build-odyssey/
downloads/
sstate-cache/
tmp*/
sources/
.temporary-buildroot/
```

The layer is the Yocto project deliverable. The Buildroot checkout is not a
submodule and must not be required to parse or build the Yocto image.

# Part R - What to modernize later

Only after the exact Buildroot-equivalent boot chain works under Yocto should the BSP be modernized.

Recommended order:

```text
1. Keep U-Boot on the current working Gudjon 2023.10 branch initially.
2. Keep OP-TEE at the current working Gudjon commit initially.
3. Move TF-A from Odyssey 2.8 to Scarthgap TF-A 2.10.
4. Move Linux from Odyssey 6.1 to ST Scarthgap Linux 6.6.
5. Replace fixed U-Boot boot command with extlinux if desired.
6. Add eMMC boot.
7. Add production packages and application layer.
```

Change only one boot-chain component at a time and keep a bootable tag after each successful step.

---

# References

## Working Buildroot branch

`https://github.com/GauiStori/buildroot-stm32mp135d-odyssey/tree/odyssey-2023-10`

Raw defconfig:

`https://raw.githubusercontent.com/GauiStori/buildroot-stm32mp135d-odyssey/odyssey-2023-10/configs/stm32mp135d_odyssey_defconfig`

U-Boot fragment:

`https://raw.githubusercontent.com/GauiStori/buildroot-stm32mp135d-odyssey/odyssey-2023-10/board/stm32mp135d-odyssey/configs/uboot-sdcard.fragment`

SD-card layout:

`https://raw.githubusercontent.com/GauiStori/buildroot-stm32mp135d-odyssey/odyssey-2023-10/board/stm32mp135d-odyssey/utilities/genimage.cfg`

## Working fork references

U-Boot:

`https://github.com/GauiStori/u-boot-st/tree/v2023.10-stm32mp-odyssey`

OP-TEE:

`https://github.com/GauiStori/optee_os/commit/b01fad7b7aba97065a2a87794fec9b6d610059a3`

## OpenSTLinux Scarthgap

Manifest repository:

`https://github.com/STMicroelectronics/oe-manifest`

Scarthgap STM32MP BSP:

`https://github.com/STMicroelectronics/meta-st-stm32mp/tree/scarthgap`

OpenSTLinux environment initialization uses:

```bash
DISTRO=openstlinux-weston MACHINE=<machine> source layers/meta-st/scripts/envsetup.sh
```

---

## Important note

This document deliberately treats the `odyssey-2023-10` Buildroot branch as the known-working board reference.

The exact source set is therefore mixed-generation by design:

```text
TF-A:    Odyssey/ST 2.8 generation
OP-TEE:  Gudjon ST fork, exact commit b01fad7...
U-Boot:  Gudjon ST fork, 2023.10 generation, branch v2023.10-stm32mp-odyssey
Linux:   Odyssey/ST 6.1 generation
Yocto:   Scarthgap
```

That is preferable for first bring-up to combining an Odyssey device tree from one BSP generation with unrelated firmware trees from another. Once the image boots, the old components can be moved toward native Scarthgap versions one at a time.
