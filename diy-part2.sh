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
#!/bin/bash
# ========= 自定义脚本（在 feeds update 后执行）=========
# 注意：此脚本默认在 openwrt 根目录下执行

echo ">>> 开始自定义配置: 导入 rtw88-oot 驱动..."

# 克隆 iStoreOS 仓库（只拉 package/kernel/rtw88-oot 子目录）
mkdir -p package/kernel/
git clone --depth=1 --filter=blob:none --sparse https://github.com/istoreos/istoreos.git tmp_istoreos
cd tmp_istoreos
git sparse-checkout set package/kernel/rtw88-oot
cp -r package/kernel/rtw88-oot ../../package/kernel/
cd ..
rm -rf tmp_istoreos

echo ">>> 成功复制 rtw88-oot 驱动到 package/kernel/ 目录。"

# 删除原本的 rtw88-usb 配置（如果存在）
sed -i '/CONFIG_PACKAGE_kmod-rtw88-usb/d' .config

# 禁用内核原生 rtw88-usb
echo "# CONFIG_PACKAGE_kmod-rtw88-usb is not set" >> .config

# 启用新的 rtw88-oot 驱动
echo "CONFIG_PACKAGE_kmod-rtw88-oot=y" >> .config

# 更新配置
make defconfig

echo ">>> diy-part2.sh 自定义配置完成！"
