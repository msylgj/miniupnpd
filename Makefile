#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=miniupnpd
PKG_VERSION:=2.3.0
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/miniupnp/miniupnp.git
PKG_SOURCE_DATE:=2022-03-20
PKG_SOURCE_VERSION:=fda61180e07abd222623e54b9239557bbffbc21d
PKG_MIRROR_HASH:=f81a5b920f1bddb5673a2455461d4dca20d17138f5488713c5a759f2a64e9f18
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)/miniupnpd

PKG_MAINTAINER:=
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:miniupnp_project:miniupnpd

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/version.mk

TAR_OPTIONS+= --strip-components 1
TAR_CMD=$(HOST_TAR) -C $(1)/.. $(TAR_OPTIONS)

define Package/miniupnpd/Default
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:= \
	+libcap-ng \
	+libmnl \
	+libuuid
  PROVIDES:=miniupnpd
  TITLE:=Lightweight UPnP IGD, NAT-PMP & PCP daemon
  SUBMENU:=Firewall
  URL:=https://miniupnp.tuxfamily.org/
endef

define Package/miniupnpd-iptables
  $(call Package/miniupnpd/Default)
  DEPENDS+= \
	+IPV6:ip6tables \
	+IPV6:libip6tc \
	+iptables \
	+libip4tc \
	+libnetfilter-conntrack
  TITLE+= (iptables)
  VARIANT:=iptables
endef

define Package/miniupnpd-nftables
  $(call Package/miniupnpd/Default)
  DEPENDS+= \
	+libnftnl
  TITLE+= (nftables)
  VARIANT:=nftables
  DEFAULT_VARIANT:=1
  CONFLICTS:=miniupnpd-iptables
endef

define Package/miniupnpd/conffiles/Default
/etc/config/upnpd
endef

Package/miniupnpd-iptables/conffiles = $(Package/miniupnpd/conffiles/Default)
Package/miniupnpd-nftables/conffiles = $(Package/miniupnpd/conffiles/Default)

define Build/Prepare
	$(call Build/Prepare/Default)
	echo "$(VERSION_NUMBER)" | tr '() ' '_' >$(PKG_BUILD_DIR)/os.openwrt
endef

CONFIGURE_ARGS = \
	$(if $(CONFIG_IPV6),--ipv6) \
	--igd2 \
	--leasefile \
	--portinuse \
	--firewall=$(BUILD_VARIANT) \
	--disable-fork

TARGET_CFLAGS += $(FPIC)
TARGET_LDFLAGS += -Wl,--gc-sections,--as-needed

ifeq ($(BUILD_VARIANT),iptables)
	TARGET_CFLAGS += -flto
endif

define Package/miniupnpd/install/Default
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/miniupnpd $(1)/usr/sbin/miniupnpd
	$(INSTALL_BIN) ./files/miniupnpd.init $(1)/etc/init.d/miniupnpd
	$(INSTALL_CONF) ./files/upnpd.config $(1)/etc/config/upnpd
	$(INSTALL_DATA) ./files/miniupnpd.hotplug $(1)/etc/hotplug.d/iface/50-miniupnpd
endef

define Package/miniupnpd-iptables/install
	$(call Package/miniupnpd/install/Default,$1)
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/usr/share/miniupnpd
	$(INSTALL_BIN) ./files/miniupnpd.defaults.iptables $(1)/etc/uci-defaults/99-miniupnpd
	$(INSTALL_DATA) ./files/firewall3.include $(1)/usr/share/miniupnpd/firewall.include
endef

define Package/miniupnpd-nftables/install
	$(call Package/miniupnpd/install/Default,$1)
	$(INSTALL_DIR) $(1)/usr/share/miniupnpd
	$(INSTALL_BIN) ./files/miniupnpd_functions.sh $(1)/usr/share/miniupnpd/miniupnpd_functions.sh
	$(INSTALL_BIN) ./files/nft_init.sh $(1)/usr/share/miniupnpd/nft_init.sh
	$(INSTALL_BIN) ./files/nft_removeall.sh $(1)/usr/share/miniupnpd/nft_removeall.sh
endef

$(eval $(call BuildPackage,miniupnpd-iptables))
$(eval $(call BuildPackage,miniupnpd-nftables))
