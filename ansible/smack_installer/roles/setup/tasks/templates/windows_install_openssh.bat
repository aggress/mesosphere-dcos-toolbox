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

mkdir C:\Users\Administrator\.ssh

Invoke-WebRequest https://github.com/aggress.keys -OutFile C:\Users\Administrator\.ssh\authorized_keys

Import-Module C:\progra~1\OpenSSH-Win64\OpenSSHUtils.psd1 -Force

Repair-AuthorizedKeyPermission -FilePath C:\Users\Administrator\.ssh\authorized_keys

net start sshd
