Describe "ApacheConfReplaceConstant" -Tag "UnitTest" {
    
    BeforeAll {

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\private")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName

        Function ApacheConfReplaceConstant {
            param(
                $Constants,
                [parameter(ValueFromPipeline = $true)]
                $Value
            )
            $Value | . $Script -Constants $Constants | write-Output
        }
    }
    Context "When no constants" {
        It "Should return the original value" {
            $Value = 'ServerRoot C:/Apache24'
            $Constants = @{}
            $Expected = "ServerRoot C:/Apache24"

            $Result = $Value | ApacheConfReplaceConstant -Constants $Constants
            $Result | Should -BeExactly $Expected
        }
    }
    Context "When one constant" {
        It "Should return the modified value" {
            $Value = 'ServerRoot ${SERVER_ROOT}/home'
            $Constants = @{ 'SERVER_ROOT' = 'C:/Apache24' }
            $Expected = 'ServerRoot C:/Apache24/home'

            $Result = $Value | ApacheConfReplaceConstant -Constants $Constants

            $Result | Should -BeExactly $Expected
        }
    }
    Context "When no matching constants" {
        It "Should return the original value" {
            $Value = 'ServerRoot ${SERVER_ROOT}/home'
            $Constants = @{ 'NOT_MATCHING' = 'C:/Apache24' }
            $Expected = 'ServerRoot ${SERVER_ROOT}/home'

            $Result = $Value | ApacheConfReplaceConstant -Constants $Constants

            $Result | Should -BeExactly $Expected
        }
    }
    Context "When some matching constants" {
        It "Should break after the first missing value" {
            $Value = 'ServerRoot ${SERVER_ROOT}/${HOME}/${DIR}'
            $Constants = @{ 'SERVER_ROOT' = 'C:/Apache24'; 'NOT_MATCHING' = 'home'; 'DIR' = 'dir' }
            $Expected = 'ServerRoot C:/Apache24/${HOME}/${DIR}'

            $Result = $Value | ApacheConfReplaceConstant -Constants $Constants

            $Result | Should -BeExactly $Expected
        }
    }
    Context "When all matching constants" {
        It "Should return the expected value" {
            $Value = 'ServerRoot ${SERVER_ROOT}/${HOME}/${DIR}'
            $Constants = @{ 'SERVER_ROOT' = 'C:/Apache24'; 'NOT_MATCHING' = 'not-matching'; 'HOME' = 'home'; 'DIR' = 'dir' }
            $Expected = 'ServerRoot C:/Apache24/home/dir'

            $Result = $Value | ApacheConfReplaceConstant -Constants $Constants

            $Result | Should -BeExactly $Expected
        }
    }
}