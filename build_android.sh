#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# FFmpeg Android Cross-Compilation Helper
# ==============================================================================
# Features:
#   - Auto-discovery of the Android NDK across common installation paths
#   - Guided installation instructions when the NDK is missing
#   - Pure arrow-key driven interactive menus (no numeric selection required)
#   - Cross compilation for single or multiple Android ABIs
#   - Non-interactive mode via positional arguments: ARCH [OUTPUT_DIR] [API]
# ------------------------------------------------------------------------------
# Example usages:
#   ./build_android.sh                     # Fully interactive flow
#   ./build_android.sh arm64               # Non-interactive using defaults
#   ./build_android.sh all ./build 26      # Build every ABI to ./build (API 26)
# ------------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Colored logging helpers
# ----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[DONE]${NC} $1"; }

# ----------------------------------------------------------------------------
# Terminal helpers for arrow-key menus
# ----------------------------------------------------------------------------
ORIGINAL_STTY=""
MENU_SELECTION=""

supports_interactive_terminal() {
    [[ -t 0 && -t 1 ]]
}

save_stty_state() {
    stty -g 2>/dev/null || true
}

hide_cursor() {
    if command -v tput >/dev/null 2>&1; then
        tput civis 2>/dev/null || true
    fi
}

show_cursor() {
    if command -v tput >/dev/null 2>&1; then
        tput cnorm 2>/dev/null || true
    fi
}

clear_menu_screen() {
    if command -v tput >/dev/null 2>&1; then
        tput cup 0 0 2>/dev/null || printf '\033[H'
        tput ed 2>/dev/null || printf '\033[J'
    else
        printf '\033[H\033[2J'
    fi
}

cleanup_terminal() {
    if [ -n "$ORIGINAL_STTY" ]; then
        stty "$ORIGINAL_STTY" 2>/dev/null || true
    fi
    show_cursor
}

trap cleanup_terminal EXIT

render_menu() {
    local title="$1"
    local selected="$2"
    shift 2
    local options=("$@")

    clear_menu_screen
    echo "=============================================================================="
    echo "$title"
    echo "=============================================================================="
    echo ""

    for i in "${!options[@]}"; do
        if [ "$i" -eq "$selected" ]; then
            printf "\033[1;32m► %d. %s\033[0m\n" $((i + 1)) "${options[i]}"
        else
            printf "  %d. %s\n" $((i + 1)) "${options[i]}"
        fi
    done

    echo ""
    echo "使用 ↑↓ 方向键选择，Enter 确认，q 退出"
}

interactive_menu_select() {
    local title="$1"
    shift
    local options=("$@")
    local total=${#options[@]}

    MENU_SELECTION=""

    if [ "$total" -eq 0 ]; then
        log_error "菜单没有可用的选项"
        return 1
    fi

    if ! supports_interactive_terminal; then
        log_error "当前终端不支持方向键交互，请在交互式终端运行或通过参数指定选项"
        return 1
    fi

    local saved_stty
    saved_stty=$(save_stty_state)
    if [ -z "$ORIGINAL_STTY" ]; then
        ORIGINAL_STTY="$saved_stty"
    fi

    hide_cursor
    stty -echo -icanon min 1 time 0

    local selected=0
    render_menu "$title" "$selected" "${options[@]}"

    while true; do
        local key
        if ! IFS= read -rsn1 key; then
            continue
        fi

        case "$key" in
            $'\n'|$'\r'|'')
                MENU_SELECTION="$selected"
                stty "$saved_stty" 2>/dev/null || true
                show_cursor
                return 0
                ;;
            $'\x03')
                stty "$saved_stty" 2>/dev/null || true
                show_cursor
                exit 130
                ;;
            $'\x1b')
                local next
                if ! IFS= read -rsn1 -t 1 next; then
                    continue
                fi
                if [ "$next" = "[" ]; then
                    if ! IFS= read -rsn1 -t 1 next; then
                        continue
                    fi
                    case "$next" in
                        A)
                            selected=$(((selected - 1 + total) % total))
                            ;;
                        B)
                            selected=$(((selected + 1) % total))
                            ;;
                        H)
                            selected=0
                            ;;
                        F)
                            selected=$((total - 1))
                            ;;
                        5)
                            if IFS= read -rsn1 -t 1 next && [ "$next" = "~" ]; then
                                selected=0
                            fi
                            ;;
                        6)
                            if IFS= read -rsn1 -t 1 next && [ "$next" = "~" ]; then
                                selected=$((total - 1))
                            fi
                            ;;
                    esac
                    render_menu "$title" "$selected" "${options[@]}"
                fi
                ;;
            q|Q)
                stty "$saved_stty" 2>/dev/null || true
                show_cursor
                MENU_SELECTION=""
                return 1
                ;;
        esac
    done
}

