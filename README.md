
<!-- ReadMe Template: 2.0.1 -->
<div id="top"></div>

<div align="center">

<h1><b>Set-SpeculativeExecutionMitigation</b></h1>
  <p>
    Small one liner project summary
    <br />
    <a href="https://github.com/CaptainQwerty/Set-SpeculativeExecutionMitigation/releases">Releases</a> -
    <a href="https://github.com/CaptainQwerty/Set-SpeculativeExecutionMitigation/issues">Report Bug</a> -
    <a href="https://github.com/CaptainQwerty/Set-SpeculativeExecutionMitigation/blob/main/CHANGELOG.md">Change Log</a>
  </p>
</div>

<!-- ABOUT THE PROJECT -->
## About The Project

The `Set-SpeculativeExecutionMitigation` PowerShell script is designed to assist administrators in mitigating speculative execution side-channel vulnerabilities on Windows systems. These vulnerabilities, which include issues like Meltdown and Spectre, can be exploited to gain unauthorized access to sensitive data. This script provides a streamlined process to apply necessary registry settings and configurations, particularly focusing on systems with Hyper-Threading and Hyper-V enabled.

The script is also able to set the values based on the CPU vendor.

### Features

* **Automated Vulnerability Mitigation**: The script checks and sets the appropriate registry values to mitigate speculative execution vulnerabilities
* **Hyper-Threading Detection**: Detects whether Hyper-Threading is enabled on the system and adjusts mitigation settings accordingly
* **Hyper-V Support**: Detects Hyper-V installations and applies additional necessary mitigations if required.
* **CPU Vendor Detection**: Detects the CPU vendor to install the correct keys
* **WhatIf and Confirm Support**: To help with testing and sanity checking both `-whatif` and `-confirm` are supported

## Parameters
- **`-ForceHyperThreadingValues`**: (Optional) A switch that forces the script to use predefined values for Hyper-Threading, regardless of the system's actual configuration
- **`-ForceVendor`**: (Optional) Allows you to specific `AMD` or `Intel` to set the values accordingly, if not specified the vendor will be detected using CIM
- **`-DetectionOnly`**: (Optional) Will simply state if the mitigation is required or not but not apply it
- **`-Verbose`**: (Optional) The script can be executed using for additional output
- **`-WhatIf`**: (Optional) Will not modify the device in any way but will say what modifications would have occurred
- **`-Confirm`**: (Optional) will confirm for continuation at specific points

<p align="right">(<a href="#top">Back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

* Run as Administrator

<!-- USAGE EXAMPLES -->
## Usage

```PowerShell
# Run the script normally; automatically detects the CPU vendor and applies mitigations.
.\Set-SpeculativeExecutionMitigation.ps1
```

```PowerShell
# Ensures the script only returns if the mitigation is needed and does not apply
.\Set-SpeculativeExecutionMitigation.ps1 -DetectionOnly
```

```PowerShell
# Force the script to apply mitigations as if the CPU vendor is Intel, regardless of the actual CPU.
.\Set-SpeculativeExecutionMitigation.ps1 -ForceVendor Intel
```

```PowerShell
# Force Intel vendor mode and display detailed information about each action the script performs.
.\Set-SpeculativeExecutionMitigation.ps1 -ForceVendor Intel -Verbose
```

```PowerShell
# Show what the script would do for Intel vendor mode without making any changes.
.\Set-SpeculativeExecutionMitigation.ps1 -ForceVendor Intel -WhatIf
```

```PowerShell
# Force the script to apply predefined Hyper-Threading settings based on the detected CPU vendor.
.\Set-SpeculativeExecutionMitigation.ps1 -ForceHyperThreadingValues
```

```PowerShell
# Force predefined Hyper-Threading settings and treat the CPU as AMD, regardless of the actual vendor.
.\Set-SpeculativeExecutionMitigation.ps1 -ForceHyperThreadingValues -ForceVendor AMD
```

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#top">Back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Othneildrew's Best-README-Template](https://github.com/othneildrew/Best-README-Template)

<p align="right">(<a href="#top">Back to top</a>)</p>











## Features


## Parameters
- **`-ForceHyperThreadingValues`**: (Optional) A Boolean parameter that forces the script to use predefined values for Hyper-Threading, regardless of the system's actual configuration.
- **`-verbose`**: (Optional) The script can be executed using for additional output.

## Usage

To run the script, open a PowerShell window with administrative privileges and execute the script. For example:
```powershell
.\Set-SpeculativeExecutionMitigation.ps1
```

Forcing Hyper-Threading values:
```powershell
.\Set-SpeculativeExecutionMitigation.ps1 -ForceHyperThreadingValues
```

Having verbose output:
```powershell
.\Set-SpeculativeExecutionMitigation.ps1 -verbose
```

## Authors
* [Antony Bragg](https://github.com/AntonyBragg)