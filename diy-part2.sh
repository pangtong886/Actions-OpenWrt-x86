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
# ========= 自定义脚本（在 feeds update 之后执行）=========
# 注意：此脚本默认在 openwrt 根目录下执行

echo ">>> 开始自定义配置: 导入 iStoreOS 驱动包..."

# 克隆 iStoreOS 仓库（只拉取 istoreos-22.03 分支）
git clone --depth=1 --single-branch --branch istoreos-22.03 https://github.com/istoreos/istoreos.git tmp_istoreos

# 复制 iStoreOS 的 package/kernel 下所有驱动
if [ -d "tmp_istoreos/package/kernel" ]; then
    mkdir -p package/kernel/
    cp -rf tmp_istoreos/package/kernel/* package/kernel/
    echo ">>> 成功复制 iStoreOS package/kernel/ 目录下所有驱动！"
else
    echo "!!! 错误: 未找到 tmp_istoreos/package/kernel/ 目录，可能 clone 失败。"
    exit 1
fi

# 清理临时目录
rm -rf tmp_istoreos

# 添加你想默认启用的驱动（这里以 kmod-rtl8821ce 为例）
# 如果想启用更多，按需追加 echo 语句
echo "CONFIG_PACKAGE_kmod-rtl8821ce=y" >> .config
# echo "CONFIG_PACKAGE_kmod-你的其他驱动=y" >> .config

# 更新配置文件
make defconfig
echo ">>> diy-part2.sh 自定义配置完成！"
