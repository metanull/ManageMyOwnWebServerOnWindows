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
    Write-DevHeader "Stopping Laravel Development Environment"
    
    $success = $true
    
    try {
        # Stop Laravel Web Server
        Write-DevInfo "Stopping Laravel web server..."
        $webResult = Stop-LaravelWeb -Port $WebPort -Force:$Force
        if (-not $webResult) {
            Write-DevWarning "Issues stopping Laravel web server"
            $success = $false
        }
        
        # Stop Vite Development Server
        Write-DevInfo "Stopping Vite development server..."
        $viteResult = Stop-LaravelVite -Port $VitePort -Force:$Force
        if (-not $viteResult) {
            Write-DevWarning "Issues stopping Vite development server"
            $success = $false
        }
        
        # Stop Laravel Queue Worker
        Write-DevInfo "Stopping Laravel queue worker..."
        if ($Queue) {
            $queueResult = Stop-LaravelQueue -Queue $Queue -Force:$Force
        } else {
            $queueResult = Stop-LaravelQueue -Force:$Force
        }
        if (-not $queueResult) {
            Write-DevWarning "Issues stopping Laravel queue worker"
            $success = $false
        }
        
        if ($success) {
            Write-DevSuccess "Laravel development environment stopped successfully!"
        } else {
            Write-DevWarning "Some Laravel services may still be running. Check the logs above."
        }
        
        return $success
        
    } catch {
        Write-DevError "Failed to stop Laravel development environment: $($_.Exception.Message)"
        return $false
    }
}
