<#
.SYNOPSIS
    Speculative Execution Mitigation

.DESCRIPTION
    Mitigates Windows Speculative Execution vulnerability (CVE-2022-0001)

.PARAMETER ForceHyperThreadingValues
    Forces the script to use predefined values for Hyper-Threading being enabled.

.PARAMETER ForceVendor
    Force CPU vendor-specific values. Valid values are "Intel" or "AMD".

.PARAMETER DetectionOnly
    Will not apply the mitigation; only states if it is required.

.EXAMPLE
    .\Set-SpeculativeExecutionMitigation.ps1
    Applies the speculative execution mitigation based on detected CPU vendor and Hyper-Threading status.

.EXAMPLE
    .\Set-SpeculativeExecutionMitigation.ps1 -DetectionOnly
    Checks if mitigation is required without applying it.

.EXAMPLE
    .\Set-SpeculativeExecutionMitigation.ps1 -ForceVendor AMD
    Forces the script to use AMD-specific values regardless of detected CPU.

.EXAMPLE
    .\Set-SpeculativeExecutionMitigation.ps1 -ForceHyperThreadingValues
    Forces the use of predefined values assuming Hyper-Threading is enabled.

.NOTES
    Created By        : Antony Bragg
    Creation Date     : 07/10/2026
    Last Updated By   : Antony Bragg
    Last Updated      : 07/10/2026
    Script Version    : 1.0.0

.LINK
    GitHub Repository : https://github.com/CaptainQwerty/Set-SpeculativeExecutionMitigation
    Documentation     : https://github.com/CaptainQwerty/Set-SpeculativeExecutionMitigation/blob/main/README.md
    Change Log        : https://github.com/CaptainQwerty/Set-SpeculativeExecutionMitigation/blob/main/CHANGELOG.MD
    Nessus Article    : https://msrc.microsoft.com/update-guide/vulnerability/CVE-2022-0001 
#>

#-----[ Requirements ]-----#

#Requires -runasAdministrator # Run as Administrator

#-----[ Script Parameters ]-----#

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(
        HelpMessage = "Forces the script to use predefined values for Hyper-Threading being enabled."
    )]
    [switch]$ForceHyperThreadingValues,

    [Parameter(
        HelpMessage = "Force CPU vendor-specific values."
    )]
    [ValidateSet("Intel","AMD")]
    [string]$ForceVendor,

    [Parameter(
        HelpMessage = "Will not apply the mitigation will only state if it is required."
    )]
    [switch]$DetectionOnly
)

#-----[ Module Setup ]-----#

# No Module Setup

#-----[ Configuration ]-----#

$ScriptVersion = "2.1.0"

# Determine Vendor of the CPU
try {
    $cpu = Get-CimInstance Win32_Processor

    $detectedVendor = if ($cpu.Manufacturer -match "Intel") {
        "Intel"
    } elseif ($cpu.Manufacturer -match "AMD") {
        "AMD"
    } else {
        throw "Unsupported CPU vendor detected: $($cpu.Manufacturer). Only Intel and AMD are supported."
    }
} catch {
    Write-Error $_
    exit 1
}

$effectiveVendor = if ($ForceVendor) {
    Write-Verbose "Forcing CPU vendor to: $ForceVendor"
    $ForceVendor
} else {
    $detectedVendor
}

Write-Verbose "Detected CPU vendor: $detectedVendor"
if ($ForceVendor -and $ForceVendor -ne $detectedVendor) {
    Write-Warning "Forced vendor '$ForceVendor' does not match detected vendor '$detectedVendor'"
}

$root = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$FeatureSettingsOverrideMaskValueRequirement = 3 # FeatureSettingsOverrideMask

switch ($effectiveVendor) {
    "Intel" {
        Write-Verbose "Applying Intel-specific logic"
        $FeatureSettingsOverrideHyperThreadingEnabled = 8388680 # FeatureSettingOverride value for when Hyper-threading is enabled
        $FeatureSettingsOverrideHyperThreadingDisabled = 8396872 # FeatureSettingOverride value for when Hyper-threading is not enabled
    }
    "AMD" {
        Write-Verbose "Applying AMD-specific logic"
        $FeatureSettingsOverrideHyperThreadingEnabled = 72 # FeatureSettingOverride value for when Hyper-threading is enabled
        $FeatureSettingsOverrideHyperThreadingDisabled = 8264 # FeatureSettingOverride value for when Hyper-threading is not enabled
    }
}

#-----[ Functions ]-----#

function Get-MitigatedSpeculativeVulnerability { 
    if ($FeatureSettingsOverrideMaskValue -ne $FeatureSettingsOverrideMaskValueRequirement) { return $false }
    if (($FeatureSettingsOverrideValue -ne $FeatureSettingsOverrideHyperThreadingDisabled) -and ($FeatureSettingsOverrideValue -ne $FeatureSettingsOverrideHyperThreadingEnabled)) { return $false }
    return $true
}

