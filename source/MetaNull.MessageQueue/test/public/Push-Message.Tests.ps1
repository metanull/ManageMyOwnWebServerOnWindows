Describe "Push-Message" -Tag "Functional","BeforeBuild" {

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

    Context "When the Mesage Queue Is Empty" {
        
        BeforeEach {
            $MessageQueueId = (New-Guid)
            $Messages = @(
                [pscustomobject]@{MessageQueueId = $MessageQueueId; Index = 1 ; Label = 'LABEL:0' ; MetaData = @{Meta = 'Data:0'}}
                [pscustomobject]@{MessageQueueId = $MessageQueueId; Index = 2 ; Label = 'LABEL:1' ; MetaData = @{Meta = 'Data:1'}}
            )

            $Messages | Select-Object -First 1 | Foreach-Object {
                $Message = $_
             
                $QueueItem = New-Item -Path "MetaNull:\MessageQueue\$($Message.MessageQueueId)"
                $QueueItem | Set-ItemProperty -Name 'MessageQueueId' -Value $Message.MessageQueueId
                $QueueItem | Set-ItemProperty -Name 'Name' -Value 'TestQueue'
                $QueueItem | Set-ItemProperty -Name 'MaximumSize' -Value 2
                $QueueItem | Set-ItemProperty -Name 'MessageRetentionPeriod' -Value 1
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
            {Invoke-ModuleFunctionStub -MessageQueueId $Messages[0].MessageQueueId -Label $Messages[0].Label -MetaData $Messages[0].MetaData} | Should -Not -Throw
        }
        It "Should output an integer" {
            $Result = Invoke-ModuleFunctionStub -MessageQueueId $Messages[0].MessageQueueId -Label $Messages[0].Label -MetaData $Messages[0].MetaData
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -BeOfType [int]
        }
        
        It "Should add to the Message Queue" {
            $Before = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub -MessageQueueId $Messages[0].MessageQueueId -Label $Messages[0].Label -MetaData $Messages[0].MetaData
            $After = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $Before.Count | Should -Be 0
            $After.Count | Should -Be 1
        }

        It "Should add to the Message Store" {
            $Before = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            Invoke-ModuleFunctionStub -MessageQueueId $Messages[0].MessageQueueId -Label $Messages[0].Label -MetaData $Messages[0].MetaData
            $After = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $Before.Count | Should -Be 0
            $After.Count | Should -Be 1
        }

        It "Should add to the proper values" {
            $Before1 = Get-Date
            Invoke-ModuleFunctionStub -MessageQueueId $Messages[0].MessageQueueId -Label $Messages[0].Label -MetaData $Messages[0].MetaData
            $Before2 = Get-Date
            Invoke-ModuleFunctionStub -MessageQueueId $Messages[1].MessageQueueId -Label $Messages[1].Label -MetaData $Messages[1].MetaData
            $After = Get-Date
            
            {Get-Item -Path "MetaNull:\MessageQueue\$($Messages[0].MessageQueueId)\$($Messages[0].Index)" -ErrorAction Stop} | Should -Not -Throw
            {Get-Item -Path "MetaNull:\MessageQueue\$($Messages[1].MessageQueueId)\$($Messages[1].Index)" -ErrorAction Stop} | Should -Not -Throw
            
            $MessageItem = Get-Item -Path "MetaNull:\MessageQueue\$($Messages[0].MessageQueueId)\1" | Get-ItemProperty
            $MessageItem | Should -Not -BeNullOrEmpty
            $MessageItem.Date | ConvertFrom-Json | Should -BeGreaterOrEqual $Before1
            $MessageItem.Date | ConvertFrom-Json | Should -BeLessOrEqual $Before2
            $MessageItem.Index | Should -Be 1

            {Get-Item -Path "MetaNull:\MessageStore\$($MessageItem.MessageId)"} | Should -Not -Throw
            $StoreItem = Get-Item -Path "MetaNull:\MessageStore\$($MessageItem.MessageId)" | Get-ItemProperty
            $StoreItem | Should -Not -BeNullOrEmpty
            $StoreItem.Date | ConvertFrom-Json | Should -Be ($MessageItem.Date | ConvertFrom-Json)
            $StoreItem.MessageId | Should -Be $MessageItem.MessageId
            $StoreItem.Label | Should -Be $Messages[0].Label
            $StoreItem.MetaData | Should -Be ($Messages[0].MetaData | ConvertTo-Json)

            $MessageItem = Get-Item -Path "MetaNull:\MessageQueue\$($Messages[1].MessageQueueId)\2" | Get-ItemProperty
            $MessageItem | Should -Not -BeNullOrEmpty
            $MessageItem.Date | ConvertFrom-Json | Should -BeGreaterOrEqual $Before2
            $MessageItem.Date | ConvertFrom-Json | Should -BeLessOrEqual $After
            $MessageItem.Index | Should -Be 2

            {Get-Item -Path "MetaNull:\MessageStore\$($MessageItem.MessageId)"} | Should -Not -Throw
            $StoreItem = Get-Item -Path "MetaNull:\MessageStore\$($MessageItem.MessageId)" | Get-ItemProperty
            $StoreItem | Should -Not -BeNullOrEmpty
            $StoreItem.Date | ConvertFrom-Json | Should -Be ($MessageItem.Date | ConvertFrom-Json)
            $StoreItem.MessageId | Should -Be $MessageItem.MessageId
            $StoreItem.Label | Should -Be $Messages[1].Label
            $StoreItem.MetaData | Should -Be ($Messages[1].MetaData | ConvertTo-Json)
        }
    }
}
