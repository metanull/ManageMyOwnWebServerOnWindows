Describe "New-MessageQueue" -Tag "Functional","BeforeBuild" {
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

        Function Find-MessageQueue {
            param($Name)
            throw 'Not implemented'
        }
    }
    AfterAll {
        # Cleanup (remove the whole test registry key)
        DestroyTestData
    }

    Context "When Find-MessageQueue returns `$false" {

        BeforeAll {
            Mock Find-MessageQueue {
                param($Name)
                return $false
            }
        }

        It "Test is initialized" {
            ValidateTestSetup | Should -BeTrue
        }
        
        It "Should not throw" {
            {Invoke-ModuleFunctionStub -Name 'TEST:NORMAL'} | Should -Not -Throw
        }
        It "Should create the record and return its ID" {
            $NewGuid = Invoke-ModuleFunctionStub -Name 'TEST:INSERT' -MaximumSize 123 -MessageRetentionPeriod 321
            {Get-Item -Path "MetaNull:\MessageQueue\$NewGuid"} | Should -Not -Throw
            $Properties = Get-Item -Path "MetaNull:\MessageQueue\$NewGuid" | Get-ItemProperty
            $Properties.MessageQueueId | Should -Be $NewGuid.ToString()
            $Properties.Name | Should -Be 'TEST:INSERT'
            $Properties.MaximumSize | Should -Be 123
            $Properties.MessageRetentionPeriod | Should -Be 321
        }
    }

    Context "When Find-MessageQueue returns `$true" {

        BeforeAll {
            Mock Find-MessageQueue {
                param($Name)
                return $true
            }
        }

        It "Test is initialized" {
            ValidateTestSetup | Should -BeTrue
        }
        
        It "Should throw" {
            {Invoke-ModuleFunctionStub -Name 'TEST:NORMAL'} | Should -Throw
        }
    }
}
