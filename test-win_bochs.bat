@echo off
echo Starting using Bochs . . . .
call .\emulator\bochs -q -f .\emulator\bochsrc.bxrc
if exist log.txt del /q log.txt
if exist emulator\log.txt del /q emulator\log.txt
