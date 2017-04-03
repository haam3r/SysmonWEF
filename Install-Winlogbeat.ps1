function Install-Winlogbeat
<#
.Synopsis

   Install winlogbeat

.DESCRIPTION

   Deploy the winlogbeat log forwarding solution to multiple machines. Install as a service, with config and hide the service.

.EXAMPLE

    Install-Winlogbeat -ComputerName win7x64 -Credential domain\admin

.EXAMPLE

   Get-ADComputer -Filter * | Install-Winlogbeat -Credential domain\admin

#>
{
    [CmdletBinding()]
    [Alias()]
    Param (
        [Parameter(Mandatory=$true,                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='One or more computer names')]
        [Alias("ComputerName")]
        # Parameter is Name so as to accept pipeline input from the Active Directory PowerShell module
        [string]$Name,
        [Parameter(Mandatory=$true,                   ValueFromPipelineByPropertyName=$true,                   HelpMessage='Credentials to use')]        [ValidateNotNull()]        [System.Management.Automation.PSCredential]        [System.Management.Automation.Credential()]        $Credential = [System.Management.Automation.PSCredential]::Empty,        [Parameter(Mandatory=$false,                Position=0,                ParameterSetName="Path",                ValueFromPipeline=$true,                ValueFromPipelineByPropertyName=$true,                HelpMessage="Where to put Sysmon. Default is ProgramData\sysmon. Expecting full path.")]        [Alias("PSPath")]        [ValidateNotNullOrEmpty()]        [string[]]        $Path = "$env:SystemDrive\ProgramData\sysmon"    )

    Begin {
         Write-Verbose -Message "Running on these machines:" -OutVariable $Name
    }

    Process {
         foreach ($Computer in $Name) {            Write-Verbose -Message "Connecting to $Computer"
            Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock {

            }
    }

    End
    {
    }
}