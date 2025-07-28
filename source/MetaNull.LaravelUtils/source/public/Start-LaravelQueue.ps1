<#
    .SYNOPSIS
    Starts the Laravel queue worker
    
    .DESCRIPTION
    Starts Laravel's queue worker to process background jobs
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER Queue
    The queue name to process (default: default)
    
    .PARAMETER ConnectionName
    The queue connection to use (default: uses Laravel's default)
    
    .PARAMETER MaxJobs
    Maximum number of jobs to process before restarting (default: 1000)
    
    .PARAMETER MaxTime
    Maximum time in seconds the worker should run (default: 3600)
    
    .PARAMETER Sleep
    Number of seconds to sleep when no jobs are available (default: 3)
    
    .PARAMETER Timeout
    Number of seconds a child process can run (default: 60)
    
    .PARAMETER Force
    Force stop any existing queue workers
    
    .EXAMPLE
    Start-LaravelQueue -Path "C:\path\to\laravel"
    Starts Laravel queue worker with default settings
    
    .EXAMPLE
    Start-LaravelQueue -Path "C:\path\to\laravel" -Queue "emails" -MaxJobs 500
    Starts Laravel queue worker for the "emails" queue with max 500 jobs
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host used for debugging output display in development utility')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,
    
    [Parameter()]
    [string]$Queue = "default",
    
    [Parameter()]
    [string]$ConnectionName,
    
    [Parameter()]
    [int]$MaxJobs = 1000,
    
    [Parameter()]
    [int]$MaxTime = 3600,
    
    [Parameter()]
    [int]$Sleep = 3,
    
    [Parameter()]
    [int]$Timeout = 60,
    
    [Parameter()]
    [switch]$Force
)

Begin {
    Write-DevStep "Starting Laravel queue worker for queue '$Queue'..."
    
    if ($Force) {
        Write-DevInfo "Stopping any existing queue workers..."
        Stop-LaravelQueue -Path $Path -Queue $Queue -Force
    }
    
    # Build the artisan command
    $queueCommand = "queue:work"
    $queueArgs = @()
    
    if ($ConnectionName) {
        $queueArgs += $ConnectionName
    }
    
    $queueArgs += "--queue=$Queue"
    $queueArgs += "--max-jobs=$MaxJobs"
    $queueArgs += "--max-time=$MaxTime"
    $queueArgs += "--sleep=$Sleep"
    $queueArgs += "--timeout=$Timeout"
    $queueArgs += "--verbose"
    
    # Start queue worker
    $queueJob = Start-Job -ScriptBlock {
        Set-Location $Using:Path
        & php artisan $Using:queueCommand $Using:queueArgs
    }
    
    # Give it a moment to start
    Start-Sleep -Seconds 2
    
    # Check if job is running
    if ($queueJob.State -eq "Running") {
        Write-DevSuccess "Laravel queue worker started successfully for queue '$Queue'"
        Write-DevInfo "Worker will process up to $MaxJobs jobs or run for $MaxTime seconds"
        return $queueJob
    } else {
        Write-DevError "Failed to start Laravel queue worker"
        
        # Get job output for debugging
        $jobOutput = Receive-Job $queueJob -ErrorAction SilentlyContinue
        if ($jobOutput) {
            Write-DevError "Queue worker output:"
            Write-Host $jobOutput -ForegroundColor Red
        }
        
        Remove-Job $queueJob -ErrorAction SilentlyContinue
        return $null
    }
}