pause_for_enter() {
    echo ""
    read -rp "按 Enter 返回菜单... " _
}

# ----------------------------------------------------------------------------
# Host and environment detection
# ----------------------------------------------------------------------------
HOST_OS=""
HOST_ARCH=""
NDK_HOST_TAG=""

detect_host() {
    case "$(uname -s)" in
        Darwin*)
            HOST_OS="darwin"
            HOST_ARCH="$(uname -m)"
            if [ "$HOST_ARCH" = "arm64" ]; then
                NDK_HOST_TAG="darwin-x86_64"  # Apple Silicon uses x86_64 prebuilts
            else
                NDK_HOST_TAG="darwin-x86_64"
            fi
            ;;
        Linux*)
            HOST_OS="linux"
            HOST_ARCH="$(uname -m)"
            NDK_HOST_TAG="linux-x86_64"
            ;;
        *)
            log_error "暂不支持的主机系统: $(uname -s)"
            exit 1
            ;;
    esac

    log_info "检测到主机环境: $HOST_OS/$HOST_ARCH (NDK host tag: $NDK_HOST_TAG)"
}

ensure_repo_root() {
    if [ ! -f "configure" ]; then
        log_error "未找到 ./configure，请在 FFmpeg 源码根目录运行本脚本"
        exit 1
    fi
}

