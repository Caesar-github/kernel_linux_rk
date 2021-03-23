#!/bin/bash

CPUs=`sed -n "N;/processor/p" /proc/cpuinfo|wc -l`
DEFCONFIG=
#####################################################################################################################
#        model          flag  arch  chip      uart       dtb                           image           fconfig
#####################################################################################################################
model_arm64=(
	"TB-RK3399ProD  TD03310 arm64 rk3399pro 0xff1a0000 rk3399pro-toybrick-prod-linux Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProDs TDs3310 arm64 rk3399pro 0xff1a0000 rk3399pro-toybrick-prod-linux Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProP  TP03310 arm64 rk3399pro 0xff1a0000 rk3399pro-toybrick-prop-linux Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProPs TPs3310 arm64 rk3399pro 0xff1a0000 rk3399pro-toybrick-prop-linux Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProX-x00  TX03310 arm64 rk3399pro 0xff1a0000 rk3399pro-toybrick-prox-x00-linux Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProXs-x00 TXs3310 arm64 rk3399pro 0xff1a0000 rk3399pro-toybrick-prox-x00-linux Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProX-x01  TX03310 arm64 rk3399pro 0xff1a0000 rk3399pro-toybrick-prox-x01-linux Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProXs-x01 TXs3310 arm64 rk3399pro 0xff1a0000 rk3399pro-toybrick-prox-x01-linux Image.rockchip  rockchip_linux_defconfig"
	#"TB-RK1808M0    TM01808 arm64 rk1808    0xff550000 rk1808-toybrick-m0            Image.rk1808    rk1808_linux_defconfig"
	#"TB-RK1808S0    TS01808 arm64 rk1808    0xff550000 rk1808-toybrick-s0            Image.rk1808    rk1808_linux_defconfig"
	#"TB-RK1808CAM0  TC01808 arm64 rk1808    0xff550000 rk1808-toybrick-cam0          Image.rk1808    rk1808_linux_defconfig"
	#"TB-RK3568D     TD03568 arm64 rk3568    
	#"TB-RK3568Ds    TDs3568 arm64 rk3568    
	)

model_arm=(
	"TB-RV1126D    TR01126 arm   rv1126    0xff1a0000  rv1126-toybrick-linux         zImage.rv1126   rv1126_defconfig"
	"TB-RV1126Ds   TRs1126 arm   rv1126    0xff1a0000  rv1126-toybrick-linux         zImage.rv1126   rv1126_defconfig"
	"TB-ToyT01     TRt1126 arm   rv1126    0xff1a0000  rv1126-toybrick-ToyT01        zImage.rv1126   rv1126_defconfig"
	)
#####################################################################################################################

function help()
{
	echo "Usage: ./make.sh ARCH"
	echo "e.g."
	echo "  ./make-linux.sh arm"
	echo "  ./make-linux.sh arm64"
	echo
	echo "Usage: ./make-linux.sh MODEL"
	echo "e.g."
	for i in "${model_arm[@]}"; do
		echo "  ./make-linux.sh $(echo $i | awk '{print $1}')"
	done
	for i in "${model_arm64[@]}"; do
		echo "  ./make-linux.sh $(echo $i | awk '{print $1}')"
	done
}

# Make all toybrick dts:
function make_toybrick_dtb()
{
	model_arch=$1
	if [ ${model_arch} == "arm" ]; then
		dts_path=arch/arm/boot/dts
	else
		dts_path=arch/arm64/boot/dts/rockchip
	fi
	rm -rf ${dts_path}/*.dtb
	dts_list=`ls ${dts_path}/*-toybrick*.dts | awk -F'.' '{print $1}'`
	for d in ${dts_list}; do
		make -f ./scripts/Makefile.build obj=${dts_path} ${d}.dtb srctree=./ objtree=./
	done
	cp ${dts_path}/*toybrick*.dtb boot_linux/extlinux/
}

function make_extlinux_conf()
{
	model=$1
	flag=$2
	model_arch=$3
	chip=$4
	uart=$5
	dtb_name=$6
	image=$7
	config=$8
	no_sn=$9

	if [ ${no_sn} -eq 1 ]; then
		file=boot_linux/extlinux/extlinux.conf
		cp boot_linux/extlinux/${dtb_name}.dtb  boot_linux/extlinux/toybrick.dtb
		echo "label rockchip-kernel-4.19" > ${file}
		echo "	kernel /extlinux/${image}" >> ${file}
		echo "	fdt /extlinux/toybrick.dtb" >> ${file}
		echo "	append  earlycon=uart8250,mmio32,$5 root=PARTUUID=614e0000-0000-4b53-8000-1d28000054a9 rw rootwait rootfstype=ext4" >> ${file}
	else
		file=boot_linux/extlinux/extlinux.conf.${flag}
		cp boot_linux/extlinux/${dtb_name}.dtb  boot_linux/extlinux/toybrick.dtb.${flag}
		echo "label rockchip-kernel-4.19" > ${file}
		echo "	kernel /extlinux/${image}" >> ${file}
		echo "	fdt /extlinux/toybrick.dtb.$2" >> ${file}
		echo "	append  earlycon=uart8250,mmio32,$5 root=PARTUUID=614e0000-0000-4b53-8000-1d28000054a9 rw rootwait rootfstype=ext4" >> ${file}
	fi
	
}

function make_kernel_image()
{
	model=$1
	flag=$2
	model_arch=$3
	chip=$4
	uart=$5
	dtb_name=$6
	image=$7
	config=$8

	if [ "${config}" != "${DEFCONFIG}" ]; then
		make ARCH=${model_arch} ${config}
		make ARCH=${model_arch} ${dtb_name}.img -j${CPUs}
		cp arch/${model_arch}/boot/`echo ${image} | awk -F'.' '{print $1}'` boot_linux/extlinux/${image} 
		DEFCONFIG=${config}
	fi
}

function make_boot_linux()
{
	if [ "`uname -i`" == "aarch64" ]; then
		echo y | mke2fs -b 4096 -d boot_linux -i 8192 -t ext2 boot_linux.img $((64 * 1024 * 1024 / 4096))
	else
		genext2fs -b 32768 -B $((64 * 1024 * 1024 / 32768)) -d boot_linux -i 8192 -U boot_linux.img
	fi
}

rm -rf boot_linux
mkdir -p boot_linux/extlinux
touch boot_linux/extlinux/extlinux.conf
case $1 in
	arm)
		make_toybrick_dtb arm
		for i in "${model_arm[@]}"; do
			make_kernel_image $i
			make_extlinux_conf $i 0
		done
		;;
	arm64)
		make_toybrick_dtb arm64
		for i in "${model_arm64[@]}"; do
			make_kernel_image $i
			make_extlinux_conf $i 0
		done
		;;
	*)
		found=0
		if [ $# -eq 1 ]; then
			for i in "${model_arm[@]}"; do
				if [ "$(echo $i | awk '{print $1}')" == "$1" ]; then
					make_toybrick_dtb $(echo $i | awk '{print $3}')
					make_kernel_image $i
					make_extlinux_conf $i 1
					found=1
				fi
			done
			for i in "${model_arm64[@]}"; do
				if [ "$(echo $i | awk '{print $1}')" == "$1" ]; then
					make_toybrick_dtb $(echo $i | awk '{print $3}')
					make_kernel_image $i
					make_extlinux_conf $i 1
					found=1
				fi
			done
			if [ ${found} -eq 0 ]; then
				help
				exit 1
			fi
		else
			help
			exit 1
		fi
esac

make_boot_linux
