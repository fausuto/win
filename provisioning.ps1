<#
.SYNOPSIS
    This provisioning.ps1 helps configure a system at the desktop.

.DESCRIPTION
    This provisioning.ps1 will first start with checking if it has access to
    internet. If not, then it will just keep checking until you plug it in or
    connect to WiFi. Then it will set up a few power settings, set the time
    zone, and make sure it does a sync for time. Set a provisioning folder
    shortcut. Then it will start communicating with Bitwarden Secrets Manager
    and getting the necessary values for licenses, url's, and passwords. The
    following scripts will then start installing such as HEVC video extension,
    Microsoft Office 365, Dell Command Update, etc. It will then use Task
    Scheduler to create a task at next start up which will install any other
    programs, such AV, RMM, and onboard to Defender. Then it will check the first
    four characters of the hostname. That way it can download the correct urls
    for onboarding to our RMM solution, and On-Prem Domain Join to the correct
    OU.

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

# Define the transcript file location
$TranscriptFile = "$ProvisioningPath\${Date}_provisioning.txt"

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

function Test-InternetConnection
{
    param (
        [string]$Target = '8.8.8.8',
        [int]$IntervalSeconds = 5
    )

    # Save the original progress preference for restoration
    # Using $global: ensures the variable is set regardless of the function's scope
    $originalProgressPreference = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'

    try
    {
        Write-CleanLog @("", "Testing internet connection. Target: $Target", "") -Color Green
        $connected = $false
        do
        {
            try
            {
                # The progress bar is now suppressed by the $ProgressPreference variable
                $testResult = Test-NetConnection -ComputerName $Target -InformationLevel Quiet -ErrorAction Stop
                $connected = $testResult
            } catch
            {
                # Catch block handles network errors gracefully instead of failing
                $connected = $false
            }

            if (-not $connected)
            {
                Write-CleanLog @(
                    "Waiting for network connection... (sleeping for $IntervalSeconds seconds)"
                ) -Color DarkGray
                Start-Sleep -Seconds $IntervalSeconds
            }
        } while (-not $connected)

        Write-CleanLog @("Network connection successful!") -Color Green
    } finally
    {
        # Restore the original progress preference
        $global:ProgressPreference = $originalProgressPreference
    }
}

# =============================================================================
# MAIN SCRIPT LOGIC
# =============================================================================

# Start a Log file
Start-Transcript -Path $TranscriptFile

# Call the following function to check if the local machine has access to the
# internet before continuing with the script.
Test-InternetConnection

# Configure power settings
$powerCommands = @(
    "powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0",
    "powercfg /x -monitor-timeout-ac 0",
    "powercfg /x -standby-timeout-ac 0",
    "powercfg /x -hibernate-timeout-ac 0"
)
Write-CleanLog @(
    "",
    "Setting power settings when plugged to AC to Never and Do Nothing when laptop lid closed",
    ""
)
$powerCommands | ForEach-Object {
    Write-CleanLog @("$_") -Color DarkGray
    cmd /c $_
}

# Create a shortcut link to quickly access the Provisioning folder
Write-CleanLog @("", "Create folder shortcut to quickly access Provisioning folder")
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut("C:\Users\faust\Desktop\Provisioning.lnk")
$Shortcut.TargetPath = "C:\ProgramData\Microsoft\Provisioning"
$Shortcut.Save()

if (Test-Path "$env:SYSTEMDRIVE\Users\faust\Desktop\Provisioning.lnk")
{
    Write-CleanLog @("", "Provisioning shortcut exists.") -Color Green
}

