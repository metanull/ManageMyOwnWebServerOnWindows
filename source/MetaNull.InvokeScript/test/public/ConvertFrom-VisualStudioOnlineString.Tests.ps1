[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing public module function ConvertFrom-VisualStudioOnlineString" -Tag "UnitTest" {
    Context "When executing the command" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the module function to test
            Function ConvertFrom-VisualStudioOnlineString {
                . $FunctionPath @args | write-Output
            }
        }

        It "Should return null if the command string is not recognized" {
            $Result = ConvertFrom-VisualStudioOnlineString -String "This is not a valid command"
            $Result | Should -Be $null
        }

        It "Should properly parse format strings" {
            $Result = ConvertFrom-VisualStudioOnlineString -String "##[section]Task completed successfully"
            $Result.Format | Should -Be 'section'
            $Result.Message | Should -Be 'Task completed successfully'

            $Result = ConvertFrom-VisualStudioOnlineString -String "##[group]Begin group of tasks"
            $Result.Format | Should -Be 'group'
            $Result.Message | Should -Be 'Begin group of tasks'

            $Result = ConvertFrom-VisualStudioOnlineString -String "##[endgroup]End group of tasks"
            $Result.Format | Should -Be 'endgroup'
            $Result.Message | Should -Be 'End group of tasks'

            $Result = ConvertFrom-VisualStudioOnlineString -String "##[command]echo 'Hello World'"
            $Result.Format | Should -Be 'command'
            $Result.Message | Should -Be 'echo ''Hello World'''

            $Result = ConvertFrom-VisualStudioOnlineString -String "##[error]Task failed"
            $Result.Format | Should -Be 'error'
            $Result.Message | Should -Be 'Task failed'

            $Result = ConvertFrom-VisualStudioOnlineString -String "##[warning]Task warning"
            $Result.Format | Should -Be 'warning'
            $Result.Message | Should -Be 'Task warning'

            $Result = ConvertFrom-VisualStudioOnlineString -String "##[debug]Task debug"
            $Result.Format | Should -Be 'debug'
            $Result.Message | Should -Be 'Task debug'
        }

        It "Should properly parse command strings" {
            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.complete result=Succeeded;]Task completed successfully"
            $Result.Command | Should -Be 'task.complete'
            $Result.Message | Should -Be 'Task completed successfully'
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Result | Should -Be 'Succeeded'

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.setvariable variable=VariableName;]VariableValue"
            $Result.Command | Should -Be 'task.setvariable'
            $Result.Message | Should -BeNullOrEmpty
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Name | Should -Be 'VariableName'
            $Result.Properties.Value | Should -Be 'VariableValue'
            $Result.Properties.IsSecret | Should -BeFalse
            $Result.Properties.IsReadOnly | Should -BeFalse
            $Result.Properties.IsOutput | Should -BeFalse

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.setvariable variable=VariableName;issecret=true;]VariableValue"
            $Result.Command | Should -Be 'task.setvariable'
            $Result.Message | Should -BeNullOrEmpty
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Name | Should -Be 'VariableName'
            $Result.PropertieS.Value | Should -Be 'VariableValue'
            $Result.Properties.IsSecret | Should -BeTrue
            $Result.Properties.IsReadOnly | Should -BeFalse
            $Result.Properties.IsOutput | Should -BeFalse

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.setvariable variable=VariableName;isreadonly=true;]VariableValue"
            $Result.Command | Should -Be 'task.setvariable'
            $Result.Message | Should -BeNullOrEmpty
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Name | Should -Be 'VariableName'
            $Result.PropertieS.Value | Should -Be 'VariableValue'
            $Result.Properties.IsSecret | Should -BeFalse
            $Result.Properties.IsReadOnly | Should -BeTrue
            $Result.Properties.IsOutput | Should -BeFalse

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.setvariable variable=VariableName;isoutput=true;]VariableValue"
            $Result.Command | Should -Be 'task.setvariable'
            $Result.Message | Should -BeNullOrEmpty
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Name | Should -Be 'VariableName'
            $Result.PropertieS.Value | Should -Be 'VariableValue'
            $Result.Properties.IsSecret | Should -BeFalse
            $Result.Properties.IsReadOnly | Should -BeFalse
            $Result.Properties.IsOutput | Should -BeTrue

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.setvariable variable=VariableName;issecret=true;isreadonly=true;isoutput=true;]VariableValue"
            $Result.Command | Should -Be 'task.setvariable'
            $Result.Message | Should -BeNullOrEmpty
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Name | Should -Be 'VariableName'
            $Result.PropertieS.Value | Should -Be 'VariableValue'
            $Result.Properties.IsSecret | Should -BeTrue
            $Result.Properties.IsReadOnly | Should -BeTrue
            $Result.Properties.IsOutput | Should -BeTrue

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.setsecret]SecretValue"
            $Result.Command | Should -Be 'task.setsecret'
            $Result.Message | Should -BeNullOrEmpty
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Value | Should -Be 'SecretValue'

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.prependpath]C:\Path\To\Prepend"
            $Result.Command | Should -Be 'task.prependpath'
            $Result.Message | Should -BeNullOrEmpty
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Value | Should -Be 'C:\Path\To\Prepend'

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.uploadfile]C:\Path\To\Upload"
            $Result.Command | Should -Be 'task.uploadfile'
            $Result.Message | Should -BeNullOrEmpty
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Value | Should -Be 'C:\Path\To\Upload'

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.setprogress value=50;]Task is 50% complete"
            $Result.Command | Should -Be 'task.setprogress'
            $Result.Message | Should -Be 'Task is 50% complete'
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Value | Should -Be 50

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.logissue type=warning;]This is a warning"
            $Result.Command | Should -Be 'task.logissue'
            $Result.Message | Should -Be 'This is a warning'
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Type | Should -Be 'warning'
            $Result.Properties.SourcePath | Should -BeNullOrEmpty
            $Result.Properties.LineNumber | Should -BeNullOrEmpty
            $Result.Properties.ColNumber | Should -BeNullOrEmpty
            $Result.Properties.Code | Should -BeNullOrEmpty

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.logissue type=error;]This is an error"
            $Result.Command | Should -Be 'task.logissue'
            $Result.Message | Should -Be 'This is an error'
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Type | Should -Be 'error'
            $Result.Properties.SourcePath | Should -BeNullOrEmpty
            $Result.Properties.LineNumber | Should -BeNullOrEmpty
            $Result.Properties.ColNumber | Should -BeNullOrEmpty
            $Result.Properties.Code | Should -BeNullOrEmpty

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[task.logissue type=error;sourcepath=C:\Path\To\Source.ext;linenumber=127;colnumber=321;code=42]This is an error"
            $Result.Command | Should -Be 'task.logissue'
            $Result.Message | Should -Be 'This is an error'
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Type | Should -Be 'error'
            $Result.Properties.SourcePath | Should -Be 'C:\Path\To\Source.ext'
            $Result.Properties.LineNumber | Should -Be 127
            $Result.Properties.ColNumber | Should -Be 321
            $Result.Properties.Code | Should -Be 42

            $Result = ConvertFrom-VisualStudioOnlineString -String "##vso[build.addbuildtag]ThisIsATag"
            $Result.Command | Should -Be 'build.addbuildtag'
            $Result.Message | Should -BeNullOrEmpty
            $Result.Properties | Should -Not -BeNullOrEmpty
            $Result.Properties.Value | Should -Be 'ThisIsATag'
        }
    }
}