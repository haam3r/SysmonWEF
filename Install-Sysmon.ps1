function Install-Sysmon {
<#
.Synopsis
   Install Sysmon on multiple machines
.DESCRIPTION
   Install Sysmon, with given config, to any number of machines. Additionaly hide the service. Accepts pipeline input for computer names and has credential support.
.EXAMPLE
   Install-Sysmon -ComputerName win7x64 -Credential domain\admin
.EXAMPLE
   Get-ADComputer -Filter * | Install-Sysmon -Credential domain\admin
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='One or more computer names')]
        [Alias("ComputerName")]
        # Parameter is Name so as to accept pipeline input from the Active Directory PowerShell module
        [string]$Name,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage='Credentials to use')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        # Specifies a path to one or more locations.
        [Parameter(Mandatory=$false,
                Position=0,
                ParameterSetName="Path",
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
                HelpMessage="Where to put Sysmon. Default is ProgramData\sysmon. Expecting full path.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path = "$env:SystemDrive\ProgramData\sysmon"

    )
    BEGIN {
        Write-Verbose -Message "Running on these machines: $Name"
    }

    PROCESS {
        foreach ($Computer in $Name) {
            Write-Verbose -Message "Running on $Computer"

            Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock {

                Write-Verbose -Message "Create sysmon directory if needed"
                if (-not (Test-Path $Path)) {
                    New-Item -Path $Path -ItemType Directory
                }
                Set-Location -Path $Path

                Write-Verbose -Message "Download the sysmon config file"
                (New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml',"$Path\sysmonconfig-export.xml")

                Write-Verbose -Message "Download and install sysmon"
                if ( ((Get-WmiObject Win32_OperatingSystem).OSArchitecture) -eq "64-bit") {
                    (New-Object System.Net.WebClient).DownloadFile('https://live.sysinternals.com/Sysmon64.exe','$Path\sysmon64.exe')
                    .\sysmon64.exe -accepteula -i sysmonconfig-export.xml
                }
                else {
                    (new-object System.Net.WebClient).DownloadFile('https://live.sysinternals.com/Sysmon.exe','$Path\sysmon.exe')
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

    END {

    }
}

# Install-Sysmon -ComputerName DC -Credential toptours\administrator -Verbose



