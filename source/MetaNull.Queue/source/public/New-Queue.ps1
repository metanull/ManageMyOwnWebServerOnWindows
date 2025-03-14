<#
    .SYNOPSIS
        Create a Queue
#>
[CmdletBinding()]
[OutputType([guid])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'CurrentUser',

    [Parameter(Mandatory)]
    [string] $Name,

    [Parameter(Mandatory=$false)]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $Description
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues\$Name"
        $Guid = [guid]::NewGuid().ToString()
        $Item = New-Item -Path $Path
        $Item | New-ItemProperty -Name Id -Value $Guid -PropertyType String
        $Item | New-ItemProperty -Name Description -Value $Description -PropertyType String
        $Item | New-ItemProperty -Name Enabled -Value 1 -PropertyType DWord
        $Item | New-ItemProperty -Name Created -Value (Get-Date|ConvertTo-Json) -PropertyType String
        $Item | New-ItemProperty -Name Modified -Value (Get-Date|ConvertTo-Json) -PropertyType String
        $Item | New-ItemProperty -Name LastResult -Value 0 -PropertyType DWord
        $Item | New-ItemProperty -Name LastResultDate -Value $null -PropertyType String
        $Item | New-ItemProperty -Name Version -Value ([version]::new(0,0,0,0)|ConvertTo-JSon -Compress) -PropertyType String
        
        $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues\$Name\Tasks"
        $Item = New-Item -Path $Path

        $Guid | Write-Output
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
