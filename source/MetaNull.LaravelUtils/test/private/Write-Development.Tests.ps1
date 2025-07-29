[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing private module function Write-Development" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
            # Create a Stub for the one module function to test
            Function Write-Development {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions

            Function Get-ModuleIcon {
                # N/A - Mocked in tests
            }

            Function Write-Host {
                # N/A - Mocked in tests
            }

            Mock Write-Host {param([string]$Object, [string]$ForegroundColor)}
            Mock Get-ModuleIcon {param([string]$Type)return "[ICON]"}

            # Set up the module variable that the function expects
            $script:ModuleColorInfo = "Cyan"
            $script:ModuleColorError = "Red"
            $script:ModuleColorWarning = "Yellow"
            $script:ModuleColorSuccess = "Green"
        }

        It "Write-Development should execute without errors" {
            { 
                Write-Development -Message "Test message"
                Write-Development -Message "Test message" -Type 'Info'
                Write-Development -Message "Test message" -Type 'Success'
                Write-Development -Message "Test message" -Type 'Warning'
                Write-Development -Message "Test message" -Type 'Error'
                Write-Development -Message "Test message" -Type 'Step'
                Write-Development -Message "Test message" -Type 'Header'
            } | Should -Not -Throw
        }

        It "Write-Development should execute without errors when Message is null or empty" {
            { 
                Write-Development -Message $null -Type 'Info'
                Write-Development -Message '' -Type 'Info'
            } | Should -Not -Throw
        }

        It "Write-Development should call Get-ModuleIcon" {
            Mock Get-ModuleIcon {param([string]$Type)return "[ICON]"}

            Write-Development -Message "Test message" -Type 'Info'
            Assert-MockCalled Get-ModuleIcon -Exactly 1 -Scope It
        }

        It "Write-Development should call Write-Host" {
            Mock Write-Host {param([string]$Object, [string]$ForegroundColor)}

            Write-Development -Message "Test message" -Type 'Info'
            Assert-MockCalled Write-Host -Exactly 1 -Scope It
        }
    }
}

