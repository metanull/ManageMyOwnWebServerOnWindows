

Describe "Testing private module function Invoke-Script" -Tag "UnitTest" {

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

        Function Invoke-VisualStudioOnlineString {
            param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [AllowEmptyString()]
                [string]$InputString,

                [Parameter(Mandatory = $false)]
                [ref]$ScriptOutput
            )
            throw "Not callable, Mock is used instead."
        }
        Function Get-FakeScriptOutput {
            [pscustomobject]@{
                Result = [pscustomobject]@{
                    Message = 'Done'
                    Result = 'Succeeded'
                }
                Variable = @()
                Secret = @()
                Path = @()
                Upload = @()
                Log = @()
                Error = @()
                Retried = 0
            }
        }

        Mock Invoke-VisualStudioOnlineString {
            param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [AllowEmptyString()]
                [string]$InputString,

                [Parameter(Mandatory = $false)]
                [ref]$ScriptOutput
            )
            Process {
                $ScriptOutput.Value = Get-FakeScriptOutput
                if(-not ([string]::IsNullOrEmpty($InputString))) {
                    $InputString | Write-Output
                }
            }
        }
    }

    Context "When command is a single 'print string' instruction" {
        
        It "Should return a Success and output the string" {
            $Result = $null
            #$Success = Invoke-ModuleFunctionStub -Commands '"hello"|Write-Warning' -ScriptOutput ([ref]$Result) 
            $CommandOutput = Invoke-ModuleFunctionStub -Commands '"##[section]hello world" | Write-Output' -ScriptOutput ([ref]$Result) 
            $CommandOutput.Count | Should -Be 1
            $CommandOutput | Should -Be '##[section]hello world'
            $Result.Result.Message | Should -Be 'Completed'
            $Result.Result.Result | Should -Be 'Succeeded'
            $Result.Variable.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Secret.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Path.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Upload.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Log.GetType().FullName | Should -Be 'System.Object[]'
        }
    }

    Context "When command throws an exception" {

        It "Should not throw" {
            $Result = $null
            {Invoke-ModuleFunctionStub -Commands 'throw "hello world"' -ScriptOutput ([ref]$Result) } | Should -Not -Throw
        }

        It "Should return a failure" {
            $Result = $null
            $CommandOutput = Invoke-ModuleFunctionStub -Commands 'throw "hello world"' -ScriptOutput ([ref]$Result) 
            $Result.Result.Result | Should -Be 'Failed'
            $Result.Result.Message | Should -Be 'Failed'
            $Result.Error.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Error.Count | Should -Be 1
            $Result.Error[0].ToString() | Should -Be 'hello world'
            $Result.Variable.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Secret.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Path.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Upload.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Log.GetType().FullName | Should -Be 'System.Object[]'
        }
    }

    Context "When command throws an exception, but ContinueOnError is true" {

        It "Should not throw" {
            $Result = $null
            {Invoke-ModuleFunctionStub -Commands 'throw "hello world"' -ContinueOnError -ScriptOutput ([ref]$Result) } | Should -Not -Throw
        }

        It "Should return a success-with issues" {
            $Result = $null
            $CommandOutput = Invoke-ModuleFunctionStub -Commands 'throw "hello world"' -ContinueOnError -ScriptOutput ([ref]$Result) 
            $Result.Result.Result | Should -Be 'SucceededWithIssues'
            $Result.Result.Message | Should -Be 'Failed'
            $Result.Error.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Error.Count | Should -Be 1
            $Result.Error[0].ToString() | Should -Be 'hello world'
            $Result.Variable.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Secret.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Path.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Upload.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Log.GetType().FullName | Should -Be 'System.Object[]'
        }
    }

    Context "When command runs for a while and timeout is too small" {

        It "Should not throw" {
            $Result = $null
            {Invoke-ModuleFunctionStub -Commands '"Sleep for 30 seconds"','Start-Sleep -Seconds 30' -TimeoutInSeconds 3 -ScriptOutput ([ref]$Result) } | Should -Not -Throw
        }

        It "Should interrupt the command soon after timeout elapses" {
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $Result = $null
            $CommandOutput = Invoke-ModuleFunctionStub -Commands '"Sleep for 30 seconds"','Start-Sleep -Seconds 30' -TimeoutInSeconds 3 -ScriptOutput ([ref]$Result) 
            $elapsed = $timer.Elapsed
            $elapsed.TotalSeconds | Should -BeGreaterOrEqual 3
            $elapsed.TotalSeconds | Should -BeLessThan 5
            $Result.Result.Result | Should -Be 'Failed'
            $Result.Result.Message | Should -Be 'Stopped'
            $CommandOutput | Should -Be 'Sleep for 30 seconds'
            $Result.Error.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Error.Count | Should -Be 0
            $Result.Variable.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Secret.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Path.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Upload.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Log.GetType().FullName | Should -Be 'System.Object[]'
        }
    }

    Context "When command throws an exception, but MaxRetryOnFailure is > 0" {

        It "Should not throw" {
            $Result = $null
            {Invoke-ModuleFunctionStub -Commands '"something"; throw "hello world"' -MaxRetryOnFailure 3 -ScriptOutput ([ref]$Result) } | Should -Not -Throw
        }

        It "Should return a Failure, with the proper Retried count" {
            $Result = $null
            $CommandOutput = Invoke-ModuleFunctionStub -Commands '"something"; throw "hello world"' -MaxRetryOnFailure 3 -ScriptOutput ([ref]$Result) 
            $Result.Retried | Should -Be 3
            $Result.Result.Result | Should -Be 'Failed'
            $Result.Result.Message | Should -Be 'Failed'
            $Result.Error.Count | Should -BeGreaterOrEqual 3
            $Result.Error[0].ToString() | Should -Be 'hello world'
            $Result.Error[1].ToString() | Should -Be 'hello world'
            $Result.Error[2].ToString() | Should -Be 'hello world'
            $Result.Variable.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Secret.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Path.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Upload.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Log.GetType().FullName | Should -Be 'System.Object[]'
        }
    }
}