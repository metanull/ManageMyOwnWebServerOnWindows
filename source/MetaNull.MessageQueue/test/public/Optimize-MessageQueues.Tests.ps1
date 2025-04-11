Describe "Optimize-MessageQueues" -Tag "Functional","BeforeBuild" {

    BeforeAll {
        # Load TestData
        . (Join-Path (Split-Path $PSCommandPath) "TestData.ps1")
        
        # Initialize tests (get references to Module Function's Code)
        $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
        $ScriptName = $PSCommandPath | Split-Path -Leaf
        $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
        $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
        $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

        # Create a Stub for the module function to test
        $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
        Function Invoke-ModuleFunctionStub {
            . $FunctionPath @args | Write-Output
        }
    }
    AfterAll {
        # Cleanup (remove the whole test registry key)
        DestroyTestData
    }

    Context "When the Mesage Queue Is Populated" {
        
        BeforeEach {
            # Adding test data to the registry
            InsertTestData -TestData $TestData
        }
        AfterEach {
            # Cleanup (remove all queues)
            RemoveTestData
        }

        It "TestData is initialized" {
            ValidateTestData -TestData $TestData | Should -BeTrue
        }
        
        It "Should not throw an exception" {
            {Invoke-ModuleFunctionStub} | Should -Not -Throw
        }
        It "Should not output anything" {
            $Result = Invoke-ModuleFunctionStub
            $Result | Should -BeNullOrEmpty
        }
        It "Should leave the Message Queues" {
            Invoke-ModuleFunctionStub
            $TestData | Foreach-Object {
                $Data = $_
                {Get-Item -Path "MetaNull:\MessageQueue\$($Data.MessageQueueId)" -ErrorAction Stop} | Should -Not -Throw
            }
        }

        It "Should trim the Message Queues" {
            $Before = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub
            $After = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $After.Count | Should -BeGreaterThan 0
            $Before.Count | Should -BeGreaterThan $After.Count
            $After.Count | Should -BeLessThan $TestData.Messages.Count
        }

        It "Should trim the Message Store" {
            $Before = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub
            $After = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $After.Count | Should -BeGreaterThan 0
            $Before.Count | Should -BeGreaterThan $After.Count
            $After.Count | Should -BeLessThan $TestData.Messages.Count
        }
    }

    Context "When the Mesage Queue Is Populated with two items, MaximumSize is set to 2 and no message older than the retention period" {
        
        BeforeEach {
            $MessageQueueId = (New-Guid)
            $Messages = @(
                @{MessageQueueId = $MessageQueueId; MessageId = (New-Guid) ; Index = 0 ; Date = (Get-Date) ; Label = 'LABEL:0' ; MetaData = @{Meta = 'Data:0'}}
                @{MessageQueueId = $MessageQueueId; MessageId = (New-Guid) ; Index = 1 ; Date = (Get-Date) ; Label = 'LABEL:1' ; MetaData = @{Meta = 'Data:1'}}
            )

            $Messages | Select-Object -First 1 | Foreach-Object {
                $Message = $_
             
                $QueueItem = New-Item -Path "MetaNull:\MessageQueue\$($Message.MessageQueueId)"
                $QueueItem | Set-ItemProperty -Name 'MessageQueueId' -Value $Message.MessageQueueId
                $QueueItem | Set-ItemProperty -Name 'Name' -Value 'TestQueue'
                $QueueItem | Set-ItemProperty -Name 'MaximumSize' -Value 2
                $QueueItem | Set-ItemProperty -Name 'MessageRetentionPeriod' -Value 1
            }
            $Messages | Foreach-Object {
                $Message = $_
                $StoreItem = New-Item -Path "MetaNull:\MessageStore\$($Message.MessageId)"
                $StoreItem | Set-ItemProperty -Name 'MessageId' -Value $Message.MessageId
                $StoreItem | Set-ItemProperty -Name 'Date' -Value ($Message.Date|ConvertTo-JSon)
                $StoreItem | Set-ItemProperty -Name 'Label' -Value $Message.Label
                $StoreItem | Set-ItemProperty -Name 'MetaData' -Value ($Message.MetaData|ConvertTo-JSon)

                $MessageItem = New-Item -Path "MetaNull:\MessageQueue\$($Message.MessageQueueId)\$($Message.Index)"
                $MessageItem | Set-ItemProperty -Name 'MessageId' -Value $Message.MessageId
                $MessageItem | Set-ItemProperty -Name 'Index' -Value $Message.Index
                $MessageItem | Set-ItemProperty -Name 'Date' -Value ($Message.Date|ConvertTo-JSon)
            }
        }

        AfterEach {
            # Cleanup (remove all queues)
            RemoveTestData
        }

        It "TestData is initialized" {
            ValidateTestSetup | Should -BeTrue
        }
        
        It "Should not throw an exception" {
            {Invoke-ModuleFunctionStub} | Should -Not -Throw
        }
        It "Should not output anything" {
            $Result = Invoke-ModuleFunctionStub
            $Result | Should -BeNullOrEmpty
        }
        It "Should leave the Message Queues" {
            Invoke-ModuleFunctionStub
            $Messages | Foreach-Object {
                $Data = $_
                {Get-Item -Path "MetaNull:\MessageQueue\$($Data.MessageQueueId)" -ErrorAction Stop} | Should -Not -Throw
            }
        }

        It "Should leave the Message Queues untouched" {
            $Before = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub
            $After = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $Before.Count | Should -Be 2
            $After.Count | Should -Be 2
        }

        It "Should leave the Message Store untouched" {
            $Before = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub
            $After = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $Before.Count | Should -Be 2
            $After.Count | Should -Be 2
        }
    }

    Context "When the Mesage Queue Is Populated with two items, and the MaximumSize is set to 1" {
        
        BeforeEach {
            $MessageQueueId = (New-Guid)
            $Messages = @(
                @{MessageQueueId = $MessageQueueId; MessageId = (New-Guid) ; Index = 0 ; Date = (Get-Date) ; Label = 'LABEL:0' ; MetaData = @{Meta = 'Data:0'}}
                @{MessageQueueId = $MessageQueueId; MessageId = (New-Guid) ; Index = 1 ; Date = (Get-Date) ; Label = 'LABEL:1' ; MetaData = @{Meta = 'Data:1'}}
            )

            $Messages | Select-Object -First 1 | Foreach-Object {
                $Message = $_
             
                $QueueItem = New-Item -Path "MetaNull:\MessageQueue\$($Message.MessageQueueId)"
                $QueueItem | Set-ItemProperty -Name 'MessageQueueId' -Value $Message.MessageQueueId
                $QueueItem | Set-ItemProperty -Name 'Name' -Value 'TestQueue'
                $QueueItem | Set-ItemProperty -Name 'MaximumSize' -Value 1
                $QueueItem | Set-ItemProperty -Name 'MessageRetentionPeriod' -Value 1
            }
            $Messages | Foreach-Object {
                $Message = $_
                $StoreItem = New-Item -Path "MetaNull:\MessageStore\$($Message.MessageId)"
                $StoreItem | Set-ItemProperty -Name 'MessageId' -Value $Message.MessageId
                $StoreItem | Set-ItemProperty -Name 'Date' -Value ($Message.Date|ConvertTo-JSon)
                $StoreItem | Set-ItemProperty -Name 'Label' -Value $Message.Label
                $StoreItem | Set-ItemProperty -Name 'MetaData' -Value ($Message.MetaData|ConvertTo-JSon)

                $MessageItem = New-Item -Path "MetaNull:\MessageQueue\$($Message.MessageQueueId)\$($Message.Index)"
                $MessageItem | Set-ItemProperty -Name 'MessageId' -Value $Message.MessageId
                $MessageItem | Set-ItemProperty -Name 'Index' -Value $Message.Index
                $MessageItem | Set-ItemProperty -Name 'Date' -Value ($Message.Date|ConvertTo-JSon)
            }
        }
        AfterEach {
            # Cleanup (remove all queues)
            RemoveTestData
        }

        It "TestData is initialized" {
            ValidateTestSetup | Should -BeTrue
        }
        
        It "Should not throw an exception" {
            {Invoke-ModuleFunctionStub} | Should -Not -Throw
        }
        It "Should not output anything" {
            $Result = Invoke-ModuleFunctionStub
            $Result | Should -BeNullOrEmpty
        }
        It "Should leave the Message Queues" {
            Invoke-ModuleFunctionStub
            $Messages | Foreach-Object {
                $Data = $_
                {Get-Item -Path "MetaNull:\MessageQueue\$($Data.MessageQueueId)" -ErrorAction Stop} | Should -Not -Throw
            }
        }

        It "Should trim the Message Queues" {
            $Before = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub
            $After = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $Before.Count | Should -Be 2
            $After.Count | Should -Be 1
        }

        It "Should trim the Message Store" {
            $Before = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub
            $After = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $Before.Count | Should -Be 2
            $After.Count | Should -Be 1
        }
    }

    Context "When the Mesage Queue Is Populated with two items, with one message older than the retention period" {
        
        BeforeEach {
            $MessageQueueId = (New-Guid)
            $Messages = @(
                @{MessageQueueId = $MessageQueueId; MessageId = (New-Guid) ; Index = 0 ; Date = (Get-Date).AddDays(-10) ; Label = 'LABEL:0' ; MetaData = @{Meta = 'Data:0'}}
                @{MessageQueueId = $MessageQueueId; MessageId = (New-Guid) ; Index = 1 ; Date = (Get-Date) ; Label = 'LABEL:1' ; MetaData = @{Meta = 'Data:1'}}
            )

            $Messages | Select-Object -First 1 | Foreach-Object {
                $Message = $_
             
                $QueueItem = New-Item -Path "MetaNull:\MessageQueue\$($Message.MessageQueueId)"
                $QueueItem | Set-ItemProperty -Name 'MessageQueueId' -Value $Message.MessageQueueId
                $QueueItem | Set-ItemProperty -Name 'Name' -Value 'TestQueue'
                $QueueItem | Set-ItemProperty -Name 'MaximumSize' -Value 2
                $QueueItem | Set-ItemProperty -Name 'MessageRetentionPeriod' -Value 1
            }
            $Messages | Foreach-Object {
                $Message = $_
                $StoreItem = New-Item -Path "MetaNull:\MessageStore\$($Message.MessageId)"
                $StoreItem | Set-ItemProperty -Name 'MessageId' -Value $Message.MessageId
                $StoreItem | Set-ItemProperty -Name 'Date' -Value ($Message.Date|ConvertTo-JSon)
                $StoreItem | Set-ItemProperty -Name 'Label' -Value $Message.Label
                $StoreItem | Set-ItemProperty -Name 'MetaData' -Value ($Message.MetaData|ConvertTo-JSon)

                $MessageItem = New-Item -Path "MetaNull:\MessageQueue\$($Message.MessageQueueId)\$($Message.Index)"
                $MessageItem | Set-ItemProperty -Name 'MessageId' -Value $Message.MessageId
                $MessageItem | Set-ItemProperty -Name 'Index' -Value $Message.Index
                $MessageItem | Set-ItemProperty -Name 'Date' -Value ($Message.Date|ConvertTo-JSon)
            }
        }
        AfterEach {
            # Cleanup (remove all queues)
            RemoveTestData
        }

        It "TestData is initialized" {
            ValidateTestSetup | Should -BeTrue
        }
        
        It "Should not throw an exception" {
            {Invoke-ModuleFunctionStub} | Should -Not -Throw
        }
        It "Should not output anything" {
            $Result = Invoke-ModuleFunctionStub
            $Result | Should -BeNullOrEmpty
        }
        It "Should leave the Message Queues" {
            Invoke-ModuleFunctionStub
            $Messages | Foreach-Object {
                $Data = $_
                {Get-Item -Path "MetaNull:\MessageQueue\$($Data.MessageQueueId)" -ErrorAction Stop} | Should -Not -Throw
            }
        }

        It "Should trim the Message Queues" {
            $Before = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub
            $After = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $Before.Count | Should -Be 2
            $After.Count | Should -Be 1
        }

        It "Should trim the Message Store" {
            $Before = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub
            $After = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $Before.Count | Should -Be 2
            $After.Count | Should -Be 1
        }
    }
}
