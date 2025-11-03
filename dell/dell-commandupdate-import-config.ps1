<#
.SYNOPSIS
    This script imports a configuration file into Dell Command | Update.

.DESCRIPTION
    This script will first check if Dell Command | Update is installed on the
    computer. Then will check if the executable is located in the correct
    directory. If everything checks out then it will create a configuration.xml
    file that it will then use to import into Dell Command | Update. We exported
    the default configuration that Dell Command | Update installs with. The only
    change that we added is for auto scanning and auto installing updates and
    drivers. There is no auto reboot, a toast message will appear for the user
    that Dell Command | Update has installed updates and needs a reboot.

.NOTES
    Author: CL
    Date: 2025-10-21
    Version: 2.0
#>

# =============================================================================
# CONFIGURATION GLOBAL VARIABLES & PARAMETERS
# =============================================================================

# Define the date format for the log file
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Define the path to the provisioning folder
$ProvisioningPath = "$env:PROGRAMDATA\Microsoft\Provisioning"

# Define the log file location
$TranscriptFile = "$ProvisioningPath\${Date}_dell-commandupdate-import.txt"

# Define the name of the software to check
$SoftwareName = "Dell Command | Update for Windows Universal"

# Define the path where the executable is located
$DcuCli = "$env:PROGRAMFILES\Dell\CommandUpdate\dcu-cli.exe"

# Define the XML content to be written in Configuration.xml
$XMLContent = @"
<Configuration>
  <Group Name="Settings" Version="5.4.0" TimeSaved="8/22/2024 11:53:32 AM (UTC -5:00)">
    <Group Name="General">
      <Property Name="SettingsModifiedTime">
        <Value>9/29/2023 6:16:50 PM</Value>
      </Property>
      <Property Name="DownloadPath" Default="ValueIsDefault" />
      <Property Name="CustomCatalogPaths" Default="ValueIsDefault" />
      <Property Name="EnableDefaultDellCatalog" Default="ValueIsDefault" />
      <Property Name="EnableCatalogXML" Default="ValueIsDefault" />
      <Property Name="TestMode" Default="ValueIsDefault" />
      <Property Name="UserConsent" Default="ValueIsDefault" />
      <Property Name="SuspendBitLocker">
        <Value>true</Value>
      </Property>
      <Property Name="AutoUpdateUserConsent" Default="ValueIsDefault" />
      <Property Name="MaxRetryAttempts" Default="ValueIsDefault" />
      <Property Name="ExcludeUpdatesFromLastNDays" Default="ValueIsDefault" />
      <Group Name="CustomProxySettings">
        <Property Name="UseDefaultProxy" Default="ValueIsDefault" />
        <Property Name="Server" Default="ValueIsDefault" />
        <Property Name="Port" Default="ValueIsDefault" />
        <Property Name="EnableProxyFallbackToDirectConnection" Default="ValueIsDefault" />
        <Property Name="UseAuthentication" Default="ValueIsDefault" />
      </Group>
    </Group>
    <Group Name="Schedule">
      <Property Name="ScheduleMode" Default="ValueIsDefault" />
      <Property Name="MonthlyScheduleMode" Default="ValueIsDefault" />
      <Property Name="WeekOfMonth" Default="ValueIsDefault" />
      <Property Name="Time" Default="ValueIsDefault" />
      <Property Name="DayOfWeek" Default="ValueIsDefault" />
      <Property Name="DayOfMonth" Default="ValueIsDefault" />
      <Property Name="AutomationMode">
        <Value>ScanDownloadApplyNotify</Value>
      </Property>
      <Property Name="ScheduledExecution" Default="ValueIsDefault" />
      <Property Name="DeferUpdate" Default="ValueIsDefault" />
      <Property Name="DisableNotification" Default="ValueIsDefault" />
      <Property Name="InstallationDeferral" Default="ValueIsDefault" />
      <Property Name="DeferralInstallInterval" Default="ValueIsDefault" />
      <Property Name="DeferralInstallCount" Default="ValueIsDefault" />
      <Property Name="SystemRestartDeferral" Default="ValueIsDefault" />
      <Property Name="DeferRestartInterval" Default="ValueIsDefault" />
      <Property Name="DeferRestartCount" Default="ValueIsDefault" />
      <Property Name="EnableForceRestart" Default="ValueIsDefault" />
    </Group>
    <Group Name="UpdateFilter">
      <Property Name="FilterApplicableMode" Default="ValueIsDefault" />
      <Group Name="RecommendedLevel">
        <Property Name="IsCriticalUpdatesSelected" Default="ValueIsDefault" />
        <Property Name="IsRecommendedUpdatesSelected" Default="ValueIsDefault" />
        <Property Name="IsOptionalUpdatesSelected" Default="ValueIsDefault" />
        <Property Name="IsSecurityUpdatesSelected" Default="ValueIsDefault" />
      </Group>
      <Group Name="UpdateType">
        <Property Name="IsDriverSelected" Default="ValueIsDefault" />
        <Property Name="IsApplicationSelected" Default="ValueIsDefault" />
        <Property Name="IsBiosSelected" Default="ValueIsDefault" />
        <Property Name="IsFirmwareSelected" Default="ValueIsDefault" />
        <Property Name="IsUtilitySelected" Default="ValueIsDefault" />
        <Property Name="IsUpdateTypeOtherSelected" Default="ValueIsDefault" />
      </Group>
      <Group Name="DeviceCategory">
        <Property Name="IsAudioSelected" Default="ValueIsDefault" />
        <Property Name="IsChipsetSelected" Default="ValueIsDefault" />
        <Property Name="IsInputSelected" Default="ValueIsDefault" />
        <Property Name="IsNetworkSelected" Default="ValueIsDefault" />
        <Property Name="IsStorageSelected" Default="ValueIsDefault" />
        <Property Name="IsVideoSelected" Default="ValueIsDefault" />
        <Property Name="IsDeviceCategoryOtherSelected" Default="ValueIsDefault" />
      </Group>
    </Group>
    <Group Name="AdvancedDriverRestore">
      <Property Name="IsCabSourceDell" Default="ValueIsDefault" />
      <Property Name="CabPath" Default="ValueIsDefault" />
      <Property Name="IsAdvancedDriverRestoreEnabled">
        <Value>false</Value>
      </Property>
    </Group>
  </Group>
