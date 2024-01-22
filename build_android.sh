#!/bin/sh

set -e
# fix apple M2 error
# https://github.com/ssut/ffmpeg-on-apple-silicon
# https://stackoverflow.com/questions/52896607/why-do-i-get-error-invalid-instruction-mnemonic-when-compiling-ffmpeg-for-and
# https://juejin.cn/post/7100938254974877726

# fdk-aac: https://sourceforge.net/projects/opencore-amr/files/fdk-aac/


# ndk 路径
NDK_ROOT=/Users/sunlulu/Library/Android/sdk/ndk/r26b
TOOLCHAIN_PREFIX=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64

echo "<<<<<<< FFMPEG 交叉编译 <<<<<<<"
echo "<<<<<<< 基于当前的NDK地址：$NDK_ROOT <<<<<<<"

CPU=armv8-a
ARCH=arm64
OS=android
SDK_VERSION=29
OPTIMIZE_CFLAGS="-march=$CPU"

# 执行输出路径
PREFIX=${1:-'./build'}

echo ">>>>> install prefix: ${PREFIX} >>>>>>"

SYSROOT=$TOOLCHAIN_PREFIX/sysroot

# 交叉编译工具链
CROSS_PREFIX=$TOOLCHAIN_PREFIX/bin/llvm-

# Android交叉编译链工具链的位置
ANDROID_CROSS_PREFIX=$TOOLCHAIN_PREFIX/bin

echo ">>>>>> FFMPEG 开始编译 >>>>>>"


./configure \
--prefix=$PREFIX \
--enable-shared \
--enable-gpl \
--enable-neon \
--enable-hwaccels \
--enable-postproc \
--enable-jni \
--enable-small \
--enable-mediacodec \
--enable-decoder=h264_mediacodec \
--enable-ffmpeg \
--disable-ffplay \
--disable-ffprobe \
--disable-ffplay \
--disable-avdevice \
--disable-debug \
--disable-static \
--disable-doc \
--disable-symver \
--cross-prefix=$CROSS_PREFIX \
--target-os=$OS \
--arch=$ARCH \
--cpu=$CPU \
--cc=${TOOLCHAIN_PREFIX}/bin/aarch64-linux-android29-clang \
--cxx=${TOOLCHAIN_PREFIX}/bin/aarch64-linux-android29-clang++ \
--enable-cross-compile \
--sysroot=$SYSROOT \
--extra-cflags="-Os -fPIC $OPTIMIZE_CFLAGS" \
--extra-ldflags="$ADDI_LDFLAGS" \

