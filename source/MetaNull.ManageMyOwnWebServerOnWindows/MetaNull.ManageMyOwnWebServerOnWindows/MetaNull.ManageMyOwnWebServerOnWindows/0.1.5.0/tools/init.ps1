if (-not ("System.Net.WebUtility" -as [Type])) {
    Add-Type -Assembly System.Net
}

if (-not ("System.Management.Automation.PSCredential" -as [Type])) {
    Add-Type -Assembly System.Management.Automation
}

