#!/usr/bin/env bash
set -e

# Lightweight installation for routers with limited storage
# This script builds the package on the build machine and transfers only the .ipk file

SDK_DIR="${1:-auto}"
ROUTER="${2:-root@192.168.1.1}"
BUILD_DIR="${WORKDIR:-$HOME}/ajc-pisowifi-build"

# Auto-download SDK if needed
if [ "$SDK_DIR" = "auto" ] || [ -z "$SDK_DIR" ]; then
  echo "Auto-downloading OpenWrt SDK for ramips/mt7621 (mipsel_24kc)..."
  SDK_BASE="$HOME/openwrt-sdk-ramips-mt7621"
  mkdir -p "$SDK_BASE"
  cd "$SDK_BASE"
  
  SDK_URL="https://downloads.openwrt.org/releases/23.05.3/targets/ramips/mt7621/openwrt-sdk-23.05.3-ramips-mt7621_gcc-12.3.0_musl.Linux-x86_64.tar.xz"
  SDK_TARBALL="openwrt-sdk-23.05.3-ramips-mt7621_gcc-12.3.0_musl.Linux-x86_64.tar.xz"
  SDK_FOLDER="openwrt-sdk-23.05.3-ramips-mt7621_gcc-12.3.0_musl.Linux-x86_64"
  
  if [ ! -d "$SDK_FOLDER" ]; then
    if [ ! -f "$SDK_TARBALL" ]; then
      echo "Downloading SDK..."
      wget -q --show-progress "$SDK_URL" -O "$SDK_TARBALL"
    fi
    echo "Extracting SDK..."
    tar -xf "$SDK_TARBALL"
  fi
  SDK_DIR="$SDK_BASE/$SDK_FOLDER"
fi

if [ ! -d "$SDK_DIR" ]; then
  echo "SDK directory not found: $SDK_DIR"
  exit 1
fi

echo "Using SDK: $SDK_DIR"

# Clone repo to build directory
rm -rf "$BUILD_DIR"
git clone https://github.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT.git "$BUILD_DIR"
cd "$BUILD_DIR"

# Build the package
echo "Building ajc-pisowifi package..."
PKG_SRC="$BUILD_DIR/openwrt/ajc-pisowifi"
PKG_DEST="$SDK_DIR/package/ajc-pisowifi"

rm -rf "$PKG_DEST"
cp -r "$PKG_SRC" "$PKG_DEST"

cd "$SDK_DIR"
./scripts/feeds update -a || true
./scripts/feeds install -a || true
make package/ajc-pisowifi/compile V=s

# Find the built .ipk file
IPK="$(find "$SDK_DIR/bin/packages" -type f -name 'ajc-pisowifi_*.ipk' | head -n1 || true)"

if [ -z "$IPK" ]; then
  echo "Error: Could not find built .ipk file"
  exit 1
fi

echo "Built package: $IPK"

# Transfer to router and install
echo "Transferring package to router..."
scp "$IPK" "$ROUTER:/tmp/"

echo "Installing package on router..."
ssh "$ROUTER" "
  echo 'Installing ajc-pisowifi package...'
  opkg update
  opkg install /tmp/$(basename "$IPK")
  
  echo 'Enabling and starting service...'
  /etc/init.d/ajc enable
  /etc/init.d/ajc start
  
  echo 'Installation complete!'
  echo 'Service status:'
  /etc/init.d/ajc status
"

echo "Lightweight installation complete!"