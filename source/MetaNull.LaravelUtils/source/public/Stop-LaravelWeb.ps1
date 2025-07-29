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
    Stop-LaravelWeb -Port 8000
    Stops Laravel web server on port 8000
    
    .EXAMPLE
    Stop-LaravelWeb -Port 8001 -Force
    Force stops Laravel web server on port 8001
#>
[CmdletBinding()]
param(
    [Parameter()]
    [int]$Port = 8000,
    
    [Parameter()]
    [switch]$Force
)

Begin {
    Write-DevStep "Stopping Laravel web server on port $Port..."
    
    try {
        if (-not (Test-DevPort -Port $Port)) {
            Write-DevInfo "Laravel web server is not running on port $Port"
            return $true
        }
        
        # Get processes using the port
        $processes = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | 
                    Select-Object -ExpandProperty OwningProcess -Unique
        
        if (-not $processes) {
            Write-DevWarning "Port $Port appears to be in use but no processes found"
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
                                Write-DevInfo "Skipping process $processId"
                                continue
                            }
                        }
                        
                        Write-DevStep "Stopping Laravel web process '$($process.Name)' (PID: $processId)"
                        
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
                            
                            Write-DevSuccess "Stopped Laravel web server (PID: $processId)"
                            $stoppedAny = $true
                            
                        } catch {
                            Write-DevError "Failed to stop process $processId`: $($_.Exception.Message)"
                        }
                    } else {
                        Write-DevWarning "Process '$($process.Name)' (PID: $processId) on port $Port doesn't appear to be a Laravel web server"
                        Write-DevInfo "Use -Force to stop it anyway"
                    }
                }
            }
        }
        
        # Verify port is now free
        Start-Sleep -Seconds 1
        if (-not (Test-DevPort -Port $Port)) {
            if ($stoppedAny) {
                Write-DevSuccess "Laravel web server stopped successfully"
            }
            return $true
        } else {
            Write-DevWarning "Laravel web port $Port is still in use after attempting to stop processes"
            return $false
        }
        
    } catch {
        Write-DevError "Failed to stop Laravel web server on port $Port`: $($_.Exception.Message)"
        return $false
    }
}
