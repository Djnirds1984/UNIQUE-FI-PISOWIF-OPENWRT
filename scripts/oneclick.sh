#!/usr/bin/env bash
set -e
SDK_DIR="${1:-auto}"
ROUTER="$2"
if [ "$SDK_DIR" = "auto" ]; then
  SDK_DIR=""
fi
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y git curl rsync unzip openssh-client wget build-essential ccache ecj fastjar file g++ gawk gettext git java-propose-classpath libelf-dev libncurses5-dev libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget python3-distutils python3-setuptools python3-dev rsync subversion swig time xsltproc zlib1g-dev
fi

WORKDIR="${WORKDIR:-$HOME/UNIQUE-FI-PISOWIF-OPENWRT}"
rm -rf "$WORKDIR"
git clone https://github.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT.git "$WORKDIR"
cd "$WORKDIR"
BRANCH="${BRANCH:-main}"
git checkout "$BRANCH"

if [ -z "$SDK_DIR" ]; then
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
  cd "$WORKDIR"
fi

if [ ! -d "$SDK_DIR" ]; then
  echo "SDK directory not found: $SDK_DIR"
  exit 1
fi

echo "Using SDK: $SDK_DIR"
bash scripts/install.sh "$SDK_DIR" "$ROUTER"
