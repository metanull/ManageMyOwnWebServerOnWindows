# Module Constants


$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($User)
$Role = [Security.Principal.WindowsBuiltInRole]::Administrator
if($Principal.IsInRole($Role)) {
    # Current use is Administrator
    $PSDriveRoot = 'HKLM:\SOFTWARE\MetaNull\PowerShell\MetaNull.MessageQueue'
} else {
    # Current user is not Administrator
    $PSDriveRoot = 'HKCU:\SOFTWARE\MetaNull\PowerShell\MetaNull.MessageQueue'
}

if(-not (Test-Path $PSDriveRoot)) {
    New-Item -Path $PSDriveRoot -Force | Out-Null
}

New-Variable MetaNull -Scope script -Value @{
    MessageQueue = @{
        PSDriveRoot = $PSDriveRoot
        LockRead = New-Object Object
        LockWrite = New-Object Object
        Drive = New-PSDrive -Name 'MetaNull' -Scope Script -PSProvider Registry -Root $PSDriveRoot
    }
}

if(-not (Test-Path MetaNull:\MessageStore)) {
    # Create the MessageStore directory in the registry
    # This is where the message details will be stored
    New-Item -Path MetaNull:\MessageStore -Force | Out-Null
}
if(-not (Test-Path MetaNull:\MessageQueue)) {
    # Create the MessageQueue directory in the registry
    # This is where the message queues will be stored
    New-Item -Path MetaNull:\MessageQueue -Force | Out-Null
}
