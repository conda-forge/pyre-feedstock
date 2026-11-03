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

# when cross-compiling, point cmake at the headers of the target's python; under the policies
# pyre's cmake asks for, FindPython in cmake 4.4.5 looks for them where the build's own python
# keeps its headers
if [ "${CONDA_BUILD_CROSS_COMPILATION:-0}" = "1" ]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DPython_INCLUDE_DIR=${PREFIX}/include/python${PY_VER}"
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
