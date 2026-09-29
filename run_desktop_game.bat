@echo off
title Desert Warz Simulator 3D - Desktop Edition
echo ===================================================
echo   DESERT WARZ SIMULATOR 3D (PC DESKTOP EDITION)
echo   Powered by Godot 4 & Vulkan (NVIDIA RTX 4050)
echo ===================================================
echo Membuka Game Desktop...
start "" "%~dp0tools\Godot_v4.3-stable_win64.exe" --path "%~dp0desktop_simulator"
exit
