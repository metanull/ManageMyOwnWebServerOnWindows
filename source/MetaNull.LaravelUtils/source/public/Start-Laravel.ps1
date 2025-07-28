<#
    .SYNOPSIS
    Starts the complete Laravel development environment

    .DESCRIPTION
    Starts all Laravel development components: Web server, Vite, and Queue workers

    .PARAMETER Path
    The root directory of the Laravel application

    .PARAMETER WebPort
    Port for the Laravel web server (default: 8000)

    .PARAMETER VitePort
    Port for the Vite development server (default: 5173)

    .PARAMETER Queue
    Queue name for Laravel queue workers (default: "default")

    .PARAMETER TimeoutSeconds
    Timeout in seconds for server startup checks (default: 30)

    .PARAMETER SkipChecks
    Skip port availability checks

    .PARAMETER Force
    Force stop any existing processes on the specified ports

    .EXAMPLE
    Start-Laravel -Path "C:\path\to\laravel"
    Starts Laravel with default settings (web on 8000, vite on 5173, default queue)

    .EXAMPLE
    Start-Laravel -Path "C:\path\to\laravel" -WebPort 8080 -VitePort 3000 -Queue "emails" -Force
    Starts Laravel with custom ports and queue, forcing stop of existing processes
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,

    [Parameter()]
    [int]$WebPort = 8000,

    [Parameter()]
    [int]$VitePort = 5173,

    [Parameter()]
    [string]$Queue = "default",

    [Parameter()]
    [int]$TimeoutSeconds = 30,

    [Parameter()]
    [switch]$SkipChecks,

    [Parameter()]
    [switch]$Force
)

Begin {
    Write-DevHeader "Starting Laravel Development Environment"

    $success = $true

    try {
        # Start Laravel Web Server
        Write-DevInfo "Starting Laravel web server..."
        $webResult = Start-LaravelWeb -Path $Path -Port $WebPort -TimeoutSeconds $TimeoutSeconds -SkipChecks:$SkipChecks -Force:$Force
        if (-not $webResult) {
            Write-DevError "Failed to start Laravel web server"
            $success = $false
        }

        # Start Vite Development Server
        Write-DevInfo "Starting Vite development server..."
        $viteResult = Start-LaravelVite -Path $Path -Port $VitePort -LaravelPort $WebPort -TimeoutSeconds $TimeoutSeconds -SkipChecks:$SkipChecks -Force:$Force
        if (-not $viteResult) {
            Write-DevError "Failed to start Vite development server"
            $success = $false
        }

        # Start Laravel Queue Worker
        Write-DevInfo "Starting Laravel queue worker..."
        $queueResult = Start-LaravelQueue -Path $Path -Queue $Queue -Force:$Force
        if (-not $queueResult) {
            Write-DevError "Failed to start Laravel queue worker"
            $success = $false
        }

        if ($success) {
            Write-DevSuccess "Laravel development environment started successfully!"
            Write-DevInfo "Services:"
            Write-DevInfo "  - Web Server: http://localhost:$WebPort"
            Write-DevInfo "  - Vite Server: http://localhost:$VitePort"
            Write-DevInfo "  - Queue Worker: $Queue queue"
        } else {
            Write-DevWarning "Some Laravel services failed to start. Check the logs above."
        }

        return $success

    } catch {
        Write-DevError "Failed to start Laravel development environment: $($_.Exception.Message)"
        return $false
    }
}
