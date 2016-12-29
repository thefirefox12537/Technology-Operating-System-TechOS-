@echo off
cd emulator
bochs -q -f bochsrc.bxrc
if exist log.txt del /q log.txt
cd ..