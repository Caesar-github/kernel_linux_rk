#!/bin/bash

CPUs=`sed -n "N;/processor/p" /proc/cpuinfo|wc -l`
DEFCONFIG=
#########################################################################################################################################
#        model           flag    arch  chip      uart       dtb                           index  image           defconfig		
#########################################################################################################################################
model_arm64=(
	"TB-RK3399ProD   TD0331 arm64 RK3399Pro 0xff1a0000 rk3399pro-toybrick-prod-linux -1     Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProDs  TDs331 arm64 RK3399pro 0xff1a0000 rk3399pro-toybrick-prod-linux -1     Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProP   TP0331 arm64 RK3399Pro 0xff1a0000 rk3399pro-toybrick-prop-linux -1     Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProPs  TPs331 arm64 RK3399Pro 0xff1a0000 rk3399pro-toybrick-prop-linux -1     Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProX0  TX0331 arm64 RK3399Pro 0xff1a0000 rk3399pro-toybrick-prox-linux 0      Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProXs0 TXs331 arm64 RK3399Pro 0xff1a0000 rk3399pro-toybrick-prox-linux 0      Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProX1  TX0331 arm64 RK3399Pro 0xff1a0000 rk3399pro-toybrick-prox-linux 1      Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3399ProXs1 TXs331 arm64 RK3399Pro 0xff1a0000 rk3399pro-toybrick-prox-linux 1      Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3568X0     TX0356 arm64 RK3568    0xff660000 rk3568-toybrick-core-linux    -1     Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3568Xs0    TXs356 arm64 RK3568    0xff660000 rk3568-toybrick-core-linux    -1     Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3568X1     TX0356 arm64 RK3568    0xff660000 rk3568-toybrick-core-linux    -1     Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3568Xs1    TXs356 arm64 RK3568    0xff660000 rk3568-toybrick-core-linux    -1     Image.rockchip  rockchip_linux_defconfig"
	"TB-RK3568C1-C   TC031C arm64 RK3568    0xff660000 rk3568-toybrick-core-linux    -1     Image.rockchip  rockchip_linux_defconfig"
	#                T---TB  C--C 03---RK3568 1C---1-C
	#"TB-RK1808M0     TM01808 arm64 RK1808    0xff550000 rk1808-toybrick-m0            -1     Image.RK1808    RK1808_linux_defconfig"
	#"TB-RK1808S0     TS01808 arm64 RK1808    0xff550000 rk1808-toybrick-s0            -1     Image.RK1808    RK1808_linux_defconfig"
	#"TB-RK1808CAM0   TC01808 arm64 RK1808    0xff550000 rk1808-toybrick-cam0          -1     Image.RK1808    RK1808_linux_defconfig"
	#"TB-RK3568D      TD03568 arm64 RK3568    0xff660000 rk3568-toybrick-dev-linux     -1     Image.rockchip  rockchip_linux_defconfig"  
	#"TB-RK3568Ds     TDs3568 arm64 RK3568    0xff660000 rk3568-toybrick-dev-linux     -1     Image.rockchip  rockchip_linux_defconfig"  
	)

model_arm=(
	"TB-RV1126D    TR01126 arm   rv1126    0xff570000  rv1126-toybrick-linux          -1     zImage.rv1126   rv1126_defconfig"
	"TB-RV1126Ds   TRs1126 arm   rv1126    0xff570000  rv1126-toybrick-linux          -1     zImage.rv1126   rv1126_defconfig"
	"TB-ToyT01     TRt1126 arm   rv1126    0xff570000  rv1126-toybrick-ToyT01         -1     zImage.rv1126   rv1126_defconfig"
	)

model_ubifs=(
	"TB-MI         TRt1126 arm   rv1126    0xff570000  rv1126-toybrick-mi             -1     zImage.rv1126   rv1126_defconfig"
	)
###########################################################################################################################################

UBIFS_KERNEL_SIZE=8
EXT4_KERNEL_SIZE=64
BLOCKS=4096

function help()
{
	echo "Usage: ./make-linux.sh {arm|arm64}"
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
	for i in "${model_ubifs[@]}"; do
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

function _make_extlinux_conf()
{
	file=$1
	src_dtb=$2
	dst_dtb=$3
	image=$4
	filesystem=$5
	cp boot_linux/extlinux/${src_dtb} boot_linux/extlinux/${dst_dtb}
	echo "label rockchip-kernel-4.19" > boot_linux/extlinux/${file}
	echo "	kernel /extlinux/${image}" >> boot_linux/extlinux/${file}
	echo "	fdt /extlinux/${dst_dtb}" >> boot_linux/extlinux/${file}
	case ${filesystem} in
	ext4)
		echo "	append earlycon=uart8250,mmio32,${uart} root=PARTUUID=614e0000-0000-4b53-8000-1d28000054a9 rw rootwait rootfstype=ext4" >> boot_linux/extlinux/${file}
		;;
	ubifs)
		echo "	append earlycon=uart8250,mmio32,${uart} printk.time=1 ubi.mtd=3 root=ubi0.rootfs rw rootwait rootfstype=ubifs initcall_debug=1" >> boot_linux/extlinux/${file}
		;;
	*)
		echo Unsupproted filesystem ...
		exit 1
		;;
	esac
}

