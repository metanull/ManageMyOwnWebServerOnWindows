<#
    .SYNOPSIS
        Unlock a named mutex that is predefined in the module constants.
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory, Position = 0)]
    [ref] $Mutex
)
Process {
    try {
        if ($Mutex -is [System.Threading.Mutex]) {
            $Mutex.ReleaseMutex()
            $Mutex.Dispose()
            return $true
        }
        throw "The Mutex parameter is not a valid Mutex object."
    } catch {
        Write-Warning $_.Exception.Message
        return $false
    }
}
