<#
.SYNOPSIS
    Test if the current user is an administrator.
.DESCRIPTION
    Test if the current user is an administrator.
.EXAMPLE
    Test-IsAdministrator
    Returns True if the current user is an administrator, False otherwise.
#>

[CmdletBinding()]
[OutputType([bool])]
param()
Process {
    (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) | Write-Output
}
