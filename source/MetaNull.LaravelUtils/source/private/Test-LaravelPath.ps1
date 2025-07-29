<#
    .SYNOPSIS
    Tests if the directory is the root of a Laravel application
    
    .DESCRIPTION
    Checks if the specified path contains a Laravel application by looking for key files and directories
    
    .PARAMETER Path
    The root directory of the Laravel application
    
    .EXAMPLE
    Test-LaravelPath -Path "C:\path\to\laravel"
    Tests if the specified path is a Laravel application root
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path = '.'
)

Begin {
    if(-Not (Test-Path -Path $Path -PathType Container)) {
        Write-Development -Message "The specified path '$Path' does not exist or is not a directory." -Type Error
        return $false
    }
    if(-Not (Test-Path -Path (Join-Path -Path $Path -ChildPath 'artisan'))) {
        Write-Development -Message "The specified path '$Path' does not contain a Laravel application (missing 'artisan' file)." -Type Error
        return $false
    }
    if(-Not (Test-Path -Path (Join-Path -Path $Path -ChildPath 'composer.json'))) {
        Write-Development -Message "The specified path '$Path' does not contain a Laravel application (missing 'composer.json' file)." -Type Error
        return $false
    }
    if(-Not (Test-Path -Path (Join-Path -Path $Path -ChildPath 'vendor'))) {
        Write-Development -Message "The specified path '$Path' does not contain a Laravel application (missing 'vendor' directory). Please run 'composer install' first." -Type Error
        return $false
    }
    if(-Not (Test-Path -Path (Join-Path -Path $Path -ChildPath 'package.json'))) {
        Write-Development -Message "The specified path '$Path' does not contain a Laravel application (missing 'package.json' file)." -Type Error
        return $false
    }
    if(-Not (Test-Path -Path (Join-Path -Path $Path -ChildPath 'vite.config.js'))) {
        Write-Development -Message "The specified path '$Path' does not contain a Laravel application (missing 'vite.config.js' file)." -Type Error
        return $false
    }
    if(-Not (Test-Path -Path (Join-Path -Path $Path -ChildPath 'node_modules'))) {
        Write-Development -Message "The specified path '$Path' does not contain a Laravel application (missing 'node_modules' directory). Please run 'npm install' first." -Type Error
        return $false
    }
    return $true
}
