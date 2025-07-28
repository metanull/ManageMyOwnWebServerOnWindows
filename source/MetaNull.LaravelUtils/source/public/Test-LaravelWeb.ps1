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
    Test-LaravelWeb -Path "C:\path\to\laravel" -Port 8000
    Tests if Laravel web server is running on port 8000
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,
    
    [Parameter()]
    [int]$Port = 8000
)

Begin {
    Write-DevInfo "Testing Laravel web server on port $Port..."
    
    # Validate Laravel path
    if (-not (Test-Path $Path -PathType Container)) {
        Write-DevError "Laravel path does not exist: $Path"
        return $false
    }
    
    if (Test-DevPort -Port $Port) {
        try {
            # Try to make a simple HTTP request to verify it's actually Laravel
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port" -Method HEAD -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response) {
                Write-DevSuccess "Laravel web server is running and responding on port $Port"
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
        Write-DevInfo "Laravel web server is not running on port $Port"
        return $false
    }
}
