<#
    .SYNOPSIS
        Lock a named mutex that is predefined in the module constants.
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet({
        $Constants = Get-ModuleConstant
        $Constants.Mutex.PSObject.Properties.Name
    })]
    [string] $Name,

    [Parameter(Mandatory, Position = 1)]
    [ref] $Mutex
)
Begin {
    $Constants = Get-ModuleConstant
}
Process {
    try {
        Write-Debug "Using mutex $($Constants.Mutex.$Name.MutexName) (timeout: $($Constants.Mutex.$Name.MutexNameTimeout))"
        $Mutex = [System.Threading.Mutex]::new($false, $Constants.Mutex.$Name.MutexName)
        if (($Mutex.WaitOne(([int]$Constants.Mutex.$Name.MutexNameTimeout)))) {
            return $true
        }
        throw "Failed to obtain the Mutex within the timeout period."
    } catch {
        Write-Warning $_.Exception.Message
        $Mutex = $null
        return $false
    }
}