# ----------------------------------------------------------------------------
# NDK discovery and selection
# ----------------------------------------------------------------------------
discover_ndk_paths() {
    local -a bases=(
        "$HOME/Library/Android/sdk/ndk"
        "$HOME/Android/Sdk/ndk"
        "$HOME/android-ndk"
        "/opt/android-sdk/ndk"
        "/usr/local/android-sdk/ndk"
        "/usr/lib/android-sdk/ndk"
    )

    if [ -n "${ANDROID_HOME:-}" ]; then
        bases=("$ANDROID_HOME/ndk" "${bases[@]}")
    fi
    if [ -n "${ANDROID_SDK_ROOT:-}" ]; then
        bases=("$ANDROID_SDK_ROOT/ndk" "${bases[@]}")
    fi

    local -a found=()

    for base in "${bases[@]}"; do
        [ -d "$base" ] || continue
        while IFS= read -r -d '' path; do
            [ -d "$path/toolchains/llvm/prebuilt" ] || continue
            found+=("$path")
        done < <(find "$base" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
    done

    if [ -n "${ANDROID_NDK_ROOT:-}" ] && [ -d "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt" ]; then
        found+=("$ANDROID_NDK_ROOT")
    fi

    if [ -n "${NDK_HOME:-}" ] && [ -d "$NDK_HOME/toolchains/llvm/prebuilt" ]; then
        found+=("$NDK_HOME")
    fi

    if [ ${#found[@]} -gt 0 ]; then
        printf '%s\n' "${found[@]}" | awk 'NF' | sort -u
    fi
}

ndk_has_host_tag() {
    local ndk_path="$1"
    [ -d "$ndk_path/toolchains/llvm/prebuilt/$NDK_HOST_TAG" ]
}

show_ndk_install_guide() {
    cat <<'EOF'

==============================================================================
Android NDK 安装指南
==============================================================================

macOS:
  1. 安装 Android SDK Command Line Tools (可通过 Android Studio 或 Homebrew)
  2. 运行 sdkmanager "ndk;26.1.10909125" 安装最新稳定版 NDK
  3. 设置 ANDROID_HOME/ANDROID_NDK_ROOT 环境变量指向 SDK/NDK

Linux:
  1. 从 https://developer.android.com/ndk/downloads 下载最新 NDK 压缩包
  2. 解压到 ~/Android/Sdk/ndk/ 或 /opt/android-sdk/ndk/
  3. 配置 ANDROID_HOME/ANDROID_NDK_ROOT 环境变量

安装完成后请返回菜单选择“重新扫描”。
EOF
    pause_for_enter
}

prompt_custom_ndk_path() {
    echo ""
    read -rp "请输入 NDK 根目录路径: " custom_path
    echo "$custom_path"
}

select_ndk_interactive() {
    local -a ndks

    ndks=()
    local ndk_output
    ndk_output=$(discover_ndk_paths 2>/dev/null || true)
    if [ -n "$ndk_output" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && ndks+=("$line")
        done <<< "$ndk_output"
    fi

    while true; do
        local -a options=()
        local -a mapping=()

        if [ ${#ndks[@]} -gt 0 ]; then
            for path in "${ndks[@]}"; do
                local version
                version=$(basename "$path")
                options+=("使用 $version ($path)")
                mapping+=("$path")
            done
        else
            options+=("未检测到 NDK，选择此项查看安装指导")
            mapping+=("__guide__")
        fi

        options+=("重新扫描已安装的 NDK")
        mapping+=("__rescan__")

        options+=("手动输入 NDK 路径")
        mapping+=("__manual__")

        options+=("查看 NDK 安装指南")
        mapping+=("__guide__")

        options+=("取消并退出脚本")
        mapping+=("__exit__")

        if ! interactive_menu_select "选择 Android NDK" "${options[@]}"; then
            return 1
        fi
        local choice_index="$MENU_SELECTION"
        local action="${mapping[choice_index]}"

        case "$action" in
            __rescan__)
                ndks=()
                ndk_output=$(discover_ndk_paths 2>/dev/null || true)
                if [ -n "$ndk_output" ]; then
                    while IFS= read -r line; do
                        [ -n "$line" ] && ndks+=("$line")
                    done <<< "$ndk_output"
                fi
                if [ ${#ndks[@]} -eq 0 ]; then
                    log_warn "仍未检测到 NDK 安装"
                    pause_for_enter
                fi
                ;;
            __manual__)
                local manual_path
                manual_path=$(prompt_custom_ndk_path)
                if [ -z "$manual_path" ]; then
                    log_warn "输入为空，返回菜单"
                    pause_for_enter
                    continue
                fi
                if ! [ -d "$manual_path" ]; then
                    log_error "目录不存在: $manual_path"
                    pause_for_enter
                    continue
                fi
                if ! ndk_has_host_tag "$manual_path"; then
                    log_error "在 $manual_path 找不到与 $NDK_HOST_TAG 匹配的预编译工具链"
                    pause_for_enter
                    continue
                fi
                NDK_ROOT="$manual_path"
                log_success "已选择 NDK: $NDK_ROOT"
                return 0
                ;;
            __guide__)
                show_ndk_install_guide
                ;;
            __exit__)
                return 1
                ;;
            *)
                if [ -d "$action" ] && ndk_has_host_tag "$action"; then
                    NDK_ROOT="$action"
                    log_success "已选择 NDK: $NDK_ROOT"
                    return 0
                else
                    log_error "选定目录不可用或缺少 $NDK_HOST_TAG 工具链"
                    pause_for_enter
                fi
                ;;
        esac
    done
}

# ----------------------------------------------------------------------------
# Build configuration helpers
# ----------------------------------------------------------------------------
ARCH_CHOICES=(arm64 armv7a x86 x86_64 all)
LIBRARY_CHOICES=(shared static both)

arch_description() {
    case "$1" in
        arm64) echo "ARM64 (arm64-v8a)" ;;
        armv7a) echo "ARMv7 (armeabi-v7a)" ;;
        x86) echo "Intel x86" ;;
        x86_64) echo "Intel x86_64" ;;
        all) echo "全部架构 (arm64/armv7a/x86/x86_64)" ;;
        *) echo "$1" ;;
    esac
}

library_description() {
    case "$1" in
        shared) echo "动态库 (.so)" ;;
        static) echo "静态库 (.a)" ;;
        both) echo "同时构建静态与动态库" ;;
        *) echo "$1" ;;
    esac
}

select_architecture_interactive() {
    local -a labels=()
    for key in "${ARCH_CHOICES[@]}"; do
        labels+=("$(arch_description "$key")")
    done

    if ! interactive_menu_select "选择目标架构" "${labels[@]}"; then
        return 1
    fi

    local idx="$MENU_SELECTION"
    TARGET_ARCH="${ARCH_CHOICES[$idx]}"
    log_success "将构建架构: $(arch_description "$TARGET_ARCH")"
    return 0
}

select_library_type_interactive() {
    local -a labels=()
    for key in "${LIBRARY_CHOICES[@]}"; do
        labels+=("$(library_description "$key")")
    done

    if ! interactive_menu_select "选择构建产物类型" "${labels[@]}"; then
        return 1
    fi

    local idx="$MENU_SELECTION"
    LIBRARY_TYPE="${LIBRARY_CHOICES[$idx]}"
    log_success "库类型: $(library_description "$LIBRARY_TYPE")"
    return 0
}

