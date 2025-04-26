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
# 第一步：拉取 RTL8821CE 驱动源码到 package/kernel 目录下
mkdir -p package/kernel
rm -rf package/kernel/rtl8821ce
git clone https://github.com/tomaspinho/rtl8821ce.git package/kernel/rtl8821ce

# 第二步：修复 get_sources.sh，改为 HTTPS 拉取
sed -i 's|git@github.com:|https://github.com/|g' package/kernel/rtl8821ce/get_sources.sh

# 第三步：执行 get_sources.sh 拉取 Realtek 官方源码
cd package/kernel/rtl8821ce
bash get_sources.sh

# 检测拉取源码是否成功
if [ ! -d "linux/drivers/net/wireless/rtl8821ce" ]; then
  echo "[ERROR] Realtek官方源码拉取失败，目录不存在！"
  exit 1
fi
cd ../../../

# 第四步：创建适配 OpenWrt 编译的 Makefile
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

# 第五步：自动启用驱动模块与固件（在 menuconfig）
echo "CONFIG_PACKAGE_kmod-rtl8821ce=y" >> .config
echo "CONFIG_PACKAGE_rtl8821ce-firmware=y" >> .config

# 合并配置
make defconfig

# 提示：diy-part2.sh 执行完成
echo "[INFO] diy-part2.sh 执行完毕，已拉取驱动并配置好编译环境。"

# 编译完成后检测 RTL8821CE 模块是否成功生成
echo "[INFO] 添加 post-compile 检测脚本..."
cat << 'EOF' > check-rtl8821ce.sh
#!/bin/bash
MODULE_PATH="bin/targets/*/*/packages/kmod-rtl8821ce_*.ipk"
if ls \$MODULE_PATH 1> /dev/null 2>&1; then
  echo "[SUCCESS] RTL8821CE 模块已成功编译并生成："
  ls \$MODULE_PATH
else
  echo "[ERROR] 未找到编译好的 RTL8821CE 模块，请检查编译日志！"
  exit 1
fi
EOF
chmod +x check-rtl8821ce.sh

# 后续在编译完成后执行： ./check-rtl8821ce.sh

