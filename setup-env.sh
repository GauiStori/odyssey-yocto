#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
YOCTO_ROOT=${YOCTO_ROOT:-$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)}

cd "$YOCTO_ROOT"
DISTRO=${DISTRO:-openstlinux-weston} \
META_LAYER_ROOT=${META_LAYER_ROOT:-odyssey-yocto-git} \
BUILD_DIR=${BUILD_DIR:-build-openstlinuxweston-stm32mp135d-odyssey} \
MACHINE=${MACHINE:-stm32mp135d-odyssey} \
  . layers/meta-st/scripts/envsetup.sh

