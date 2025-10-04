#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# FFmpeg iOS Cross-Compilation Helper
# ==============================================================================
# Features:
#   - Detects Xcode command line tools and available iOS SDKs
#   - Arrow-key driven menus for selecting build presets, library type, iOS target
#   - Supports device, simulator, and universal (multi-arch) builds
#   - Creates static, shared, or dual outputs using the standard FFmpeg configure flow
#   - Non-interactive usage mirrors build_android.sh semantics
# ------------------------------------------------------------------------------
# Examples:
#   ./build_ios.sh                                # Fully interactive wizard
#   ./build_ios.sh device-arm64                   # Build arm64 for devices
#   ./build_ios.sh universal-fat ./out 13.0 both   # Universal static/shared bundles
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
# Host environment detection
# ----------------------------------------------------------------------------

ensure_repo_root() {
    if [ ! -f "configure" ]; then
        log_error "未找到 ./configure，请在 FFmpeg 源码根目录运行本脚本"
        exit 1
    fi
}

require_macos() {
    if [ "$(uname -s)" != "Darwin" ]; then
        log_error "iOS 交叉编译仅支持在 macOS 上运行"
        exit 1
    fi
}

ensure_xcode_tools() {
    if ! command -v xcode-select >/dev/null 2>&1; then
        log_error "未检测到 xcode-select，请安装 Xcode Command Line Tools"
        exit 1
    fi

    if ! xcode-select -p >/dev/null 2>&1; then
        log_error "未找到 Xcode Command Line Tools，请运行 'xcode-select --install'"
        exit 1
    fi

    if ! command -v xcrun >/dev/null 2>&1; then
        log_error "未检测到 xcrun，请确认 Xcode Command Line Tools 安装完整"
        exit 1
    fi
}

get_sdk_path() {
    local sdk="$1"
    if ! xcrun --sdk "$sdk" --show-sdk-path 2>/dev/null; then
        return 1
    fi
}

assert_sdk_available() {
    local sdk="$1"
    if ! get_sdk_path "$sdk" >/dev/null; then
        log_error "未找到 SDK: $sdk，请确认 Xcode 已安装对应平台支持"
        exit 1
    fi
}

# ----------------------------------------------------------------------------
# Build presets and selections
# ----------------------------------------------------------------------------
PRESET_KEYS=(
    device-arm64
    sim-arm64
    sim-x86_64
    universal-arm64
    universal-fat
)

preset_description() {
    case "$1" in
        device-arm64) echo "iOS 设备 (iphoneos) - arm64" ;;
        sim-arm64) echo "iOS 模拟器 (iphonesimulator) - arm64" ;;
        sim-x86_64) echo "iOS 模拟器 (iphonesimulator) - x86_64" ;;
        universal-arm64) echo "通用: 设备 arm64 + 模拟器 arm64" ;;
        universal-fat) echo "通用: 设备 arm64 + 模拟器 arm64/x86_64" ;;
        *) echo "$1" ;;
    esac
}

LIBRARY_CHOICES=(shared static both)

version_lt() {
    local IFS=.
    read -r a b <<<"$1"
    read -r c d <<<"$2"
    a=${a:-0}; b=${b:-0}; c=${c:-0}; d=${d:-0}
    if [ "$a" -ne "$c" ]; then
        [ "$a" -lt "$c" ] && return 0 || return 1
    fi
    [ "$b" -lt "$d" ]
}

DISABLE_METAL=0

library_description() {
    case "$1" in
        shared) echo "动态库 (.dylib/.so)" ;;
        static) echo "静态库 (.a)" ;;
        both) echo "同时构建静态与动态库" ;;
        *) echo "$1" ;;
    esac
}

select_preset_interactive() {
    local -a labels=()
    for key in "${PRESET_KEYS[@]}"; do
        labels+=("$(preset_description "$key")")
    done

    if ! interactive_menu_select "选择构建预设" "${labels[@]}"; then
        return 1
    fi

    local idx="$MENU_SELECTION"
    BUILD_PRESET="${PRESET_KEYS[$idx]}"
    log_success "预设: $(preset_description "$BUILD_PRESET")"
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

select_deployment_target_interactive() {
    local defaults=(12.0 13.0 14.0 15.0 16.0 17.0)
    local -a options=()
    local -a mapping=()

    for ver in "${defaults[@]}"; do
        options+=("iOS $ver")
        mapping+=("$ver")
    done

    options+=("自定义版本号")
    mapping+=("__custom__")

    if ! interactive_menu_select "选择最低支持的 iOS 版本" "${options[@]}"; then
        return 1
    fi

    local idx="$MENU_SELECTION"
    local selected="${mapping[$idx]}"

    if [ "$selected" = "__custom__" ]; then
        read -rp "请输入最低版本号 (示例 12.0): " custom
        if [[ "$custom" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            IOS_MIN_VERSION="$custom"
            log_success "最低版本: iOS $IOS_MIN_VERSION"
            return 0
        else
            log_error "无效的版本号"
            pause_for_enter
            return select_deployment_target_interactive
        fi
    else
        IOS_MIN_VERSION="$selected"
        log_success "最低版本: iOS $IOS_MIN_VERSION"
        return 0
    fi
}

select_output_dir_interactive() {
    local default_dir="./build/ios-${BUILD_PRESET}"
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
# Preset resolution utilities
# ----------------------------------------------------------------------------
declare -a BUILD_COMBINATIONS=()

resolve_preset() {
    case "$1" in
        device-arm64)
            BUILD_COMBINATIONS=("iphoneos:arm64")
            ;;
        sim-arm64)
            BUILD_COMBINATIONS=("iphonesimulator:arm64")
            ;;
        sim-x86_64)
            BUILD_COMBINATIONS=("iphonesimulator:x86_64")
            ;;
        universal-arm64)
            BUILD_COMBINATIONS=("iphoneos:arm64" "iphonesimulator:arm64")
            ;;
        universal-fat)
            BUILD_COMBINATIONS=("iphoneos:arm64" "iphonesimulator:arm64" "iphonesimulator:x86_64")
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

