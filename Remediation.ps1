#-----[ Configuration ]-----#

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
    $ForceVendor
} else {
    $detectedVendor
}

$root = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$FeatureSettingsOverrideMaskValueRequirement = 3 # FeatureSettingsOverrideMask

switch ($effectiveVendor) {
    "Intel" {
        $FeatureSettingsOverrideHyperThreadingEnabled = 8388680 # FeatureSettingOverride value for when Hyper-threading is enabled
        $FeatureSettingsOverrideHyperThreadingDisabled = 8396872 # FeatureSettingOverride value for when Hyper-threading is not enabled
    }
    "AMD" {
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
        return (Get-WindowsFeature -Name Hyper-V).InstallState -eq 'Installed'
    } else {
        return (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State -eq 'Enabled'
    }
}

#-----[ Execution ]-----#

$isServer = (Get-CimInstance -class win32_OperatingSystem).ProductType -ne 1

$FeatureSettingsOverrideMaskValue = (Get-ItemProperty -Path $root).FeatureSettingsOverrideMask # Gets the current FeatureSettingsOverrideMask
$FeatureSettingsOverrideValue = (Get-ItemProperty -Path $root).FeatureSettingsOverride # Gets the current FeatureSettingsOverride value

if(Get-MitigatedSpeculativeVulnerability) { Exit 0 }

$Processor = Get-CimInstance Win32_Processor; 
$hyperThreadingEnabled = ($Processor| measure-object -Property NumberOfLogicalProcessors -sum).Sum -gt ($Processor | measure-object -Property NumberOfCores -sum).Sum

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
    New-ItemProperty -Path $root -Name FeatureSettingsOverrideMask -PropertyType DWord -Force
    Set-ItemProperty -Path $root -Name FeatureSettingsOverrideMask -Value $FeatureSettingsOverrideMaskValueRequirement -Force
}

if ($FeatureSettingsOverrideValue -ne $FeatureSettingsOverride) {
    New-ItemProperty -Path $root -Name FeatureSettingsOverride -PropertyType DWord -Force
    Set-ItemProperty -Path $root -Name FeatureSettingsOverride -Value $FeatureSettingsOverride
}

if (Get-HypervState) {
    $hyperVRegistryRoot = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization"

    if ((Get-ItemProperty -Path $hyperVRegistryRoot -Name MinVmVersionForCpuBasedMitigations -ErrorAction SilentlyContinue).MinVmVersionForCpuBasedMitigations -notmatch "1.0")     {
        Set-ItemProperty -Path $hyperVRegistryRoot -Name MinVmVersionForCpuBasedMitigations -Value "1.0"
    }
}