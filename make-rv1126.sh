#!/bin/bash

JOB=`sed -n "N;/processor/p" /proc/cpuinfo|wc -l`

function make_extlinux_conf()
{
	echo "label rockchip-kernel-4.19" > boot_linux/extlinux/extlinux.conf
	echo "	kernel /extlinux/zImage" >> boot_linux/extlinux/extlinux.conf
	echo "	fdt /extlinux/toybrick.dtb" >> boot_linux/extlinux/extlinux.conf
	echo "	append  earlycon=uart8250,mmio32,0xff570000 console=ttyFIQ0 root=PARTUUID=614e0000-0000-4b53-8000-1d28000054a9 rw rootwait rootfstype=ext4" >> boot_linux/extlinux/extlinux.conf
}

rm -rf boot_linux
mkdir -p boot_linux/extlinux
make ARCH=arm rv1126_defconfig
make ARCH=arm rv1126-evb-ddr3-v13.img -j${JOB}
cp -f arch/arm/boot/dts/rv1126-evb-ddr3-v13.dtb boot_linux/extlinux/toybrick.dtb
cp -f arch/arm/boot/zImage boot_linux/extlinux/
make_extlinux_conf
if [ "`uname -i`" == "aarch64" ]; then
	echo y | mke2fs -b 4096 -d boot_linux -i 8192 -t ext2 boot_linux.img $((64 * 1024 * 1024 / 4096))
else
	genext2fs -b 32768 -B $((64 * 1024 * 1024 / 32768)) -d boot_linux -i 8192 -U boot_linux.img
fi

