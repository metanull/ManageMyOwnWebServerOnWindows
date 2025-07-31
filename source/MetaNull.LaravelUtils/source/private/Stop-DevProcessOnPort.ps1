<#
    .SYNOPSIS
    Stops processes running on a specific port

    .DESCRIPTION
    Finds and forcefully stops all processes that are listening on the specified port.
    Useful for freeing up ports before starting development servers.

    .PARAMETER Port
    The port number to free up

    .EXAMPLE
    Stop-DevProcessOnPort -Port 8000
    Stops all processes using port 8000
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$Port
)
End {
    try {
        $processes = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
                    Select-Object -ExpandProperty OwningProcess -Unique

        foreach ($processId in $processes) {
            if ($processId -and $processId -ne 0) {
                $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                if ($process) {
                    Write-Development -Message "Stopping process $($process.Name) (PID: $processId) on port $Port" -Type Warning
                    if ($PSCmdlet.ShouldProcess("Process $($process.Name) (PID: $processId)", "Stop")) {
                        Stop-Process -Id $processId -Force
                    }
                    Start-Sleep -Seconds 1
                }
            }
        }
    } catch {
        # Ignore errors when stopping processes
        Write-Development -Message "Could not stop processes on port $Port - they may have already been stopped" -Type Warning
    }
}
