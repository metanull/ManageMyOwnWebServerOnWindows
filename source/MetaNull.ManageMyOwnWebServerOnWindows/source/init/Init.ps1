# Module Constants

Set-Variable MOWOW -option Constant -Description 'Constants of the ManageMyOwnWebServerOnWindows Module' -Value @{
    Registry = @{
        # Registry Path
        Path = 'HKLM:\SOFTWARE\ManageMyOwnWebServerOnWindows'
        # Registry Key
        Key = 'Settings'
        # Registry Value
        Value = @{
            # HTTPD binary path
            Httpd = ''
            # HTTPD configuration path
            HttpdConf = ''
            # PHP binary path
            Php = ''
            # PHP configuration path
            PhpIni = ''
            # NodeJS binary path
            Node = ''
        }
    }
}