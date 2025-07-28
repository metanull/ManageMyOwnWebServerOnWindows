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
    Test-Laravel -Path "C:\path\to\laravel"
    Tests all Laravel services with default settings
    
    .EXAMPLE
    Test-Laravel -Path "C:\path\to\laravel" -WebPort 8080 -VitePort 3000 -Queue "emails"
    Tests Laravel services with custom ports and specific queue
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host used for status output formatting with spacing in development utility')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,
    
    [Parameter()]
    [int]$WebPort = 8000,
    
    [Parameter()]
    [int]$VitePort = 5173,
    
    [Parameter()]
    [string]$Queue
)

Begin {
    Write-DevHeader "Testing Laravel Development Environment"
    
    $webStatus = $false
    $viteStatus = $false
    $queueStatus = $false
    
    try {
        # Test Laravel Web Server
        Write-DevInfo "Testing Laravel web server..."
        $webStatus = Test-LaravelWeb -Path $Path -Port $WebPort
        
        # Test Vite Development Server
        Write-DevInfo "Testing Vite development server..."
        $viteStatus = Test-LaravelVite -Path $Path -Port $VitePort
        
        # Test Laravel Queue Worker
        Write-DevInfo "Testing Laravel queue worker..."
        if ($Queue) {
            $queueStatus = Test-LaravelQueue -Path $Path -Queue $Queue
        } else {
            $queueStatus = Test-LaravelQueue -Path $Path
        }
        
        # Summary
        Write-Host ""
        Write-DevInfo "Laravel Development Environment Status:"
        Write-DevInfo "  - Web Server (port $WebPort): $(if($webStatus) { 'Running' } else { 'Stopped' })"
        Write-DevInfo "  - Vite Server (port $VitePort): $(if($viteStatus) { 'Running' } else { 'Stopped' })"
        Write-DevInfo "  - Queue Worker$(if($Queue) { " ($Queue)" }): $(if($queueStatus) { 'Running' } else { 'Stopped' })"
        
        $allRunning = $webStatus -and $viteStatus -and $queueStatus
        
        if ($allRunning) {
            Write-DevSuccess "All Laravel services are running!"
        } else {
            $runningCount = @($webStatus, $viteStatus, $queueStatus) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
            Write-DevWarning "$runningCount of 3 Laravel services are running"
        }
        
        return @{
            Web = $webStatus
            Vite = $viteStatus
            Queue = $queueStatus
            All = $allRunning
        }
        
    } catch {
        Write-DevError "Failed to test Laravel development environment: $($_.Exception.Message)"
        return @{
            Web = $false
            Vite = $false
            Queue = $false
            All = $false
        }
    }
}
