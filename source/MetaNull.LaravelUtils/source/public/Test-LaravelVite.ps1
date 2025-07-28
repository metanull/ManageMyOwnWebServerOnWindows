<#
    .SYNOPSIS
    Tests if the Laravel Vite development server is running
    
    .DESCRIPTION
    Checks if the Laravel Vite server is responding on the specified port
    
    .PARAMETER Port
    The port number to test (default: 5173)
    
    .EXAMPLE
    Test-LaravelVite -Port 5173
    Tests if Laravel Vite server is running on port 5173
#>
[CmdletBinding()]
param(
    [Parameter()]
    [int]$Port = 5173
)

Begin {
    Write-DevInfo "Testing Laravel Vite server on port $Port..."
    
    if (Test-DevPort -Port $Port) {
        try {
            # Try to make a simple HTTP request to verify it's actually Vite
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port" -Method HEAD -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response) {
                Write-DevSuccess "Laravel Vite server is running and responding on port $Port"
                return $true
            } else {
                Write-DevWarning "Port $Port is in use but not responding to HTTP requests"
                return $false
            }
        } catch {
            Write-DevWarning "Port $Port is in use but HTTP test failed: $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-DevInfo "Laravel Vite server is not running on port $Port"
        return $false
    }
}
