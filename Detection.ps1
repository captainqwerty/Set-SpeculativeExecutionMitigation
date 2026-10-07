$intune = $true

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

$root = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$FeatureSettingsOverrideMaskValueRequirement = 3 # FeatureSettingsOverrideMask

switch ($detectedVendor) {
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

#-----[ Execution ]-----#

$FeatureSettingsOverrideMaskValue = (Get-ItemProperty -Path $root).FeatureSettingsOverrideMask # Gets the current FeatureSettingsOverrideMask

$FeatureSettingsOverrideValue = (Get-ItemProperty -Path $root).FeatureSettingsOverride # Gets the current FeatureSettingsOverride value

if(Get-MitigatedSpeculativeVulnerability) {
    if ($intune) {
        Exit 0
    } else {
        return $true
    }
} else {
    if ($intune) {
        Exit 1
    } else {
        return $false
    }
}