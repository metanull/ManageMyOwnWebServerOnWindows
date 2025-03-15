# Module Constants

Set-Variable METANULL_QUEUE_CONSTANTS -Option ReadOnly -Scope script -Value @{
    Registry = @{
        Path = 'SOFTWARE\MetaNull\PowerShell\MetaNull.Queue'
        Version = '0.1.0.0'
    }
    Mutex = @{
        QueueReadWrite = @{
            Lock = New-Object Object
            MutexName = 'MetaNull.Queue.QueueReadWrite'
            Timeout = 60
        }
    }
}
Set-Variable METANULL_QUEUE_LOCKS -Scope script -Value @{
    QueueReadWrite = New-Object Object
    QueuesSetup = New-Object Object
}
