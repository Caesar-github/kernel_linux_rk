#!/bin/bash

VERSION="2.0"
JOB=`sed -n "N;/processor/p" /proc/cpuinfo|wc -l`
DTB=toybrick-$2

function help()
{
	echo "Usage: ./make.sh os board"
	echo
	echo "Parameter:"
	echo "1) os: should be android or linux"
	echo "2) board:"
	echo "   - prod: TB-RK3399ProD"
	echo "   - prop: TB-RK3399ProP"
	echo "   - prox: TB-RK3399ProX"
	echo "   - 96ai: TB-96AI"
	echo
	echo "e.g. ./make.sh android prod"
	echo "     ./make.sh android prop"
	echo "     ./make.sh android 96ai"
	echo "     ./make.sh android prox"
	echo "     ./make.sh linux prod"
	echo "     ./make.sh linux prop"
	echo "     ./make.sh linux 96ai"
    echo "     ./make.sh linux prox"
}

function make_extlinux_conf()
{
	echo "label rockchip-kernel-4.19" > boot_linux/extlinux/extlinux.conf
	echo "	kernel /extlinux/zImage" >> boot_linux/extlinux/extlinux.conf
	echo "	fdt /extlinux/toybrick.dtb" >> boot_linux/extlinux/extlinux.conf
}

function make_toybrick_release()
{	
	echo "Version: Toybrick release 2.0 (initramfs)" > boot_linux/toybrick-release
	echo "Model: TB-RV1126D" >> boot_linux/toybrick-release
	echo "Manufacture ID: TRV11261210100001" >> boot_linux/toybrick-release
}

function make_extlinux_conf_initramfs()
{
	echo "	append  earlycon=uart8250,mmio32,0xff1a0000 initrd=/initramfs-toybrick-${VERSION}.img root=PARTUUID=614e0000-0000-4b53-8000-1d28000054a9 rw rootwait rootfstype=ext4" >> boot_linux/extlinux/extlinux.conf
}

function make_extlinux_conf_rv1126()
{
	echo "	append  earlycon=uart8250,mmio32,0xff570000 console=ttyFIQ0 root=PARTUUID=614e0000-0000-4b53-8000-1d28000054a9 rw rootwait rootfstype=ext4" >> boot_linux/extlinux/extlinux.conf
}

function copy_initramfs()
{
	cp -f initramfs-toybrick-${VERSION}.img boot_linux/
	cp -f rescue.sh boot_linux/
}

if [ $# -lt 2 ];then
	help
	exit 1
fi

case $1 in
	android)
		make rockchip_defconfig
		make ARCH=arm64 rk3399pro-${DTB}-android.img -j${JOB}
		;;
	linux)
		rm -rf boot_linux
		mkdir -p boot_linux/extlinux
		DEFCONFIG=rockchip_linux_defconfig
		ROCKCHIP=rockchip
		case $2 in
			prod)
				DTB=rk3399pro-toybrick-prod-linux
				MODEL="TB-RK3399ProD"
				MACHINE=arm64
				make ARCH=${MACHINE} ${DEFCONFIG}
				make ARCH=arm64 ${DTB}-edp.img -j${JOB}
				make ARCH=arm64 ${DTB}-mipi.img -j${JOB}
				cp -f arch/arm64/boot/dts/rockchip/${DTB}-edp.dtb boot_linux/extlinux/toybrick-edp.dtb
				cp -f arch/arm64/boot/dts/rockchip/${DTB}-mipi.dtb boot_linux/extlinux/toybrick-mipi.dtb
				;;
			prop)
				DTB=rk3399pro-toybrick-prop-linux
				MACHINE=arm64
				;;
			96ai)
				DTB=rk3399pro-toybrick-96ai-linux
				MACHINE=arm64
				;;
			prox)
				DTB=rk3399pro-toybrick-prox-linux
				MACHINE=arm64
                ;;
			rv1126d)
				DTB=rv1126-toybrick-linux
				MACHINE=arm
				DEFCONFIG=rv1126_defconfig
				ROCKCHIP=./
				;;
			rv1126-evb)
				DTB=rv1126-evb-ddr3-v13
				MACHINE=arm
				DEFCONFIG=rv1126_defconfig
				ROCKCHIP=./
				;;
			rv1126-lt7911d)
				DTB=rv1126-lt7911d
				MACHINE=arm
				DEFCONFIG=rv1126_defconfig
				ROCKCHIP=./
				;;
			*)

				help
				exit 1
				;;
		esac
		make ARCH=${MACHINE} ${DEFCONFIG}
		make ARCH=${MACHINE} ${DTB}.img -j${JOB}

		cp -f arch/${MACHINE}/boot/dts/${ROCKCHIP}/${DTB}.dtb boot_linux/extlinux/toybrick.dtb
		cp -f arch/${MACHINE}/boot/dts/${ROCKCHIP}/${DTB}.dtb boot_linux/extlinux/toybrick-default.dtb
		cp -f arch/${MACHINE}/boot/zImage boot_linux/extlinux/
		make_extlinux_conf
		if [ -z `echo $2 | grep rv1126` ]; then
			make_extlinux_conf_initramfs
			copy_initramfs
		else
			make_toybrick_release
			make_extlinux_conf_rv1126
		fi

		if [ "`uname -i`" == "aarch64" ]; then
			echo y | mke2fs -b 4096 -d boot_linux -i 8192 -t ext2 boot_linux.img $((64 * 1024 * 1024 / 4096))
		else
			genext2fs -b 32768 -B $((64 * 1024 * 1024 / 32768)) -d boot_linux -i 8192 -U boot_linux.img
		fi
		;;
	*)
		help
		exit 1
		;;
esac

exit 0

