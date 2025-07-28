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
    
    .PARAMETER SkipChecks
    Skip port availability checks and start immediately
    
    .PARAMETER Force
    Force stop any existing processes on the specified port
    
    .EXAMPLE
    Start-LaravelWeb -Path "C:\path\to\laravel" -Port 8000
    Starts Laravel web server on port 8000
    
    .EXAMPLE
    Start-LaravelWeb -Path "C:\path\to\laravel" -Port 8001 -TimeoutSeconds 15 -SkipChecks
    Starts Laravel web server on port 8001 with 15 second timeout, skipping checks
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Path', Justification = 'Used via $Using:Path in Start-Job ScriptBlock')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host used for error output display in development utility')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,
    
    [Parameter()]
    [int]$Port = 8000,
    
    [Parameter()]
    [int]$TimeoutSeconds = 10,
    
    [Parameter()]
    [switch]$SkipChecks,
    
    [Parameter()]
    [switch]$Force
)

Begin {
    Write-DevStep "Starting Laravel web server on port $Port..."
    
    if ($Force -or -not $SkipChecks) {
        # Check if port is available
        if (Test-DevPort -Port $Port) {
            Write-DevWarning "Port $Port is already in use. Attempting to free it..."
            Stop-DevProcessOnPort -Port $Port
            Start-Sleep -Seconds 2
            
            if (Test-DevPort -Port $Port) {
                Write-DevError "Unable to free port $Port. Please check what's using it and try again."
                return $null
            }
        }
    }
    
    # Start Laravel server
    $laravelJob = Start-Job -ScriptBlock {
        Set-Location $Using:Path
        php artisan serve --port=$Using:Port --host=127.0.0.1
    }
    
    if ($SkipChecks) {
        Write-DevInfo "Laravel web server started (checks skipped)"
        return $laravelJob
    }
    
    # Wait for server to start with configurable timeout
    Write-DevInfo "Waiting for Laravel web server to start (timeout: $TimeoutSeconds seconds)..."
    if (Wait-ForDevPort -Port $Port -TimeoutSeconds $TimeoutSeconds) {
        Write-DevSuccess "Laravel web server running at http://127.0.0.1:$Port"
        return $laravelJob
    } else {
        Write-DevError "Failed to start Laravel web server within $TimeoutSeconds seconds"
        
        # Get job output for debugging
        Start-Sleep -Seconds 1
        $jobOutput = Receive-Job $laravelJob -ErrorAction SilentlyContinue
        if ($jobOutput) {
            Write-DevError "Laravel job output:"
            Write-Host $jobOutput -ForegroundColor Red
        }
        
        if ($laravelJob) {
            Stop-Job $laravelJob -ErrorAction SilentlyContinue
            Remove-Job $laravelJob -ErrorAction SilentlyContinue
        }
        return $null
    }
}
