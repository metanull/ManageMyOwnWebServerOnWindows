Describe "Testing private module function Invoke-VisualStudioOnlineString" -Tag "UnitTest" {
    Context "When calling the function" {
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

            Function ConvertFrom-VisualStudioOnlineString {
                return ($args -join ' ')
            }
        }

        It "Should not throw when state is not initialized and input is empty" {
            $State = $null
            {'' | Invoke-ModuleFunctionStub -VsoInputString '' -VsoState ([ref]$State)} | Should -Not -Throw
        }
        It "Should initialize the state variable and input is empty" {
            $State = $null
            '' | Invoke-ModuleFunctionStub -VsoInputString '' -VsoState ([ref]$State)
            $State | Should -Not -BeNullOrEmpty
            $State.Result.Result | Should -Be 'Failed'
            $State.Result.Message | Should -Be 'Not started'
            # $State.Variable | Should -BeOfType 'System.Object[]'
            $State.Variable.GetType().FullName | Should -Be 'System.Object[]'
            #$State.Secret | Should -BeOfType 'System.Object[]'
            $State.Secret.GetType().FullName | Should -Be 'System.Object[]'
            #$State.Path | Should -BeOfType 'System.Object[]'
            $State.Path.GetType().FullName | Should -Be 'System.Object[]'
            #$State.Upload | Should -BeOfType 'System.Object[]'
            $State.Upload.GetType().FullName | Should -Be 'System.Object[]'
            #$State.Log | Should -BeOfType 'System.Object[]'
            $State.Log.GetType().FullName | Should -Be 'System.Object[]'
        }

        It "Should return unmodified input when no processing occures" {
            $State = $null
            $Result = Invoke-ModuleFunctionStub -VsoInputString 'Unmodified input' -VsoState ([ref]$State)
            $Result | Should -Be 'Unmodified input'
        }

        It "Should obfuscate secrets" {
            $State = $null
            Invoke-ModuleFunctionStub -VsoInputString '' -VsoState ([ref]$State)
            $State.Secret += ,'secret'
            $Result = Invoke-ModuleFunctionStub -VsoInputString 'whatever secret whatever' -VsoState ([ref]$State)
            $Result | Should -Be 'whatever *** whatever'
        }
    }

    Context "When calling the function on a VSO formatted string" {
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

            Function ConvertFrom-VisualStudioOnlineString {
                @{
                    Format = 'warning'
                    Message = 'message'
                }
            }

            Mock Write-Host {
                # Do nothing
            }
        }

        It "Should invoke Write-Host" {
            $State = $null
            Invoke-ModuleFunctionStub -VsoInputString 'whatever' -VsoState ([ref]$State)
            Should -Invoke -CommandName 'Write-Host' -Exactly -Times 1 -Scope It
        }
    }

    Context "When calling the function on a VSO command string: task.complete" {
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

            Function ConvertFrom-VisualStudioOnlineString {
                @{
                    Command = 'task.complete'
                    Message = 'Done with test'
                    Properties = @{
                        Result = 'Succeeded'
                    }
                }
            }
        }

        It "Should update the State" {
            $State = $null
            Invoke-ModuleFunctionStub -VsoInputString 'whatever' -VsoState ([ref]$State)
            $State.Result.Result | Should -Be 'Succeeded'
            $State.Result.Message | Should -Be 'Done with test'
        }
    }

    Context "When calling the function on a VSO command string: task.setvariable" {
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

            Function ConvertFrom-VisualStudioOnlineString {
                @{
                    Command = 'task.setvariable'
                    Message = 'Done with test'
                    Properties = @{
                        Name       = 'MyVariable'
                        Value      = 'Hello World'
                        IsSecret   = $false
                        IsOutput   = $false
                        IsReadOnly = $false
                    }
                }
            }
        }

        It "Should update the State" {
            $State = $null
            Invoke-ModuleFunctionStub -VsoInputString 'whatever' -VsoState ([ref]$State)
            $Result = $State.Variable | Select-Object -First 1
            $Result.Name | Should -Be 'MyVariable'
            $Result.Value | Should -Be 'Hello World'
            $Result.IsSecret | Should -Be $false
            $Result.IsOutput | Should -Be $false
            $Result.IsReadOnly | Should -Be $false
        }
    }
}