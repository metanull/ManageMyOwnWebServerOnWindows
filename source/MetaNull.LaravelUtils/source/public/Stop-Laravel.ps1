<#
    .SYNOPSIS
    Stops the complete Laravel development environment
    
    .DESCRIPTION
    Stops all Laravel development components: Web server, Vite, and Queue workers
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER WebPort
    Port for the Laravel web server (default: 8000)
    
    .PARAMETER VitePort
    Port for the Vite development server (default: 5173)
    
    .PARAMETER Queue
    Queue name for Laravel queue workers (optional - stops all if not specified)
    
    .PARAMETER Force
    Force stop processes without graceful shutdown
    
    .EXAMPLE
    Stop-Laravel
    Stops all Laravel services with default settings
    
    .EXAMPLE
    Stop-Laravel -WebPort 8080 -VitePort 3000 -Queue "emails" -Force
    Forcefully stops Laravel services with custom ports and specific queue
#>
[CmdletBinding()]
param(
    [Parameter()]
    [int]$WebPort = 8000,
    
    [Parameter()]
    [int]$VitePort = 5173,
    
    [Parameter()]
    [string]$Queue,
    
    [Parameter()]
    [switch]$Force
)

Begin {
    Write-Development -Message "Stopping Laravel Development Environment" -Type Header
    
    $success = $true
    
    try {
        # Stop Laravel Web Server
        Write-Development -Message "Stopping Laravel web server..." -Type Info
        $webResult = Stop-LaravelWeb -Port $WebPort -Force:$Force
        if (-not $webResult) {
            Write-Development -Message "Issues stopping Laravel web server" -Type Warning
            $success = $false
        }
        
        # Stop Vite Development Server
        Write-Development -Message "Stopping Vite development server..." -Type Info
        $viteResult = Stop-LaravelVite -Port $VitePort -Force:$Force
        if (-not $viteResult) {
            Write-Development -Message "Issues stopping Vite development server" -Type Warning
            $success = $false
        }
        
        # Stop Laravel Queue Worker
        Write-Development -Message "Stopping Laravel queue worker..." -Type Info
        if ($Queue) {
            $queueResult = Stop-LaravelQueue -Queue $Queue -Force:$Force
        } else {
            $queueResult = Stop-LaravelQueue -Force:$Force
        }
        if (-not $queueResult) {
            Write-Development -Message "Issues stopping Laravel queue worker" -Type Warning
            $success = $false
        }
        
        if ($success) {
            Write-Development -Message "Laravel development environment stopped successfully!" -Type Success
        } else {
            Write-Development -Message "Some Laravel services may still be running. Check the logs above." -Type Warning
        }
        
        return $success
        
    } catch {
        Write-Development -Message "Failed to stop Laravel development environment: $($_.Exception.Message)" -Type Error
        return $false
    }
}
