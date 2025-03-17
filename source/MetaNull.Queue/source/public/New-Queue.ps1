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
    [string] $Description,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Iddle','Running','Disabled','Suspended')]
    [string] $Status = 'Iddle'
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    try {
        # Create the queue object
        $Guid = [guid]::NewGuid().ToString()
        $Properties = @{
            Id = $Guid
            Name = $Name
            Description = $Description
            Status = $Status
        }

        # Store the queue into the registry
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            $Item = New-Item -Path "MetaNull:\Queues\$Guid" -Force
            New-Item -Path "MetaNull:\Queues\$Guid\Commands" -Force | Out-Null
            $Properties.GetEnumerator() | ForEach-Object {
                $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
            }
            return $Guid
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
