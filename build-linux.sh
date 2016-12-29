#!/bin/sh

# This script assembles the TechOS bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on Linux)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files

# (If you need to blank the floppy image: 'mkdosfs disk_images/techos.flp')


if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi


if [ ! -e disk_images/techos.flp ]
then
	echo "Creating new TechOS floppy image..."
	mkdosfs -C disk_images/techos.flp 1440 || exit
fi


echo "Assembling bootloader..."

nasm -O0 -w+orphan-labels -f bin -o source/bootloader/boot.bin source/bootloader/boot.asm || exit


echo "Assembling TechOS kernel..."

cd source
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
nasm -O0 -w+orphan-labels -f bin -o techosk.sys techosk.asm || exit
cd ..


echo "Assembling programs..."

cd programs

for i in *.asm
do
	nasm -O0 -w+orphan-labels -f bin $i -o `basename $i .asm`.bin || exit
done

cd ..


echo "Adding bootloader to floppy image..."

dd status=noxfer conv=notrunc if=source/bootloader/boot.bin of=disk_images/techos.flp || exit


echo "Copying TechOS kernel and programs..."

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat disk_images/techos.flp tmp-loop && cp source/kernel.bin tmp-loop/ && cp source/techosk.sys tmp-loop/

cp programs/*.bin tmp-loop && cp programs/*.bas tmp-loop && cp programs/*.pcx tmp-loop && cp programs/*.txt tmp-loop
cp diskfiles/avignon.snd tmp-loop/ && cp diskfiles/*.bin tmp-loop && cp diskfiles/bfmbl.prg tmp-loop/ && cp diskfiles/backgrnd.aap tmp-loop/ && cp diskfiles/menu.txt tmp-loop/

sleep 0.2

echo "Unmounting loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop

rm -f disk_images/techos.ima
cp disk_images/techos.flp disk_images/techos.ima

echo "Creating CD-ROM ISO image..."

rm -f disk_images/techos.iso
mkisofs -quiet -V 'TECHNOLOGY' -input-charset iso8859-1 -o disk_images/techos.iso -b techos.flp disk_images/ || exit

echo 'Done!'

