<#
    .SYNOPSIS
    Runs the linter on the Laravel application

    .DESCRIPTION
    Executes the linter to check the code style of the Laravel application (Pint and/or ESLint).

    .PARAMETER Path
    The root directory of the Laravel application (default: current directory)

    .PARAMETER Target
    The target for the linter (php, node, artisan). Default is php.
    - "artisan" runs Laravel's built-in lint runner.
      - "pint" specifically runs the Pint PHP linter.
    - "node" runs Node.js linter (e.g., ESLint).

    .PARAMETER OtherArgs
    Additional arguments to pass to the Pint command (optional)
    
    .EXAMPLE
    Invoke-Lint -Path "C:\path\to\laravel" -Target artisan

    Runs the Pint linter on the specified Laravel application path.

    .EXAMPLE
    Invoke-Lint -Path C:\path\to\laravel -Target pint --no-interaction --ansi

    Runs the Pint linter with additional arguments on the specified Laravel application path.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-LaravelPath -Path $_ })]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidateSet('artisan','node','pint')]
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

        Write-Development -Message "Running Node.js Linter..." -Type Info
        & $npmPath -C $Path run lint @OtherArgs 2>&1
    }
    elseif ($Target -eq 'artisan') {
        $artisanPath = Join-Path -Path $Path -ChildPath "artisan"
        if (-Not (Test-Path $artisanPath)) {
            throw "artisan executable not found at $artisanPath"
        }

        Write-Development -Message "Running Artisan Linter..." -Type Info
        & php $artisanPath lint @OtherArgs 2>&1
    }
    elseif ($Target -eq 'pint') {
        $pintPath = Join-Path -Path $Path -ChildPath "vendor/bin/pint"
        if (-Not (Test-Path $pintPath)) {
            throw "pint executable not found at $pintPath"
        }

        Write-Development -Message "Running Pint PHP Linter..." -Type Info
        & $pintPath @OtherArgs 2>&1
    }
    else {
        throw "Unsupported target: $Target"
    }
}