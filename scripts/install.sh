#!/usr/bin/env bash
set -e
REPO_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
SDK_DIR="$1"
ROUTER="$2"
BRANCH="${BRANCH:-main}"
if [ -z "$SDK_DIR" ]; then
  echo "Usage: $0 /path/to/openwrt-sdk [root@router_ip]"
  exit 1
fi
if git -C "$REPO_DIR" rev-parse >/dev/null 2>&1; then
  git -C "$REPO_DIR" fetch --all
  git -C "$REPO_DIR" checkout "$BRANCH"
  git -C "$REPO_DIR" pull --ff-only origin "$BRANCH"
fi
bash "$REPO_DIR/scripts/openwrt-sdk-build.sh" "$SDK_DIR" "$ROUTER"
