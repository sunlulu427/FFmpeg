#!/bin/sh

set -e

echo "<<<<<<< Lame 交叉编译 <<<<<<<"

PREFIX=$(pwd)/build
NDK_ROOT=/Users/sunlulu/Library/Android/sdk/ndk/21.1.6352462
PREBUILT=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64
PLATFORM=$NDK_211/platforms/android-21/arch-arm

CPU=armv8-a
HOST=aarch64-linux-android
export PATH=$PATH:$PREBUILT/bin:$PLATFORM/usr/include
export LDFLAGS="-L$PLATFORM/usr/lib -L$PREBUILT/aarch64-linux-android/lib -march=$CPU"
export CFLAGS="-L$PLATFORM/usr/include -march=$CPU -mfloat-abi=softfp -mfpu=vfp -ffast-math -O2"

export CPPFLAGS="$CFLAGS"
export CFLAGS="$CFLAGS"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="$LDFLAGS"

export AR="${PREBUILT}/bin/llvm-ar"
export LD="${PREBUILT}/bin/aarch64-linux-android-ld"
export AS="${PREBUILT}/bin/llvm-as"
export CXX="${PREBUILT}/bin/bin/clang++ --sysroot=${PLATFORM}"
export CC="${PREBUILT}/bin/clang --sysroot=${PLATFORM} -march=$CPU"
export NM="${PREBUILT}/bin/llvm-nm"
export STRIP="${PREBUILT}/bin/llvm-strip"
export RANLIB="${PREBUILT}/bin/llvm-ranlib"


./configure \
--prefix=$PREFIX \
--enable-static \
--enable-shared \
--host=$HOST \

