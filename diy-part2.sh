#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Modify default IP
sed -i 's/192.168.11.1/192.168.11.201/g' package/base-files/files/bin/config_generate
#sed -i 's/KERNEL_PATCHVER:=5.15/KERNEL_PATCHVER:=6.1/g' target/linux/x86/Makefile
#sed -i "s/.*PKG_VERSION:=.*/PKG_VERSION:=4.3.9_v1.2.14/" package/lean/qBittorrent-static/Makefile
#sed -i "s/.*PKG_VERSION:=.*/PKG_VERSION:=5.0.0-stable/" package/libs/wolfssl/Makefile
# welcome test

# 进入OpenWrt源码目录（Lean的LEDE）
cd openwrt

# 第一步：拉取RTL8821CE驱动源码到package/kernel目录下
mkdir -p package/kernel
rm -rf package/kernel/rtl8821ce
git clone https://github.com/tomaspinho/rtl8821ce.git package/kernel/rtl8821ce

# 第二步：获取完整的RTL8821CE驱动源码（官方Realtek源码）
cd package/kernel/rtl8821ce
bash get_sources.sh
cd ../../..

# 第三步：创建适配OpenWrt编译的Makefile
cat << 'EOL' > package/kernel/rtl8821ce/Makefile
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=rtl8821ce
PKG_RELEASE:=1

BUILD_DIR:=$(KERNEL_BUILD_DIR)/rtl8821ce
PKG_BUILD_DIR:=$(BUILD_DIR)

COPIES:=$(shell cp -r $(CURDIR) $(PKG_BUILD_DIR))

define KernelPackage/rtl8821ce
  SUBMENU:=Wireless Drivers
  TITLE:=Realtek RTL8821CE WiFi Driver
  DEPENDS:=@PCI_SUPPORT +kmod-cfg80211 +kmod-rtlwifi
  FILES:=$(PKG_BUILD_DIR)/rtl8821ce.ko
  AUTOLOAD:=$(call AutoProbe,rtl8821ce)
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp -r $(CURDIR)/* $(PKG_BUILD_DIR)/
endef

MAKE_OPTS += \
	KSRC=$(LINUX_DIR) \
	ARCH="$(LINUX_KARCH)" CROSS_COMPILE="$(KERNEL_CROSS)" \
	CONFIG_RTL8821CE=m

define Build/Compile
	$(MAKE) -C "$(PKG_BUILD_DIR)" $(MAKE_OPTS)
endef

$(eval $(call KernelPackage,rtl8821ce))
EOL

# 第四步：自动启用驱动模块（在menuconfig）
echo "CONFIG_PACKAGE_kmod-rtl8821ce=y" >> .config

# 合并配置
make defconfig
