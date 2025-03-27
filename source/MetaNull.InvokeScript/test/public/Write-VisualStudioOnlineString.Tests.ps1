Describe "Testing public module function Write-VisualStudioOnlineString" -Tag "UnitTest" {
    Context "When executing the command" {
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

        It "Should throw if the format is not proper" {
            {Invoke-ModuleFunctionStub -Format 'Whatever' -Message 'This is not a valid command'} | Should -Throw
        }

        It "Should return the expected Format string" {
            $Result = Invoke-ModuleFunctionStub -Format 'section' -Message 'Task completed successfully'
            $Result | Should -Be '##[section]Task completed successfully'

            $Result = Invoke-ModuleFunctionStub -Format 'group' -Message 'Begin group of tasks'
            $Result | Should -Be '##[group]Begin group of tasks'

            $Result = Invoke-ModuleFunctionStub -Format 'endgroup' -Message 'End group of tasks'
            $Result | Should -Be '##[endgroup]End group of tasks'

            $Result = Invoke-ModuleFunctionStub -Format 'command' -Message 'echo "Hello World"'
            $Result | Should -Be '##[command]echo "Hello World"'

            $Result = Invoke-ModuleFunctionStub -Format 'error' -Message 'Task failed'
            $Result | Should -Be '##[error]Task failed'

            $Result = Invoke-ModuleFunctionStub -Format 'warning' -Message 'Task warning'
            $Result | Should -Be '##[warning]Task warning'

            $Result = Invoke-ModuleFunctionStub -Format 'debug' -Message 'Task debug'
            $Result | Should -Be '##[debug]Task debug'
        }

        It "Should return the expected Command string" {
            $Result = Invoke-ModuleFunctionStub -CompleteTask -Result 'Succeeded' -Message 'Task completed successfully'
            $Result | Should -Be '##vso[task.complete result=Succeeded]Task completed successfully'

            $Result = Invoke-ModuleFunctionStub -SetTaskVariable -Name 'VariableName' -Value 'VariableValue'
            $Result | Should -Be '##vso[task.setvariable variable=VariableName;issecret=false;isoutput=false;isreadonly=false]VariableValue'

            $Result = Invoke-ModuleFunctionStub -SetTaskVariable -Name 'VariableName' -Value 'VariableValue' -IsSecret
            $Result | Should -Be '##vso[task.setvariable variable=VariableName;issecret=true;isoutput=false;isreadonly=false]VariableValue'

            $Result = Invoke-ModuleFunctionStub -SetTaskVariable -Name 'VariableName' -Value 'VariableValue' -IsReadOnly
            $Result | Should -Be '##vso[task.setvariable variable=VariableName;issecret=false;isoutput=false;isreadonly=true]VariableValue'

            $Result = Invoke-ModuleFunctionStub -SetTaskVariable -Name 'VariableName' -Value 'VariableValue' -IsOutput
            $Result | Should -Be '##vso[task.setvariable variable=VariableName;issecret=false;isoutput=true;isreadonly=false]VariableValue'

            $Result = Invoke-ModuleFunctionStub -SetTaskVariable -Name 'VariableName' -Value 'VariableValue' -IsSecret -IsReadOnly -IsOutput
            $Result | Should -Be '##vso[task.setvariable variable=VariableName;issecret=true;isoutput=true;isreadonly=true]VariableValue'

            $Result = Invoke-ModuleFunctionStub -SetTaskSecret -Value 'SecretValue'
            $Result | Should -Be '##vso[task.setsecret]SecretValue'

            $Result = Invoke-ModuleFunctionStub -PrependTaskPath -Path 'C:\Path\To\Prepend'
            $Result | Should -Be '##vso[task.prependpath]C:\Path\To\Prepend'

            $Result = Invoke-ModuleFunctionStub -UploadTaskFile -Path 'C:\Path\To\Upload'
            $Result | Should -Be '##vso[task.uploadfile]C:\Path\To\Upload'

            $Result = Invoke-ModuleFunctionStub -SetTaskProgress -Progress 50 -Message 'Task is 50% complete'
            $Result | Should -Be '##vso[task.setprogress value=50;]Task is 50% complete'

            $Result = Invoke-ModuleFunctionStub -LogIssue -Type 'warning' -Message 'This is a warning'
            $Result | Should -Be '##vso[task.logissue type=warning;]This is a warning'

            $Result = Invoke-ModuleFunctionStub -LogIssue -Type 'error' -Message 'This is an error'
            $Result | Should -Be '##vso[task.logissue type=error;]This is an error'

            $Result = Invoke-ModuleFunctionStub -LogIssue -Type 'warning' -Message 'This is a warning' -SourcePath 'C:\Path\To\Source' -LineNumber 10 -ColNumber 5 -Code '1234'
            $Result | Should -Be '##vso[task.logissue type=warning;sourcepath=C:\Path\To\Source;linenumber=10;colnumber=5;code=1234]This is a warning'

            $Result = Invoke-ModuleFunctionStub -AddBuildTag -Tag 'ThisIsATag'
            $Result | Should -Be '##vso[build.addbuildtag]ThisIsATag'
        }

    }
}