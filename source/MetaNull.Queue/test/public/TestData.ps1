# Mock Module Initialization, create the test registry key
$PSDriveRoot = 'HKCU:\SOFTWARE\MetaNull\PowerShell.Tests\MetaNull.Queue'
New-Item -Force -Path $PSDriveRoot\Queues -ErrorAction SilentlyContinue  | Out-Null
$MetaNull = @{
    Queue = @{
        PSDriveRoot = $PSDriveRoot
        Lock = New-Object Object
        Drive = New-PSDrive -Name 'MetaNull' -Scope Script -PSProvider Registry -Root $PSDriveRoot
    }
}
# Generate TestData
$TestData = @(
    @{
        Queue = @{
            Id = (New-Guid)
            Name = 'NAME:1-7346C3F01B4E97608D24523623B77EC4'
            Description = 'DESCRIPTION:1'
            Status = 'Iddle'
        }
        Commands = @(
            @{
                Index = 1
                Name = 'Test-Command:1#1'
                Command = "'Hello' | Write-Output"
                Output = 'Hello'
            }
            @{
                Index = 2
                Name = 'Test-Command:1#2'
                Command = "'World' | Write-Output"
                Output = 'World'
            }
        )
    }
    @{
        Queue = @{
            Id = (New-Guid)
            Name = 'NAME:2-C79157071A0AC0A363BE15A1ED29FD7A'
            Description = 'DESCRIPTION:2'
            Status = 'Iddle'
        }
        Commands = @(
            @{
                Index = 1
                Name = 'Test-Command:2#1'
                Command = "'Hello' | Write-Output"
                Output = 'Hello'
            }
            @{
                Index = 2
                Name = 'Test-Command:2#2'
                Command = "'World' | Write-Output"
                Output = 'World'
            }
            @{
                Index = 3
                Name = 'Test-Command:2#3'
                Command = "'!' | Write-Output"
                Output = '!'
            }
        )
    }
)

Function ValidateTestData {
    param($TestData)
    
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if( -not (Get-PSDrive -Name 'MetaNull')) {
            throw 'PSDrive MetaNull: is not defined'
        }
        if( -not (Test-Path MetaNull:\Queues)) {
            throw 'Path MetaNull:\Queues was not found'
        }
        $ix = -1
        $TestData | Foreach-Object {
            $ix += 1
            if(-not ($_.Queue)) {
                throw "TestData[$ix].Queue was empty"
            }
            if(-not ($_.Commands)) {
                throw "TestData[$ix].Commands was empty"
            }
            $Queue = $_.Queue
            if(-not (Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands")) {
                throw "Path MetaNull:\Queues\$($Queue.Id)\Commands was not found"
            }
            if((Get-ChildItem "MetaNull:\Queues\$($Queue.Id)\Commands").Count -ne $($_.Commands.Count)) {
                throw "Path MetaNull:\Queues\$($Queue.Id)\Commands doesn't contain $($_.Commands.Count) elements"
            }
            $_.Commands | Foreach-Object {
                if( -not (Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands\$($_.Index)")) {
                    throw "Path MetaNull:\Queues\$($Queue.Id)\Commands\$($_.Index)"
                }
                $Item = Get-Item "MetaNull:\Queues\$($Queue.Id)\Commands\$($_.Index)"
                if(-not ($Item)) {
                    throw "Couldn't get item at MetaNull:\Queues\$($Queue.Id)\Commands\$($_.Index)"
                }
                $Command = $Item | Get-ItemProperty | Select-Object -ExpandProperty 'Command'
                if(-not ($command)) {
                    throw "Couldn't get the Command property of MetaNull:\Queues\$($Queue.Id)\Commands\$($_.Index)"
                }
            }
        }
        return $true
    } catch {
        Write-Warning $_.Exception.ToString()
        return $false
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}