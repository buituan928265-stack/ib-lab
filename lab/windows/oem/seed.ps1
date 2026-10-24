# Stage 2: fill the lab.test domain with training objects for lessons 10-13.
# All names and passwords are fictional and valid only inside this lab.
$ErrorActionPreference = 'Stop'
Start-Transcript -Path C:\OEM\seed-transcript.txt -Append

# Active Directory Web Services needs a minute after the first boot of a new DC
for ($i = 0; $i -lt 60; $i++) {
    try { Import-Module ActiveDirectory; Get-ADDomain | Out-Null; break }
    catch { Start-Sleep -Seconds 10 }
}
Import-Module GroupPolicy
$domainDN = (Get-ADDomain).DistinguishedName
$userPass = ConvertTo-SecureString 'Student2026!' -AsPlainText -Force

# --- Admin account for the student (local accounts disappear after promotion)
if (-not (Get-ADUser -Filter "SamAccountName -eq 'labadmin'")) {
    New-ADUser -Name 'labadmin' -SamAccountName 'labadmin' -Enabled $true `
        -AccountPassword (ConvertTo-SecureString 'LabAdmin2026!' -AsPlainText -Force) `
        -PasswordNeverExpires $true
    Add-ADGroupMember 'Domain Admins' 'labadmin'
}

# --- Lesson 13: organizational units, users, groups
foreach ($ou in 'Staff', 'Interns', 'Former') {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'")) {
        New-ADOrganizationalUnit -Name $ou -Path $domainDN -ProtectedFromAccidentalDeletion $false
    }
}
$users = @(
    @{ Sam = 'a.ivanov';       Name = 'Anton Ivanov';     OU = 'Staff';   Enabled = $true  },
    @{ Sam = 'm.petrova';      Name = 'Maria Petrova';    OU = 'Staff';   Enabled = $true  },
    @{ Sam = 'intern.sidorov'; Name = 'Ilya Sidorov';     OU = 'Interns'; Enabled = $true  },
    @{ Sam = 'o.leaving';      Name = 'Oleg Leaving';     OU = 'Former';  Enabled = $false }
)
foreach ($u in $users) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.Sam)'")) {
        New-ADUser -Name $u.Name -SamAccountName $u.Sam -UserPrincipalName "$($u.Sam)@lab.test" `
            -Path "OU=$($u.OU),$domainDN" -AccountPassword $userPass -Enabled $u.Enabled `
            -PasswordNeverExpires $true
    }
}
foreach ($g in 'Instructions-Read', 'Instructions-Edit', 'Project-Old') {
    if (-not (Get-ADGroup -Filter "Name -eq '$g'")) {
        New-ADGroup -Name $g -GroupScope Global -Path "OU=Staff,$domainDN"
    }
}
Add-ADGroupMember 'Instructions-Edit' 'a.ivanov'
Add-ADGroupMember 'Instructions-Read' 'm.petrova', 'intern.sidorov'
# The hidden mistake for lesson 10: an old project group still grants Modify
Add-ADGroupMember 'Project-Old' 'intern.sidorov', 'o.leaving'

# --- Lesson 10: shared folder with NTFS permissions
$share = 'C:\Shares\Instructions'
New-Item -ItemType Directory -Path $share -Force | Out-Null
Set-Content -Path "$share\vpn-howto.txt" -Value 'How to connect to the office VPN (training text).'
Set-Content -Path "$share\printer.txt" -Value 'How to add the office printer (training text).'
$acl = Get-Acl $share
$acl.SetAccessRuleProtection($true, $false)   # stop inheritance, start from a clean list
$rules = @(
    @('BUILTIN\Administrators', 'FullControl'),
    @('NT AUTHORITY\SYSTEM', 'FullControl'),
    @('LAB\Instructions-Read', 'ReadAndExecute'),
    @('LAB\Instructions-Edit', 'Modify'),
    @('LAB\Project-Old', 'Modify')
)
foreach ($r in $rules) {
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        $r[0], $r[1], 'ContainerInherit,ObjectInherit', 'None', 'Allow')))
}
Set-Acl -Path $share -AclObject $acl
if (-not (Get-SmbShare -Name 'Instructions' -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name 'Instructions' -Path $share -FullAccess 'Authenticated Users' | Out-Null
}

# --- Lesson 13: a harmless group policy linked to the Interns OU
if (-not (Get-GPO -Name 'Lab-Interns-ScreenLock' -ErrorAction SilentlyContinue)) {
    New-GPO -Name 'Lab-Interns-ScreenLock' -Comment 'Training policy: lock the screen after 5 minutes' | Out-Null
    Set-GPRegistryValue -Name 'Lab-Interns-ScreenLock' `
        -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' `
        -ValueName 'ScreenSaveTimeOut' -Type String -Value '300' | Out-Null
    Set-GPRegistryValue -Name 'Lab-Interns-ScreenLock' `
        -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' `
        -ValueName 'ScreenSaverIsSecure' -Type String -Value '1' | Out-Null
    New-GPLink -Name 'Lab-Interns-ScreenLock' -Target "OU=Interns,$domainDN" | Out-Null
}

# --- Lesson 12: security events to investigate (three failed logons, then a success)
auditpol /set /subcategory:"Logon" /success:enable /failure:enable | Out-Null
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Domain', 'lab.test')
foreach ($pw in 'student2026', 'Studnet2026!', 'Student2025!') {
    $ctx.ValidateCredentials('m.petrova', $pw) | Out-Null
    Start-Sleep -Seconds 20
}
$ctx.ValidateCredentials('m.petrova', 'Student2026!') | Out-Null

Set-Content -Path C:\OEM\seed-done.txt -Value (Get-Date -Format s)
Unregister-ScheduledTask -TaskName 'IBLab-Seed' -Confirm:$false
Stop-Transcript
