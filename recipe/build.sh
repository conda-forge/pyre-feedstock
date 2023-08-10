#!/bin/sh
set -euo pipefail

# Workaround for leftover build directory paths in HDF5 installation
# https://github.com/HDFGroup/hdf5/issues/2422
sed -i.tmp 's/-I.*H5FDsubfiling//' \
    "$(which h5cc)" \
    "$(which h5c++)"

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
cmake ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DPYRE_DEST_PACKAGES=$SP_DIR \
    -DPython_EXECUTABLE=$PYTHON \
    -DPYRE_VERSION=$PKG_VERSION \
    $SRC_DIR

cmake --build . --target install -j${CPU_COUNT}
