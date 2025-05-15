#!/bin/sh

KERNEL=$1
ROOTFS=$2
DTB=$3

qemu-system-aarch64 \
   -M virt \
   -cpu cortex-a53 \
   -kernel $KERNEL \
   -dtb $DTB \
   -append "console=ttyAMA0 earlycon root=/dev/vda rw init=/sbin/init" \
   -drive file=$ROOTFS,format=raw,if=none,id=hd0 \
   -device virtio-blk-device,drive=hd0 \
   -nographic