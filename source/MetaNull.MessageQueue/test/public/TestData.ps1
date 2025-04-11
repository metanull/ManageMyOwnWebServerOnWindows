# Mock Module Initialization, create the test registry key
$PSDriveRoot = 'HKCU:\SOFTWARE\MetaNull\PowerShell.Tests\MetaNull.MesageQueue'
New-Item -Force -Path $PSDriveRoot\MessageQueue -ErrorAction SilentlyContinue 
New-Item -Force -Path $PSDriveRoot\MessageStore -ErrorAction SilentlyContinue 
$MetaNull = @{
    MessageQueue = @{
        PSDriveRoot = $PSDriveRoot
        LockMessageQueue = New-Object Object
        MutexMessageQueue = New-Object System.Threading.Mutex($false, 'MetaNull.MessageQueue.Test')
        Drive = New-PSDrive -Name 'MetaNull' -Scope Script -PSProvider Registry -Root $PSDriveRoot
    }
}
# Generate TestData
$TestData = @(
    @{
        MessageQueueId = (New-Guid)
        Name = 'TEST:1'
        MaximumSize = 3
        MessageRetentionPeriod = 1
        Messages = @(
            @{MessageId = (New-Guid) ; Index = 1 ; Date = (Get-Date).AddDays(-10) ; Label = 'LABEL:1' ; MetaData = @{Meta = 'Data:1'}}
            @{MessageId = (New-Guid) ; Index = 2 ; Date = (Get-Date).AddDays(-5) ; Label = 'LABEL:2' ; MetaData = @{Meta = 'Data:2'}}
            @{MessageId = (New-Guid) ; Index = 3 ; Date = (Get-Date).AddDays(-2) ; Label = 'LABEL:3' ; MetaData = @{Meta = 'Data:3'}}
            @{MessageId = (New-Guid) ; Index = 4 ; Date = (Get-Date).AddDays(-1) ; Label = 'LABEL:4' ; MetaData = @{Meta = 'Data:4'}}
            @{MessageId = (New-Guid) ; Index = 5 ; Date = (Get-Date) ; Label = 'LABEL:5' ; MetaData = @{Meta = 'Data:5'}}
        )
    }
    @{
        MessageQueueId = (New-Guid)
        Name = 'TEST:2'
        MaximumSize = 3
        MessageRetentionPeriod = 1
        Messages = @(
            @{MessageId = (New-Guid) ; Index = 1 ; Date = (Get-Date).AddDays(-10) ; Label = 'LABEL:1' ; MetaData = @{Meta = 'Data:1'}}
            @{MessageId = (New-Guid) ; Index = 2 ; Date = (Get-Date).AddDays(-5) ; Label = 'LABEL:2' ; MetaData = @{Meta = 'Data:2'}}
            @{MessageId = (New-Guid) ; Index = 3 ; Date = (Get-Date).AddDays(-2) ; Label = 'LABEL:3' ; MetaData = @{Meta = 'Data:3'}}
            @{MessageId = (New-Guid) ; Index = 4 ; Date = (Get-Date).AddDays(-1) ; Label = 'LABEL:4' ; MetaData = @{Meta = 'Data:4'}}
            @{MessageId = (New-Guid) ; Index = 5 ; Date = (Get-Date) ; Label = 'LABEL:5' ; MetaData = @{Meta = 'Data:5'}}
        )
    }
)

Function DestroyTestData {
    Remove-Item -Force -Recurse -Path MetaNull:\ -ErrorAction SilentlyContinue 
    Remove-PSDrive -Name MetaNull -Scope Script -ErrorAction SilentlyContinue
}

