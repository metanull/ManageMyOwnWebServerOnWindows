<#
    .SYNOPSIS
        Create a Queue
#>
[CmdletBinding()]
[OutputType([guid])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

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

    $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues\$Name"
    if(Test-Path -Path $Path) {
        throw "Queue $Name already exists"
    }

    [System.Threading.Monitor]::Enter($METANULL_QUEUE_CONSTANTS.Lock)
    try {
        $Guid = [guid]::NewGuid().ToString()
        $Item = New-Item -Path $Path
        $Item | New-ItemProperty -Name Id -Value $Guid -PropertyType String | Out-Null
        $Item | New-ItemProperty -Name Description -Value $Description -PropertyType String | Out-Null
        $Item | New-ItemProperty -Name Status -Value 'Iddle' -PropertyType String | Out-Null
        $Item | New-ItemProperty -Name CreatedDate -Value (Get-Date|ConvertTo-Json) -PropertyType String | Out-Null
        $Item | New-ItemProperty -Name ModifiedDate -Value (Get-Date|ConvertTo-Json) -PropertyType String | Out-Null
        $Item | New-ItemProperty -Name StartCount -Value 0 -PropertyType DWord | Out-Null
        $Item | New-ItemProperty -Name FailureCount -Value 0 -PropertyType DWord | Out-Null
        $Item | New-ItemProperty -Name Disabled -Value 0 -PropertyType DWord | Out-Null
        $Item | New-ItemProperty -Name Suspended -Value 0 -PropertyType DWord | Out-Null
        $Item | New-ItemProperty -Name DisabledDate -Value $null -PropertyType String | Out-Null
        $Item | New-ItemProperty -Name SuspendedDate -Value $null -PropertyType String | Out-Null
        $Item | New-ItemProperty -Name LastStartedDate -Value $null -PropertyType String | Out-Null
        $Item | New-ItemProperty -Name LastFinishedDate -Value $null -PropertyType String | Out-Null
        $Item | New-ItemProperty -Name Version -Value ([version]::new(0,0,0,0)|ConvertTo-JSon -Compress) -PropertyType String | Out-Null
        
        $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues\$Name\Commands"
        $CommandItem = New-Item -Path $Path -Force | Out-Null

        return $Guid
    } finally {
        [System.Threading.Monitor]::Exit($METANULL_QUEUE_CONSTANTS.Lock)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
