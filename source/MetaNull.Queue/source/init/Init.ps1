# Module Constants

Set-Variable METANULL_QUEUE_CONSTANTS -Option ReadOnly -Scope script -Value @{
    Registry = @{
        Path = 'SOFTWARE\MetaNull\PowerShell\MetaNull.Queue'
    }
    Mutex = @{
        QueueReadWrite = @{
            MutexName = 'MetaNull.Queue.QueueReadWrite'
            Timeout = 60
        }
    }
}
Set-Variable METANULL_QUEUE_ATOMIC_OBJECT -Scope script -Value (New-Object Object)
