@echo off
cd emulator
call .\TechOS.vmc
if errorlevel 1 goto error
cd..
exit

:error
cls
echo Virtual PC not installed.
pause
cd ..
exit