#!/bin/bash

#
# Copyright (C) 2021-2022 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

# based on https://github.com/raspberry-vanilla/android_device_brcm_rpi4/blob/android-14.0/mkimg.sh
VERSION=RaspberryAOSP
DATE=$(date +%Y%m%d)
IMGNAME=${VERSION}-${DATE}-rpi4.img
IMGSIZE=7

OUTDIR=.
ANDROID_TOP_DIR=$1
GKI_OUT_DIR=$2
BLOB_DIR=$3
ANDROID_OUT_DIR=${ANDROID_TOP_DIR}/out/target/product/rpi4

function usage() {
  echo "### aosp build helper ###"
  echo "invocation <script> <AOSP_TOP_DIR> <GKI_OUT_DIR> <BLOB_DIR>"
  echo "1 - build android rpi"
  echo "2 - prepare image"
  echo "AOSP_TOP_DIR) AOSP top level"
  echo "GKI_OUT_DIR) folder holding dtb, overlay and kernel image"
  echo "BLOB_DIR) proprietary files"
}

function build_android_rpi() {
  cd $ANDROID_TOP_DIR && source build/envsetup.sh && lunch rpi4-eng && make ramdisk systemimage vendorimage
}

function make_image() {
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

  echo "Creating loop device..."
  LOOPDEV=$(sudo kpartx -av "${OUTDIR}/${IMGNAME}" | awk 'NR==1{ sub(/p[0-9]$/, "", $3); print $3 }')
  if [ -z ${LOOPDEV} ]; then
    echo "Unable to find loop device!"
    exit 1
  fi
  echo "Image mounted as /dev/${LOOPDEV}"
  sleep 1

  if [ -e ${ANDROID_OUT_DIR}/boot.img ]
  then
    echo "Copying boot..."
    sudo dd if=${ANDROID_OUT_DIR}/boot.img of=/dev/mapper/${LOOPDEV}p1 bs=1M
  else
    echo "Copying ramdisk..."
    sudo cp -v ${ANDROID_OUT_DIR}/ramdisk.img boot_dir
  fi
  sudo mkfs.vfat /dev/mapper/${LOOPDEV}p1
  sudo mkdir -p tmp_boot_dir
  sudo mount /dev/mapper/${LOOPDEV}p1 tmp_boot_dir
  sudo cp -v ${BLOB_DIR}/* tmp_boot_dir
  sudo cp -v ${GKI_OUT_DIR}/bcm27*-rpi*.dtb tmp_boot_dir
  sudo mkdir -p tmp_boot_dir/overlays/
  sudo cp -v ${GKI_OUT_DIR}/vc4-kms*.dtbo tmp_boot_dir/overlays/
  sudo cp -v ${GKI_OUT_DIR}/overlays/* tmp_boot_dir/overlays/
  sudo cp -v ${GKI_OUT_DIR}/Image tmp_boot_dir
  sudo umount tmp_boot_dir

  echo "Copying system..."
  sudo dd if=${ANDROID_OUT_DIR}/system.img of=/dev/mapper/${LOOPDEV}p2 bs=1M

  echo "Copying vendor..."
  sudo dd if=${ANDROID_OUT_DIR}/vendor.img of=/dev/mapper/${LOOPDEV}p3 bs=1M

  echo "Creating userdata..."
  sudo mkfs.ext4 /dev/mapper/${LOOPDEV}p4 -I 512 -L userdata
  sync

  sudo kpartx -d "/dev/${LOOPDEV}"
  echo "Done, created ${OUTDIR}/${IMGNAME}!"
}

usage
echo "take a option:"
read -r answer
echo $answer
case $answer in
    "1") build_android_rpi ;;
    "2") make_image ;;
    *) usage;;
esac

exit 0
