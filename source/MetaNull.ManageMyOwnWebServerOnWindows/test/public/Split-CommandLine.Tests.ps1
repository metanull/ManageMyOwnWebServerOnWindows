Describe "ApacheConfReplaceConstant" -Tag "UnitTest" {
    
    BeforeAll {

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\public")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName

        Function Split-CommandLine {
            param(
                [parameter(ValueFromPipeline = $true)]
                $CommandLine
            )
            $CommandLine | . $Script | write-Output
        }
    }
    Context "When regular case" {
        It "Should return the expected command" {
            $CommandLine = 'C:/Apache24/bin/httpd.exe -f conf/httpd.conf -k start'
            $ExpectedCommand = 'C:/Apache24/bin/httpd.exe'
            $ExpectedParams = @('-f', 'conf/httpd.conf', '-k', 'start')

            $Result = $CommandLine | Split-CommandLine
            $Result.Command | Should -BeExactly $ExpectedCommand
        }
        It "Should return the expected parameters" {
            $CommandLine = 'C:/Apache24/bin/httpd.exe -f conf/httpd.conf -k start'
            $ExpectedCommand = 'C:/Apache24/bin/httpd.exe'
            $ExpectedParams = @('-f', 'conf/httpd.conf', '-k', 'start')

            $Result = $CommandLine | Split-CommandLine
            $Result.Arguments | Should -BeExactly $ExpectedParams
        }
    }
    Context "When quoted" {
        It "Should return the expected command" {
            $CommandLine = '"C:/Apache24/bin/httpd.exe" -f conf/httpd.conf -k "start"'
            $ExpectedCommand = 'C:/Apache24/bin/httpd.exe'
            $ExpectedParams = @('-f', 'conf/httpd.conf', '-k', 'start')

            $Result = $CommandLine | Split-CommandLine
            $Result.Command | Should -BeExactly $ExpectedCommand
        }
        It "Should return the expected parameters" {
            $CommandLine = '"C:/Apache24/bin/httpd.exe" -f conf/httpd.conf -k "start"'
            $ExpectedCommand = 'C:/Apache24/bin/httpd.exe'
            $ExpectedParams = @('-f', 'conf/httpd.conf', '-k', 'start')

            $Result = $CommandLine | Split-CommandLine
            $Result.Arguments | Should -BeExactly $ExpectedParams
        }
    }
}