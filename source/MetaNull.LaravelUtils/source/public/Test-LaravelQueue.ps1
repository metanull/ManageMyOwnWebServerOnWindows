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
    Test-LaravelQueue -Path "C:\path\to\laravel"
    Tests if any Laravel queue workers are running
    
    .EXAMPLE
    Test-LaravelQueue -Path "C:\path\to\laravel" -Queue "emails"
    Tests if Laravel queue workers are running for the "emails" queue
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,
    
    [Parameter()]
    [string]$Queue
)

Begin {
    Write-DevInfo "Testing Laravel queue worker$(if($Queue) { " for queue '$Queue'" })..."
    
    # Validate Laravel path
    if (-not (Test-Path $Path -PathType Container)) {
        Write-DevError "Laravel path does not exist: $Path"
        return $false
    }
    
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
            Write-DevSuccess "Found $processCount Laravel queue worker process$(if($processCount -gt 1) { 'es' })$(if($Queue) { " for queue '$Queue'" })"
            
            foreach ($process in $queueProcesses) {
                Write-DevInfo "  - PID: $($process.ProcessId), Started: $($process.CreationDate)"
            }
            
            return $true
        } else {
            Write-DevInfo "No Laravel queue worker processes found$(if($Queue) { " for queue '$Queue'" })"
            return $false
        }
        
    } catch {
        Write-DevError "Failed to test Laravel queue worker: $($_.Exception.Message)"
        return $false
    }
}
