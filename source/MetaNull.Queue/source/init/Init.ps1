# Module Constants


$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($User)
$Role = [Security.Principal.WindowsBuiltInRole]::Administrator
if($Principal.IsInRole($Role)) {
    # Current use is Administrator
    $PSDriveRoot = 'HKLM:\SOFTWARE\MetaNull\PowerShell\MetaNull.Queue'
} else {
    # Current user is not Administrator
    $PSDriveRoot = 'HKCU:\SOFTWARE\MetaNull\PowerShell\MetaNull.Queue'
}

if(-not (Test-Path $PSDriveRoot)) {
    New-Item -Path $PSDriveRoot -Force | Out-Null
}

New-Variable MetaNull -Scope script -Value @{
    Queue = @{
        PSDriveRoot = $PSDriveRoot
        Lock = New-Object Object
        Drive = New-PSDrive -Name 'MetaNull' -Scope Script -PSProvider Registry -Root $PSDriveRoot
    }
}

if(-not (Test-Path MetaNull:\Queues)) {
    New-Item -Path MetaNull:\Queues -Force | Out-Null
}
