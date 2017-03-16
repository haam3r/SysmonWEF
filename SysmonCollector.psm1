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

        xWEFSubscription SysmonTest {
            SubscriptionID = "SysmonTest"
            Ensure = "Present"
            Description = "Collects Sysmon events from domain computers"
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

SysmonCollector -ComputerName DC -OutputPath c:\DSC\
Start-DscConfiguration -Wait -Force -Path c:\DSC\ -Verbose -ComputerName DC