Describe "ApacheConfExtractValuePair" -Tag "UnitTest" {
    BeforeAll {

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\private")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName

        Function ApacheConfExtractValuePair {
            param(
                $Statement,
                [parameter(ValueFromPipeline = $true)]
                $Conf
            )
            $Conf | . $Script @args | write-Output
        }
    }

    Context "When no space, quote, tab, or comment" {
        It "Should return a hashtable" {
            $Result = @("Define SRVROOT C:/Apache24") | . $Script -Statement 'Define'
            $Result | Should -BeOfType [hashtable]
        }
        It "Should return @{SRVROOT = 'C:/Apache24'} should return a hashtable with SRVROOT = 'C:/Apache24'" {
            $Result = @("Define SRVROOT C:/Apache24") | . $Script -Statement 'Define'
            $Result.ContainsKey('SRVROOT') | Should -Be $true
            $Result['SRVROOT'] | Should -Be 'C:/Apache24'
        }
    }
    Context "When quote, and no space tab, or comment" {
        It "Should return a hashtable" {
            $Result = @("Define SRVROOT ""C:/Apache 24""") | . $Script -Statement 'Define'
            $Result | Should -BeOfType [hashtable]
        }
        It "Should return @{SRVROOT = 'C:/Apache24'} should return a hashtable with SRVROOT = 'C:/Apache24'" {
            $Result = @("Define SRVROOT ""C:/Apache 24""") | . $Script -Statement 'Define'
            $Result.ContainsKey('SRVROOT') | Should -Be $true
            $Result['SRVROOT'] | Should -Be 'C:/Apache 24'
        }
    }
    Context "When quote, space and comment" {
        It "Should return a hashtable" {
            $Result = @(" Define  SRVROOT  ""C:/Apache 24""  # hello ") | . $Script -Statement 'Define'
            $Result | Should -BeOfType [hashtable]
        }
        It "Should return @{SRVROOT = 'C:/Apache24'} should return a hashtable with SRVROOT = 'C:/Apache24'" {
            $Result = @(" Define  SRVROOT  ""C:/Apache 24""  # hello ") | . $Script -Statement 'Define'
            $Result.ContainsKey('SRVROOT') | Should -Be $true
            $Result['SRVROOT'] | Should -Be 'C:/Apache 24'
        }
    }
    Context "When multiple matches, quote and comment" {
        It "Should return an array of length 2" {
            $Result = @("Define SRVROOT C:/Apache24", 'Define SRVROOT "C:/Apache 24"', '# Define SRVROOT C:/Apache24') | . $Script -Statement 'Define'
            $Result.Count | Should -Be 2
        }
        It "Should return C:/Apache24 twice" {
            $Result = @("Define SRVROOT C:/Apache24", 'Define SRVROOT "C:/Apache 24"', '# Define SRVROOT C:/Apache24') | . $Script -Statement 'Define'

            $Result[0].ContainsKey('SRVROOT') | Should -Be $true
            $Result[0]['SRVROOT'] | Should -Be 'C:/Apache24'

            $Result[1].ContainsKey('SRVROOT') | Should -Be $true
            $Result[1]['SRVROOT'] | Should -Be 'C:/Apache 24'
        }
    }
}
    