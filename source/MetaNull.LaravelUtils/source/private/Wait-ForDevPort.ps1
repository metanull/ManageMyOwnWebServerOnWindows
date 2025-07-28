<#
    .SYNOPSIS
    Waits for a port to become available (in use) with timeout

    .DESCRIPTION
    Continuously tests a port until it becomes available or timeout is reached.
    Useful for waiting for servers to start up.

    .PARAMETER Port
    The port number to wait for

    .PARAMETER TimeoutSeconds
    Maximum time to wait in seconds (default: 10)

    .PARAMETER IntervalSeconds
    Time between checks in seconds (default: 1)

    .OUTPUTS
    Boolean - True if port became available within timeout, False otherwise

    .EXAMPLE
    Wait-ForDevPort -Port 8000 -TimeoutSeconds 30
    Waits up to 30 seconds for port 8000 to become available
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $true)]
    [int]$Port,

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSeconds = 10,

    [Parameter(Mandatory = $false)]
    [int]$IntervalSeconds = 1
)

End {
    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        if (Test-DevPort -Port $Port) {
            return $true
        }
        Start-Sleep -Seconds $IntervalSeconds
        $elapsed += $IntervalSeconds
    }
    return $false
}