Function RemoveTestData {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Remove-Item -Force -Recurse -Path MetaNull:\MessageStore\* -ErrorAction SilentlyContinue 
        Remove-Item -Force -Recurse -Path MetaNull:\MessageQueue\* -ErrorAction SilentlyContinue 
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
Function InsertTestData {
    param($TestData)

    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $TestData | Foreach-Object {
            $QueueData = $_
            $QueueItem = New-Item "MetaNull:\MessageQueue\$($QueueData.MessageQueueId)"
            $QueueItem | Set-ItemProperty -Name 'MessageQueueId' -Value $QueueData.MessageQueueId
            $QueueItem | Set-ItemProperty -Name 'Name' -Value $QueueData.Name
            $QueueItem | Set-ItemProperty -Name 'MaximumSize' -Value $QueueData.MaximumSize
            $QueueItem | Set-ItemProperty -Name 'MessageRetentionPeriod' -Value $QueueData.MessageRetentionPeriod
            $QueueData.Messages | Foreach-Object {
                $MessageData = $_

                $StoreItem = New-Item "MetaNull:\MessageStore\$($MessageData.MessageId)"
                $StoreItem | Set-ItemProperty -Name 'MessageId' -Value $MessageData.MessageId
                $StoreItem | Set-ItemProperty -Name 'Date' -Value ($MessageData.Date|ConvertTo-JSon)
                $StoreItem | Set-ItemProperty -Name 'Label' -Value $MessageData.Label
                $StoreItem | Set-ItemProperty -Name 'MetaData' -Value ($MessageData.MetaData|ConvertTo-JSon)

                $MessageItem = New-Item "MetaNull:\MessageQueue\$($QueueData.MessageQueueId)\$($MessageData.Index)"
                $MessageItem | Set-ItemProperty -Name 'MessageId' -Value $MessageData.MessageId
                $MessageItem | Set-ItemProperty -Name 'Index' -Value $MessageData.Index
                $MessageItem | Set-ItemProperty -Name 'Date' -Value ($MessageData.Date|ConvertTo-JSon)
            }
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}

Function ValidateTestSetup {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if( -not (Get-PSDrive -Name 'MetaNull')) {
            throw 'PSDrive MetaNull: is not defined'
        }
        if( -not (Test-Path MetaNull:\MessageQueue)) {
            throw 'Path MetaNull:\MessageQueue was not found'
        }
        if( -not (Test-Path MetaNull:\MessageStore)) {
            throw 'Path MetaNull:\MessageStore was not found'
        }
        return $true
    } catch {
        Write-Warning $_.Exception.ToString()
        return $false
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
Function ValidateTestData {
    param($TestData)
    
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if(-not (ValidateTestSetup)) {
            throw 'TestSetup was not valid'
        }
        
        if(-not ($TestData.MessageQueueId.Count -gt 0)) {
            throw "TestData was empty"
        }
        $TestData | Foreach-Object -Begin {$QueueIndex = -1} -Process {
            $QueueIndex ++
            if(-not ($_.MessageQueueId)) {
                throw "TestData[$QueueIndex].MessageQueueId was empty"
            }

            # Throws an exception if the MessageQueueId is not a GUID
            [guid]$_.MessageQueueId

            if(-not ($_.Name)) {
                throw "TestData[$QueueIndex].Name was empty"
            }
            if(-not ($_.MaximumSize)) {
                throw "TestData[$QueueIndex].MaximumSize was empty"
            }
            if(-not ($_.MessageRetentionPeriod)) {
                throw "TestData[$QueueIndex].MessageRetentionPeriod was empty"
            }
            $_.Messages | Foreach-Object -Begin {$MessageIndex = -1} -Process {
                $MessageIndex += 1
                if(-not ($_.MessageId)) {
                    throw "TestData[$QueueIndex][$MessageIndex].MessageId was empty"
                }
                if(-not ($_.Index)) {
                    throw "TestData[$QueueIndex][$MessageIndex].Index was empty"
                }
                if(-not ($_.Label)) {
                    throw "TestData[$QueueIndex][$MessageIndex].Label was empty"
                }
                if(-not ($_.Date)) {
                    throw "TestData[$QueueIndex][$MessageIndex].Date was empty"
                }
                if(-not ($_.MetaData)) {
                    throw "TestData[$QueueIndex][$MessageIndex].MetaData was empty"
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