function Find-Powershell {
	<#
        .NOTES
            Author: Pascal Havelange
        .SYNOPSIS
            Find strings in all Powershell files in a given path
        .DESCRIPTION
            Find strings in all Powershell files in a given path
        .PARAMETER Pattern
            The pattern to search for
        .PARAMETER Path
            The path to search in. If not specified, the current directory is used.
        .EXAMPLE
            # Find all powershell containing 'apache' in the current directory
            Find-Powershell -Pattern 'NEEDLE'
        .EXAMPLE
            # Find all powershell containing 'apache' in all the drives
            $ErrorView = 'CategoryView'
            Get-Volume | Foreach-Object { "$($_.DriveLetter):\" } | Find-Powershell -Pattern 'NEEDLE'

	#>
	[CmdLetBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
	param(
		[Parameter(ValueFromPipeline,Position = 1)]
		[ValidateScript({ $_ | Test-Path -PathType Container })]
		[string] $Path = (Get-Location),
        
        [Parameter(Mandatory,Position = 0)]
        [ValidateScript({ $_ -is [string] })]
        [ValidateNotNullOrEmpty()]
        [string] $Pattern
	)
    Process {
        
        try {
            Get-ChildItem -Path $Path -Recurse -Include *.ps*1 -ErrorAction Continue | Where-Object {
                ($_ | Test-Path -PathType Leaf) -and $_.Extension -in '.ps1','.psm1','.psd1'
            } | Foreach-Object {
                [pscustomobject]@{
                    File=$_
                    Matches=(Select-String -Path $_.FullName -CaseSensitive -Pattern $Pattern)
                }
            } | Where-Object {
                $null -ne $_.Matches
            }
        } catch {
            $ErrorView = $OldErrorView
            Write-Warning "Error accessing $($_):"
            $_ | Out-Null
        }
    }
}