combo_label() {
    local platform="${1%%:*}"
    local arch="${1##*:}"
    echo "$platform-$arch"
}

# ----------------------------------------------------------------------------
# Build helpers
# ----------------------------------------------------------------------------
IOS_MIN_VERSION=""
LIBRARY_TYPE=""
BUILD_PRESET=""
OUTPUT_DIR=""
BUILD_MODE=""

cc_for_sdk() {
    local sdk="$1"
    xcrun --sdk "$sdk" --find clang
}

cxx_for_sdk() {
    local sdk="$1"
    xcrun --sdk "$sdk" --find clang++
}

tool_for_sdk() {
    local sdk="$1"; shift
    xcrun --sdk "$sdk" --find "$1"
}

build_single_combo() {
    local combo="$1"
    local platform="${combo%%:*}"
    local arch="${combo##*:}"
    local sdk_path
    sdk_path=$(get_sdk_path "$platform")

    local cc
    cc=$(cc_for_sdk "$platform")
    local cxx
    cxx=$(cxx_for_sdk "$platform")
    local ar
    ar=$(tool_for_sdk "$platform" ar)
    local ranlib
    ranlib=$(tool_for_sdk "$platform" ranlib)
    local strip
    strip=$(tool_for_sdk "$platform" strip)

    local target_arch="$arch"
    local extra_cflags="-arch $arch -isysroot $sdk_path -fembed-bitcode"
    local extra_ldflags="-arch $arch -isysroot $sdk_path"
    local min_flag

    if [ "$platform" = "iphoneos" ]; then
        min_flag="-miphoneos-version-min=${IOS_MIN_VERSION}"
    else
        min_flag="-mios-simulator-version-min=${IOS_MIN_VERSION}"
    fi

    extra_cflags="$extra_cflags $min_flag"
    extra_ldflags="$extra_ldflags $min_flag"

    local combo_dir="$OUTPUT_DIR/${platform}-${arch}"
    mkdir -p "$combo_dir"

    local configure_cmd=(
        ./configure
        --prefix="$combo_dir"
        --target-os=darwin
        --arch="$target_arch"
        --enable-cross-compile
        --cc="$cc"
        --cxx="$cxx"
        --ar="$ar"
        --ranlib="$ranlib"
        --strip="$strip"
        --sysroot="$sdk_path"
        --extra-cflags="$extra_cflags"
        --extra-ldflags="$extra_ldflags"
        --enable-pic
        --enable-gpl
        --enable-version3
        --enable-nonfree
        --disable-programs
        --disable-doc
        --disable-avdevice
        --disable-symver
        --disable-debug
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

    if [ "$DISABLE_METAL" -eq 1 ]; then
        log_info "禁用 Metal 相关模块"
        configure_cmd+=(--disable-metal)
    fi

    log_info "配置 $platform:$arch (SDK: $sdk_path)"
    log_info "命令: ${configure_cmd[*]}"

    if ! "${configure_cmd[@]}"; then
        log_error "FFmpeg 配置失败 ($platform-$arch)"
        return 1
    fi

    log_info "产物类型: $(library_description "$LIBRARY_TYPE")"
    log_info "开始编译 FFmpeg..."
    make clean >/dev/null 2>&1 || true
    local jobs
    jobs=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)

    if ! make -j"$jobs"; then
        log_error "构建失败 ($platform-$arch)"
        return 1
    fi

    if ! make install; then
        log_error "安装失败 ($platform-$arch)"
        return 1
    fi

    log_success "完成 $platform-$arch 构建，输出目录: $combo_dir"
    return 0
}

