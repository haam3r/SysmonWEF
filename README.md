# SysmonWEF
Deploying Sysmon and WEF

# Deploying Sysmon and WEF with SwiftOnSecurity's config

Lab environment consists of a Windows 10 client and Server 2016 Core as DC and log collector.

Scripts and settings use the term "COLLECTOR" to reference the log collector server, change the name to your server name.

## Enable remote log access on Server

WinRM should be enabled by default.

```powershell
# Start a PowerShell remoting session on the server
Enter-PSSession -ComputerName COLLECTOR
# Enable a FW rule group to remotely view logs on the server 
Enable-NetFirewallRule -DisplayGroup "Remote Event Log Management"
```

##  Setup the log collector

We will be utilising a Powershell DSC module to set this up.

Grab the DSC module from: https://github.com/haam3r/xWindowsEventForwarding

Collector configuration:

```powershell
Configuration SysmonCollector {
    Param (
        [string[]]$ComputerName
    )
    Import-DscResource -ModuleName xWindowsEventForwarding

    Node $ComputerName {
        
        xWEFCollector Enabled {
            Ensure = "Present"
            Name = "Enabled"
        }

        xWEFSubscription Sysmon {
            SubscriptionID = "Sysmon"
            Ensure = "Present"
            Description = "Collect Sysmon events"
            SubscriptionType = "SourceInitiated"
            Query = @(
                'Microsoft-Windows-Sysmon/Operational:*'
            )
            DependsOn = "[xWEFCollector]Enabled"
        }
    }
}

if (-not (Test-Path c:\DSC)) {
    New-Item -Path C:\DSC -ItemType Directory
}

SysmonCollector -ComputerName COLLECTOR -OutputPath c:\DSC\
Start-DscConfiguration -Wait -Force -Path c:\DSC\ -Verbose -ComputerName COLLECTOR
```

## GPO Settings

Create a new GPO targeting the machines you wish to collect logs from.

Under "Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Restricted Groups" :
- right-click and "Add Group" with the Group Name being "BUILTIN\Event Log Readers" and members "NT AUTHORITY\NETWORK SERVICE"

Under "Computer Configuration -> Policies -> Administrative Templates -> Windows Components -> Event Forwarding":
- Set a value of "Server=http://COLLECTOR:5985/wsman/SubscriptionManager/WEC,Refresh=60" for "Configure target Subscription Manager"

Under "Computer Configuration -> Policies -> Administrative Templates -> Windows Components -> Event Log Service -> Application":
- Set a value of 'O:BAG:SYD:(A;;0xf0007;;;SY)(A;;0x7;;;BA)(A;;0x1;;;BO)(A;;0x1;;;SO)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)' for "Configure Log Access"

Under "Computer Configuration -> Policies -> Administrative Templates -> Windows Components -> Event Log Service -> Security":
- Set a value of 'O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS) for "Configure Log Access"


## Sysmon deploy

Grab: https://github.com/SwiftOnSecurity/sysmon-config and the Sysmon exe itself from https://live.sysinternals.com/Sysmon64.exe

```powershell

```

