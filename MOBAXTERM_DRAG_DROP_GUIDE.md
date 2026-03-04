# MobaXterm Drag-and-Drop File Transfer Guide

## Para sa PisoWiFi Installation

### Step 1: I-connect ang MobaXterm sa OpenWrt

1. Buksan ang **MobaXterm**
2. Click ang **"Session"** button sa top-left
3. Piliin ang **"SSH"**
4. Ilagay ang details:
   - **Remote host**: `192.168.1.1` (palitan kung iba ang IP mo)
   - **Username**: `root`
   - **Port**: `22` (default)
5. Click **"OK"** para mag-connect

### Step 2: Gamitin ang Drag-and-Drop (Pinakamadali!)

**Method 1 - SFTP Panel (Auto-lalabas):**
- Sa left side ng MobaXterm, may lalabas na **SFTP panel** pag nakaconnect ka na
- Makikita mo ang files ng OpenWrt sa left panel
- **Drag lang ang files galing Windows Explorer**, drop sa SFTP panel

**Method 2 - Direct Terminal Drop:**
- I-connect sa SSH muna
- Sa Windows Explorer, **i-drag ang files mo**
- **I-drop sa MobaXterm terminal window**
- Auto-magically gagawa ng SCP command

### Step 3: Common Files na I-copy

#### Para sa ajc-pisowifi installation:
```
Files to copy → Destination sa OpenWrt
ajc-pisowifi*.ipk → /tmp/
```

#### Para sa configuration backup:
```
/etc/config/network → (backup sa PC mo)
/etc/config/wireless → (backup sa PC mo)
```

### Quick Commands After Drag-Drop:

```bash
# Pagkatapos i-drop ang .ipk file:
ssh root@192.168.1.1
cd /tmp
opkg install ajc-pisowifi*.ipk
/etc/init.d/ajc enable
/etc/init.d/ajc start
```

### Tips:
- **/tmp/** folder = safe para sa temporary uploads
- **Right-click** sa SFTP panel → "Upload" option
- **Ctrl+Shift+F** = buksan ang file browser
- **Check storage first**: `df -h /overlay`

### Kung ayaw gumana ang drag-drop:
```bash
# Manual SCP command backup:
scp root@192.168.1.1:/etc/config/network C:\backup\

# Upload command:
scp C:\path\to\file.ipk root@192.168.1.1:/tmp/
```

## Visual Steps:
1. Connect SSH → 2. SFTP panel appears → 3. Drag files → 4. Drop → 5. Done!

**Note**: Ang drag-and-drop gumagana lang pag naka-SSH connect ka na.