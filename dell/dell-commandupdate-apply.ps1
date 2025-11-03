<#
.SYNOPSIS
    This script will use Dell Command | Update to apply updates and drivers.

.DESCRIPTION
    What this scrilpt will do is make sure that Dell Command | Update is installed.
    If it is then it will check if the executable is in its directory. Then it
    will apply any available scanned updates and drivers. There has to be scanned
    updates and installs for apply to work.

.NOTES
    Author: CL
    Date: 2025-10-20
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
$TranscriptFile = "$ProvisioningPath\${Date}_dell-commandupdate-apply.txt"

# Define the name of the software to check
$SoftwareName = "Dell Command | Update for Windows Universal"

# Define the path where the executable is located
$DcuCli = "$env:PROGRAMFILES\Dell\CommandUpdate\dcu-cli.exe"

# Define the arguments to use for the executable
$DcuCliArgs = "/applyUpdates"

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
Start-Transcript -Path $TranscriptFile

if ($SoftwareInstalled)
{
    Write-CleanLog @("", "`"$SoftwareName`" is installed.") -Color Green
    Write-CleanLog @("", "Checking for $DcuCli...")

    if (Test-Path -Path $DcuCli)
    {
        Write-CleanLog @("", "`"$DcuCli`" exists.") -Color Green
        Write-CleanLog @("", "Applying any available updates...")
        Write-CleanLog @("", "& `"$DcuCli`" $DcuCliArgs", "") -Color DarkGray

        & $DcuCli $DcuCliArgs
    } else
    {
        Write-CleanLog @("", "`"$DcuCli`" does not exist.") -Color Red
    }
} else
{
    Write-CleanLog @("", "`"$SoftwareName`" is not installed.") -Color Red
}

Write-CleanLog @("", "Exiting script.", "")
Write-Host "Transcript stopped, output file is $TranscriptFile"
Stop-Transcript

Exit