create_universal_static_archives() {
    local universal_dir="$OUTPUT_DIR/universal"
    mkdir -p "$universal_dir/lib"

    local first_combo="${BUILD_COMBINATIONS[0]}"
    local first_dir="$OUTPUT_DIR/$(combo_label "$first_combo")"
    local base_lib_dir="$first_dir/lib"

    if [ ! -d "$base_lib_dir" ]; then
        log_warn "跳过通用静态库打包：未找到 $base_lib_dir"
        return
    fi

    local libs=("$base_lib_dir"/*.a)
    if [ ${#libs[@]} -eq 0 ]; then
        log_warn "未找到静态库，跳过通用合并"
        return
    fi

    local lipo_bin
    lipo_bin=$(xcrun --find lipo)

    for lib_path in "${libs[@]}"; do
        local lib_name
        lib_name=$(basename "$lib_path")
        local inputs=()
        for combo in "${BUILD_COMBINATIONS[@]}"; do
            local combo_dir="$OUTPUT_DIR/$(combo_label "$combo")/lib/$lib_name"
            if [ -f "$combo_dir" ]; then
                inputs+=("$combo_dir")
            fi
        done

        if [ ${#inputs[@]} -gt 1 ]; then
            local output_file="$universal_dir/lib/$lib_name"
            log_info "创建通用静态库: $lib_name"
            "$lipo_bin" -create "${inputs[@]}" -output "$output_file"
        elif [ ${#inputs[@]} -eq 1 ]; then
            cp "${inputs[0]}" "$universal_dir/lib/$lib_name"
        fi
    done

    # Copy headers from first combo
    if [ -d "$first_dir/include" ]; then
        rsync -a "$first_dir/include" "$universal_dir/"
    fi

    log_success "已生成通用静态库目录: $universal_dir"
}

show_summary() {
    echo ""
    echo "=============================================================================="
    echo "构建配置"
    echo "=============================================================================="
    echo "预设:       $(preset_description "$BUILD_PRESET")"
    echo "库类型:     $(library_description "$LIBRARY_TYPE")"
    echo "iOS 版本:   $IOS_MIN_VERSION"
    echo "输出目录:   $OUTPUT_DIR"
    if [ "$DISABLE_METAL" -eq 1 ]; then
        echo "Metal:      已禁用 (iOS < 13 或手动配置)"
    else
        echo "Metal:      启用"
    fi
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
# Main flows
# ----------------------------------------------------------------------------

non_interactive_flow() {
    BUILD_PRESET="${1:-device-arm64}"
    OUTPUT_DIR="${2:-}"
    IOS_MIN_VERSION="${3:-13.0}"
    LIBRARY_TYPE="${4:-static}"

    if [ -z "$OUTPUT_DIR" ]; then
        OUTPUT_DIR="./build/ios-${BUILD_PRESET}"
    fi

    if ! resolve_preset "$BUILD_PRESET"; then
        log_error "未知预设: $BUILD_PRESET"
        exit 1
    fi

    case "$LIBRARY_TYPE" in
        shared|static|both) ;;
        *)
            log_error "库类型参数无效: $LIBRARY_TYPE (shared/static/both)"
            exit 1
            ;;
    esac

    log_info "非交互模式: 预设=$BUILD_PRESET, 输出=$OUTPUT_DIR, iOS $IOS_MIN_VERSION, 库类型=$(library_description "$LIBRARY_TYPE")"

    if version_lt "$IOS_MIN_VERSION" "13.0"; then
        DISABLE_METAL=1
        log_info "iOS 版本 < 13.0，将禁用 Metal"
    else
        DISABLE_METAL=0
    fi
}

interactive_flow() {
    while true; do
        if ! select_preset_interactive; then
            log_warn "用户取消"
            exit 0
        fi

        if ! select_library_type_interactive; then
            log_warn "用户取消"
            exit 0
        fi

        if ! select_deployment_target_interactive; then
            log_warn "用户取消"
            exit 0
        fi

        if version_lt "$IOS_MIN_VERSION" "13.0"; then
            DISABLE_METAL=1
        else
            DISABLE_METAL=0
        fi

        if ! select_output_dir_interactive; then
            log_warn "用户取消"
            exit 0
        fi

        if ! resolve_preset "$BUILD_PRESET"; then
            log_error "预设解析失败"
            exit 1
        fi

        show_summary
        confirm_summary
        local confirmation=$?

        case "$confirmation" in
            0) return 0 ;;
            2)
                BUILD_PRESET=""
                OUTPUT_DIR=""
                IOS_MIN_VERSION=""
                LIBRARY_TYPE=""
                DISABLE_METAL=0
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
    require_macos
    ensure_xcode_tools

    if ! supports_interactive_terminal && [ $# -eq 0 ]; then
        log_warn "检测到非交互式终端，请提供参数运行脚本"
        log_warn "示例: ./build_ios.sh device-arm64 ./out 13.0 static"
        exit 1
    fi

    assert_sdk_available iphoneos
    assert_sdk_available iphonesimulator

    if [ $# -gt 0 ]; then
        non_interactive_flow "$@"
    else
        interactive_flow
    fi

    log_info "开始执行构建计划..."

    for combo in "${BUILD_COMBINATIONS[@]}"; do
        if ! build_single_combo "$combo"; then
            log_error "构建失败: $combo"
            exit 1
        fi
    done

    if [ ${#BUILD_COMBINATIONS[@]} -gt 1 ] && [ "$LIBRARY_TYPE" != "shared" ]; then
        create_universal_static_archives
    fi

    log_success "全部任务完成"
}

main "$@"
