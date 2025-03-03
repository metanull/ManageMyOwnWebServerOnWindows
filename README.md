# ManageMyOwnWebServerOnWindows

**Author:** Pascal Havelange (havelangep@hotmail.com)

## Purpose

The purpose of this module is to allow for managing a web server powered by Apache HTTPD on a Windows machine. It leverages Windows' Task Scheduler, Registry, and Powershell to permit managing Virtual Hosts remotely through the web.

## Features

- **Registry Management**: Creates and maintains the necessary Registry key structure, stores configuration values to ensure persistence.
- **Task Execution**: Uses Task Scheduler to execute commands, ensuring actions are performed regardless of the Apache HTTPD server's state.
- **Virtual Host Management**: Adds new Virtual Hosts to the Registry, creates/updates/deletes Apache Virtual Hosts on the fly.
- **CI/CD Operations**: Performs limited CI/CD actions including pulling code from a git repository, building PHP/Laravel and Node.js code, and deploying built code to the web server.

## Installation

To install the module, run the following command in Powershell:

```powershell
Install-Module -Name ManageMyOwnWebServerOnWindows
```

## Usage

Here is a brief overview of the commands available in the module:

- `Test-ServerSideSetup`: Verifies if server is configured.
- `Register-ServerSideSetup`: Configure the server, creating the Registry Key and directory.
- `Unregister-ServerSideSetup`: Remove the configuration of the server.
- `New-WebApplication`:
- `Remove-WebApplication`:
- `Initialize-WebApplication`:
- `Get-WebApplication`:
- `Set-WebApplication`:
- `Reset-WebApplication`:
- `Enable-WebApplication`:
- `Disable-WebApplication`:
- `Test-WebApplication`: 
- `Publish-WebApplication`: 
- `Unpublish-WebApplication`: 
- `Update-WebApplication`: Pulls, builds and deploys the WEbApplication.
- `New-Task`: Queues a task for execution by the Task Scheduler.
- `Remove-Task`: Deletes a task from the Task Scheduler.
- `Invoke-Tasks`: Immediately triggers a queued task for execution.

## License
This project is licensed under [The Unlicense](https://unlicense.org/). See the [LICENSE](./LICENSE) file for more details.
