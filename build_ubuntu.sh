#!/bin/bash
FASTPOTIFY_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$FASTPOTIFY_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <fastpotify_version> <build_version> [architecture]"
    echo "Example: $0 0.2.0 1 arm64"
    echo "Example: $0 0.2.0 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

UPSTREAM_URL="https://github.com/crmne/fastpotify/releases/download/v${FASTPOTIFY_VERSION}"

# Map a Debian architecture to the Rust target triple upstream names its
# release assets after. Upstream publishes Linux binaries for x86_64 and
# aarch64 only -- no armhf, i386, riscv64 or ppc64el.
get_target_triple() {
    case "$1" in
        "amd64") echo "x86_64-unknown-linux-gnu" ;;
        "arm64") echo "aarch64-unknown-linux-gnu" ;;
        *)       echo "" ;;
    esac
}

# The binary is glibc linked and built on Ubuntu 24.04, so it needs
# GLIBC_2.39 (pidfd_spawnp, pidfd_getpid). ALSA and PulseAudio are linked
# directly; the GUI stack (GL/EGL, X11, Wayland, xkbcommon) is dlopened at
# run time by eframe/glutin/winit, so those have to be declared by hand.
PACKAGE_DEPENDS="libc6 (>= 2.39), libgcc-s1, libasound2t64 | libasound2, libpulse0, libgl1, libegl1, libx11-6, libx11-xcb1, libxcursor1, libxi6, libxrender1, libxkbcommon0, libxkbcommon-x11-0, libwayland-client0, libwayland-egl1"
# Titles in CJK, Arabic, Hebrew, Thai and Indic scripts are drawn with fonts
# found on the system; without these they render as boxes.
PACKAGE_RECOMMENDS="fonts-noto-cjk, fonts-noto-core"

build_architecture() {
    local build_arch=$1
    local triple asset

    triple=$(get_target_triple "$build_arch")
    if [ -z "$triple" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi
    asset="fastpotify-v${FASTPOTIFY_VERSION}-${triple}"

    echo "Building for architecture: $build_arch using ${asset}.tar.gz"

    rm -rf "dist/$build_arch" || true
    mkdir -p "dist/$build_arch"

    # The archive holds a single top-level fastpotify-v<ver>-<triple>/ with the
    # binary, README, LICENSE and the Linux desktop entry and icon under
    # packaging/.
    if ! wget -q "${UPSTREAM_URL}/${asset}.tar.gz" -O "dist/$build_arch/fastpotify.tar.gz"; then
        echo "❌ Failed to download fastpotify binary for $build_arch"
        return 1
    fi
    if ! tar -xf "dist/$build_arch/fastpotify.tar.gz" -C "dist/$build_arch" --strip-components=1; then
        echo "❌ Failed to extract fastpotify binary for $build_arch"
        return 1
    fi
    rm -f "dist/$build_arch/fastpotify.tar.gz"

    for f in "dist/$build_arch/fastpotify" \
             "dist/$build_arch/packaging/applications/fastpotify.desktop" \
             "dist/$build_arch/packaging/icons/fastpotify.svg"; do
        if [ ! -s "$f" ]; then
            echo "❌ Unexpected archive layout for $build_arch (missing $f)"
            return 1
        fi
    done

    # GLIBC_2.39 rules out jammy (2.35); noble is exactly 2.39.
    declare -a arr=("noble" "questing" "resolute")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$FASTPOTIFY_VERSION-${BUILD_VERSION}~${dist}_${build_arch}_ubu"
        echo "  Building $FULL_VERSION"

        if ! docker build . -f Dockerfile.ubu -t "fastpotify-ubuntu-$dist-$build_arch" \
            --build-arg UBUNTU_DIST="$dist" \
            --build-arg FASTPOTIFY_VERSION="$FASTPOTIFY_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg PACKAGE_DEPENDS="$PACKAGE_DEPENDS" \
            --build-arg PACKAGE_RECOMMENDS="$PACKAGE_RECOMMENDS"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "fastpotify-ubuntu-$dist-$build_arch")"
        if ! docker cp "$id:/fastpotify_$FULL_VERSION.deb" - > "./fastpotify_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./fastpotify_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    rm -rf "dist/$build_arch" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

if [ "$ARCH" = "all" ]; then
    echo "🚀 Building fastpotify $FASTPOTIFY_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    ARCHITECTURES=("amd64" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la fastpotify_*.deb
else
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