function Get-HypervState {
    if ($isServer) {
        Write-Verbose "Checking if Server has Hyper-V enabled"
        return (Get-WindowsFeature -Name Hyper-V).InstallState -eq 'Installed'
    } else {
        Write-Verbose "Checking if Desktop OS has Hyper-V enabled"
        return (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State -eq 'Enabled'
    }
}

#-----[ Execution ]-----#

Write-Host "Speculative Execution Fix - Version $ScriptVersion"

$isServer = (Get-CimInstance -class win32_OperatingSystem).ProductType -ne 1

$FeatureSettingsOverrideMaskValue = (Get-ItemProperty -Path $root).FeatureSettingsOverrideMask # Gets the current FeatureSettingsOverrideMask
Write-Verbose "FeatureSettingsOverrideMask value is currently $FeatureSettingsOverrideMaskValue"

$FeatureSettingsOverrideValue = (Get-ItemProperty -Path $root).FeatureSettingsOverride # Gets the current FeatureSettingsOverride value
Write-Verbose "FeatureSettingsOverride value is currently $FeatureSettingsOverrideValue"

if(Get-MitigatedSpeculativeVulnerability) {
    Write-Host "Mitigations already in place." -ForegroundColor Green
    Exit 0
} else {
    Write-Host "Mitigation required" -ForegroundColor Red
    if($DetectionOnly) {
        Write-Host "Mitigation not applied as -DetectionOnly was specified" -ForegroundColor Yellow
        Exit 3
    }
}

$Processor = Get-CimInstance Win32_Processor; 
$hyperThreadingEnabled = ($Processor| measure-object -Property NumberOfLogicalProcessors -sum).Sum -gt ($Processor | measure-object -Property NumberOfCores -sum).Sum
Write-verbose "Hyper-Threading: $hyperThreadingEnabled"
Write-Verbose "Force Hyper-Threading Settings: $ForceHyperThreadingValues"
Write-Verbose "Detected Device as Server: $isServer" 

if($ForceHyperThreadingValues) {
    $FeatureSettingsOverride = $FeatureSettingsOverrideHyperThreadingEnabled
} else {
    $FeatureSettingsOverride = switch ($hyperThreadingEnabled)
    {
        $true {$FeatureSettingsOverrideHyperThreadingEnabled; break;}
        $false {$FeatureSettingsOverrideHyperThreadingDisabled; break;}
    }
}

if ($FeatureSettingsOverrideMaskValue -ne 3) {
    if ($PSCmdlet.ShouldProcess(
        "Registry: $root",
        "Set FeatureSettingsOverrideMask to $FeatureSettingsOverrideMaskValueRequirement"
    )) {
        Write-Verbose "Setting FeatureSettingsOverrideMask to $FeatureSettingsOverrideMaskValueRequirement"
        New-ItemProperty -Path $root -Name FeatureSettingsOverrideMask -PropertyType DWord -Force
        Set-ItemProperty -Path $root -Name FeatureSettingsOverrideMask -Value $FeatureSettingsOverrideMaskValueRequirement -Force
    }
}

if ($FeatureSettingsOverrideValue -ne $FeatureSettingsOverride) {
    if ($PSCmdlet.ShouldProcess(
        "Registry: $root",
        "Set FeatureSettingsOverride to $FeatureSettingsOverride"
    )) {
        Write-Verbose "Setting FeatureSettingsOverride to $FeatureSettingsOverride"
        New-ItemProperty -Path $root -Name FeatureSettingsOverride -PropertyType DWord -Force
        Set-ItemProperty -Path $root -Name FeatureSettingsOverride -Value $FeatureSettingsOverride
    }
}

if (Get-HypervState) {
    Write-Verbose "Hyper-V installation detected. Additional settings are being configured."
    $hyperVRegistryRoot = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization"

    if ((Get-ItemProperty -Path $hyperVRegistryRoot -Name MinVmVersionForCpuBasedMitigations -ErrorAction SilentlyContinue).MinVmVersionForCpuBasedMitigations -notmatch "1.0") {
        
        if ($PSCmdlet.ShouldProcess(
            "Registry: $hyperVRegistryRoot",
            "Set MinVmVersionForCpuBasedMitigations to 1.0"
        )) {
            Set-ItemProperty -Path $hyperVRegistryRoot -Name MinVmVersionForCpuBasedMitigations -Value "1.0"
        }
    }
}

if (-not $WhatIfPreference) {
    Write-Host "Mitigations now implemented. Consider rebooting." -ForegroundColor Green
} else {
    Write-Host "Mitigations not implemented as -WhatIf was specified." -ForegroundColor Yellow
}