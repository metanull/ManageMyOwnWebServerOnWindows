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
    Stop-LaravelVite -Path "C:\path\to\laravel" -Port 5173
    Stops Laravel Vite server on port 5173
    
    .EXAMPLE
    Stop-LaravelVite -Path "C:\path\to\laravel" -Force
    Force stops Laravel Vite server with default port
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,
    
    [Parameter()]
    [int]$Port = 5173,
    
    [Parameter()]
    [switch]$Force
)

Begin {
    Write-DevStep "Stopping Laravel Vite server on port $Port..."
    
    # Validate Laravel path
    if (-not (Test-Path $Path -PathType Container)) {
        Write-DevError "Laravel path does not exist: $Path"
        return $false
    }
    
    try {
        if (-not (Test-DevPort -Port $Port)) {
            Write-DevInfo "Laravel Vite server is not running on port $Port"
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
                    # Verify this is likely a Vite server process
                    $isViteProcess = $process.ProcessName -match "(node|npm)" -or 
                                   $process.CommandLine -match "(vite|npm.*dev)"
                    
                    if ($isViteProcess -or $Force) {
                        if (-not $Force) {
                            $confirmation = Read-Host "Stop Laravel Vite process '$($process.Name)' (PID: $processId)? [Y/n]"
                            if ($confirmation -eq "n" -or $confirmation -eq "N") {
                                Write-DevInfo "Skipping process $processId"
                                continue
                            }
                        }
                        
                        Write-DevStep "Stopping Laravel Vite process '$($process.Name)' (PID: $processId)"
                        
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
                            
                            Write-DevSuccess "Stopped Laravel Vite server (PID: $processId)"
                            $stoppedAny = $true
                            
                        } catch {
                            Write-DevError "Failed to stop process $processId`: $($_.Exception.Message)"
                        }
                    } else {
                        Write-DevWarning "Process '$($process.Name)' (PID: $processId) on port $Port doesn't appear to be a Laravel Vite server"
                        Write-DevInfo "Use -Force to stop it anyway"
                    }
                }
            }
        }
        
        # Verify port is now free
        Start-Sleep -Seconds 1
        if (-not (Test-DevPort -Port $Port)) {
            if ($stoppedAny) {
                Write-DevSuccess "Laravel Vite server stopped successfully"
            }
            return $true
        } else {
            Write-DevWarning "Laravel Vite port $Port is still in use after attempting to stop processes"
            return $false
        }
        
    } catch {
        Write-DevError "Failed to stop Laravel Vite server on port $Port`: $($_.Exception.Message)"
        return $false
    }
}
