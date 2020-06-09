#!/bin/bash

# We let PREFIX being expanded everywhere in the script.
# conda will automatically replace it during installation.
# Note that this isn't true for BUILD_PREFIX.
EPICS_BASE="$PREFIX/epics"
EPICS_HOST_ARCH=$(perl src/tools/EpicsHostArch.pl)

cat << EOF >> configure/CONFIG_SITE.local
INSTALL_LOCATION=${EPICS_BASE}
MSI=\$(EPICS_BASE)/bin/\$(EPICS_HOST_ARCH)/msi
EOF

cat << EOF >> configure/os/CONFIG_SITE.Common.linux-x86_64
# Set GNU_DIR to BUILD_PREFIX or PREFIX if not set (when not using conda-build)
# Allow to compile without conda-build by installing manually the compilers
# in a local conda environment
GNU_DIR = \$(or \$(BUILD_PREFIX),$PREFIX)
CMPLR_PREFIX = x86_64-conda_cos6-linux-gnu-

# --disable-new-dtags is required to avoid LD_LIBRARY_PATH overrride RPATH settings
OP_SYS_LDFLAGS += -Wl,--disable-new-dtags -Wl,-rpath,${PREFIX}/lib -Wl,-rpath-link,${PREFIX}/lib -L${PREFIX}/lib -Wl,-rpath-link,${EPICS_BASE}/lib/linux-x86_64
OP_SYS_INCLUDES += -I${PREFIX}/include
EOF

cat << EOF >> configure/os/CONFIG_SITE.Common.darwin-x86
GNU_DIR = \$(or \$(BUILD_PREFIX),$PREFIX)
CMPLR_PREFIX = x86_64-apple-darwin13.4.0-
CMPLR_CLASS = clang
CC = x86_64-apple-darwin13.4.0-clang
CCC = x86_64-apple-darwin13.4.0-clang++

OP_SYS_CFLAGS += -isysroot \${CONDA_BUILD_SYSROOT} -mmacosx-version-min=\${MACOSX_DEPLOYMENT_TARGET}
OP_SYS_CXXFLAGS += -isysroot \${CONDA_BUILD_SYSROOT} -mmacosx-version-min=\${MACOSX_DEPLOYMENT_TARGET}
OP_SYS_LDFLAGS += -Wl,-rpath,${PREFIX}/lib -L${PREFIX}/lib
OP_SYS_INCLUDES += -I${PREFIX}/include
EOF

# Compile epics-base
# Build fails when using -j${CPU_COUNT} (at least with 7.0.2.1)
make

# Create files to set/unset variables when running
# activate/deactivate

# Note that modifying the PATH in deactivate scripts require conda >= 4.7
mkdir -p $PREFIX/etc/conda/activate.d
cat <<EOF > $PREFIX/etc/conda/activate.d/epics-base_activate.sh
export EPICS_BASE="$EPICS_BASE"
export EPICS_HOST_ARCH="$EPICS_HOST_ARCH"
export EPICS_BASE_HOST_BIN="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}"
export EPICS_BASE_VERSION="${PKG_VERSION}"
export PATH=\$EPICS_BASE_HOST_BIN:\$PATH
EOF

mkdir -p $PREFIX/etc/conda/deactivate.d
cat <<EOF > $PREFIX/etc/conda/deactivate.d/epics-base_deactivate.sh
unset EPICS_BASE
unset EPICS_HOST_ARCH
unset EPICS_BASE_VERSION
export PATH=\$(echo \$PATH | sed "s?\$EPICS_BASE_HOST_BIN:??")
unset EPICS_BASE_HOST_BIN
EOF
