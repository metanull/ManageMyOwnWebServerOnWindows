<#
    .SYNOPSIS
    Starts the Laravel web development server
    
    .DESCRIPTION
    Starts the Laravel artisan serve command on the specified port with proper error handling
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER Port
    The port number to start the Laravel server on (default: 8000)
    
    .PARAMETER TimeoutSeconds
    How long to wait for the server to start (default: 10)
    
    .PARAMETER Force
    Force stop any existing processes on the specified port
    
    .EXAMPLE
    Start-WorkerWeb -Path "C:\path\to\laravel" -Port 8000
    Starts Laravel web server on port 8000
    
    .EXAMPLE
    Start-WorkerWeb -Path "C:\path\to\laravel" -Port 8001 -TimeoutSeconds 15
    Starts Laravel web server on port 8001 with 15 second timeout
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Start-WorkerWeb does not modify state but starts services')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Path', Justification = 'Used via $Using:Path in Start-Job ScriptBlock')]
param(
    [Parameter()]
    [ValidateScript({ Test-LaravelPath -Path $_})]
    [string]$Path = '.',
    
    [Parameter()]
    [int]$Port = 8000,
    
    [Parameter()]
    [int]$TimeoutSeconds = 10,
    
    [Parameter()]
    [switch]$Force
)

Begin {
    Write-Development -Message "Starting Laravel web server on port $Port..." -Type Step
    
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
    
    # Start Laravel server
    $laravelJob = Start-Job -ScriptBlock {
        Set-Location $Using:Path
        php artisan serve --port=$Using:Port --host=127.0.0.1
    }
    
    # Wait for server to start with configurable timeout
    Write-Development -Message "Waiting for Laravel web server to start (timeout: $TimeoutSeconds seconds)..." -Type Info
    if (Wait-ForDevPort -Port $Port -TimeoutSeconds $TimeoutSeconds) {
        Write-Development -Message "Laravel web server running at http://127.0.0.1:$Port" -Type Success
        return $laravelJob
    } else {
        Write-Development -Message "Failed to start Laravel web server within $TimeoutSeconds seconds" -Type Error
        
        # Get job output for debugging
        Start-Sleep -Seconds 1
        $jobOutput = Receive-Job $laravelJob -ErrorAction SilentlyContinue
        if ($jobOutput) {
            Write-Development -Message "Laravel job output: $jobOutput" -Type Error
        }
        
        if ($laravelJob) {
            Stop-Job $laravelJob -ErrorAction SilentlyContinue
            Remove-Job $laravelJob -ErrorAction SilentlyContinue
        }
        return $null
    }
}
