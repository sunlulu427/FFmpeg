#!/bin/sh

set -e

# brew install autoconf automake libtool
# 交叉编译
# https://juejin.cn/post/6844904191844958216?searchId=20240122232633E5D131A7962C33239B57#heading-7
# libSBRdec/src/lpp_tran.cpp:122:21: fatal error: log/log.h: No such file or directory #include "log/log.h"
# https://github.com/rong5690001/android-issues/issues/37
# https://github.com/mstorsjo/fdk-aac/issues/124
echo "<<<<<<< FFMPFDK-AAC 交叉编译 <<<<<<<"

ARCH=$1
source ../../config.sh $ARCH

#!/bin/bash

ARCH=$1

source ../../config.sh $ARCH
LIBS_DIR=$(pwd)/build

PREFIX=$LIBS_DIR/$AOSP_ABI
echo "PREFIX="$PREFIX

export CC="$CC"
export CXX="$CXX"
export CFLAGS="$FF_CFLAGS"
export CXXFLAGS="$FF_EXTRA_CFLAGS"
# x86架构源码中使用了math库所以必须链接
export LDFLAGS="-lm"
export AR="${TOOLCHAIN}/bin/llvm-ar"
export LD="${TOOLCHAIN}/bin/ld"
export AS="${TOOLCHAIN}/bin/llvm-as"


./configure \
--prefix=$PREFIX \
--target=android \
--with-sysroot=$SYS_ROOT \
--enable-static \
--enable-shared \
--host=$HOST \
