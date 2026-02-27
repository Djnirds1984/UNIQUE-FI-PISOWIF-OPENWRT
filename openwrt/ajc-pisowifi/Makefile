include $(TOPDIR)/rules.mk
PKG_NAME:=ajc-pisowifi
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
include $(INCLUDE_DIR)/package.mk
define Package/ajc-pisowifi
  SECTION:=net
  CATEGORY:=Network
  TITLE:=AJC PisoWiFi captive portal for OpenWrt
  DEPENDS:=+uhttpd +nftables
endef
define Package/ajc-pisowifi/description
 A lightweight captive portal and session controller.
endef
define Build/Compile
endef
define Package/ajc-pisowifi/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/ajc $(1)/etc/init.d/ajc
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/ajc $(1)/etc/config/ajc
	$(INSTALL_DIR) $(1)/usr/lib/ajc
	$(INSTALL_BIN) ./files/usr/lib/ajc/session.sh $(1)/usr/lib/ajc/session.sh
	$(INSTALL_BIN) ./files/usr/lib/ajc/setup.sh $(1)/usr/lib/ajc/setup.sh
	$(INSTALL_DIR) $(1)/www/ajc
	$(INSTALL_DATA) ./files/www/ajc/index.html $(1)/www/ajc/index.html
	$(INSTALL_DIR) $(1)/www/cgi-bin/ajc
	$(INSTALL_BIN) ./files/www/cgi-bin/ajc/authorize $(1)/www/cgi-bin/ajc/authorize
endef
$(eval $(call BuildPackage,ajc-pisowifi))
