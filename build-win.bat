@echo off
echo TechOS Build script for Windows
echo.

path %path%;%CD%\build_programs

echo Assembling bootloader...
cd source\bootloader
nasm -O0 -f bin -o boot.bin boot.asm
cd ..

echo Assembling TechOS kernel...
nasm -O0 -f bin -o kernel.bin kernel.asm
nasm -O0 -f bin -o techosk.sys techosk.asm

echo Assembling programs...
cd ..\programs
 for %%i in (*.asm) do nasm -O0 -fbin %%i
 for %%i in (*.bin) do del %%i
 for %%i in (*.) do ren %%i %%i.bin
cd ..

echo Adding bootsector to disk image...
partcopy "%CD%\source\bootloader\boot.bin" "%CD%\disk_images\techos.flp" 0h 511d

echo Mounting disk image...
imdisk -a -f disk_images\techos.flp -s 1440K -m B:

echo Copying kernel and applications to disk image...
copy source\kernel.bin b:\
copy source\techosk.sys b:\
copy programs\*.bin b:\
copy programs\*.bas b:\
copy programs\*.pcx b:\
copy programs\*.txt b:\
copy diskfiles\avignon.snd b:\
copy diskfiles\*.bin b:\
copy diskfiles\bfmbl.prg b:\
copy diskfiles\backgrnd.aap b:\
copy diskfiles\menu.txt b:\

echo Dismounting disk image...
imdisk -D -m B:

del disk_images\techos.ima
copy disk_images\techos.flp disk_images\techos.ima

echo Creating CD-ROM ISO image...

cd disk_images
del techos.iso
mkisofs -quiet -V TECHNOLOGY -input-charset iso8859-1 -o techos.iso -b techos.ima .
cd ..

echo Done!
pause
