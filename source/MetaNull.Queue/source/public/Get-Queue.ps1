<#
    .SYNOPSIS
        Returns the list of Queues
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [AllowNull()]
    [AllowEmptyString()]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return $null -eq $_ -or $_ -eq [string]::empty -or ([guid]::TryParse($_, [ref]$ref))
    })]
    [string] $Id = $null
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $StrId = '*'
        if($Id) {
            $StrId = $Id
        }
        "MetaNull:\Queues\$StrId" | Write-Debug
        Get-Item -Path "MetaNull:\Queues\$StrId" | ConvertFrom-QueueRegistry | Foreach-Object {
            $_.Commands = Get-ChildItem "MetaNull:\Queues\$($_.Id)\Commands" | ConvertFrom-CommandRegistry
            $_ | write-output
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
