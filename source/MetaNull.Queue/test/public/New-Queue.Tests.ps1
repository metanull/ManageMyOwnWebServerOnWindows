Describe "New-Queue" -Tag "UnitTest" {

    Context "When the function is called" {
        
        BeforeAll {
            # Mock Module Initialization, create the test registry key
            $PSDriveRoot = 'HKCU:\SOFTWARE\MetaNull\PowerShell.Tests\MetaNull.Queue'
            New-Item -Force -Path $PSDriveRoot\Queues -ErrorAction SilentlyContinue  | Out-Null
            $MetaNull = @{
                Queue = @{
                    PSDriveRoot = $PSDriveRoot
                    Lock = New-Object Object
                    Drive = New-PSDrive -Name 'MetaNull' -Scope Script -PSProvider Registry -Root $PSDriveRoot
                }
            }
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
            $PSDriveRoot = 'HKCU:\SOFTWARE\MetaNull\PowerShell.Tests\MetaNull.Queue'
            Remove-Item -Force -Recurse -Path $PSDriveRoot -ErrorAction SilentlyContinue  | Out-Null
            Remove-PSDrive -Name 'MetaNull' -Scope Script -ErrorAction SilentlyContinue
        }
        AfterEach {
            # Cleanup (remove all queues)
            $PSDriveRoot = 'HKCU:\SOFTWARE\MetaNull\PowerShell.Tests\MetaNull.Queue\Queues'
            Remove-Item -Force -Recurse -Path $PSDriveRoot -ErrorAction SilentlyContinue  | Out-Null
        }

        It "Test environment should be initialized" {
            $MetaNull.Queue.PSDriveRoot | Should -Not -BeNullOrEmpty
        }
        It "Should not throw an exception" {
            {Invoke-ModuleFunctionStub -Name 'Test-44'} | Should -Not -Throw
        }
        It "Should modify the registry" {
            Invoke-ModuleFunctionStub -Name 'Test-47'
            Get-ChildItem -Path MetaNull:\Queues | Should -Not -BeNullOrEmpty
        }
        It "Should add the queue to the registry with the right defaults" {
            Invoke-ModuleFunctionStub -Name 'Test-51'
            Get-ChildItem -Path MetaNull:\Queues | Where-Object {
                ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name) -eq 'Test-51' `
                -and (-not ($_ | Get-ItemProperty | Select-Object -ExpandProperty Description))  `
                -and ($_ | Get-ItemProperty | Select-Object -ExpandProperty Status) -eq 'Iddle'
            } | Should -Not -BeNullOrEmpty
        }
        It "Should add the queue to the registry with the right Description" {
            Invoke-ModuleFunctionStub -Name 'Test-59' -Description 'Test-59-DESCRIPTION'
            Get-ChildItem -Path MetaNull:\Queues | Where-Object {
                ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name) -eq 'Test-59' `
                -and ($_ | Get-ItemProperty | Select-Object -ExpandProperty Description) -eq 'Test-59-DESCRIPTION'
            } | Should -Not -BeNullOrEmpty
        }
        It "Should add the queue to the registry with the right Description" {
            Invoke-ModuleFunctionStub -Name 'Test-66' -Status 'Disabled'
            Get-ChildItem -Path MetaNull:\Queues | Where-Object {
                ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name) -eq 'Test-66' `
                -and ($_ | Get-ItemProperty | Select-Object -ExpandProperty Status) -eq 'Disabled'
            } | Should -Not -BeNullOrEmpty
        }
    }
}