select_api_level_interactive() {
    local defaults=(21 23 24 26 28 29 30 33 34)
    local -a options=()
    local -a mapping=()

    for api in "${defaults[@]}"; do
        options+=("API $api")
        mapping+=("$api")
    done

    options+=("自定义 API 级别")
    mapping+=("__custom__")

    if ! interactive_menu_select "选择 Android API 级别" "${options[@]}"; then
        return 1
    fi
    local idx="$MENU_SELECTION"
    local selected="${mapping[$idx]}"
    if [ "$selected" = "__custom__" ]; then
        read -rp "请输入 API 级别 (例: 26): " custom
        if [[ "$custom" =~ ^[0-9]+$ ]] && [ "$custom" -ge 16 ] && [ "$custom" -le 34 ]; then
            API_LEVEL="$custom"
            log_success "使用自定义 API: $API_LEVEL"
            return 0
        else
            log_error "无效的 API 级别"
            pause_for_enter
            return select_api_level_interactive
        fi
    else
        API_LEVEL="$selected"
        log_success "使用推荐 API: $API_LEVEL"
        return 0
    fi
}

select_output_dir_interactive() {
    local default_dir
    if [ "$TARGET_ARCH" = "all" ]; then
        default_dir="./build"
    else
        default_dir="./build/android-$TARGET_ARCH"
    fi

    local options=("默认输出目录: $default_dir" "自定义输出目录" "退出构建")
    if ! interactive_menu_select "选择输出目录" "${options[@]}"; then
        return 1
    fi

    local idx="$MENU_SELECTION"
    case "$idx" in
        0)
            OUTPUT_DIR="$default_dir"
            ;;
        1)
            read -rp "请输入输出目录路径: " custom_dir
            if [ -z "$custom_dir" ]; then
                log_error "输出目录不能为空"
                pause_for_enter
                return select_output_dir_interactive
            fi
            OUTPUT_DIR="$custom_dir"
            ;;
        *)
            return 1
            ;;
    esac

    log_success "输出目录: $OUTPUT_DIR"
    return 0
}

# ----------------------------------------------------------------------------
# Toolchain preparation
# ----------------------------------------------------------------------------
NDK_ROOT=""
NDK_TOOLCHAIN_PREFIX=""
SYSROOT=""

prepare_ndk_toolchain() {
    if [ -z "$NDK_ROOT" ]; then
        log_error "未选择 NDK"
        exit 1
    fi

    local prebuilt="$NDK_ROOT/toolchains/llvm/prebuilt/$NDK_HOST_TAG"
    if [ ! -d "$prebuilt" ]; then
        log_error "在 $prebuilt 找不到 LLVM 工具链"
        exit 1
    fi

    NDK_TOOLCHAIN_PREFIX="$prebuilt"
    SYSROOT="$prebuilt/sysroot"

    log_info "使用 NDK: $NDK_ROOT"
    log_info "工具链目录: $NDK_TOOLCHAIN_PREFIX"
}

configure_architecture() {
    local arch="$1"

    case "$arch" in
        arm64|arm64-v8a)
            FFMPEG_ARCH="arm64"
            FFMPEG_CPU="armv8-a"
            ABI="arm64-v8a"
            CLANG_PREFIX="aarch64-linux-android"
            OPT_CFLAGS="-march=armv8-a"
            ;;
        armv7a|armeabi-v7a)
            FFMPEG_ARCH="arm"
            FFMPEG_CPU="armv7-a"
            ABI="armeabi-v7a"
            CLANG_PREFIX="armv7a-linux-androideabi"
            OPT_CFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=neon"
            ;;
        x86)
            FFMPEG_ARCH="x86"
            FFMPEG_CPU="i686"
            ABI="x86"
            CLANG_PREFIX="i686-linux-android"
            OPT_CFLAGS="-march=i686 -mtune=intel -mssse3 -mfpmath=sse -m32"
            ;;
        x86_64)
            FFMPEG_ARCH="x86_64"
            FFMPEG_CPU="x86_64"
            ABI="x86_64"
            CLANG_PREFIX="x86_64-linux-android"
            OPT_CFLAGS="-march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel"
            ;;
        *)
            log_error "不支持的架构: $arch"
            exit 1
            ;;
    esac

    CROSS_PREFIX="$NDK_TOOLCHAIN_PREFIX/bin/"
    CC="$NDK_TOOLCHAIN_PREFIX/bin/${CLANG_PREFIX}${API_LEVEL}-clang"
    CXX="$NDK_TOOLCHAIN_PREFIX/bin/${CLANG_PREFIX}${API_LEVEL}-clang++"

    if [ ! -x "$CC" ]; then
        log_error "未找到 C 编译器: $CC"
        exit 1
    fi
    if [ ! -x "$CXX" ]; then
        log_error "未找到 C++ 编译器: $CXX"
        exit 1
    fi
}

