#!/bin/sh

# This script assembles the TechOS bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on Mac OS X)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files


echo "TechOS OS X build script - requires nasm and mkisofs"


if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi


echo "Assembling bootloader..."

nasm -O0 -f bin -o source/bootloader/boot.bin source/bootloader/boot.asm || exit


echo "Assembling TechOS kernel..."

cd source
nasm -O0 -f bin -o kernel.bin kernel.asm || exit
nasm -O0 -f bin -o techosk.sys techosk.asm || exit
cd ..


echo "Assembling programs..."

cd programs

for i in *.asm
do
	nasm -O0 -f bin $i -o `basename $i .asm`.bin || exit
done

cd ..

echo "Creating floppy..."
cp disk_images/techos.flp disk_images/techos.dmg


echo "Adding bootloader to floppy image..."

dd conv=notrunc if=source/bootloader/boot.bin of=disk_images/techos.dmg || exit


echo "Copying TechOS kernel and programs..."

rm -rf tmp-loop

dev=`hdid -nobrowse -nomount disk_images/techos.dmg`
mkdir tmp-loop && mount -t msdos ${dev} tmp-loop && cp source/kernel.bin tmp-loop/ && cp source/techosk.sys tmp-loop/

cp programs/*.bin tmp-loop && cp programs/*.bas tmp-loop && cp programs/*.pcx tmp-loop && cp programs/*.txt tmp-loop
cp diskfiles/avignon.snd tmp-loop/ && cp diskfiles/*.bin tmp-loop && cp diskfiles/bfmbl.prg tmp-loop/ && cp diskfiles/backgrnd.aap tmp-loop/ && cp diskfiles/menu.txt tmp-loop/

echo "Unmounting loopback floppy..."

umount tmp-loop || exit
hdiutil detach ${dev}

rm -rf tmp-loop

echo "TechOS floppy image is disk_images/techos.dmg"

rm -f disk_images/techos.ima
cp disk_images/techos.dmg disk_images/techos.ima

echo "Creating CD-ROM ISO image..."

rm -f disk_images/techos.iso
mkisofs -quiet -V 'TECHNOLOGY' -input-charset iso8859-1 -o disk_images/techos.iso -b techos.dmg disk_images/ || exit

echo 'Done!'

