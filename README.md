# Petalinux project for Avnet Ultra96
This repository contains a Petalinux project (hardware and software) for the Avnet Ultra96 board. It consists of a Vivado hardware definition, Linux kernel, PetaLinux-based OS and assorted bootloaders, and will hopefully be a stable platform option for SDR (Software Defined Radio) experimentation.

Right now, the changes from the original Xilinx Ultra96 BSP image are:
* Rewired the console port to come out of the console connector
* Added drivers for some popular Realtek-based USB Ethernet dongles (so you can use Ethernet, or even TFTP-boot!)
* Applied the Xilinx fix for the power button not turning the machine off (AR71722)
* Add sshd, Python3, SWIG, Sqlite, VFIO
* Remove a bunch of demo software
* Coming soon: [fan speed control](https://www.hackster.io/andycap/ultra96-fan-control-21fb8b)! This thing is way too loud.
* Coming soon: make this into a platform for SDSoC. [A great article on this subject has been
   published by Anuj Vaishnav recently](https://www.hackster.io/anujvaishnav20/building-custom-sdsoc-platform-with-petalinux-268bfd), which should make this quite achievable.
* Coming soon: Binaries, so anybody can try this out without 10s of GB of downloads, hours of computation and gobs of disk space.

This is built with the 2018.2 versions of Vivado as well as PetaLinux. There is a branch for
migration to 2018.3, but I put this on hold for the time being. It appears that the support
for SDSoC is a lot more mature with 2018.2. The only known deficiency for now is the 
inability of the included UBoot version to write its environment into a disk file. For 
the moment, I can live with this.

# What's with the name?
PlusUltra is the negation of "Non plus ultra" (which means for "Nothing further beyond"). It is also the national motto of Spain.

# Building a system
make sure you clone this repository using the `--recursive` git option, as this project contains a git submodule. Forgot to do that? No problem, just run `git submodule update --recursive` from a command line, which will take care of updating the submodule.

## Building the hardware project
You need Xilinx Vivado 2018.2 for this part. Open the project `hardware/xilinx-ultra96-reva-2018.2/xilinx-ultra96-reva-2018.2.xpr`, and make any changes you desire. Build the bitstream. If it is successful, you want to export the hardware definition to the default location (make sure to check the checkbox to include the bitfile). Then you can proceed to build a matching software image.

## Building the software
You will need an installation of Petalinux 2018.2 from Xilinx (please note that this needs to be installed on a Linux machine). Refer to the Xilinx documentation on how to do this, specifically [chapter 2 of UG1144](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_2/ug1144-petalinux-tools-reference-guide.pdf#G4.364401), which lists the installation requirements.
Please make sure you are not building this on an ecryptfs file system, as path length restrictions will probably trip you up!

* Don't forget to import the Petalinux system variables
* Change directories to the root of the project
* run `petalinux-config --get-hw-description hardware/xilinx-ultra96-reva-2018.2/xilinx-ultra96-reva-2018.2.sdk`. If you are presented with a configuration screen, you can exit out, the default options should work.
* run `petalinux-build`
* This is going to take a while.
* No, really, find something else to do.
* Change directory to `images/linux`
* run `petalinux-package --boot --force --fsbl zynqmp_fsbl.elf --fpga system.bit --u-boot --pmufw pmufw.elf`. This will create a file `BOOT.BIN` that contains boot loaders and the FPGA image.

## Deploying to hardware
You will need an SD card that is partitioned and formatted into two partitions:
* A FAT32 partition of a few 100 MB
* An ext4 partition for the rest of the SD card

You will want to copy the build products `image.ub` and `BOOT.bin` to the FAT32 partition. The other partition is for the root file system, and Petalinux has helpfully packaged that up for you in a million different ways. The easiest way to get this onto the SD card (given that you are on a Linux machine anyway) is to use tar onto the SD partion. For example, if the ext4 partition is mounted on your PC as `/media/foo`, you want to run `sudo tar xvf rootfs.tar.gz -C /media/foo`. This needs to be run with `sudo` to get the right permissions onto the file system.

# Booting and playing around.
Insert the SD card into your Ultra96 board and power it up. If you have a console connected to the console connector, you should see the boot progressing. Either way, you should be able to connect the board the same way that you connected to it with the out-of-the-box image.

# Contributing to this effort
Congratulations, you are now running your first home-baked hardware and software image! If you find anything wrong or broken, please submit an issue, or make it better by sending a pull-request with your improvments. Even if you have never done it before. *Especially* if you have never done it before! Don't worry about "doing it right", we can figure it out together. 
If you want to contribute but don't know what, documentation is always a good place to start.
