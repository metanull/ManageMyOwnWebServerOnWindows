Describe "Get-Queue" -Tag "Functional","BeforeBuild" {

    Context "When the function is called" {
        
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
                . $FunctionPath @args | write-Output
            }
        }
        AfterAll {
            # Cleanup (remove the whole test registry key)
            Remove-Item -Force -Recurse -Path MetaNull:\ -ErrorAction SilentlyContinue  | Out-Null
            Remove-PSDrive -Name MetaNull -Scope Script -ErrorAction SilentlyContinue
        }
        BeforeEach {
            # Adding test data to the registry
            $TestData | Foreach-Object {
                $Id = $_.Queue.Id
                $Properties = $_.Queue
                New-Item "MetaNull:\Queues\$Id\Commands" -Force | Out-Null
                $Item = Get-Item "MetaNull:\Queues\$Id"
                $Properties.GetEnumerator() | ForEach-Object {
                    $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                }
                $_.Commands | Foreach-Object {
                    $Item = New-Item -Path "MetaNull:\Queues\$Id\Commands\$($_.Index)" -Force
                    $_.GetEnumerator() | ForEach-Object {
                        $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                    }
                }
            }
        }
        AfterEach {
            # Cleanup (remove all queues)
            Remove-Item -Force -Recurse -Path MetaNull:\Queues\* -ErrorAction SilentlyContinue  | Out-Null
        }

        It "TestData is initialized" {
            ValidateTestData -TestData $TestData | Should -BeTrue
        }
        
        It "Should not throw an exception - by Id" {
            $TestData | Foreach-Object {
                {Invoke-ModuleFunctionStub -Id $_.Queue.Id} | Should -Not -Throw
            }
        }
        It "Should return two Queues when no Id is provided" {
            $Result = Invoke-ModuleFunctionStub
            $Result.Count | Should -Be $TestData.Queue.Count
        }
        It "Should return the expected when the Id is provided" {
            $TestData | Foreach-Object {
                $CurrentTest = $_
                $Result = Invoke-ModuleFunctionStub -Id $CurrentTest.Queue.Id
                $Result | Should -BeOfType [PSCustomObject]
                $Result.Id | Should -Be $CurrentTest.Queue.Id
                $Result.Name | Should -Be $CurrentTest.Queue.Name
                $Result.Description | Should -Be $CurrentTest.Queue.Description
                $Result.Status | Should -Be $CurrentTest.Queue.Status
            }
        }
        It "Should throw when the Id is not found" {
            {Invoke-ModuleFunctionStub -Id (New-Guid)} | Should -Throw
        }
    }
}
