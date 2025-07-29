<#
    .SYNOPSIS
    Tests if the complete Laravel development environment is running
    
    .DESCRIPTION
    Checks if all Laravel development components are active: Web server, Vite, and Queue workers
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER WebPort
    Port for the Laravel web server (default: 8000)
    
    .PARAMETER VitePort
    Port for the Vite development server (default: 5173)
    
    .PARAMETER Queue
    Queue name for Laravel queue workers (optional - checks all if not specified)
    
    .EXAMPLE
    Test-Laravel
    Tests all Laravel services with default settings
    
    .EXAMPLE
    Test-Laravel -WebPort 8080 -VitePort 3000 -Queue "emails"
    Tests Laravel services with custom ports and specific queue
#>
[CmdletBinding()]
param(
    [Parameter()]
    [int]$WebPort = 8000,
    
    [Parameter()]
    [int]$VitePort = 5173,
    
    [Parameter()]
    [string]$Queue
)

Begin {
    Write-Development -Message "Testing Laravel Development Environment" -Type Header
    
    $webStatus = $false
    $viteStatus = $false
    $queueStatus = $false
    
    try {
        # Test Laravel Web Server
        Write-Development -Message "Testing Laravel web server..." -Type Info
        $webStatus = Test-LaravelWeb -Port $WebPort
        
        # Test Vite Development Server
        Write-Development -Message "Testing Vite development server..." -Type Info
        $viteStatus = Test-LaravelVite -Port $VitePort

        # Test Laravel Queue Worker
        Write-Development -Message "Testing Laravel queue worker..." -Type Info
        if ($Queue) {
            $queueStatus = Test-LaravelQueue -Queue $Queue
        } else {
            $queueStatus = Test-LaravelQueue
        }
        
        # Summary
        Write-Development -Message "" -Type Info
        Write-Development -Message "Laravel Development Environment Status:" -Type Info
        Write-Development -Message "  - Web Server (port $WebPort): $(if($webStatus) { 'Running' } else { 'Stopped' })" -Type Info
        Write-Development -Message "  - Vite Server (port $VitePort): $(if($viteStatus) { 'Running' } else { 'Stopped' })" -Type Info
        Write-Development -Message "  - Queue Worker$(if($Queue) { " ($Queue)" }): $(if($queueStatus) { 'Running' } else { 'Stopped' })" -Type Info
        
        $allRunning = $webStatus -and $viteStatus -and $queueStatus
        
        if ($allRunning) {
            Write-Development -Message "All Laravel services are running!" -Type Success
        } else {
            $runningCount = @($webStatus, $viteStatus, $queueStatus) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
            Write-Development -Message "$runningCount of 3 Laravel services are running" -Type Warning
        }
        
        return @{
            Web = $webStatus
            Vite = $viteStatus
            Queue = $queueStatus
            All = $allRunning
        }
        
    } catch {
        Write-Development -Message "Failed to test Laravel development environment: $($_.Exception.Message)" -Type Error
        return @{
            Web = $false
            Vite = $false
            Queue = $false
            All = $false
        }
    }
}
