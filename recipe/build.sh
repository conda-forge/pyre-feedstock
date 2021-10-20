#!/bin/sh
set -euo pipefail

if [ `uname` = "Darwin" ]; then
    # Use specified macOS SDK, and enforce minimum version
    export CXXFLAGS="$CXXFLAGS -isysroot $CONDA_BUILD_SYSROOT"
else
    # Remove after resolving https://github.com/pyre/pyre/issues/64
    export LDFLAGS="-lrt $LDFLAGS"
fi

mkdir build && cd build

# Override LIBDIR from GNUInstallDirs - would be lib64 on centos
# Specify $PYTHON to avoid using system python
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DPYRE_DEST_PACKAGES=$SP_DIR \
    -DPython_EXECUTABLE=$PYTHON \
    -DPYRE_VERSION=$PKG_VERSION \
    $SRC_DIR

cmake --build . --target install -j${CPU_COUNT}

# Disable TCP test on Docker
# Reenable locale_codec after resolving https://github.com/pyre/pyre/issues/65
ctest \
    -E '(pyre.pkg.ipc.tcp.py|python.locale_codec.py|pyre.pkg.codecs.yaml_|pyre.lib.timers.process_timer|pyre.pkg.timers)' \
    --output-on-failure
