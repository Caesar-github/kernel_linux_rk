#!/bin/bash

JOB=`sed -n "N;/processor/p" /proc/cpuinfo|wc -l`

function help()
{
	echo "Usage: ./make-android.sh ARCH BOOTIMG DTS"
	echo ""
	echo "e.g. ./make-android.sh arm64 ../rockdev/Image-rk3399pro-Android10 rk3399pro-toybrick-prod-android"
	echo ""
}

if [ $# -lt 3 ];then
        help
        exit 1
fi

make ARCH=$1 rockchip_defconfig android-10.config
make ARCH=$1 BOOT_IMG=$2/boot.img $3.img -j${JOB}
