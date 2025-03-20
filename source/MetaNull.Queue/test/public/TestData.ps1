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
$TestData = @{
    Queues = @(
        @{
            Id = (New-Guid)
            Name = 'NAME:1-7346C3F01B4E97608D24523623B77EC4'
            Description = 'DESCRIPTION:1'
            Status = 'Iddle'
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
            Id = (New-Guid)
            Name = 'NAME:2-C79157071A0AC0A363BE15A1ED29FD7A'
            Description = 'DESCRIPTION:2'
            Status = 'Iddle'
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
}

Function DestroyTestData {
    Remove-Item -Force -Recurse -Path MetaNull:\ -ErrorAction SilentlyContinue  | Out-Null
    Remove-PSDrive -Name MetaNull -Scope Script -ErrorAction SilentlyContinue
}

Function RemoveTestData {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Remove-Item -Force -Recurse -Path MetaNull:\Queues\* -ErrorAction SilentlyContinue  | Out-Null
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
Function InsertTestData {
    param($TestData)

    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {

        $TestData.Queues | Foreach-Object {
            $Queue = $_
            $Id = $Queue.Id
            $Properties = $Queue
            New-Item "MetaNull:\Queues\$Id" -Force | Out-Null
            $Item = Get-Item "MetaNull:\Queues\$Id"
            $Properties.GetEnumerator() | Where-Object {
                $_.Key -ne 'Commands'
            } | ForEach-Object {
                $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
            }
            $Queue.Commands | Foreach-Object {
                $Command = $_
                $Index = $Command.Index
                $Item = New-Item -Path "MetaNull:\Queues\$Id\Commands\$Index" -Force
                $_.GetEnumerator() | Where-Object {
                    $_.Key -ne 'Output'
                } | ForEach-Object {
                    $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                }
            }
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}

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
        if(-not ($TestData.Queues)) {
            throw "TestData.Queues was empty"
        }
        $QueueIndex = -1
        $TestData.Queues | Foreach-Object {
            $QueueIndex += 1
            if(-not ($_.Id)) {
                throw "TestData.Queues[$QueueIndex].Id was empty"
            }
            if(-not ($_.Name)) {
                throw "TestData.Queues[$QueueIndex].Name was empty"
            }
            if(-not ($_.Description)) {
                throw "TestData.Queues[$QueueIndex].Description was empty"
            }
            if(-not ($_.Status)) {
                throw "TestData.Queues[$QueueIndex].Status was empty"
            }
            if(-not ($_.Commands)) {
                throw "TestData.Queues[$QueueIndex].Commands was empty"
            }
            $CommandIndex = -1
            $_.Commands | Foreach-Object {
                $CommandIndex += 1
                if(-not ($_.Index)) {
                    throw "TestData.Queues[$QueueIndex].Commands[$CommandIndex].Index was empty"
                }
                if(-not ($_.Name)) {
                    throw "TestData.Queues[$QueueIndex].Commands[$CommandIndex].Name was empty"
                }
                if(-not ($_.Command)) {
                    throw "TestData.Queues[$QueueIndex].Commands[$CommandIndex].Command was empty"
                }
                if(-not ($_.Output)) {
                    throw "TestData.Queues[$QueueIndex].Commands[$CommandIndex].Output was empty"
                }
                if($_.Command.Count -ne $_.Output.Count) {
                    throw "TestData.Queues[$QueueIndex].Commands[$CommandIndex].Command.Count doesn't match TestData[$QueueIndex].Commands[$CommandIndex].Output.Count"
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