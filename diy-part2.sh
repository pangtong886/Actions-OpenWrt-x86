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
# 第一步：拉取适配 OpenWrt 的稳定版 RTL8821CE 驱动源码到 package/kernel 目录下
mkdir -p package/kernel
rm -rf package/kernel/rtl8821ce
git clone https://github.com/Broly1/rtl8821ce.git package/kernel/rtl8821ce

# （Broly1 版本已包含完整源码，无需额外 get_sources.sh 拉取步骤）

# 第二步：自动启用驱动模块与固件（在 menuconfig）
echo "CONFIG_PACKAGE_kmod-rtl8821ce=y" >> .config
echo "CONFIG_PACKAGE_rtl8821ce-firmware=y" >> .config

# 合并配置
make defconfig

# 提示：diy-part2.sh 执行完成
echo "[INFO] diy-part2.sh 执行完毕，已拉取驱动并配置好编译环境。"

# 第三步：编译完成后检测 RTL8821CE 模块是否成功生成

# 添加 post-compile 检测脚本
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


