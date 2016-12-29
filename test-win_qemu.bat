@echo off
cd emulator
qemu -fda ..\disk_images\techos.ima -m 10 -soundhw pcspk
cd ..
