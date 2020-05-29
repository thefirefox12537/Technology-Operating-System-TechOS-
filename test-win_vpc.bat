@echo off
echo Starting using Virtual PC . . . .
if not "%PROCESSOR_ARCHITECTURE%"=="X86" goto 64bit
start /wait "%programfiles%\Microsoft Virtual PC\virtual pc.exe" -startvm "%cd%\emulator\TechOS.vmc"
if errorlevel 1 goto error
exit

:64bit
start /wait "%programfiles(x86)%\Microsoft Virtual PC\virtual pc.exe" -startvm "%cd%\emulator\TechOS.vmc"
if errorlevel 1 goto error
exit

:error
echo Virtual PC not installed.
pause
exit
