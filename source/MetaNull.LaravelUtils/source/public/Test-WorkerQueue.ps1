<#
    .SYNOPSIS
    Tests if the Laravel queue worker is running
    
    .DESCRIPTION
    Checks if Laravel queue worker processes are active
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER Queue
    Specific queue name to check (optional)
    
    .EXAMPLE
    Test-WorkerQueue
    Tests if any Laravel queue workers are running
    
    .EXAMPLE
    Test-WorkerQueue -Queue "emails"
    Tests if Laravel queue workers are running for the "emails" queue
#>
[CmdletBinding()]
[OutputType([System.Boolean])]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet', '', Justification = 'Test file uses WMI for process detection')]
param(
    [Parameter()]
    [string]$Queue
)

Begin {
    Write-Development -Message "Testing Laravel queue worker$(if($Queue) { " for queue '$Queue'" })..." -Type Info
    
    try {
        # Find queue worker processes using WMI for more reliable command line detection
        # Note: Using WMI for compatibility with existing tests and broad system support
        $queueProcesses = Get-WmiObject Win32_Process | Where-Object {
            $_.Name -match "php" -and 
            $_.CommandLine -match "artisan.*queue:work"
        }
        
        if ($Queue) {
            $queueProcesses = $queueProcesses | Where-Object {
                $_.CommandLine -match "queue.*$Queue"
            }
        }
        
        if ($queueProcesses) {
            $processCount = $queueProcesses.Count
            Write-Development -Message "Found $processCount Laravel queue worker process$(if($processCount -gt 1) { 'es' })$(if($Queue) { " for queue '$Queue'" })" -Type Success
            
            foreach ($process in $queueProcesses) {
                Write-Development -Message "  - PID: $($process.ProcessId), Started: $($process.CreationDate)" -Type Info
            }
            
            return $true
        } else {
            Write-Development -Message "No Laravel queue worker processes found$(if($Queue) { " for queue '$Queue'" })" -Type Info
            return $false
        }
        
    } catch {
        Write-Development -Message "Failed to test Laravel queue worker: $($_.Exception.Message)" -Type Error
        return $false
    }
}
