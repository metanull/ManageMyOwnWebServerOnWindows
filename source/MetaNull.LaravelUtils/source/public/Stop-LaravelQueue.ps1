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
    Write-Development -Message "Stopping Laravel queue worker$(if($Queue) { " for queue '$Queue'" })..." -Type Step
    
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
            Write-Development -Message "No Laravel queue worker processes found$(if($Queue) { " for queue '$Queue'" })" -Type Info
            return $true
        }
        
        $stoppedAny = $false
        
        foreach ($process in $queueProcesses) {
            if (-not $Force) {
                $confirmation = Read-Host "Stop Laravel queue worker process (PID: $($process.Id))? [Y/n]"
                if ($confirmation -eq "n" -or $confirmation -eq "N") {
                    Write-Development -Message "Skipping process $($process.Id)" -Type Info
                    continue
                }
            }
            
            Write-Development -Message "Stopping Laravel queue worker process (PID: $($process.Id))" -Type Step
            
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
                
                Write-Development -Message "Stopped Laravel queue worker (PID: $($process.Id))" -Type Success
                $stoppedAny = $true
                
            } catch {
                Write-Development -Message "Failed to stop process $($process.Id)`: $($_.Exception.Message)" -Type Error
            }
        }
        
        if ($stoppedAny) {
            Write-Development -Message "Laravel queue worker$(if($Queue) { "s for queue '$Queue'" }) stopped successfully" -Type Success
            return $true
        } else {
            Write-Development -Message "No Laravel queue workers were stopped" -Type Warning
            return $false
        }
        
    } catch {
        Write-Development -Message "Failed to stop Laravel queue worker: $($_.Exception.Message)" -Type Error
        return $false
    }
}
