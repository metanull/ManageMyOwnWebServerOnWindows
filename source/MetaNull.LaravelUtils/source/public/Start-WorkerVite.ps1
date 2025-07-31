<#
    .SYNOPSIS
    Starts the Laravel Vite development server
    
    .DESCRIPTION
    Starts the Vite development server for Laravel frontend assets
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER Port
    The port number to start the Vite server on (default: 5173)
    
    .PARAMETER LaravelPort
    The Laravel web server port for proper integration (default: 8000)
    
    .PARAMETER TimeoutSeconds
    How long to wait for the server to start (default: 15)
    
    .PARAMETER Force
    Force stop any existing processes on the specified port
    
    .EXAMPLE
    Start-WorkerVite -Path "C:\path\to\laravel" -Port 5173 -LaravelPort 8000
    Starts Vite server on port 5173 integrated with Laravel on port 8000
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Start-WorkerVite does not modify state but starts services')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Path', Justification = 'Used via $Using:Path in Start-Job ScriptBlock')]
param(
    [Parameter()]
    [ValidateScript({ Test-LaravelPath -Path $_})]
    [string]$Path = '.',
    
    [Parameter()]
    [int]$Port = 5173,
    
    [Parameter()]
    [int]$LaravelPort = 8000,
    
    [Parameter()]
    [int]$TimeoutSeconds = 15,
    
    [Parameter()]
    [switch]$Force
)

Begin {
    Write-Development -Message "Starting Laravel Vite server on port $Port..." -Type Step
    
    # Check if port is available
    if (Test-DevPort -Port $Port) {
        if ($Force) {
            Write-Development -Message "Port $Port is already in use. Force stopping processes..." -Type Warning
            Stop-DevProcessOnPort -Port $Port
            Start-Sleep -Seconds 2
        }
        
        if (Test-DevPort -Port $Port) {
            Write-Development -Message "Unable to free port $Port. Please check what's using it and try again." -Type Error
            return $null
        }
    }
    
    # Start Vite server with output redirection to prevent job termination
    $viteJob = Start-Job -ScriptBlock {
        Set-Location $Using:Path
        
        # Set environment variables for Vite to ensure IPv4 binding
        $env:VITE_PORT = $Using:Port
        $env:VITE_HOST = "127.0.0.1"
        $env:VITE_DEV_SERVER_URL = "http://127.0.0.1:$($Using:Port)"
        
        # Start Vite with port specification using npx directly for proper argument handling
        npx vite --host 127.0.0.1 --port $Using:Port --strictPort 2>&1
    }
    
    # Wait longer for Vite to start (it takes more time than Laravel)
    Write-Development -Message "Waiting for Laravel Vite server to start (timeout: $TimeoutSeconds seconds)..." -Type Info
    if (Wait-ForDevPort -Port $Port -TimeoutSeconds $TimeoutSeconds) {
        Write-Development -Message "Laravel Vite server running at http://127.0.0.1:$Port" -Type Success
        Write-Development -Message "Note: Access your Vue app via Laravel at http://127.0.0.1:$LaravelPort/" -Type Info
        return $viteJob
    } else {
        Write-Development -Message "Failed to start Laravel Vite server within $TimeoutSeconds seconds" -Type Error
        if ($viteJob) {
            # Get job output for debugging
            Start-Sleep -Seconds 2  # Give job time to produce output
            $jobOutput = Receive-Job $viteJob -ErrorAction SilentlyContinue
            if ($jobOutput) {
                Write-Development -Message "Vite job output: $jobOutput" -Type Error
            }
            
            # Also check job state and errors
            if ($viteJob.State -eq "Failed") {
                $jobErrors = $viteJob.ChildJobs[0].Error
                if ($jobErrors) {
                    Write-Development -Message "Vite job errors: $jobErrors" -Type Error
                }
            }
            
            Stop-Job $viteJob -ErrorAction SilentlyContinue
            Remove-Job $viteJob -ErrorAction SilentlyContinue
        }
        return $null
    }
}
