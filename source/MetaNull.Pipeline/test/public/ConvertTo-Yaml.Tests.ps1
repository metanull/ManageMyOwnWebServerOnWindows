Describe "ConvertTo-Yaml" -Tag "Functional","BeforeBuild" {

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

        Function Test-Pipeline {
            param([Guid]$Id)
        }

        Function Get-Pipeline {
            param([Guid]$Id)
        }
        
    }

    AfterAll {
        # Cleanup (remove the whole test registry key)
        DestroyTestData
    }

    Context "When the pipeline Id is invalid" {
        BeforeAll {
            Mock Test-Pipeline {
                return $false
            }
            Mock Get-Pipeline {
                return
            }
        }
        It "Should throw when the Pipeline Id is not found" {
            {Invoke-ModuleFunctionStub -Id (New-Guid)} | Should -Throw
        }
    }

    Context "When the pipeline Id is invalid function is called" {
        BeforeAll {
            Mock Test-Pipeline {
                return $true
            }
            Mock Get-Pipeline {
                @{
                    Id = (New-Guid)
                    Name = 'PIPELINE:1'
                    Stages = @(
                        @{
                            Index = 1
                            Name = 'STAGE:1.1'
                            Jobs = @(
                                @{
                                    Index = 1
                                    Name = 'JOB:1.1.1'
                                    Steps = @(
                                        @{
                                            Index = 1
                                            Name = 'STEP:1.1.1.1'
                                            Commands = @(
                                                'Write-Output "Hello"'
                                                'Write-Output "One"'
                                            )
                                            Output = @(
                                                'Hello'
                                                'One'
                                            )
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
            }
        }

        It "Should not throw when the Pipeline Id is valid" {
            {Invoke-ModuleFunctionStub -Id $Pipeline.Id} | Should -Throw
        }
        It "Should return the expected output as an array of strings" {
            $Result = Invoke-ModuleFunctionStub -Id (New-Guid)
            $Result.Count | Should -Be 21
            $Expected = @'
trigger:
- main
pool:
  vmImage: 'windows-latest'
stages:
- stage: STAGE:1.1
  jobs:
  - job: JOB:1.1.1
    steps:
    - task: Powershell@2
      inputs:
        targetType: 'inline'
        pwsh: true
        workingDirectory: '$Build.SourcesDirectory'
        script: |
          Write-Output "Hello"
          Write-Output "One"
        errorActionPreference: stop
        failOnStderr: true
      displayName: STEP:1.1.1.1
      env:
'@
            $Result -join "`n" | Should -Be ($Expected -split "`r?`n" -join "`n")
        }
    }
}