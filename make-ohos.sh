#!/bin/bash

MAKE64="make ARCH=arm64 CROSS_COMPILE=../../prebuilts/gcc/linux-x86/aarch64/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"
MAKE32="make ARCH=arm CROSS_COMPILE=../../prebuilts/gcc/linux-x86/arm/gcc-linaro-7.5.0-arm-linux-gnueabi/bin/arm-linux-gnueabi-"
CPUs=`sed -n "N;/processor/p" /proc/cpuinfo|wc -l`
MAX_BOARDs=16
KERNEL_SIZE=64
EXTLINUX_BLOCKS=4096
ROOTFS_UUID="PARTUUID=614e0000-0000-4b53-8000-1d28000054a9"
#########################################################################################################################################
# rk356x(rk3566 & rk3568)
#########################################################################################################################################
rk356x_defconfig=rockchip_linux_defconfig
rk356x_defdtb=rk3568-toybrick-core-linux
rk356x_uart=0xff660000
rk356x_arch=arm64
rk356x_image=Image

#model                   flag(the top six of SN)  dts                           multi
product_TB_RK3568C1_C="  TC031C                   rk3568-toybrick-core-linux    1"
product_TB_RK3568X0="    TX0356                   rk3568-toybrick-core-linux-x0 0"
product_TB_RK3568Xs0="   TXs356                   rk3568-toybrick-core-linux    1"
product_TB_RK3568X1_C="  TX031C                   rk3568-toybrick-core-linux-x0 0"
product_TB_RK3568X0_C="  TX030C                   rk3568-toybrick-core-linux-x0 0"
product_RK3566_EVB2_V11="TE2011                   rk3566-evb2-lp4x-v10-linux    0"
product_RK3568_EVB1_V10="TE1110                   rk3568-evb1-ddr4-v10-linux    0"

product_rk356x=(
	"${product_TB_RK3568C1_C}"
	"${product_TB_RK3568X0}"
	"${product_TB_RK3568Xs0}"
	"${product_TB_RK3568X1_C}"
	"${product_TB_RK3568X0_C}"
	"${product_RK3566_EVB2_V11}"
	"${product_RK3568_EVB1_V10}"
	)

function make_rk356x_image()
{
	MAKE=${MAKE64}
	dts_path=arch/arm64/boot/dts/rockchip

	rm -rf ${dts_path}/*.dtb
	${MAKE} ${rk356x_defconfig}
	if [ $? -ne 0 ]; then
		echo "make ${rk356x_defconfig} failed!"
		exit 1
	fi
	${MAKE} ${rk356x_defdtb}.img -j${CPUs}
	if [ $? -ne 0 ]; then
		echo "make ${rk356x_defdtb}.img failed!"
		exit 1
	fi
	cp arch/arm64/boot/Image boot_linux/extlinux/

	for p in "${product_rk356x[@]}"; do
		product=(${p})
		flag=${product[0]}
		dtb_name=${product[1]}
		multi=${product[2]}
		if [ ${multi} -eq 1 ]; then
			for i in $(seq 0 ${MAX_BOARDs}); do
				if [ ! -f ${dts_path}/${dtb_name}-x${i}.dts ]; then
					continue
				fi
				${MAKE} -f ./scripts/Makefile.build obj=${dts_path} ${dts_path}/${dtb_name}-x${i}.dtb srctree=./ objtree=./
				if [ $? -ne 0 ]; then
					echo "make ${dtb_name}-x${i}.dtb failed!"
					exit 1
				fi
				dtb_file=toybrick.dtb.${flag}.${i}
				conf_path=boot_linux/extlinux/extlinux.conf.${flag}.${i}
				cp ${dts_path}/${dtb_name}-x${i}.dtb boot_linux/extlinux/${dtb_file}
				echo "label rockchip-kernel-4.19" > ${conf_path}
				echo "	kernel /extlinux/${rk356x_image}" >> ${conf_path}
				echo "	fdt /extlinux/${dtb_file}" >> ${conf_path}
				echo "	append earlycon=uart8250,mmio32,${rk356x_uart} root=PARTUUID=${ROOTFS_UUID} rw rootwait rootfstype=ext4" >> ${conf_path}
			done
		else
			${MAKE} -f ./scripts/Makefile.build obj=${dts_path} ${dts_path}/${dtb_name}.dtb srctree=./ objtree=./
			if [ $? -ne 0 ]; then
				echo "make ${dtb_name}.dtb failed!"
				exit 1
			fi
			dtb_file=toybrick.dtb.${flag}
			conf_path=boot_linux/extlinux/extlinux.conf.${flag}
			cp ${dts_path}/${dtb_name}.dtb boot_linux/extlinux/${dtb_file}
			echo "label rockchip-kernel-4.19" > ${conf_path}
			echo "	kernel /extlinux/${rk356x_image}" >> ${conf_path}
			echo "	fdt /extlinux/${dtb_file}" >> ${conf_path}
			echo "	append earlycon=uart8250,mmio32,${rk356x_uart} root=PARTUUID=${ROOTFS_UUID} rw rootwait rootfstype=ext4" >> ${conf_path}
		fi
	done
}

function make_boot_linux()
{
	blocks=${EXTLINUX_BLOCKS}
	block_size=$((${KERNEL_SIZE} * 1024 * 1024 / ${blocks}))
	if [ "`uname -i`" == "aarch64" ]; then
		echo y | mke2fs -b ${block_size} -d boot_linux -i 8192 -t ext2 boot_linux.img ${blocks}
	else
		genext2fs -B ${blocks} -b ${block_size} -d boot_linux -i 8192 -U boot_linux.img
	fi
}

function help()
{
	echo "Usage: ./make-linux.sh {rk356x}"
}
rm -rf boot_linux
mkdir -p boot_linux/extlinux
touch boot_linux/extlinux/extlinux.conf

case $1 in
	rk356x)
		make_rk356x_image
		;;
	*)
		help
		exit 1	
		;;
esac

make_boot_linux