# configure time zone
Write-CleanLog @("", "Checking if Windows Time Service is running...")
if ((Get-Service -Name w32time).Status -eq 'Running')
{
    Write-CleanLog @(
        "",
        "Windows Time Service is running. Setting the time zone to Central Standard Time.")
    Write-CleanLog @(
        "",
        "Get-TimeZone -ListAvailable | Where-Object{`$_.DisplayName -like `"*Central Time*`"} | Set-TimeZone") -Color DarkGray
    Write-CleanLog @(
        "",
        "Force a time sync")
    Write-CleanLog @(
        "",
        "w32tm /resync /rediscover", "") -Color DarkGray

    Get-TimeZone -ListAvailable | Where-Object{$_.DisplayName -like "*Central Time*"} | Set-TimeZone

    w32tm /resync /rediscover
} else
{
    Write-CleanLog @(
        "",
        "Windows Time Service is NOT running. Starting the service.") -Color Red
    Write-CleanLog @(
        "",
        "Start-Service w32time") -Color DarkGray
    Write-CleanLog @(
        "",
        "Setting the time zone to Central Standard Time.")
    Write-CleanLog @(
        "",
        "Get-TimeZone -ListAvailable | Where-Object{`$_.DisplayName -like `"*Central Time*`"} | Set-TimeZone") -Color DarkGray
    Write-CleanLog @(
        "",
        "Force a time sync")
    Write-CleanLog @(
        "",
        "w32tm /resync /rediscover", "") -Color DarkGray

    Start-Service w32time

    Get-TimeZone -ListAvailable | Where-Object{$_.DisplayName -like "*Central Time*"} | Set-TimeZone

    w32tm /resync /rediscover
}

$dcuInstallScript = "$PSScriptRoot\dell\dell-commandupdate-install-winget.ps1"
Write-CleanLog @("", "Dell Command | Update Install") -Color Yellow
Write-CleanLog @(
    "",
    (
        "Start-Process -FilePath `"powershell.exe`" " +
        "-ArgumentList `"-ExecutionPolicy Bypass -File `"$dcuInstallScript`" -NoNewWindow -Wait`""
    )
    ""
) -Color DarkGray

Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$dcuInstallScript`"" -NoNewWindow -Wait

$dcuImportScript = "$PSScriptRoot\dell\dell-commandupdate-import-config.ps1"
Write-CleanLog @("", "Dell Command | Update Import Configuration") -Color Yellow
Write-CleanLog @(
    "",
    (
        "Start-Process -FilePath `"powershell.exe`" " +
        "-ArgumentList `"-ExecutionPolicy Bypass -File `"$dcuImportScript`" -NoNewWindow -Wait`""
    )
    ""
) -Color DarkGray

Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$dcuImportScript`"" -NoNewWindow -Wait

$dcuScanScript = "$PSScriptRoot\dell\dell-commandupdate-scan.ps1"
Write-CleanLog @("", "Dell Command | Update Scan") -Color Yellow
Write-CleanLog @(
    "",
    (
        "Start-Process -FilePath `"powershell.exe`" " +
        "-ArgumentList `"-ExecutionPolicy Bypass -File `"$dcuScanScript`" -NoNewWindow -Wait`""
    )
    ""
) -Color DarkGray

Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$dcuScanScript`"" -NoNewWindow -Wait

$dcuApplyScript = "$PSScriptRoot\dell\dell-commandupdate-apply.ps1"
Write-CleanLog @("", "Dell Command | Update Apply") -Color Yellow
Write-CleanLog @(
    "",
    (
        "Start-Process -FilePath `"powershell.exe`" " +
        "-ArgumentList `"-ExecutionPolicy Bypass -File `"$dcuApplyScript`" -NoNewWindow -Wait`""
    )
    ""
) -Color DarkGray

Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$dcuApplyScript`"" -NoNewWindow -Wait

$regScript = "$PSScriptRoot\utility\registries.ps1"
Write-CleanLog @("", "Applying other registries") -Color Yellow
Write-CleanLog @(
    "",
    (
        "Start-Process -FilePath `"powershell.exe`" " +
        "-ArgumentList `"-ExecutionPolicy Bypass -File `"$regScript`" -NoNewWindow -Wait`""
    )
    ""
) -Color DarkGray

Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$regScript`"" -NoNewWindow -Wait

Write-CleanLog @("", "Exiting script.", "")
Write-Host "Transcript stopped, output file is $TranscriptFile"
Stop-Transcript

Exit

