# Queue
Queue permits sequential execution of arbitrary commands
The primary goal is to limit resource usage on the server by limiting the number of concurrent tasks executed simultaneously
Multiple queues can be executed in parallel. Commands in a queue are executed in a sequence

Queue
+- Command

```
[System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
try {
    # Do domsething 
} finally {
    [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
}
```