# ----------------------------------------------------------------------------
# Build routines
# ----------------------------------------------------------------------------
run_configure() {
    local prefix="$1"

    local configure_cmd=(
        ./configure
        --prefix="$prefix"
        --target-os=android
        --arch="$FFMPEG_ARCH"
        --cpu="$FFMPEG_CPU"
        --cross-prefix="${CROSS_PREFIX}llvm-"
        --cc="$CC"
        --cxx="$CXX"
        --enable-cross-compile
        --sysroot="$SYSROOT"
        --extra-cflags="-Os -fPIC $OPT_CFLAGS -DANDROID"
        --extra-ldflags=""
        --enable-gpl
        --enable-version3
        --enable-nonfree
        --enable-runtime-cpudetect
        --enable-jni
        --enable-mediacodec
        --enable-decoder=h264_mediacodec
        --enable-decoder=hevc_mediacodec
        --enable-decoder=mpeg4_mediacodec
        --enable-decoder=vp8_mediacodec
        --enable-decoder=vp9_mediacodec
        --enable-hwaccels
        --disable-doc
        --disable-programs
        --disable-debug
        --disable-symver
        --disable-stripping
    )

    case "$LIBRARY_TYPE" in
        static)
            configure_cmd+=(--enable-static --disable-shared)
            ;;
        both)
            configure_cmd+=(--enable-static --enable-shared)
            ;;
        *)
            configure_cmd+=(--enable-shared --disable-static)
            ;;
    esac

    log_info "执行配置: ${configure_cmd[*]}"
    if ! "${configure_cmd[@]}"; then
        log_error "FFmpeg 配置失败，请检查上述输出或 config.log"
        return 1
    fi
    return 0
}

build_single_arch() {
    local arch="$1"
    local output_dir="$2"

    log_info "================ 构建 $arch (API $API_LEVEL) ================"

    configure_architecture "$arch"

    mkdir -p "$output_dir"

    if ! run_configure "$output_dir"; then
        return 1
    fi

    log_info "产物类型: $(library_description "$LIBRARY_TYPE")"
    log_info "开始编译 FFmpeg..."
    make clean >/dev/null 2>&1 || true
    local jobs
    jobs=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

    if ! make -j"$jobs"; then
        log_error "构建失败，尝试减少并行度 (make -j1) 或查看上方日志"
        return 1
    fi

    if ! make install; then
        log_error "安装失败，请检查输出目录权限"
        return 1
    fi

    log_success "完成 $arch 架构构建，产物位于: $output_dir"
    return 0
}

build_all_architectures() {
    local base_dir="$1"
    local -a targets=(arm64 armv7a x86 x86_64)
    local -a failed=()

    for arch in "${targets[@]}"; do
        local dir="$base_dir/android-$arch"
        if ! build_single_arch "$arch" "$dir"; then
            failed+=("$arch")
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        log_error "以下架构构建失败: ${failed[*]}"
        return 1
    fi

    log_success "所有架构构建完成，基础目录: $base_dir"
    return 0
}

# ----------------------------------------------------------------------------
# Configuration summary
# ----------------------------------------------------------------------------
show_summary() {
    echo ""
    echo "=============================================================================="
    echo "构建配置"
    echo "=============================================================================="
    echo "NDK:        $NDK_ROOT"
    echo "架构:       $TARGET_ARCH ($(arch_description "$TARGET_ARCH"))"
    echo "API 级别:   $API_LEVEL"
    echo "输出目录:   $OUTPUT_DIR"
    echo "库类型:     $(library_description "$LIBRARY_TYPE")"
    echo "=============================================================================="
    echo ""
}

confirm_summary() {
    local options=("确认并开始构建" "返回重新配置" "取消退出")
    if ! interactive_menu_select "确认构建配置" "${options[@]}"; then
        return 1
    fi
    local idx="$MENU_SELECTION"
    case "$idx" in
        0) return 0 ;;
        1) return 2 ;;
        *) return 1 ;;
    esac
}

