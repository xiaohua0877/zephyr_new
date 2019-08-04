@echo off
set ZEPHYR_BASE=%~dp0

set ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
set GNUARMEMB_TOOLCHAIN_PATH=D:\gnu_arm_embedded

echo  apt:%ZEPHYR_TOOLCHAIN_VARIANT%
echo path:%GNUARMEMB_TOOLCHAIN_PATH%

if exist "%userprofile%\zephyrrc.cmd" (
	call "%userprofile%\zephyrrc.cmd"
)
