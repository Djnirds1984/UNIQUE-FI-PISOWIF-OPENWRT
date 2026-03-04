# OpenWrt Installation Guide (Ruijie RG‑EW1200G PRO v1/v1.1)

This guide explains how to:
- Flash OpenWrt on the Ruijie RG‑EW1200G PRO v1/v1.1
- Build and install the ajc-pisowifi captive portal/session controller package
- Configure and verify the captive portal and client authorization

## 1) Flash OpenWrt on the Router

Prerequisites:
- The correct OpenWrt image for ramips/mt7621 and your exact hardware revision
- Access to the router shell on stock firmware (root)

Typical flashing steps (adjust to the instructions for your model):
1. On your PC, serve the firmware file:
   - `python -m http.server` in the directory containing `factory.bin`
2. On the router:
   - `cd /tmp`
   - `wget http://<PC_IP>:8000/factory.bin`
   - `mtd -r write factory.bin firmware`
3. After reboot, access OpenWrt at `http://192.168.1.1` and set a root password.

Notes:
- The RG‑EW1200G PRO v1.1 is officially supported; verify exact variant in the OpenWrt Hardware DB.
- Always follow device-specific installation notes from OpenWrt.

## 2) Build the ajc-pisowifi Package (.ipk)

Use the OpenWrt SDK that matches ramips/mt7621 (mipsel_24kc):
1. Download and extract the OpenWrt SDK for your target.
2. Copy the package sources into the SDK:
   - Place the folder `openwrt/ajc-pisowifi` into `package/ajc-pisowifi` inside the SDK.
     - Package Makefile: [openwrt/ajc-pisowifi/Makefile](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/openwrt/ajc-pisowifi/Makefile)
     - Init script: [files/etc/init.d/ajc](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/openwrt/ajc-pisowifi/files/etc/init.d/ajc)
     - UCI config: [files/etc/config/ajc](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/openwrt/ajc-pisowifi/files/etc/config/ajc)
     - Setup/session: [files/usr/lib/ajc/setup.sh](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/openwrt/ajc-pisowifi/files/usr/lib/ajc/setup.sh), [files/usr/lib/ajc/session.sh](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/openwrt/ajc-pisowifi/files/usr/lib/ajc/session.sh)
     - Portal/CGI: [files/www/ajc/index.html](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/openwrt/ajc-pisowifi/files/www/ajc/index.html), [files/www/cgi-bin/ajc/authorize](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/openwrt/ajc-pisowifi/files/www/cgi-bin/ajc/authorize)
3. Update and install feeds in the SDK:
   - `./scripts/feeds update -a`
   - `./scripts/feeds install -a`
4. Select the target and package:
   - `make menuconfig`
   - Target System: MediaTek Ralink MIPS
   - Subtarget: MT7621
   - Select Network → `ajc-pisowifi`
5. Build the package:
   - `make package/ajc-pisowifi/compile V=s`
6. Locate the generated `.ipk` under `bin/packages/mipsel_24kc/`.

## 3) Install the Package on OpenWrt

1. Copy the `.ipk` to your router (e.g., `scp` to `/tmp`).
2. SSH into the router, then:
   - `opkg update`
   - `opkg install /tmp/ajc-pisowifi_*.ipk`
3. Enable and start the service:
   - `/etc/init.d/ajc enable`
   - `/etc/init.d/ajc start`

Dependencies (`uhttpd`, `nftables`) are automatically pulled in by the package.

## 4) Configure via UCI (Optional)

Default configuration file:
- [openwrt/ajc-pisowifi/files/etc/config/ajc](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/openwrt/ajc-pisowifi/files/etc/config/ajc)

Common adjustments:
- `uci set ajc.main.lan_if='br-lan'`
- `uci set ajc.main.portal_ip='192.168.1.1'`
- `uci commit ajc`
- `/etc/init.d/ajc restart`

## 5) Verify Captive Portal and Authorization

Captive portal:
- Connect a LAN client and visit `http://192.168.1.1/ajc/`

