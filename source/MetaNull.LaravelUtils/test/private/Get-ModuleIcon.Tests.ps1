Describe "Testing private module function Get-ModuleIcon" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Get-ModuleIcon {
                . $FunctionPath @args | write-Output
            }

            # Mock used module's variables
            $script:ModuleIcons = @{
                Unicode = @{
                    "Rocket" = "`u{1F680}"
                    "CheckMark" = "`u{1F197}"
                }
                PlainText = @{
                    "Rocket" = "[START]"
                    "CheckMark" = "[OK]"
                }
            }
            $script:UseEmojis = $PSVersionTable.PSVersion.Major -ge 7
        }

        It "Get-ModuleIcon -IconName 'Rocket' -Mode 'unicode'" {
            $Result = Get-ModuleIcon -IconName 'Rocket' -Mode 'unicode'
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -Be "`u{1F680}"
        }

        It "Get-ModuleIcon -IconName 'Rocket' -Mode 'plaintext'" {
            $Result = Get-ModuleIcon -IconName 'Rocket' -Mode 'plaintext'
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -Be "[START]"
        }

        It "Get-ModuleIcon -IconName 'CheckMark' -Mode 'unicode'" {
            $Result = Get-ModuleIcon -IconName 'CheckMark' -Mode 'unicode'
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -Be "`u{1F197}"
        }

        It "Get-ModuleIcon -IconName 'CheckMark' -Mode 'plaintext'" {
            $Result = Get-ModuleIcon -IconName 'CheckMark' -Mode 'plaintext'
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -Be "[OK]"
        }

        It "Returns '?' for an unknown icon: Get-ModuleIcon -IconName 'UnknownIcon'" {
            Mock Write-Warning {
                # Hide warning message in test output
            }
            $Result = Get-ModuleIcon -IconName 'UnknownIcon'
            $Result | Should -Be '?'
        }
    }
}