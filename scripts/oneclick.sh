#!/usr/bin/env bash
set -e
SDK_DIR="$1"
ROUTER="$2"
if [ -z "$SDK_DIR" ]; then
  echo "Usage: bash oneclick.sh /path/to/openwrt-sdk [root@router_ip]"
  exit 1
fi
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y git curl rsync unzip openssh-client
fi
WORKDIR="${WORKDIR:-$HOME/UNIQUE-FI-PISOWIF-OPENWRT}"
rm -rf "$WORKDIR"
git clone https://github.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT.git "$WORKDIR"
cd "$WORKDIR"
BRANCH="${BRANCH:-main}"
git checkout "$BRANCH"
bash scripts/install.sh "$SDK_DIR" "$ROUTER"
