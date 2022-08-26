#!/usr/bin/env bash

set -e
# export BL31=`pwd`/rkbin/bin/rk33/rk3308_bl31_v2.22.elf
cd u-boot
echo "Building uboot"
make -j`nproc` CROSS_COMPILE=aarch64-linux-gnu- all
echo "Generating uboot.img"
../rockchip-bsp/rkbin/tools/loaderimage --pack --uboot ./u-boot-dtb.bin uboot.img 0x600000 --size 1024 1
echo "Writing uboot.img to sd card"
sudo dd if=./uboot.img of=/dev/mmcblk0 bs=512 seek=16384
sync
echo "SD card ready to boot from"