function make_extlinux_conf()
{
	model=$1
	flag=$2
	model_arch=$3
	chip=$4
	uart=$5
	dtb_name=$6
	index=$7
	image=$8
	config=$9
	filesystem=${10}
	no_sn=${11}

	if [ ${no_sn} -eq 1 ]; then
		file=extlinux.conf
		dst_dtb=toybrick.dtb
		if [ ${index} -ne -1 ]; then
			src_dtb=${dtb_name}-x${index}.dtb
		else
			src_dtb=${dtb_name}.dtb
		fi
		_make_extlinux_conf ${file} ${src_dtb} ${dst_dtb} ${image} ${filesystem}
	fi
	if [ ${index} -ne -1 ]; then
		file=extlinux.conf.${flag}.${index}
		dst_dtb=toybrick.dtb.${flag}.${index}
		src_dtb=${dtb_name}-x${index}.dtb
	else
		file=extlinux.conf.${flag}
		dst_dtb=toybrick.dtb.${flag}
		src_dtb=${dtb_name}.dtb
	fi
	_make_extlinux_conf ${file} ${src_dtb} ${dst_dtb} ${image} ${filesystem}

	if [ ${index} -ne -1 ]; then
		# uboot will load this config to get the index of the mainboard
		# see arch/arm/include/asm/arch-rockchip/toybrick.h for the detail
		file=extlinux.conf.${flag}
		dst_dtb=toybrick.dtb.${flag}
		src_dtb=${dtb_name}.dtb
		_make_extlinux_conf ${file} ${src_dtb} ${dst_dtb} ${image} ${filesystem}
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
	index=$7
	image=$8
	config=$9
	filesystem=${10}

	if [ "${config}" != "${DEFCONFIG}" ]; then
		make ARCH=${model_arch} ${config}
		if [ ${index} -ne -1 ]; then
			make ARCH=${model_arch} ${dtb_name}-x${index}.img -j${CPUs}
		else
			make ARCH=${model_arch} ${dtb_name}.img -j${CPUs}
		fi
		cp arch/${model_arch}/boot/`echo ${image} | awk -F'.' '{print $1}'` boot_linux/extlinux/${image} 
		DEFCONFIG=${config}
	fi
}

function make_boot_linux()
{
	if [ "$1" == "ubifs" ]; then
		size_m=${UBIFS_KERNEL_SIZE}
	else
		size_m=${EXT4_KERNEL_SIZE}
	fi
	blocks=${BLOCKS}
	block_size=$((${size_m} * 1024 * 1024 / ${blocks}))

	if [ "`uname -i`" == "aarch64" ]; then
		echo y | mke2fs -b ${block_size} -d boot_linux -i 8192 -t ext2 boot_linux.img ${blocks}
	else
		genext2fs -B ${blocks} -b ${block_size} -d boot_linux -i 8192 -U boot_linux.img
	fi
}

rm -rf boot_linux
mkdir -p boot_linux/extlinux
touch boot_linux/extlinux/extlinux.conf
case $1 in
	arm)
		make_kernel_image ${model_arm[0]}
		make_toybrick_dtb arm
		for i in "${model_arm[@]}"; do
			make_kernel_image $i
			make_extlinux_conf $i ext4 0
		done
		make_boot_linux ext4
		;;
	arm64)
		make_kernel_image ${model_arm64[0]}
		make_toybrick_dtb arm64
		for i in "${model_arm64[@]}"; do
			make_kernel_image $i
			make_extlinux_conf $i ext4 0
		done
		make_boot_linux ext4
		;;
	*)
		if [ $# -eq 1 ]; then
			found=0
			for i in "${model_arm[@]}"; do
				if [ "$(echo $i | awk '{print $1}')" == "$1" ]; then
					make_toybrick_dtb $(echo $i | awk '{print $3}')
					make_kernel_image $i
					make_extlinux_conf $i ext4 1
					make_boot_linux ext4
					found=1
				fi
			done
			for i in "${model_arm64[@]}"; do
				if [ "$(echo $i | awk '{print $1}')" == "$1" ]; then
					make_toybrick_dtb $(echo $i | awk '{print $3}')
					make_kernel_image $i
					make_extlinux_conf $i ext4 1
					make_boot_linux ext4
					found=1
				fi
			done
			for i in "${model_ubifs[@]}"; do
				if [ "$(echo $i | awk '{print $1}')" == "$1" ]; then
					make_toybrick_dtb $(echo $i | awk '{print $3}')
					make_kernel_image $i
					make_extlinux_conf $i ubifs 1
					make_boot_linux ubifs
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

