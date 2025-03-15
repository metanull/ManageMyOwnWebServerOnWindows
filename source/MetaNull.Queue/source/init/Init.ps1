# Module Constants

Set-Variable METANULL_QUEUE_CONSTANTS -Option ReadOnly -Scope script -Value @{
    Registry = @{
        Path = 'SOFTWARE\MetaNull\PowerShell\MetaNull.Queue'
    }
    Lock = New-Object Object
}