Authorize a client by MAC for N seconds:
- HTTP:
  - `http://192.168.1.1/cgi-bin/ajc/authorize?mac=AA:BB:CC:DD:EE:FF&sec=1800`
- Shell:
  - `/usr/lib/ajc/session.sh AA:BB:CC:DD:EE:FF 1800`

Inspect nft ruleset:
- `nft list ruleset | grep ajc`

## 6) Optional: Include in Custom Firmware (ImageBuilder)

Using the ImageBuilder for ramips/mt7621:
1. Place your built `.ipk` in ImageBuilder’s `packages/` directory.
2. Build an image with:
   - `make image PROFILE=<your_device_profile> PACKAGES="ajc-pisowifi uhttpd nftables"`

## Troubleshooting

- No redirect:
  - Ensure `lan_if` matches your LAN bridge (`br-lan`) and `portal_ip` is correct.
  - Reload firewall: `/etc/init.d/firewall reload`
  - Check rules: `nft list ruleset`
- CGI not found:
  - Check that `uhttpd` is running and files exist under `/www/cgi-bin/ajc/authorize`.
- MAC parsing issues:
  - Use uppercase MAC with colons (e.g., `AA:BB:CC:DD:EE:FF`).

## Uninstall / Disable

- Stop and disable service:
  - `/etc/init.d/ajc stop`
  - `/etc/init.d/ajc disable`
- Remove rules and package:
  - `rm -f /etc/nftables.d/ajc.nft && /etc/init.d/firewall reload`
  - `opkg remove ajc-pisowifi`

## 7) Pag-pull mula sa Git Repository (UNIQUE-FI-PISOWIF-OPENWRT)

Repository URL:
- `https://github.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT.git`

Karaniwang daloy (OpenWrt SDK build machine — Linux/macOS):
1. Clone ang repository:
   - `git clone https://github.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT.git`
   - `cd UNIQUE-FI-PISOWIF-OPENWRT`
2. Kopyahin ang package papunta sa SDK:
   - `cp -r openwrt/ajc-pisowifi /path/to/openwrt-sdk/package/ajc-pisowifi`
3. Sa SDK:
   - `./scripts/feeds update -a && ./scripts/feeds install -a`
   - `make menuconfig` (piliin ramips/mt7621 at ajc-pisowifi)
   - `make package/ajc-pisowifi/compile V=s`
4. I-install ang nabuo na `.ipk` sa router:
   - `scp bin/packages/mipsel_24kc/*/ajc-pisowifi_*.ipk root@192.168.1.1:/tmp/`
   - `ssh root@192.168.1.1 "opkg update && opkg install /tmp/ajc-pisowifi_*.ipk && /etc/init.d/ajc enable && /etc/init.d/ajc start"`

Pag-update mula sa repo at rebuild:
1. Sa cloned repo:
   - `git pull origin main`
2. Ulitin ang copy papunta sa SDK at `make package/ajc-pisowifi/compile V=s`
3. I-upgrade sa router:
   - `opkg install --force-reinstall /tmp/ajc-pisowifi_*.ipk`
   - `/etc/init.d/ajc restart`

## 8) Automation: Build Helper Script

Pwede mong patakbuhin ang helper script para awtomatikong kopya/build at optional install sa router:
- Script path: [scripts/openwrt-sdk-build.sh](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/scripts/openwrt-sdk-build.sh)
- Usage:
  - `bash scripts/openwrt-sdk-build.sh /path/to/openwrt-sdk`
  - `bash scripts/openwrt-sdk-build.sh /path/to/openwrt-sdk root@192.168.1.1`
  - Unang argumento: path ng OpenWrt SDK
  - Ikalawang argumento (optional): router SSH target (`root@<ip>`) para auto‑install

## 9) Quick Install Script

