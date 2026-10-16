# STM32MP135D Odyssey Yocto build

## Prerequisites

Debian (tested on Debian unstable)
apt install  chrpath diffstat rpcsvc-proto

This repository contains the board-specific Yocto metadata for the Seeed
STM32MP135D Odyssey. Build it inside the Debian Bookworm chroot.

## Workspace setup

Create or use a workspace containing the OpenEmbedded and ST layers. `repo` is
optional; BitBake does not require it. It is only a tool for synchronising a
set of Git repositories. For Wrynose, the ST manifest reference may not exist,
so the repositories can be checked out with normal Git commands instead.

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

Also check out the matching Wrynose versions of BitBake and meta-openembedded.
The ST `meta-st-openstlinux` repository currently has no Wrynose branch, so it
is deliberately not used here. This Wrynose setup uses the standard
`DISTRO=odyssey-wrynose` configuration. The `meta-st-scripts` checkout provides
`layers/meta-st/scripts/envsetup.sh`; it currently has no Wrynose branch, so
use its available `scarthgap` tooling branch.

Do not mix Scarthgap and Wrynose branches. For a reproducible checkout, record
the commit ID of every layer after cloning; branch names can move.

If a repository already exists, verify it instead of cloning it again:

```bash
git -C layers/meta-st/meta-st-stm32mp branch --show-current
git -C layers/meta-st/meta-st-stm32mp status --short
```

If the working tree is clean and it is on the wrong branch, switch it with:

```bash
git -C layers/meta-st/meta-st-stm32mp fetch origin wrynose_v26.02.18
git -C layers/meta-st/meta-st-stm32mp switch wrynose_v26.02.18
```

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
directory so they survive cleanup of `build-*` or `tmp-glibc`.

The custom board metadata is independent of the repository-management method:

```text
odyssey-yocto/meta-odyssey135d/
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

## Cleaning without downloading again

To reconstruct the build while preserving downloaded sources and shared-state
artifacts, remove only the temporary output:

```bash
rm -rf build-odyssey-wrynose-stm32mp135d-odyssey/tmp-glibc
```

Do not remove `downloads/` unless all source archives and Git mirrors may be
downloaded again. Remove `sstate-cache/` only when a complete rebuild from
source is required.

## Git contents

Commit this repository, including:

```text
odyssey-yocto/
```

Do not commit Yocto build output, downloaded sources, shared-state cache,
temporary source checkouts, generated images, or the upstream OpenEmbedded/ST
layer checkouts. Manage those upstream checkouts separately with Git.
