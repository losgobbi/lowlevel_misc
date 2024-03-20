#!/bin/bash

#### install kernel selftests from buildroot and run qemu

set -x

# variables
BUILDROOT_DIR=/opt/buildroot_topdir/build_cfg_files/buildroot
KERNEL_DIR=linux-v6.8-rc5

sudo mkdir -p $BUILDROOT_DIR/root_loop
sudo mount -o loop $BUILDROOT_DIR/images/rootfs.ext2 $BUILDROOT_DIR/root_loop
sleep 2

# install selftests
cd $BUILDROOT_DIR/build/$KERNEL_DIR/tools/testing/selftests
sudo mkdir -p $BUILDROOT_DIR/root_loop/tests
sudo ./kselftest_install.sh $BUILDROOT_DIR/root_loop/tests
sudo umount $BUILDROOT_DIR/root_loop

# run
qemu-system-x86_64 \
    -kernel /opt/buildroot_topdir/build_cfg_files/buildroot/images/bzImage \
    -nographic -append "root=/dev/sda console=ttyS0 hugepages=512" \
    -hda /opt/buildroot_topdir/build_cfg_files/buildroot/images/rootfs.ext2 \
    -m 12G \
    -smp 8 # not very stable for some tests