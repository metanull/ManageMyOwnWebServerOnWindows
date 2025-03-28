Describe "New-Step" -Tag "Functional","BeforeBuild" {

    Context "When the function is called" {
        BeforeAll {
            # Load TestData
            . (Join-Path (Split-Path $PSCommandPath) "TestData.ps1")

            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
            $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the module function to test
            Function Invoke-ModuleFunctionStub {
                . $FunctionPath @args | write-Output
            }
        }

        AfterAll {
            # Cleanup (remove the whole test registry key)
            DestroyTestData
        }
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

        It "Should throw when the Pipeline Id is not found" {
            {Invoke-ModuleFunctionStub -Id (New-Guid)} | Should -Throw
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage 127} | Should -Throw
            }
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is valid and Job Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Id -Job 127} | Should -Throw
                }
            }
        }
        It "Should not throw when the Pipeline Id is valid and Stage Index is valid and Job Index is valid and Step Index is not found" {
            $Pipeline = $TestData.Pipelines | Select-Object -First 1
            $Stage = $Pipeline.Stages | Select-Object -First 1
            $Job = $Stage.Jobs | Select-Object -First 1
            $StepParameters = @{
                Id = $Pipeline.Id
                Stage = $Stage.Index
                Job = $Job.Index
                Name = "Test Step"
                Commands = @("'Test-57_Command1' | Write-Output","'Test-57_Command2' | Write-Output","'Test-57_Command3' | Write-Output")
                ContinueOnError = $false
                TimeoutInSeconds = 1
                RetryCountOnStepFailure = 0
            }
            $StepCommandOutputs = @("Test-57_Command1","Test-57_Command2","Test-57_Command3")
            {Invoke-ModuleFunctionStub @StepParameters} | Should -Not -Throw
        }
        It "Should return the Step's Index" {
            $Pipeline = $TestData.Pipelines | Select-Object -First 1
            $Stage = $Pipeline.Stages | Select-Object -First 1
            $Job = $Stage.Jobs | Select-Object -First 1
            $StepParameters = @{
                Id = $Pipeline.Id
                Stage = $Stage.Index
                Job = $Job.Index
                Name = "Test Step"
                Commands = @("'Test-57_Command1' | Write-Output","'Test-57_Command2' | Write-Output","'Test-57_Command3' | Write-Output")
                ContinueOnError = $false
                TimeoutInSeconds = 1
                RetryCountOnStepFailure = 0
            }
            $StepCommandOutputs = @("Test-57_Command1","Test-57_Command2","Test-57_Command3")
            $StepIndex = Invoke-ModuleFunctionStub @StepParameters | Should -Be $Job.Steps.Count
        }
        It "Should store the Step with the correct properties, and only the correct properties" {
            $Pipeline = $TestData.Pipelines | Select-Object -First 1
            $Stage = $Pipeline.Stages | Select-Object -First 1
            $Job = $Stage.Jobs | Select-Object -First 1
            $StepParameters = @{
                Id = $Pipeline.Id
                Stage = $Stage.Index
                Job = $Job.Index
                Name = "Test Step"
                Commands = @("'Test-57_Command1' | Write-Output","'Test-57_Command2' | Write-Output","'Test-57_Command3' | Write-Output")
                ContinueOnError = $false
                TimeoutInSeconds = 1
                RetryCountOnStepFailure = 0
            }
            $StepCommandOutputs = @("Test-57_Command1","Test-57_Command2","Test-57_Command3")

            $StepIndex = Invoke-ModuleFunctionStub @StepParameters
            Test-Path "MetaNull:\Pipelines\$Id\Stages\$($Stage.Index)\Jobs\$($Job.Index)\Steps\$($StepIndex)" | Should -Be $true
            $Item = Get-Item -Path "MetaNull:\Pipelines\$Id\Stages\$($Stage.Index)\Jobs\$($Job.Index)\Steps\$($StepIndex)"
            $Item | Should -Not -BeNullOrEmpty
            $ItemProperties = $Item | Get-ItemProperty
            $ItemProperties | Should -Not -BeNullOrEmpty
            $_.GetEnumerator() | Where-Object {
                $_.Key -notin 'Commands','Name','Index'
            } | Should -BeNullOrEmpty
            $ItemProperties.Commands -join "`n" | Should -Be $StepParameters.Commands -join "`n"
            $ItemProperties.Name | Should -Be $StepParameters.Name
            $ItemProperties.Index | Should -Be $StepIndex
        }
    }
}