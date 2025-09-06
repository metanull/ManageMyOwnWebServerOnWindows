<#
    .SYNOPSIS
        Formats and displays PHP error logs in a readable format.
    .OUTPUTS
        The formatted PHP error logs.
    .DESCRIPTION
        Formats and displays PHP error logs in a readable format. It reads the log file line by line, extracts relevant information, and displays it in a structured format.
    .PARAMETER Path
        The path to the PHP error log file. This parameter is mandatory and accepts wildcards.
    .EXAMPLE
        # Formats and displays the PHP error log file located at "C:\Logs\php_errors.log".
        Format-PHPLog -Path "C:\Logs\php_errors.log"
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ Get-Item $_ | Test-Path -PathType Leaf })]
    [SupportsWildcards()]
    [string]
    $Path
)
Process {
    Get-Content -Path $Path -wait | Foreach-Object -Begin {
        $Buffer = ([ref]('VOID'))
    } -End {
        if ($Buffer.Value -ne 'VOID') {
            $Buffer | Write-Output
        }
    } -Process {
        $expr = [regex]::new('^\[(?<TIMESTAMP>[^\]]+)\] ((?<SEVERITY>[^:]+):[ ]+)?(?<MESSAGE>.*?)( in (?<FILE>\S+)(:| on line )(?<LINE>\d+))?$')
        $rx = $expr.Match($_)
        if ($rx.Success) {
            if ($Buffer.Value -ne 'VOID') {
                $Buffer.Value | Write-Output
            }
            $Buffer.Value = [pscustomobject]@{
                Time     = $rx.Groups['TIMESTAMP'].Value
                Severity = $rx.Groups['SEVERITY'].Value
                Message  = $rx.Groups['MESSAGE'].Value
                File     = $rx.Groups['FILE'].Value
                Line     = $rx.Groups['LINE'].Value
                Extra    = @()
            }
        }
        elseif (-not ([string]::IsNullOrEmpty($Buffer.Value.Severity))) {
            $Buffer.Value.Extra += , $_
        }
        else {
            $Buffer.Value = 'VOID'
            [pscustomobject]@{Time = $null; Severity = $null; Message = $_; File = $null; Line = $null; Extra = @() } | Write-Output
        }
    } | Foreach-Object {
        if ($null -ne $_.Severity) {
            switch -Regex ($_.Severity) {
                'error' { Write-Host -NoNewLine -ForegroundColor Red $_ }
                'warning' { Write-Host -NoNewLine -ForegroundColor Yellow $_ }
                'notice' { Write-Host -NoNewLine -ForegroundColor Cyan $_ }
                default { Write-Host -NoNewLine -ForegroundColor Magenta $_ }
            }
            Write-Host -NoNewline ' '
            Write-Host -ForegroundColor DarkYellow  $_.Message
            Write-Host -NoNewline '   > '
            Write-Host -NoNewLine -ForegroundColor DarkCyan $_.Time
            Write-Host -NoNewline ' | '
            Write-Host -NoNewLine -ForegroundColor DarkCyan $_.File
            Write-Host -NoNewline ' | '
            Write-Host -ForegroundColor DarkCyan $_.Line
            $_.Extra | Foreach-Object {
                Write-Host -ForegroundColor DarkGray "   > $_"
            }
        }
        else {
            Write-Host -NoNewline -ForegroundColor DarkRed $_.Message
        }
    }
}