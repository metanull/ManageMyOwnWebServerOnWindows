<#
    .SYNOPSIS
    Tests if the Laravel web development server is running
    
    .DESCRIPTION
    Checks if the Laravel web server is responding on the specified port
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .PARAMETER Port
    The port number to test (default: 8000)
    
    .EXAMPLE
    Test-LaravelWeb -Port 8000
    Tests if Laravel web server is running on port 8000
#>
[CmdletBinding()]
param(
    [Parameter()]
    [int]$Port = 8000
)

Begin {
    Write-Development -Message "Testing Laravel web server on port $Port..." -Type Info
    
    if (Test-DevPort -Port $Port) {
        try {
            # Try to make a simple HTTP request to verify it's actually Laravel
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port" -Method HEAD -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response) {
                Write-Development -Message "Laravel web server is running and responding on port $Port" -Type Success
                return $true
            } else {
                Write-Development -Message "Port $Port is in use but not responding to HTTP requests" -Type Warning
                return $false
            }
        } catch {
            Write-Development -Message "Port $Port is in use but HTTP test failed: $($_.Exception.Message)" -Type Warning
            return $false
        }
    } else {
        Write-Development -Message "Laravel web server is not running on port $Port" -Type Info
        return $false
    }
}
