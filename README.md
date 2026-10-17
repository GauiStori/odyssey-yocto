# STM32MP135D Odyssey Yocto Wrynose build

## Prerequisites

Debian. Tested on Debian unstable but please use distros recommended by
Yocto.
```bash
apt install  chrpath diffstat rpcsvc-proto
```
This repository contains the board-specific Yocto metadata for the Seeed
STM32MP135D Odyssey.

## Workspace setup

The STM32MP layer has the Wrynose branch `wrynose_v26.02.18`:

```bash
export YOCTO_ROOT=<my yocto root dir>
cd "$YOCTO_ROOT"
mkdir -p layers/meta-st

if [ ! -d layers/openembedded-core/.git ]; then
    git clone --branch wrynose \
        https://github.com/openembedded/openembedded-core.git \
        layers/openembedded-core
fi

if [ ! -d layers/bitbake/.git ]; then
    # Wrynose uses the BitBake 2.18 release branch.
    git clone --branch 2.18 \
        https://github.com/openembedded/bitbake.git \
        layers/bitbake
fi

if [ ! -d layers/meta-openembedded/.git ]; then
    git clone --branch wrynose \
        https://github.com/openembedded/meta-openembedded.git \
        layers/meta-openembedded
fi

if [ ! -d layers/meta-st/scripts/.git ]; then
    # meta-st-scripts currently has no Wrynose branch. The script is tooling;
    # use its available Scarthgap branch.
    git clone --branch scarthgap \
        https://github.com/STMicroelectronics/meta-st-scripts.git \
        layers/meta-st/scripts
fi

if [ ! -d layers/meta-st/meta-st-stm32mp/.git ]; then
    git clone --branch wrynose_v26.02.18 \
        https://github.com/STMicroelectronics/meta-st-stm32mp.git \
        layers/meta-st/meta-st-stm32mp
fi

```

## Initialize the environment

From the workspace root:

```bash
cd "$YOCTO_ROOT"
DISTRO=nodistro MACHINE=stm32mp135d-odyssey \
    source odyssey-yocto/setup-env.sh
```

The script selects:

```text
MACHINE: stm32mp135d-odyssey
DISTRO:  odyssey-wrynose
DL_DIR:  ${YOCTO_ROOT}/downloads
SSTATE_DIR: ${YOCTO_ROOT}/sstate-cache
```

Run the same command when re-entering an existing build environment. Do not
source the environment with a different machine into the same build directory.

The expected layout is:

```text
YOCTO_ROOT/
├── layers/
│   ├── openembedded-core/
│   ├── meta-openembedded/
│   └── meta-st/
├── odyssey-yocto/
├── downloads/
└── sstate-cache/
```

The `downloads/` and `sstate-cache/` directories are shared outside the build
directory so they survive cleanup of `build-*` or `tmp-glibc`. Check the directories with
```bash
bitbake -e core-image-minimal | grep -E '^(DL_DIR|SSTATE_DIR)='
```

The custom board metadata is independent of the repository-management method:

```text
odyssey-yocto/meta-odyssey135d/
```

## Build

Build the minimal image:

```bash
bitbake core-image-minimal
```

The WIC image is generated under:

```text
build-odyssey-wrynose-stm32mp135d-odyssey/tmp-glibc/deploy/images/stm32mp135d-odyssey/
```

Use the newest timestamped `.wic` file when flashing the SD card.


