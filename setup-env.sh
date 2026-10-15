#!/bin/sh
set -e

if [ -n "${BASH_SOURCE:-}" ]; then
    SCRIPT_PATH=${BASH_SOURCE[0]}
else
    SCRIPT_PATH=$0
fi
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)
# Always derive the workspace root from this script.  ST's envsetup exports
# YOCTO_ROOT, and reusing that stale value can point the next invocation at
# the build directory instead of the workspace.
YOCTO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
ODYSSEY_BUILD_DIR=${BUILD_DIR:-build-openstlinuxweston-stm32mp135d-odyssey}

cd "$YOCTO_ROOT"
DISTRO=${DISTRO:-openstlinux-weston} \
META_LAYER_ROOT=${META_LAYER_ROOT:-.} \
BSP_DEPENDENCY=odyssey-yocto/meta-odyssey135d \
BUILD_DIR=$ODYSSEY_BUILD_DIR \
MACHINE=${MACHINE:-stm32mp135d-odyssey} \
  . layers/meta-st/scripts/envsetup.sh

# ST's template does not consume odyssey-yocto/conf/local.conf.sample. Apply
# the shared cache locations after ST regenerates the build configuration.
BUILD_CONF="$YOCTO_ROOT/$ODYSSEY_BUILD_DIR/conf/local.conf"
if [ -f "$BUILD_CONF" ]; then
    sed -i '/^[[:space:]]*DL_DIR[[:space:]]*=/d; /^[[:space:]]*SSTATE_DIR[[:space:]]*=/d' "$BUILD_CONF"
    sed -i '/^DISTRO[[:space:]]*=/a DL_DIR = "${TOPDIR}/../downloads"' "$BUILD_CONF"
    sed -i '/^[[:space:]]*DL_DIR[[:space:]]*=/a SSTATE_DIR = "${TOPDIR}/../sstate-cache"' "$BUILD_CONF"
fi

