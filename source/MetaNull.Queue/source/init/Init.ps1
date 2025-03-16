# Module Constants

Set-Variable METANULL_QUEUE_CONSTANTS -Option ReadOnly -Scope script -Value @{
    Registry = 'SOFTWARE\MetaNull\PowerShell\MetaNull.Queue'
    Lock = New-Object Object
    Drive = 'MetaNullQueue'
}

# New-PSDrive -Name CurrentUserQueue -PSProvider Registry -Root (Join-Path -Path HKCU: -ChildPath $METANULL_QUEUE_CONSTANTS.Registry) | Out-Null
# New-PSDrive -Name AllUsersQueue -PSProvider Registry -Root (Join-Path -Path HKCU: -ChildPath $METANULL_QUEUE_CONSTANTS.Registry) | Out-Null

if(Test-IsAdministrator) {
    New-PSDrive -Name $METANULL_QUEUE_CONSTANTS.Drive -Scope Script -PSProvider Registry -Root (Join-Path -Path HKLM: -ChildPath $METANULL_QUEUE_CONSTANTS.Registry) | Out-Null
} else {
    New-PSDrive -Name $METANULL_QUEUE_CONSTANTS.Drive -Scope Script -PSProvider Registry -Root (Join-Path -Path HKCU: -ChildPath $METANULL_QUEUE_CONSTANTS.Registry) | Out-Null
}
