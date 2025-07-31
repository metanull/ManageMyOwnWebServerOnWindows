<#
    .SYNOPSIS
    Stops the Laravel web development server
    
    .DESCRIPTION
    Stops processes running on the Laravel web server port
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER Port
    The port number where Laravel web server is running (default: 8000)
    
    .PARAMETER Force
    Force stop without confirmation
    
    .EXAMPLE
    Stop-WorkerWeb -Port 8000
    Stops Laravel web server on port 8000
    
    .EXAMPLE
    Stop-WorkerWeb -Port 8001 -Force
    Force stops Laravel web server on port 8001
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Stop-WorkerWeb does not modify state but stops services')]
[OutputType([System.Boolean])]
param(
    [Parameter()]
    [int]$Port = 8000,
    
    [Parameter()]
    [switch]$Force
)

Begin {
    Write-Development -Message "Stopping Laravel web server on port $Port..." -Type Step
    
    try {
        if (-not (Test-DevPort -Port $Port)) {
            Write-Development -Message "Laravel web server is not running on port $Port" -Type Info
            return $true
        }
        
        # Get processes using the port
        $processes = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | 
                    Select-Object -ExpandProperty OwningProcess -Unique
        
        if (-not $processes) {
            Write-Development -Message "Port $Port appears to be in use but no processes found" -Type Warning
            return $false
        }
        
        $stoppedAny = $false
        
        foreach ($processId in $processes) {
            if ($processId -and $processId -ne 0) {
                $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                if ($process) {
                    # Verify this is likely a Laravel web server process
                    $isLaravelProcess = $process.ProcessName -match "(php|artisan)" -or 
                                      $process.CommandLine -match "artisan serve"
                    
                    if ($isLaravelProcess -or $Force) {
                        if (-not $Force) {
                            $confirmation = Read-Host "Stop Laravel web process '$($process.Name)' (PID: $processId)? [Y/n]"
                            if ($confirmation -eq "n" -or $confirmation -eq "N") {
                                Write-Development -Message "Skipping process $processId" -Type Info
                                continue
                            }
                        }
                        
                        Write-Development -Message "Stopping Laravel web process '$($process.Name)' (PID: $processId)" -Type Step
                        
                        try {
                            # Try graceful stop first
                            $process.CloseMainWindow()
                            Start-Sleep -Seconds 2
                            
                            # Check if process is still running
                            $runningProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue
                            if ($runningProcess) {
                                # Force kill if still running
                                Stop-Process -Id $processId -Force
                                Start-Sleep -Seconds 1
                            }
                            
                            Write-Development -Message "Stopped Laravel web server (PID: $processId)" -Type Success
                            $stoppedAny = $true
                            
                        } catch {
                            Write-Development -Message "Failed to stop process $processId`: $($_.Exception.Message)" -Type Error
                        }
                    } else {
                        Write-Development -Message "Process '$($process.Name)' (PID: $processId) on port $Port doesn't appear to be a Laravel web server" -Type Warning
                        Write-Development -Message "Use -Force to stop it anyway" -Type Info
                    }
                }
            }
        }
        
        # Verify port is now free
        Start-Sleep -Seconds 1
        if (-not (Test-DevPort -Port $Port)) {
            if ($stoppedAny) {
                Write-Development -Message "Laravel web server stopped successfully" -Type Success
            }
            return $true
        } else {
            Write-Development -Message "Laravel web port $Port is still in use after attempting to stop processes" -Type Warning
            return $false
        }
        
    } catch {
        Write-Development -Message "Failed to stop Laravel web server on port $Port`: $($_.Exception.Message)" -Type Error
        return $false
    }
}
