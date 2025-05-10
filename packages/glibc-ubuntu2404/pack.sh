#!/bin/bash
set -e

DEB_DOWNLOAD_DIR=$(realpath "$(pwd)/../../")
OUTPUT_DIR=${DEB_DOWNLOAD_DIR}/output
SYSROOT_DIR=${OUTPUT_DIR}/sysroot

PACKAGES=("libc-bin" "libstdc++6")
export DOCKER_TAG=ubuntu2404

TAR_NAME="glibc-ubuntu2404.tar.xz"
TAR_PATH="$OUTPUT_DIR/$TAR_NAME"

if ! mkdir -p "$OUTPUT_DIR"; then
    echo "Error: Failed to create output directory" >&2
    exit 1
fi
if ! mkdir -p "$SYSROOT_DIR"; then
    echo "Error: Failed to create sysroot directory" >&2
    exit 1
fi


pushd . || { echo "pushd failed" >&2; exit 1; }
cd $DEB_DOWNLOAD_DIR || { echo "cd to $DEB_DOWNLOAD_DIR failed" >&2; exit 1; }

if ! make clean; then
    echo "Warning: make clean failed, retrying with sudo..." >&2
    if ! sudo make clean; then
        echo "Error: sudo make clean also failed" >&2
        exit 1
    fi
fi

for PACKAGE in "${PACKAGES[@]}"; do
    export PACKAGE_NAME=$PACKAGE
if ! make download; then
        echo "Error: make download failed for $PACKAGE" >&2
    exit 1
fi
done

if ! make unpack; then
    echo "Error: make unpack failed" >&2
    exit 1
fi

pushd . || { echo "pushd failed" >&2; exit 1; }
cd $SYSROOT_DIR || { echo "cd to $SYSROOT_DIR failed" >&2; exit 1; }
# Create required symlinks in sysroot
if ! ln -sf usr/lib $SYSROOT_DIR/lib; then
    echo "Warning: lib symlink creation failed with normal user, retrying with sudo..." >&2
    if ! sudo ln -sf usr/lib $SYSROOT_DIR/lib; then
        echo "Error: failed to create lib symlink" >&2
        exit 1
    else
       echo "/usr/lib symlink creation successful with sudo." >&2
    fi
fi
if ! ln -sf usr/lib64 $SYSROOT_DIR/lib64; then
    if ! sudo ln -sf usr/lib64 $SYSROOT_DIR/lib64; then
        echo "Error: failed to create lib64 symlink" >&2
        exit 1
    else
       echo "/usr/lib64 symlink creation successful with sudo." >&2
    fi
fi

popd || { echo "popd failed" >&2; exit 1; }

if ! sudo chmod a+r $SYSROOT_DIR ; then
    echo "Error: Failed to set read permissions on $SYSROOT_DIR" >&2
    exit 1
fi

if ! sudo chmod a+rw $OUTPUT_DIR ; then
    echo "Error: Failed to set read/write permissions on $OUTPUT_DIR" >&2
    exit 1
fi


pushd . || { echo "pushd failed" >&2; exit 1; }
cd $OUTPUT_DIR || { echo "cd to $OUTPUT_DIR failed" >&2; exit 1; }

echo "Packaging..."
# Package sysroot into tarball
if ! sudo tar -cJf $OUTPUT_DIR/${TAR_NAME} sysroot ; then
     echo "Error: failed to create tarball" >&2
    exit 1
fi

echo "Calculating MD5 and renaming the tarball..."
# Calculate MD5 and rename the tarball
MD5_SUM=$(md5sum $OUTPUT_DIR/${TAR_NAME} | cut -d' ' -f1)
DATE_SUFFIX=$(date +"%Y%m%d%H%M")
NEW_TAR_NAME="${TAR_NAME%.tar.xz}-${DATE_SUFFIX}-${MD5_SUM}.tar.xz"
if ! mv $OUTPUT_DIR/${TAR_NAME} $OUTPUT_DIR/${NEW_TAR_NAME}; then
    echo "Error: failed to rename tarball with MD5 sum" >&2
    exit 1
fi

echo "Package ${NEW_TAR_NAME} downloaded, unpacked, and sysroot prepared successfully."


popd || { echo "popd failed" >&2; exit 1; }

popd || { echo "popd failed" >&2; exit 1; }

