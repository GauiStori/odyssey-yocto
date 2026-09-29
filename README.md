# STM32MP135D Odyssey Yocto metadata

**NOTICE** This build is not tested yet

This directory is the Git-controlled board-specific part of the Yocto
project. It is independent of Buildroot. The Buildroot kernel configuration
was copied into `meta-odyssey135d/recipes-kernel/linux/files/linux.config`.

Keep this directory in Git. Do not commit Yocto build output, downloads,
sstate, or temporary source checkouts.

The upstream OpenEmbedded/ST layers are expected beside this directory under
the Yocto workspace, for example:

```text
workspace/
  layers/openembedded-core
  layers/meta-openembedded
  layers/meta-st
  odyssey-yocto-git/
```

Initialize or re-enter the environment from the workspace root:

```bash
DISTRO=openstlinux-weston \
META_LAYER_ROOT=odyssey-yocto-git \
BUILD_DIR=build-openstlinuxweston-stm32mp135d-odyssey \
MACHINE=stm32mp135d-odyssey \
source layers/meta-st/scripts/envsetup.sh
```

Then build the minimal image:

```bash
bitbake core-image-minimal
```

See `sources.lock` for the source revisions selected by the recipes.

