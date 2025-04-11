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


# MetaNull.MessageQueue

# MessageQueue

## Stores a list of message queues and their properties

**Commands**:

- `Find-MessageQueue` Find a MessageQueueId by Name
  - Thread Safe: **No**
  - Parameters
    - [`string`] Name = The name of the message queue
  - Outputs
    - [`guid`] The MessageQueueId
    - [`Object[]`] An array of [guid] of matching MessageQueueId
- `Test-MessageQueue` Tests the exisantance of a MessageQueue
  - Thread Safe: **No**
  - Parameters
    - [`guid`] MessageQueueId = The ID of the message queue
  - Outputs
    - [`bool`] True if the message queue exists, otherwise false
- `New-MessageQueue` Create a Message Queue
  - Thread Safe: **Yes**
  - Parameters
    - [`string`] Name = The name of the message queue
    - [`ìnt`] MaximumSize = The maximum number of messages the message queue should support
    - [`int`] MessageRetentionPeriod = The maximum of days a message should be stored in the message queue
  - Outputs
    - [`guid`] The MessageQueueId of the created queue
- `Remove-MessageQueue` Removes a Message Queue
  - Thread Safe: **Yes**
  - Parameters
    - MessageQueueId
  - Outputs
    - The command only outputs to the _Verbose_ stream
- `Get-MessageQueue` Get a Message Queue by ID, or lists all message queues
  - Thread Safe: **Yes**
  - Parameters
    - _(optional)_ [`guid`] MessageQueueId
  - Outputs
    - `object[]` 
      - [`guid`] MessageQueueId = The ID of the message queue
      - [`string`] Name = Name of the message queue
      - [`int`] MaximumSize = Max messages in queue
      - [`int`] MessageRetentionPeriod = Max days to keep messages
- `Clear-MessageQueue` Removes all messages in a Message Queue
  - Thread Safe: **Yes**
  - Parameters
    - [`guid`] MessageQueueId
  - Outputs
    - The command only outputs to the _Verbose_ stream
- `Optimize-MessageQueues` Perform cleanup of the messages, removing too old or excess messages from all the queues, and removing Messages that are not linked to any message queue
  - Thread Safe: **Yes**
  - Paramters
    - _None_
  - Outputs
    - The command only outputs to the _Verbose_ stream

**Storage**: `MetaNull:\MessageQueue\{GUID}` (Stores the message queues)
    
- Properties:
  - [`string`] Name = Name of the message queue
  - [`int`] MaximumSize = Max messages in queue (default: 100)
  - [`int`] MessageRetentionPeriod = Max days to keep messages (default: 7)
  - - _Implicit_ [`guid`] MessageQueueId = The ID of the message queue can be extracted from the Path

**Storage**: `MetaNull:\MessageQueue\{GUID}\Message\{Index}` (Stores the message indexes)

- Properties:
  - [`guid`] MessageId = The ID of the message
  - _Implicit_ [`guid`] MessageQueueId = The ID of the message queue can be extracted from the Path
  - _Implicit_ [`int`] Index = The order/index of the message in the queue can be extracted from the Path
    
# MessageStore

## Stores the list and details of Messages

**Commands**:

- `Push-Message` Push a Message to the Message Queue
  - Parameters
    - [`guid`] MessageQueueId
    - [`string`] Label
    - [`object`] MetaData
  - Outputs
    - [`guid`] The MessageId of the created message
- `Pop-Message` Retrieves and removes the older Message in the Message Queue
  - Parameters
    - [`guid`] MessageQueueId
  - Outputs
    - `object`
      - [`guid`] MessageQueueId = The ID of the message queue
      - [`guid`] MessageId = The ID of the message
      - [`int`] Index = The Index of the message in the queue
      - [`string`] Label = The label of the message
      - [`datetime`] Date = The date and time when the message was stored
      - [`object`] MetaData
- `Get-Message` Retrieves all the messages in the Message Queue
  - Parameters
    - [`guid`] MessageQueueId = The ID of the message queue
    - _(optional)_ [`switch`] Remove = If set, the messages are also removed from the Message Queue
  - Outputs
    - `object[]`
      - [`guid`] MessageQueueId = The ID of the message queue
      - [`guid`] MessageId = The ID of the message
      - [`int`] Index = The Index of the message in the queue
      - [`string`] Label = The label of the message
      - [`datetime`] Date = The date and time when the message was stored
      - [`object`] MetaData

**Storage**: `MetaNull:\MessageStore\{GUID}` (stores the messages details)

- Properties:
  - [`datetime`] Time = The datetime when message was stored
  - [`string`] Label = The label of the message
  - [`object`] MetaData = MetaData of the message as a json string
  - _Implicit_ [`guid`] MessageId = The ID of the message queue can be extracted from the Path
