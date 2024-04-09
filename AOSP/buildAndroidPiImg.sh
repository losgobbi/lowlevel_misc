#!/bin/bash

set -x
#
# Copyright (C) 2021-2022 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

# based on https://github.com/raspberry-vanilla/android_device_brcm_rpi4/blob/android-14.0/mkimg.sh
VERSION=RaspberryAOSP14
DATE=$(date +%Y%m%d)
IMGNAME=${VERSION}-${DATE}-rpi4.img
IMGSIZE=7
OUTDIR=.
ANDROID_TOP_DIR=/media/gobbi/ssd_workspace3/android_14_rpi
ANDROID_OUT_DIR=${ANDROID_TOP_DIR}/out/target/product/rpi4
GKI_OUT_DIR=/media/gobbi/ssd/tmp_workspace/out/arpi14-6.1/dist

echo "Creating image file ${OUTDIR}/${IMGNAME}..."
sudo dd if=/dev/zero of="${OUTDIR}/${IMGNAME}" bs=1M count=$(echo "${IMGSIZE}*1024" | bc)
sync

echo "Creating partitions..."
(
echo o
echo n
echo p
echo 1
echo
echo +128M
echo n
echo p
echo 2
echo
echo +2048M
echo n
echo p
echo 3
echo
echo +256M
echo n
echo p
echo
echo
echo t
echo 1
echo c
echo a
echo 1
echo w
) | sudo fdisk "${OUTDIR}/${IMGNAME}"
sync

LOOPDEV=$(sudo kpartx -av "${OUTDIR}/${IMGNAME}" | awk 'NR==1{ sub(/p[0-9]$/, "", $3); print $3 }')
if [ -z ${LOOPDEV} ]; then
  echo "Unable to find loop device!"
  exit 1
fi
echo "Image mounted as /dev/${LOOPDEV}"
sleep 1

echo "Copying boot..."
#sudo dd if=${ANDROID_DIR}/boot.img of=/dev/mapper/${LOOPDEV}p1 bs=1M
sudo mkfs.vfat /dev/mapper/${LOOPDEV}p1
sudo mkdir -p boot_dir
sudo mount /dev/mapper/${LOOPDEV}p1 boot_dir
sudo cp -v ${ANDROID_TOP_DIR}/device/arpi/rpi4/boot/* boot_dir
sudo cp -v ${ANDROID_OUT_DIR}/ramdisk.img boot_dir
sudo cp -v ${GKI_OUT_DIR}/bcm2711-rpi*.dtb boot_dir
sudo mkdir -p boot_dir/overlays/
sudo cp -v ${GKI_OUT_DIR}/vc4-kms-v3d-pi4.dtbo boot_dir/overlays/
sudo cp -v ${GKI_OUT_DIR}/Image.gz boot_dir
sudo umount boot_dir

echo "Copying system..."
sudo dd if=${ANDROID_OUT_DIR}/system.img of=/dev/mapper/${LOOPDEV}p2 bs=1M

echo "Copying vendor..."
sudo dd if=${ANDROID_OUT_DIR}/vendor.img of=/dev/mapper/${LOOPDEV}p3 bs=1M

echo "Creating userdata..."
sudo mkfs.ext4 /dev/mapper/${LOOPDEV}p4 -I 512 -L userdata
sync

sudo kpartx -d "/dev/${LOOPDEV}"
echo "Done, created ${OUTDIR}/${IMGNAME}!"

exit 0