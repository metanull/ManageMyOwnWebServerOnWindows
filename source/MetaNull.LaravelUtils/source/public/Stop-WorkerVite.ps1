<#
    .SYNOPSIS
    Stops the Laravel Vite development server
    
    .DESCRIPTION
    Stops processes running on the Laravel Vite server port
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER Port
    The port number where Laravel Vite server is running (default: 5173)
    
    .PARAMETER Force
    Force stop without confirmation
    
    .EXAMPLE
    Stop-WorkerVite -Port 5173
    Stops Laravel Vite server on port 5173
    
    .EXAMPLE
    Stop-WorkerVite -Force
    Force stops Laravel Vite server with default port
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Stop-WorkerVite does not modify state but stops services')]
[OutputType([System.Boolean])]
param(
    [Parameter()]
    [int]$Port = 5173,
    
    [Parameter()]
    [switch]$Force
)

Begin {
    Write-Development -Message "Stopping Laravel Vite server on port $Port..." -Type Step
    
    try {
        if (-not (Test-DevPort -Port $Port)) {
            Write-Development -Message "Laravel Vite server is not running on port $Port" -Type Info
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
                    # Verify this is likely a Vite server process
                    $isViteProcess = $process.ProcessName -match "(node|npm)" -or 
                                   $process.CommandLine -match "(vite|npm.*dev)"
                    
                    if ($isViteProcess -or $Force) {
                        if (-not $Force) {
                            $confirmation = Read-Host "Stop Laravel Vite process '$($process.Name)' (PID: $processId)? [Y/n]"
                            if ($confirmation -eq "n" -or $confirmation -eq "N") {
                                Write-Development -Message "Skipping process $processId" -Type Info
                                continue
                            }
                        }
                        
                        Write-Development -Message "Stopping Laravel Vite process '$($process.Name)' (PID: $processId)" -Type Step
                        
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
                            
                            Write-Development -Message "Stopped Laravel Vite server (PID: $processId)" -Type Success
                            $stoppedAny = $true
                            
                        } catch {
                            Write-Development -Message "Failed to stop process $processId`: $($_.Exception.Message)" -Type Error
                        }
                    } else {
                        Write-Development -Message "Process '$($process.Name)' (PID: $processId) on port $Port doesn't appear to be a Laravel Vite server" -Type Warning
                        Write-Development -Message "Use -Force to stop it anyway" -Type Info
                    }
                }
            }
        }
        
        # Verify port is now free
        Start-Sleep -Seconds 1
        if (-not (Test-DevPort -Port $Port)) {
            if ($stoppedAny) {
                Write-Development -Message "Laravel Vite server stopped successfully" -Type Success
            }
            return $true
        } else {
            Write-Development -Message "Laravel Vite port $Port is still in use after attempting to stop processes" -Type Warning
            return $false
        }
        
    } catch {
        Write-Development -Message "Failed to stop Laravel Vite server on port $Port`: $($_.Exception.Message)" -Type Error
        return $false
    }
}
