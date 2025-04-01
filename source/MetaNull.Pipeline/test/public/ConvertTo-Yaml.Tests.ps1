Describe "ConvertTo-Yaml" -Tag "UnitTest","BeforeBuild" {

    BeforeAll {
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

    Context "When the pipeline Id is invalid function is called" {
        BeforeAll {
            $PipelineData = @{
                Id = (New-Guid)
                Name = 'PIPELINE:1'
                Stages = @(
                    @{
                        Name = 'STAGE:1.1'
                        Jobs = @(
                            @{
                                Name = 'JOB:1.1.1'
                                Steps = @(
                                    @{
                                        Name = 'STEP:1.1.1.1'
                                        Commands = @(
                                            'Write-Output "Hello"'
                                            'Write-Output "One"'
                                        )
                                    }
                                )
                            }
                        )
                    }
                )
            }
        }

        It "Should not throw when the Pipeline is valid" {
            {Invoke-ModuleFunctionStub -Pipeline $PipelineData} | Should -Not -Throw
        }
        It "Should return the expected output as an array of strings" {
            $Result = Invoke-ModuleFunctionStub -Pipeline $PipelineData
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