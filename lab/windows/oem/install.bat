@echo off
rem Runs once at the end of the automatic Windows installation (dockur/windows /oem).
rem Promotes the server to the lab.test domain controller; seed.ps1 fills the domain after reboot.
powershell -NoProfile -ExecutionPolicy Bypass -File C:\OEM\setup.ps1 > C:\OEM\setup.log 2>&1
