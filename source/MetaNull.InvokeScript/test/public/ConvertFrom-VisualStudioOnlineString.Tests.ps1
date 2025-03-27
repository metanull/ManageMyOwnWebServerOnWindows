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

        It "Should return null if the command string is not recognized" {
            $Result = Invoke-ModuleFunctionStub -String "This is not a valid command"
            $Result | Should -Be $null
        }

        It "Should properly parse format strings" {
            $Result = Invoke-ModuleFunctionStub -String "##[section]Task completed successfully"
            $Result | Should -Be @{Format='section';Message='Task completed successfully'}

            $Result = Invoke-ModuleFunctionStub -String "##[group]Begin group of tasks"
            $Result | Should -Be @{Format='group';Message='Begin group of tasks'}

            $Result = Invoke-ModuleFunctionStub -String "##[endgroup]End group of tasks"
            $Result | Should -Be @{Format='endgroup';Message='End group of tasks'}

            $Result = Invoke-ModuleFunctionStub -String "##[command]echo 'Hello World'"
            $Result | Should -Be @{Format='command';Message="echo 'Hello World'"}

            $Result = Invoke-ModuleFunctionStub -String "##[error]Task failed"
            $Result | Should -Be @{Format='error';Message='Task failed'}

            $Result = Invoke-ModuleFunctionStub -String "##[warning]Task warning"
            $Result | Should -Be @{Format='warning';Message='Task warning'}

            $Result = Invoke-ModuleFunctionStub -String "##[debug]Task debug"
            $Result | Should -Be @{Format='debug';Message='Task debug'}
        }

        It "Should properly parse command strings" {
            $Result = Invoke-ModuleFunctionStub -String "##vso[task.complete result=Succeeded;]Task completed successfully"
            $Result | Should -Be @{Command='task.complete';Result='Succeeded';Message='Task completed successfully'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.setvariable variable=VariableName;]VariableValue"
            $Result | Should -Be @{Command='task.setvariable';Variable='VariableName';Value='VariableValue'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.setvariable variable=VariableName;issecret=true;]VariableValue"
            $Result | Should -Be @{Command='task.setvariable';Variable='VariableName';Value='VariableValue';IsSecret=$true}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.setvariable variable=VariableName;isreadonly=true;]VariableValue"
            $Result | Should -Be @{Command='task.setvariable';Variable='VariableName';Value='VariableValue';IsReadOnly=$true}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.setvariable variable=VariableName;isoutput=true;]VariableValue"
            $Result | Should -Be @{Command='task.setvariable';Variable='VariableName';Value='VariableValue';IsOutput=$true}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.setvariable variable=VariableName;issecret=true;isreadonly=true;isoutput=true;]VariableValue"
            $Result | Should -Be @{Command='task.setvariable';Variable='VariableName';Value='VariableValue';IsSecret=$true;IsReadOnly=$true;IsOutput=$true}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.addattachment type=attachmentType;name=attachmentName;]attachmentPath"
            $Result | Should -Be @{Command='task.addattachment';Type='attachmentType';Name='attachmentName';Path='attachmentPath'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.setsecret]SecretValue"
            $Result | Should -Be @{Command='task.setsecret';Value='SecretValue'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.prependpath]C:\Path\To\Prepend"
            $Result | Should -Be @{Command='task.prependpath';Path='C:\Path\To\Prepend'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.uploadfile]C:\Path\To\Upload"
            $Result | Should -Be @{Command='task.uploadfile';Path='C:\Path\To\Upload'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.setprogress value=50;]Task is 50% complete"
            $Result | Should -Be @{Command='task.setprogress';Value=50;Message='Task is 50% complete'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.logissue type=warning;]This is a warning"
            $Result | Should -Be @{Command='task.logissue';Type='warning';Message='This is a warning'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.logissue type=error;]This is an error"
            $Result | Should -Be @{Command='task.logissue';Type='error';Message='This is an error'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.logissue type=error;sourcepath=sourcePath;linenumber=1;colnumber=1;code=code;tag=tag;]This is an error"
            $Result | Should -Be @{Command='task.logissue';Type='error';Message='This is an error';SourcePath='sourcePath';LineNumber=1;ColNumber=1;Code='code';Tag='tag'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[task.logissue type=error;sourcepath=sourcePath;linenumber=1;colnumber=1;code=code;tag=tag;]This is an error"
            $Result | Should -Be @{Command='task.logissue';Type='error';Message='This is an error';SourcePath='sourcePath';LineNumber=1;ColNumber=1;Code='code';Tag='tag'}

            $Result = Invoke-ModuleFunctionStub -String "##vso[build.addbuildtag]ThisIsATag"
            $Result | Should -Be @{Command='build.addbuildtag';Tag='ThisIsATag'}
        }
    }
}