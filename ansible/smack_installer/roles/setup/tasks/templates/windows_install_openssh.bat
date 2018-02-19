Invoke-WebRequest https://github.com/PowerShell/Win32-OpenSSH/releases/download/v1.0.0.0/OpenSSH-Win64.zip -OutFile c:\OpenSSH-Win64.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "c:\OpenSSH-Win64.zip" "c:\progra~1"

powershell.exe -ExecutionPolicy Bypass -File c:\progra~1\OpenSSH-Win64\install-sshd.ps1

netsh advfirewall firewall add rule name=sshd dir=in action=allow protocol=TCP localport=22

net start sshd

mkdir C:\Users\Administrator\.ssh

echo ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtvS/He/8IexJHjQ6bLnb6r2yQGERHZe5fArddb+IifJC40KYZx9dbC3g1YzLObo7G5REnQA/j8uy94vK9HJOEH+QBpfBlFp/8T+/m56zhWATkgF2vp3hIsiNYSIaMqxPrb3ZX0qzcQD7cHa0FdpfGNKB1DVlc4288MaV9sjsR6eHwHvjAmukJbVwTO3U0hMaHaA9DafbYpc2AFAd3pMEZvvnDMbl5g7DQQ6g/DAVQr99l+s8r1rgLZ1gfgPdHm0iCw/1RpobOT38+jfqHVWnqngLx39/V0uWNTzg6Ec0LzKsowJDVyaRuPOwOEWspiQ/JM0RwYu9owipP+WER84Byw== rshaw@mesosphere.com > C:\Users\Administrator\.ssh\authorized_keys

Import-Module C:\progra~1\OpenSSH-Win64\OpenSSHUtils.psd1 -Force

Repair-AuthorizedKeyPermission -FilePath C:\Users\Administrator\.ssh\authorized_keys