Para one‑command build at optional install, gamitin:
- Script path: [scripts/install.sh](file:///c:/Users/Administrator/Documents/GitHub/UNIQUE-FI-PISOWIF-OPENWRT/scripts/install.sh)
- Usage:
  - `bash scripts/install.sh /path/to/openwrt-sdk`
  - `bash scripts/install.sh /path/to/openwrt-sdk root@192.168.1.1`
- Optional:
  - `BRANCH=main bash scripts/install.sh /path/to/openwrt-sdk root@192.168.1.1`
  - `BRANCH` controls kung aling branch ang i-pu-pull bago mag-build.

### Direct Link (GitHub Raw)
- Raw URL ng install script:
  - `https://raw.githubusercontent.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT/main/scripts/install.sh`
- Inirerekomenda: patakbuhin ang script mula sa cloned repo para mahanap ang helper scripts at sources:
  - `git clone https://github.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT.git`
  - `cd UNIQUE-FI-PISOWIF-OPENWRT`
  - `bash scripts/install.sh /path/to/openwrt-sdk root@192.168.1.1`
- One‑liner (clone + run):
  - `git clone https://github.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT.git && cd UNIQUE-FI-PISOWIF-OPENWRT && BRANCH=main bash scripts/install.sh /path/to/openwrt-sdk root@192.168.1.1`

## 10) One‑click Bootstrap Link (with Auto SDK Download)

- Raw URL ng one‑click script:
  - `https://raw.githubusercontent.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT/main/scripts/oneclick.sh`

### Zero-config option (auto-downloads SDK):
```bash
curl -sSL https://raw.githubusercontent.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT/main/scripts/oneclick.sh | bash -s -- auto root@192.168.1.1
```

### Manual SDK path option:
```bash
curl -sSL https://raw.githubusercontent.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT/main/scripts/oneclick.sh | bash -s -- /path/to/openwrt-sdk root@192.168.1.1
```

- Palitan ang `root@192.168.1.1` ayon sa setup mo
- Gamitin ang `auto` para mag-download ng tamang SDK para sa ramips/mt7621 (mipsel_24kc)
- O kaya'y ibigay ang sarili mong SDK path kung meron ka na

## 11) Lightweight Installation (Para sa Router na Mababa ang Storage)

Para sa mga router na kulang sa storage space (gaya ng error: "Only have 6808kb available"), gamitin ang lightweight installation:

### Option A: Lightweight Install (Build sa PC, transfer .ipk file lang)
```bash
# Gamitin ang build machine mo (Ubuntu/Debian PC)
curl -sSL https://raw.githubusercontent.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT/main/scripts/lightweight-install.sh | bash -s -- auto root@192.168.1.1
```

### Option B: Ultra-lightweight Install (Mas maliit na package)
```bash
# Para sa sobrang kulang sa storage
curl -sSL https://raw.githubusercontent.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT/main/scripts/ultra-lightweight-install.sh | bash -s -- auto root@192.168.1.1
```

### Manual Transfer (Kung gusto mo ng manual control)
```bash
# 1. Build sa PC mo
git clone https://github.com/Djnirds1984/UNIQUE-FI-PISOWIF-OPENWRT.git
cd UNIQUE-FI-PISOWIF-OPENWRT
bash scripts/openwrt-sdk-build.sh auto  # Build lang, no install

# 2. Hanapin ang .ipk file
find ~/openwrt-sdk-ramips-mt7621/*/bin/packages -name '*ajc*.ipk'

# 3. I-transfer sa router
scp /path/to/ajc-pisowifi*.ipk root@192.168.1.1:/tmp/

# 4. I-install sa router
ssh root@192.168.1.1
opkg update
opkg install /tmp/ajc-pisowifi*.ipk
/etc/init.d/ajc enable
/etc/init.d/ajc start
```

### Storage Tips:
- **Free up space**: `opkg remove ppp ppp-mod-pppoe kmod-ppp kmod-pppoe kmod-pppox` (kung hindi mo ginagamit)
- **Check storage**: `df -h /overlay`
- **List big packages**: `opkg list-installed | xargs opkg info | grep -E "Package:|Size:" | awk '/Package:/ {pkg=$2} /Size:/ {print pkg, $2}' | sort -k2 -nr`
- **Minimal edition**: ~50KB lang ang ultra-lightweight package
