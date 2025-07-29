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
    [Parameter()]
    [ValidateScript({ Test-LaravelPath -Path $_ })]
    [string]$Path = '.',

    [Parameter()]
    [int]$WebPort = 8000,

    [Parameter()]
    [int]$VitePort = 5173,

    [Parameter()]
    [string]$Queue = "default",

    [Parameter()]
    [int]$TimeoutSeconds = 30,

    [Parameter()]
    [switch]$Force
)

Begin {
    Write-Development -Message "Starting Laravel Development Environment" -Type Header

    $success = $true

    try {
        # Start Laravel Web Server
        Write-Development -Message "Starting Laravel web server..." -Type Info
        $webResult = Start-LaravelWeb -Path $Path -Port $WebPort -TimeoutSeconds $TimeoutSeconds -Force:$Force
        if (-not $webResult) {
            Write-Development -Message "Failed to start Laravel web server" -Type Error
            $success = $false
        }

        # Start Vite Development Server
        Write-Development -Message "Starting Vite development server..." -Type Info
        $viteResult = Start-LaravelVite -Path $Path -Port $VitePort -LaravelPort $WebPort -TimeoutSeconds $TimeoutSeconds -Force:$Force
        if (-not $viteResult) {
            Write-Development -Message "Failed to start Vite development server" -Type Error
            $success = $false
        }

        # Start Laravel Queue Worker
        Write-Development -Message "Starting Laravel queue worker..." -Type Info
        $queueResult = Start-LaravelQueue -Path $Path -Queue $Queue -Force:$Force
        if (-not $queueResult) {
            Write-Development -Message "Failed to start Laravel queue worker" -Type Error
            $success = $false
        }

        if ($success) {
            Write-Development -Message "Laravel development environment started successfully!" -Type Success
            Write-Development -Message "Services:" -Type Info
            Write-Development -Message "  - Web Server: http://localhost:$WebPort" -Type Info
            Write-Development -Message "  - Vite Server: http://localhost:$VitePort" -Type Info
            Write-Development -Message "  - Queue Worker: $Queue queue" -Type Info
        } else {
            Write-Development -Message "Some Laravel services failed to start. Check the logs above." -Type Warning
        }

        return $success

    } catch {
        Write-Development -Message "Failed to start Laravel development environment: $($_.Exception.Message)" -Type Error
        return $false
    }
}
