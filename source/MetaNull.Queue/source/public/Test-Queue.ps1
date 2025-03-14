<#
    .SYNOPSIS
        Returns the list of Queues
#>
[CmdletBinding(DefaultParameterSetName = 'Name')]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

    [Parameter(Mandatory, ParameterSetName = 'GUID')]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return [guid]::TryParse($_, [ref]$ref)
    })]
    [string] $Id,

    [Parameter(Mandatory, ParameterSetName = 'Name')]
    [string] $Name
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if($pscmdlet.ParameterSetName -eq 'GUID') {
            $Queue = Get-Queue -Scope $Scope -Id $Id
            return $null -ne $Queue
        } elseif($pscmdlet.ParameterSetName -eq 'Name') {
            $Queue = Get-Queue -Scope $Scope -Name $Name
            return $null -ne $Queue
        }
    } catch {
        Write-Warning $_.Exception.Message
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
    return $false
}
