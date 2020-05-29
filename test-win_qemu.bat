@echo off
echo Starting using QEMU . . . .
call .\emulator\qemu.exe -fda ..\disk_images\techos.flp -m 10 -soundhw pcspk
