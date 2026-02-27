#!/bin/sh
set_name=$(uci get ajc.main.set_name 2>/dev/null)
[ -z "$set_name" ] && set_name=allow_macs
mac="$1"
seconds="$2"
[ -z "$mac" ] && exit 1
[ -z "$seconds" ] && seconds=600
nft add element inet ajc $set_name { $mac timeout ${seconds}s } >/dev/null 2>&1
