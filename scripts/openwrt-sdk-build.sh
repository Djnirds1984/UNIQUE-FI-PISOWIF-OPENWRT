#!/usr/bin/env bash
set -e
SDK_DIR="$1"
ROUTER="$2"
if [ -z "$SDK_DIR" ]; then
  echo "Usage: $0 /path/to/openwrt-sdk [root@router_ip]"
  exit 1
fi
PKG_SRC="$(cd "$(dirname "$0")"/.. && pwd)/openwrt/ajc-pisowifi"
if [ ! -d "$PKG_SRC" ]; then
  echo "Package source not found: $PKG_SRC"
  exit 1
fi
if [ ! -d "$SDK_DIR" ]; then
  echo "SDK directory not found: $SDK_DIR"
  exit 1
fi
if [ ! -x "$SDK_DIR/scripts/feeds" ]; then
  echo "Invalid SDK: scripts/feeds missing"
  exit 1
fi
PKG_DEST="$SDK_DIR/package/ajc-pisowifi"
rm -rf "$PKG_DEST"
mkdir -p "$(dirname "$PKG_DEST")"
cp -r "$PKG_SRC" "$PKG_DEST"
cd "$SDK_DIR"
./scripts/feeds update -a || true
./scripts/feeds install -a || true
make package/ajc-pisowifi/compile V=s
IPK="$(find "$SDK_DIR/bin/packages" -type f -name 'ajc-pisowifi_*.ipk' | head -n1 || true)"
if [ -z "$IPK" ]; then
  echo "Build completed but .ipk not found in bin/packages"
  exit 1
fi
echo "Built package: $IPK"
if [ -n "$ROUTER" ]; then
  scp "$IPK" "$ROUTER:/tmp/"
  ssh "$ROUTER" "opkg update && opkg install /tmp/$(basename "$IPK") && /etc/init.d/ajc enable && /etc/init.d/ajc start"
  echo "Installed on router: $ROUTER"
fi
