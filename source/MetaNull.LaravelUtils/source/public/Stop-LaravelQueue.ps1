<#
    .SYNOPSIS
    Stops the Laravel queue worker
    
    .DESCRIPTION
    Stops Laravel queue worker processes gracefully
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER Force
    Force stop without confirmation
    
    .PARAMETER Queue
    Specific queue name to target (optional)
    
    .EXAMPLE
    Stop-LaravelQueue
    Stops all Laravel queue workers
    
    .EXAMPLE
    Stop-LaravelQueue -Queue "emails" -Force
    Force stops Laravel queue workers for the "emails" queue
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [string]$Queue
)

Begin {
    Write-DevStep "Stopping Laravel queue worker$(if($Queue) { " for queue '$Queue'" })..."
    
    try {
        # Find queue worker processes
        $queueProcesses = Get-Process | Where-Object {
            $_.ProcessName -match "php" -and 
            $_.CommandLine -match "artisan.*queue:work"
        }
        
        if ($Queue) {
            $queueProcesses = $queueProcesses | Where-Object {
                $_.CommandLine -match "queue.*$Queue"
            }
        }
        
        if (-not $queueProcesses) {
            Write-DevInfo "No Laravel queue worker processes found$(if($Queue) { " for queue '$Queue'" })"
            return $true
        }
        
        $stoppedAny = $false
        
        foreach ($process in $queueProcesses) {
            if (-not $Force) {
                $confirmation = Read-Host "Stop Laravel queue worker process (PID: $($process.Id))? [Y/n]"
                if ($confirmation -eq "n" -or $confirmation -eq "N") {
                    Write-DevInfo "Skipping process $($process.Id)"
                    continue
                }
            }
            
            Write-DevStep "Stopping Laravel queue worker process (PID: $($process.Id))"
            
            try {
                # Try graceful stop first
                $process.CloseMainWindow()
                Start-Sleep -Seconds 3
                
                # Check if process is still running
                $runningProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
                if ($runningProcess) {
                    # Force kill if still running
                    Stop-Process -Id $process.Id -Force
                    Start-Sleep -Seconds 1
                }
                
                Write-DevSuccess "Stopped Laravel queue worker (PID: $($process.Id))"
                $stoppedAny = $true
                
            } catch {
                Write-DevError "Failed to stop process $($process.Id)`: $($_.Exception.Message)"
            }
        }
        
        if ($stoppedAny) {
            Write-DevSuccess "Laravel queue worker$(if($Queue) { "s for queue '$Queue'" }) stopped successfully"
            return $true
        } else {
            Write-DevWarning "No Laravel queue workers were stopped"
            return $false
        }
        
    } catch {
        Write-DevError "Failed to stop Laravel queue worker: $($_.Exception.Message)"
        return $false
    }
}