# ----------------------------------------------------------------------------
# Main flow
# ----------------------------------------------------------------------------
TARGET_ARCH=""
OUTPUT_DIR=""
API_LEVEL=""
LIBRARY_TYPE=""

non_interactive_flow() {
    TARGET_ARCH="${1:-arm64}"
    OUTPUT_DIR="${2:-}"
    API_LEVEL="${3:-21}"
    LIBRARY_TYPE="${4:-shared}"

    if [ -z "$OUTPUT_DIR" ]; then
        if [ "$TARGET_ARCH" = "all" ]; then
            OUTPUT_DIR="./build"
        else
            OUTPUT_DIR="./build/android-$TARGET_ARCH"
        fi
    fi

    case "$LIBRARY_TYPE" in
        shared|static|both)
            ;;
        *)
            log_error "库类型参数无效: $LIBRARY_TYPE (可选值: shared, static, both)"
            exit 1
            ;;
    esac

    log_info "非交互模式: 架构=$TARGET_ARCH, API=$API_LEVEL, 输出目录=$OUTPUT_DIR, 库类型=$(library_description "$LIBRARY_TYPE")"

    if ! ndk_has_host_tag "$NDK_ROOT"; then
        log_error "NDK ($NDK_ROOT) 不包含所需的 $NDK_HOST_TAG 工具链"
        exit 1
    fi
}

interactive_flow() {
    while true; do
        if [ -z "$NDK_ROOT" ] || ! ndk_has_host_tag "$NDK_ROOT"; then
            if ! select_ndk_interactive; then
                log_warn "用户取消"
                exit 0
            fi
        else
            log_info "使用已检测到的 NDK: $NDK_ROOT"
        fi

        if ! select_architecture_interactive; then
            log_warn "用户取消"
            exit 0
        fi

        if ! select_library_type_interactive; then
            log_warn "用户取消"
            exit 0
        fi

        if ! select_api_level_interactive; then
            log_warn "用户取消"
            exit 0
        fi

        if ! select_output_dir_interactive; then
            log_warn "用户取消"
            exit 0
        fi

        show_summary
        confirm_summary
        local confirmation=$?

        case "$confirmation" in
            0)
                return 0
                ;;
            2)
                log_info "重新配置"
                # 清空已选择，方便重新选择 NDK
                NDK_ROOT=""
                TARGET_ARCH=""
                OUTPUT_DIR=""
                API_LEVEL=""
                ;;
            *)
                log_warn "构建已取消"
                exit 0
                ;;
        esac
    done
}

main() {
    ensure_repo_root
    detect_host

    if ! supports_interactive_terminal && [ $# -eq 0 ]; then
        log_warn "检测到非交互式终端，请使用参数运行脚本"
        log_warn "示例: ./build_android.sh arm64 ./out/android-arm64 26"
        exit 1
    fi

    # Pre-load NDK_ROOT from environment if available
    if [ -n "${ANDROID_NDK_ROOT:-}" ] && ndk_has_host_tag "$ANDROID_NDK_ROOT"; then
        NDK_ROOT="$ANDROID_NDK_ROOT"
    elif [ -n "${NDK_ROOT:-}" ] && ndk_has_host_tag "$NDK_ROOT"; then
        NDK_ROOT="$NDK_ROOT"
    fi

    if [ -z "$NDK_ROOT" ]; then
        local ndk_candidates
        ndk_candidates=$(discover_ndk_paths 2>/dev/null || true)
        if [ -n "$ndk_candidates" ]; then
            local detected=""
            while IFS= read -r line; do
                [ -n "$line" ] && detected="$line"
            done <<< "$ndk_candidates"
            if [ -n "$detected" ] && ndk_has_host_tag "$detected"; then
                NDK_ROOT="$detected"
                log_info "自动检测到 NDK: $NDK_ROOT"
            fi
        fi
    fi

    if [ $# -gt 0 ]; then
        if [ -z "$NDK_ROOT" ]; then
            log_error "非交互模式需要提前设置 ANDROID_NDK_ROOT 或 NDK_ROOT"
            exit 1
        fi
        non_interactive_flow "$@"
    else
        interactive_flow
    fi

    prepare_ndk_toolchain

    if [ "$TARGET_ARCH" = "all" ]; then
        build_all_architectures "$OUTPUT_DIR"
    else
        build_single_arch "$TARGET_ARCH" "$OUTPUT_DIR"
    fi

    log_success "全部任务完成"
}

main "$@"
