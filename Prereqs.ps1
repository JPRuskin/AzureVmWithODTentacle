<# PSRepository Initialization #>
$NuGetExe = &(Import-Module PowerShellGet -PassThru) {
    [CmdletBinding()]
    param()
    if (!($script:NuGetExePath -and (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetExePath))) {
        Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -BootstrapNuGetExe -Force
    }
    $script:NuGetExePath
}

<# Install Required DSC #>
if (-not (Get-Module OctopusDSC -ListAvailable)) {
    Install-Module -Name OctopusDSC -Force
}