<#
    .SYNOPSIS
        Tests if the current user has Administrative rights
#>
[CmdletBinding()]
[OutputType([bool])]
param()
Process {
    $User = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = [Security.Principal.WindowsPrincipal]::new($User)
    $Role = [Security.Principal.WindowsBuiltInRole]::Administrator
    return $Principal.IsInRole($Role)
}