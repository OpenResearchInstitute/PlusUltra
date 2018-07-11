# Petalinux project for Avnet Ultra96

This repository is used for some controlled experiments with the Avnet Ultra96 board.
It contains a Petalinux project (hardware and software), that will hopefully accomplish
the following:
* Provide a stable, up-to-date base system with boot loaders, device tree and kernels
* Support a Debian Stretch userland
* Support all relevant hardware, particularly the Wi-FI/BT chipset
* Be able to Boot with a USB Ethernet adapter, possibly also mount the rootfs via NFS

## How to build
* Make sure you are not on an ecryptfs file system (path restrictions will trip up Yocto)
* run `petalinux-build`
* run `petalinux-package --boot --force --fsbl zynqmp_fsbl.elf --fpga system.bit --u-boot --pmufw pmufw.elf`

