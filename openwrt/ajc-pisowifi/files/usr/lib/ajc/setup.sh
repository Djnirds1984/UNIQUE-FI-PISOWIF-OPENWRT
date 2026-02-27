#!/bin/sh
. /lib/functions.sh
lan_if=$(uci get ajc.main.lan_if 2>/dev/null)
portal_ip=$(uci get ajc.main.portal_ip 2>/dev/null)
set_name=$(uci get ajc.main.set_name 2>/dev/null)
[ -z "$lan_if" ] && lan_if=br-lan
[ -z "$portal_ip" ] && portal_ip=$(uci get network.lan.ipaddr 2>/dev/null)
[ -z "$set_name" ] && set_name=allow_macs
nft_file=/etc/nftables.d/ajc.nft
generate() {
	mkdir -p /etc/nftables.d
	cat > "$nft_file" <<EOF
table inet ajc {
 set $set_name { type ether_addr; flags timeout; }
 chain prerouting {
  type nat hook prerouting priority -100;
  iifname "$lan_if" tcp dport 80 ether saddr != @$set_name dnat to $portal_ip:80
 }
 chain forward {
  type filter hook forward priority 0;
  iifname "$lan_if" ether saddr @$set_name accept
  iifname "$lan_if" drop
 }
}
EOF
}
case "$1" in
 start)
  generate
  /etc/init.d/firewall reload >/dev/null 2>&1 || true
 ;;
 stop)
  rm -f "$nft_file"
  /etc/init.d/firewall reload >/dev/null 2>&1 || true
 ;;
esac
