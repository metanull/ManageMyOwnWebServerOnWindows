<#
    .SYNOPSIS
    Runs the tests on the Laravel application

    .DESCRIPTION
    Executes the tests to check the functionality of the Laravel application (PHPUnit and/or Node.js tests).

    .PARAMETER Path
    The root directory of the Laravel application.

    .PARAMETER Target
    The target for the tests (node, artisan, phpunit, pest).
    - "artisan" runs Laravel's built-in test runner.
      - "pest" specifically runs the Pest testing framework.
      - "phpunit" specifically runs the PHPUnit testing framework.
    - "node" runs Node.js tests.

    .PARAMETER OtherArgs
    Additional arguments to pass to the test command (optional)

    .EXAMPLE
    Invoke-Test -Path "C:\path\to\laravel" -Target artisan

    Runs the php tests on the specified Laravel application path.

    .EXAMPLE
    Invoke-Test -Path C:\path\to\laravel -Target artisan --parallel --compact

    Runs the php tests with additional arguments on the specified Laravel application path.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-LaravelPath -Path $_ })]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidateSet('artisan','node','phpunit','pest')]
    [string]$Target,

    [Parameter(ValueFromRemainingArguments=$true)]
    $OtherArgs
)
End {
    if ($Target -eq 'node') {
        $npmPath = Get-Command npm -ErrorAction Stop
        if (-Not $npmPath) {
            throw "npm command not found. Please ensure Node.js is installed."
        }

        Write-Development -Message "Running Node.js Tests..." -Type Info
        & $npmPath -C $Path run test @OtherArgs 2>&1
    }
    elseif ($Target -eq 'artisan') {
        $artisanPath = Join-Path -Path $Path -ChildPath "artisan"
        if (-Not (Test-Path $artisanPath)) {
            throw "artisan executable not found at $artisanPath"
        }

        Write-Development -Message "Running Artisan Tests..." -Type Info
        & php $artisanPath test @OtherArgs 2>&1
    }
    elseif ($Target -eq 'pest') {
        $pestPath = Join-Path -Path $Path -ChildPath "vendor/bin/pest"
        if (-Not (Test-Path $pestPath)) {
            throw "pest executable not found at $pestPath"
        }
        $phpunitXmlPath = Join-Path -Path $Path -ChildPath "phpunit.xml"
        if (-Not (Test-Path $phpunitXmlPath)) { 
            throw "phpunit.xml configuration file not found at $phpunitXmlPath"
        }

        Write-Development -Message "Running Pest..." -Type Info
        & $pestPath --configuration $phpunitXmlPath @OtherArgs 2>&1
    }
    elseif ($Target -eq 'phpunit') {
        $phpunitPath = Join-Path -Path $Path -ChildPath "vendor/bin/phpunit"
        if (-Not (Test-Path $phpunitPath)) {
            throw "phpunit executable not found at $phpunitPath"
        }
        $phpunitXmlPath = Join-Path -Path $Path -ChildPath "phpunit.xml"
        if (-Not (Test-Path $phpunitXmlPath)) { 
            throw "phpunit.xml configuration file not found at $phpunitXmlPath"
        }

        Write-Development -Message "Running PHPUnit..." -Type Info
        & $phpunitPath --configuration $phpunitXmlPath @OtherArgs 2>&1
    }
    else {
        throw "Unsupported target: $Target"
    }
}
