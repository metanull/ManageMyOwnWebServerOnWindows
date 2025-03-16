<#
    .SYNOPSIS
        Create a Queue
#>
[CmdletBinding()]
[OutputType([guid])]
param(
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

    if(Find-Queue -Name $Name) {
        throw "Queue '$Name' already exists"
    }

    [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
    try {
        $Guid = [guid]::NewGuid().ToString()
        $Item = New-Item -Path "MetaNull:\Queues\$Guid" -Force
        $Commands = New-Item -Path "MetaNull:\Queues\$Guid\Commands" -Force
        $Properties = @{
            Name = $Name
            Id = $Guid
            Description = $Description
            Status = 'Iddle'
            CreatedDate = (Get-Date|ConvertTo-Json)
            ModifiedDate = (Get-Date|ConvertTo-Json)
            StartCount = 0
            FailureCount = 0
            Disabled = 0
            Suspended = 0
            DisabledDate = $null
            SuspendedDate = $null
            LastStartedDate = $null
            LastFinishedDate = $null
            Version = ([version]::new(0,0,0,0)|ConvertTo-JSon -Compress)
        }
        $Properties.GetEnumerator() | ForEach-Object {
            $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
        }
        $Item | Write-Warning
        return $Guid
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
