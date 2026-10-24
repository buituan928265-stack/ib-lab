# Stage 1: install AD DS and create the lab.test forest. The server reboots at the end.
# Files are ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.
$ErrorActionPreference = 'Stop'
Start-Transcript -Path C:\OEM\setup-transcript.txt -Append

# Lab-only password (same as PASSWORD in compose.yaml). It becomes the LAB\Administrator password.
$plain = 'LabAdmin2026!'
$secure = ConvertTo-SecureString $plain -AsPlainText -Force
net user Administrator $plain /active:yes

# Stage 2 runs at the next start as SYSTEM and removes itself when done
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\OEM\seed.ps1'
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName 'IBLab-Seed' -Action $action -Trigger $trigger `
    -User 'SYSTEM' -RunLevel Highest -Force | Out-Null

Install-WindowsFeature AD-Domain-Services, GPMC -IncludeManagementTools | Out-Null
Import-Module ADDSDeployment
Install-ADDSForest -DomainName 'lab.test' -DomainNetbiosName 'LAB' `
    -SafeModeAdministratorPassword $secure -InstallDns -Force
Stop-Transcript
