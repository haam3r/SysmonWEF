function Install-Sysmon {
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='One or more computer names')]
        [Alias("ComputerName")]
        [string]$Name,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage='Credentials to use')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    PROCESS {
        Write-Verbose -Message "Received list: $Name"
        foreach ($Computer in $Name) {
            Write-Verbose -Message "Running on $Computer"

            Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock {
        
                Write-Verbose -Message "Create sysmon directory if needed"
                if (-not (Test-Path $env:SystemDrive\ProgramData\sysmon)) {
                    New-Item -Path $env:SystemDrive\ProgramData\sysmon -ItemType Directory
                }
                cd $env:SystemDrive\ProgramData\sysmon

                Write-Verbose -Message "Download the sysmon config file"
                (New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml',"$env:SystemDrive\ProgramData\sysmon\sysmonconfig-export.xml")

                Write-Verbose -Message "Download and install sysmon"
                if ( ((Get-WmiObject Win32_OperatingSystem).OSArchitecture) -eq "64-bit") {
                    (New-Object System.Net.WebClient).DownloadFile('https://live.sysinternals.com/Sysmon64.exe','C:\ProgramData\sysmon\sysmon64.exe')
                    .\sysmon64.exe -accepteula -i sysmonconfig-export.xml
                }
                else {
                    (new-object System.Net.WebClient).DownloadFile('https://live.sysinternals.com/Sysmon.exe','C:\ProgramData\sysmon\sysmon.exe')
                    .\sysmon.exe -accepteula -i sysmonconfig-export.xml
                }

                Write-Verbose -Message "Set sysmon to restart on service failure"
                sc.exe failure Sysmon actions= restart/10000/restart/10000// reset= 120

                Write-Verbose -Message "Hide sysmon from services.msc and Powershell-s Get-Service"
                sc.exe sdset Sysmon 'D:(D;;DCLCWPDTSD;;;IU)(D;;DCLCWPDTSD;;;SU)(D;;DCLCWPDTSD;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)S:(AU;FA;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)'

                # Just in case it's needed. Restore sysmon to services.msc 
                # sc.exe sdset Sysmon 'D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)S:(AU;FA;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)'
            }
        }
    }
}

# Install-Sysmon -ComputerName DC -Credential toptours\administrator -Verbose



