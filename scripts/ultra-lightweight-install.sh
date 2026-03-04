#!/usr/bin/env bash
set -e

# Ultra-lightweight installation for routers with very limited storage
# Creates minimal package without git/http dependencies

SDK_DIR="${1:-auto}"
ROUTER="${2:-root@192.168.1.1}"
BUILD_DIR="${WORKDIR:-$HOME}/ajc-pisowifi-minimal"

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

# Clone and create minimal package
rm -rf "$BUILD_DIR"
git clone https://github.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT.git "$BUILD_DIR"
cd "$BUILD_DIR"

# Create minimal package without heavy dependencies
echo "Creating minimal package..."
MINIMAL_PKG="$BUILD_DIR/openwrt/ajc-pisowifi-minimal"
cp -r "$BUILD_DIR/openwrt/ajc-pisowifi" "$MINIMAL_PKG"

# Update Makefile for minimal build
cat > "$MINIMAL_PKG/Makefile" << 'EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=ajc-pisowifi-minimal
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=AJC PisoWiFi
PKG_LICENSE:=GPL-3.0

include $(INCLUDE_DIR)/package.mk

define Package/ajc-pisowifi-minimal
  SECTION:=net
  CATEGORY:=Network
  TITLE:=AJC PisoWiFi - Minimal Edition
  DEPENDS:=+kmod-nft-core +kmod-nft-nat +nftables
  PKGARCH:=all
endef

define Package/ajc-pisowifi-minimal/description
  Lightweight captive portal for Ruijie RG-EW1200G PRO v1
  Minimal edition for routers with limited storage
endef

define Build/Prepare
	$(CP) ./files/* $(PKG_BUILD_DIR)/
endef

define Package/ajc-pisowifi-minimal/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/ajc $(1)/etc/init.d/ajc
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/ajc $(1)/etc/config/ajc
	$(INSTALL_DIR) $(1)/usr/lib/ajc
	$(INSTALL_BIN) ./files/usr/lib/ajc/setup.sh $(1)/usr/lib/ajc/setup.sh
	$(INSTALL_BIN) ./files/usr/lib/ajc/session.sh $(1)/usr/lib/ajc/session.sh
	$(INSTALL_DIR) $(1)/www/ajc
	$(INSTALL_DATA) ./files/www/ajc/index.html $(1)/www/ajc/index.html
	$(INSTALL_DIR) $(1)/www/cgi-bin/ajc
	$(INSTALL_BIN) ./files/www/cgi-bin/ajc/authorize $(1)/www/cgi-bin/ajc/authorize
endef

define Package/ajc-pisowifi-minimal/postinst
#!/bin/sh
/etc/init.d/ajc enable
/etc/init.d/ajc start
exit 0
endef

$(eval $(call BuildPackage,ajc-pisowifi-minimal))
EOF

# Build the minimal package
echo "Building minimal package..."
PKG_DEST="$SDK_DIR/package/ajc-pisowifi-minimal"
rm -rf "$PKG_DEST"
cp -r "$MINIMAL_PKG" "$PKG_DEST"

cd "$SDK_DIR"
./scripts/feeds update -a || true
./scripts/feeds install -a || true
make package/ajc-pisowifi-minimal/compile V=s

# Find the built .ipk file
IPK="$(find "$SDK_DIR/bin/packages" -type f -name 'ajc-pisowifi-minimal_*.ipk' | head -n1 || true)"

if [ -z "$IPK" ]; then
  echo "Error: Could not find built .ipk file"
  exit 1
fi

echo "Built minimal package: $IPK"
echo "Package size: $(du -h "$IPK" | cut -f1)"

# Transfer to router and install
echo "Transferring minimal package to router..."
scp "$IPK" "$ROUTER:/tmp/"

echo "Installing minimal package on router..."
ssh "$ROUTER" "
  echo 'Installing ajc-pisowifi-minimal package...'
  opkg update
  opkg install /tmp/$(basename "$IPK")
  
  echo 'Enabling and starting service...'
  /etc/init.d/ajc enable
  /etc/init.d/ajc start
  
  echo 'Minimal installation complete!'
  echo 'Service status:'
  /etc/init.d/ajc status
  echo 'Storage usage:'
  df -h /overlay
"

echo "Ultra-lightweight installation complete!"