Describe "Get-Message" -Tag "Functional","BeforeBuild" {

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

    Context "When the Mesage Queue Is Populated with two messages" {
        
        BeforeEach {
            $MessageQueueId = (New-Guid)
            $CurrentDate = Get-Date
            $Messages = @(
                [pscustomobject]@{MessageQueueId = $MessageQueueId; Index = 1 ; Label = 'LABEL:0' ; MetaData = @{Meta = 'Data:0'} ; Date = $CurrentDate ; MessageId = (New-Guid)}
                [pscustomobject]@{MessageQueueId = $MessageQueueId; Index = 2 ; Label = 'LABEL:1' ; MetaData = @{Meta = 'Data:1'} ; Date = $CurrentDate ; MessageId = (New-Guid)}
            )

            $Messages | Select-Object -First 1 | Foreach-Object {
                $Message = $_
             
                $QueueItem = New-Item -Path "MetaNull:\MessageQueue\$($Message.MessageQueueId)"
                $QueueItem | Set-ItemProperty -Name 'MessageQueueId' -Value $Message.MessageQueueId
                $QueueItem | Set-ItemProperty -Name 'Name' -Value 'TestQueue'
                $QueueItem | Set-ItemProperty -Name 'MaximumSize' -Value 2
                $QueueItem | Set-ItemProperty -Name 'MessageRetentionPeriod' -Value 1
            }
            $Messages | Select-Object | Foreach-Object {
                $Message = $_

                $MessageItem = New-Item -Path "MetaNull:\MessageQueue\$($Message.MessageQueueId)\$($Message.Index)"
                $MessageItem | Set-ItemProperty -Name 'MessageId' -Value $Message.MessageId
                $MessageItem | Set-ItemProperty -Name 'Index' -Value $Message.Index
                $MessageItem | Set-ItemProperty -Name 'Date' -Value ($Message.Date | ConvertTo-Json)

                $StoreItem = New-Item -Path "MetaNull:\MessageStore\$($Message.MessageId)"
                $StoreItem | Set-ItemProperty -Name 'MessageId' -Value $Message.MessageId
                $StoreItem | Set-ItemProperty -Name 'Date' -Value ($Message.Date | ConvertTo-Json)
                $StoreItem | Set-ItemProperty -Name 'Label' -Value $Message.Label
                $StoreItem | Set-ItemProperty -Name 'MetaData' -Value ($Message.MetaData | ConvertTo-Json)
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
            {Invoke-ModuleFunctionStub -MessageQueueId $Messages[0].MessageQueueId} | Should -Not -Throw
        }
        It "Should output an Object[] of size 2" {
            $Result = Invoke-ModuleFunctionStub -MessageQueueId $Messages[0].MessageQueueId
            $Result | Should -Not -BeNullOrEmpty
            ($Result).GetType().Name | Should -Be 'Object[]'
            $Result.Count | Should -Be 2
        }
        
        It "Should get the proper values" {
            $Result = Invoke-ModuleFunctionStub -MessageQueueId $Messages[0].MessageQueueId
            $Result[0].MessageQueueId | Should -Be $Messages[0].MessageQueueId
            $Result[0].MessageId | Should -Be $Messages[0].MessageId
            $Result[0].Index | Should -Be $Messages[0].Index
            $Result[0].Label | Should -Be $Messages[0].Label
            $Result[0].MetaData | ConvertTo-Json | Should -Be ($Messages[0].MetaData | ConvertTo-Json)
            $Result[0].Date | Should -BeOfType [DateTime]
            $Result[0].Date | Should -Be ($Messages[0].Date)

            $Result[1].MessageQueueId | Should -Be $Messages[1].MessageQueueId
            $Result[1].MessageId | Should -Be $Messages[1].MessageId
            $Result[1].Index | Should -Be $Messages[1].Index
            $Result[1].Label | Should -Be $Messages[1].Label
            $Result[1].MetaData | ConvertTo-Json | Should -Be ($Messages[1].MetaData | ConvertTo-Json)
            $Result[1].Date | Should -BeOfType [DateTime]
            $Result[1].Date | Should -Be ($Messages[1].Date)
        }
    }
}
