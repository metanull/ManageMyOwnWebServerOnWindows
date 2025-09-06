<#
    .SYNOPSIS


    .EXAMPLE
    
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-LaravelPath -Path $_ })]
    [string]$Path
)
End {
    $Diagnostics = @(
        @{ Name = 'Composer Diagnose'; Command = { composer diagnose 2>&1 } },
        @{ Name = 'Composer Validate'; Command = { composer validate --with-dependencies --strict --quiet 2>&1 } },
        @{ Name = 'Composer Audit'; Command = { composer audit --format=summary 2>&1 } },
        @{ Name = 'Laravel Lint'; Command = { php artisan lint --ansi --no-interaction 2>&1 } },
        #@{ Name = 'Laravel Test'; Command = { php artisan test --bail --compact --parallel 2>&1 } },
        @{ Name = 'Prettier'; Command = { npx prettier --log-level warn --no-color --check resources/js/ 2>&1 } },
        @{ Name = 'ESLint'; Command = { npx eslint --quiet --no-fix --format stylish 2>&1 } },
        @{ Name = 'Vue TSC'; Command = { npx vue-tsc --noEmit --pretty false 2>&1 } },
        @{ Name = 'NPM Audit'; Command = { npm audit --omit=dev --audit-level moderate 2>&1 } },
        @{ Name = 'NPM Build'; Command = { npm run build 2>&1 } }
    )
    Push-Location -Path $Path -ErrorAction Stop
    try {
        Write-Development -Message "Running Diagnostics..." -Type Header
        foreach ($diagnostic in $Diagnostics) {
            $StartTime = Get-Date
            Write-Development -Message "Running $($diagnostic.Name)..." -Type Step
            #$diagnostic.Command = $diagnostic.Command.Invoke()
            #Write-Host "Running $($diagnostic.Name)..."
            & $diagnostic.Command
            if ($LASTEXITCODE -ne 0) {
                Write-Development -Message "$($diagnostic.Name) failed with exit code $LASTEXITCODE" -Type Error
            } else {
                Write-Development -Message "$($diagnostic.Name) completed successfully." -Type Success
            }
            $EndTime = Get-Date
            Write-Development -Message "$($diagnostic.Name) completed in $($EndTime - $StartTime)" -Type Info
        }
    } finally {
        Pop-Location
    }
}