</Configuration>
"@

# Define the path and name of the XML file
$XMLConfigPath = "$ProvisioningPath\Configuration.xml"

# Define the arguments to use for the executable
$DcuCliArgs = @("/configure", "-importSettings=$XMLConfigPath")

# Define the registry paths to the list of installed programs
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

# Initialize an empty array to store the installed software
$InstalledSoftware = @()

# Get the list of installed programs from each registry path
foreach ($RegistryPath in $RegistryPaths)
{
    $InstalledSoftware += Get-ItemProperty -Path "$RegistryPath\*" -ErrorAction SilentlyContinue
}

# Check if the specified software is installed
$SoftwareInstalled = $InstalledSoftware | Where-Object { $_.DisplayName -like "*$SoftwareName*"}

# =============================================================================
# FUNCTIONS
# =============================================================================

# Powershell logging function with here-string and indentation cleanup
function Write-CleanLog
{
    param (
        [Parameter(Position = 0)]
        [string[]]$Messages,
        [string]$Color = "White" # Default color
    )

    # Build the log lines
    foreach ($msg in $Messages)
    {
        if ([string]::IsNullOrWhiteSpace($msg))
        {
            Write-Host "" # True blank line
        } else
        {
            $timestamp = Get-Date -Format 'HH:mm:ss'
            Write-Host "[$timestamp] $msg" -ForegroundColor $Color
        }
    }
}

# =============================================================================
# MAIN SCRIPT LOGIC
# =============================================================================

# Start a Log file
Start-Transcript -Path "$TranscriptFile"

# Checking if software is installed, if so, exit script, if not then download the executable
if ($SoftwareInstalled)
{
    Write-CleanLog @("", "`"$SoftwareName`" is installed.") -Color Green
    Write-CleanLog @("", "Checking for `"$DcuCli`"...")
    if (Test-Path -Path $DcuCli)
    {
        Write-CleanLog @("", "`"$DcuCli`" exists.") -Color Green
        Write-CleanLog @("", "Creating `"$XMLConfigPath`" with the following XML content...")
        Write-CleanLog @("", "$XMLContent | Out-File -FilePath `"$XMLConfigPath`" -Force") -Color DarkGray

        $XMLContent | Out-File -FilePath $XMLConfigPath -Force

        if (Test-Path -Path $XMLConfigPath)
        {
            Write-CleanLog @("", "`"$XMLConfigPath`" exists.") -Color Green
            Write-CleanLog @("", "Importing `"$XMLConfigPath`"...")
            Write-CleanLog @("", "& `"$DcuCli`" $($DcuCliArgs -join ' ')", "") -Color DarkGray

            & $DcuCli @DcuCliArgs
        } else
        {
            Write-CleanLog @(
                "",
                "`"$XMLConfigPath`" does not exist."
                "",
                "Something went wrong generating `"$XMLConfigPath`""
                "",
                "Exiting script."
            ) -Color Red
        }
    } else
    {
        Write-CleanLog @("", "`"$DcuCli`" does not exist.", "", "Exiting script.") -Color Red
    }
} else
{
    Write-CleanLog @("", "`"$SoftwareName`" is not installed.", "", "Exiting script.") -Color Red
}

Write-CleanLog @("", "Cleaning up files from `"$ProvisioningPath`", if any...", "")

if (Test-Path $XMLConfigPath)
{
    Write-CleanLog @("Remove-Item -Path `"$XMLConfigPath`" -Force") -Color DarkGray
    Remove-Item -Path $XMLConfigPath -Force
}

Write-CleanLog @("", "Exiting script", "")
Write-Host "Transcript stopped, output file is $TranscriptFile"
Stop-Transcript

Exit

