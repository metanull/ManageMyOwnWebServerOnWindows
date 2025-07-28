<#
    .SYNOPSIS
    Tests if a TCP port is open and accepting connections

    .DESCRIPTION
    Uses a TCP client to test if a port is available on localhost (127.0.0.1).
    This approach avoids IPv6 warnings that can occur with Test-NetConnection.

    .PARAMETER Port
    The port number to test

    .OUTPUTS
    Boolean - True if port is in use, False if available

    .EXAMPLE
    Test-DevPort 8000
    Returns $true if port 8000 is in use, $false if available
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $true)]
    [int]$Port
)

End {
    try {
        # Use a TCP client approach which is more reliable and doesn't show IPv6 warnings
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ReceiveTimeout = 1000
        $tcpClient.SendTimeout = 1000
        $result = $tcpClient.BeginConnect("127.0.0.1", $Port, $null, $null)
        $success = $result.AsyncWaitHandle.WaitOne(1000, $false)

        if ($success) {
            try {
                $tcpClient.EndConnect($result)
                $tcpClient.Close()
                return $true
            } catch {
                $tcpClient.Close()
                return $false
            }
        } else {
            $tcpClient.Close()
            return $false
        }
    } catch {
        return $false
    }
}
