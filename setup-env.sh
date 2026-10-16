#!/bin/sh

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
ODYSSEY_BUILD_DIR=${BUILD_DIR:-build-odyssey-wrynose-stm32mp135d-odyssey}

cd "$YOCTO_ROOT"
if [ ! -f "$YOCTO_ROOT/layers/meta-st/scripts/envsetup.sh" ]; then
    echo "ERROR: missing layers/meta-st/scripts/envsetup.sh" >&2
    echo "Clone STMicroelectronics/meta-st-scripts into layers/meta-st/scripts" >&2
    exit 1
fi
if [ ! -d "$YOCTO_ROOT/layers/openembedded-core" ] && [ ! -d "$YOCTO_ROOT/layers/poky" ]; then
    echo "ERROR: missing OpenEmbedded-Core checkout" >&2
    echo "Create layers/openembedded-core (or layers/poky) on the Wrynose release" >&2
    exit 1
fi
if [ ! -d "$YOCTO_ROOT/layers/bitbake" ]; then
    echo "ERROR: missing BitBake checkout" >&2
    echo "Create layers/bitbake from the BitBake branch matching OpenEmbedded-Core (2.18 for Wrynose)" >&2
    exit 1
fi
if [ ! -d "$YOCTO_ROOT/layers/meta-openembedded" ]; then
    echo "ERROR: missing meta-openembedded checkout" >&2
    echo "Create layers/meta-openembedded on the Wrynose branch" >&2
    exit 1
fi
DISTRO=${DISTRO:-odyssey-wrynose} \
META_LAYER_ROOT=${META_LAYER_ROOT:-.} \
BSP_DEPENDENCY="layers/meta-st/meta-st-stm32mp odyssey-yocto/meta-odyssey135d" \
TEMPLATECONF="$YOCTO_ROOT/layers/openembedded-core/meta/conf/templates/default" \
BUILD_DIR=$ODYSSEY_BUILD_DIR \
MACHINE=${MACHINE:-stm32mp135d-odyssey} \
  . layers/meta-st/scripts/envsetup.sh
ENVSETUP_STATUS=$?
if [ "$ENVSETUP_STATUS" -ne 0 ]; then
    echo "ERROR: ST environment setup failed" >&2
    return "$ENVSETUP_STATUS"
fi

# ST's template does not consume odyssey-yocto/conf/local.conf.sample. Apply
# the shared cache locations after ST regenerates the build configuration.
BUILD_CONF="$YOCTO_ROOT/$ODYSSEY_BUILD_DIR/conf/local.conf"
if [ -f "$BUILD_CONF" ]; then
    sed -i '/^[[:space:]]*DL_DIR[[:space:]]*=/d; /^[[:space:]]*SSTATE_DIR[[:space:]]*=/d' "$BUILD_CONF"
    sed -i '/^DISTRO[[:space:]]*=/a DL_DIR = "${TOPDIR}/../downloads"' "$BUILD_CONF"
    sed -i '/^[[:space:]]*DL_DIR[[:space:]]*=/a SSTATE_DIR = "${TOPDIR}/../sstate-cache"' "$BUILD_CONF"
fi

