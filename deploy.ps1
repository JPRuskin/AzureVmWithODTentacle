<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template
#>
[CmdletBinding(DefaultParameterSetName='NoOctopus')]
param(
    # Purpose of the deployed template
    [string]$Purpose = 'QA',

    # SiteLocation to deploy the template to
    [ValidateNotNullOrEmpty()]
    [string]$SiteLocation = 'AUSE2',

    # Template to deploy
    [ValidateScript({Test-Path (Resolve-Path $_)})]
    [string]$TemplateFilePath = "$PSScriptRoot\azuredeploy.json",

    # The URI to the OctopusDeploy server to connect to
    [Parameter(ParameterSetName = 'OctopusDeploy')]
    [ValidateScript({(Invoke-RestMethod -Uri "$($_)/api").Application -eq 'Octopus Deploy'})]
    [string]$OctopusDeployApiUrl = "https://dev.deployment.questionmark.com",

    # If the VM should be connected to dev.deployment.questionmark.com, please provide a key here
    [Parameter(ParameterSetName = 'OctopusDeploy', Mandatory)]
    [string]$OctopusDeployApiKey,

    # Target for the VM automated-shutdown notification e-mails
    [string]$ShutdownNotificationEmail,

    # Admin credential for the VM
    [Parameter(Mandatory)]
    [PSCredential]$LabCredential = 'ForgeQA'
)
$ErrorActionPreference = "Stop"

$null = Set-AzureRmContext -SubscriptionName 'Forge Dev/Test'

try {
    $ResourceGroupName = Get-QMAzureResourceGroupName -Site $SiteLocation -DeploymentType FRG -Product $Purpose
    $ResourceGroupLocation = (Get-AzureRmLocation | Where DisplayName -eq (Get-QMAzureSiteLocation -SiteLocation $SiteLocation)[1]).Location
} catch [System.Management.Automation.CommandNotFoundException] {
    # We assume that Questionmark.Configuration is not available
    $ResourceGroupName = $SiteLocation + '-FRG' + $Purpose
    $ResourceGroupLocation = switch ($SiteLocation) {
        'AUSE2' {'East US 2'}
        'AEUW1' {'West Europe'}
        default {'West Europe'}
    }
}

# Create or check for existing resource group
if (-not ($ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Verbose "Creating resource group '$ResourceGroupName' in '$ResourceGroupLocation'"
    $null = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation
} else {
    Write-Verbose "Using existing resource group '$ResourceGroupName'"
}

# Generate deployment parameters
$DeploymentParameters = @{
    ResourceGroupName       = $ResourceGroupName
    TemplateFile            = (Resolve-Path $TemplateFilePath)
    TemplateParameterObject = @{
        baseName = $ResourceGroupName
    }
}
if ($PSBoundParameters.ContainsKey('OctopusDeployApiKey')) {
    $DeploymentParameters.TemplateParameterObject.OctopusDeployApiUrl = $OctopusDeployApiUrl
    $DeploymentParameters.TemplateParameterObject.OctopusDeployApiKey = $OctopusDeployApiKey
}
if ($PSBoundParameters.ContainsKey('ShutdownNotificationEmail')) {
    $DeploymentParameters.TemplateParameterObject.autoShutdownNotificationEmail = $ShutdownNotificationEmail
}
if ($PSBoundParameters.ContainsKey('LabCredential')) {
    $DeploymentParameters.TemplateParameterObject.adminUsername = $LabCredential.Username
    $DeploymentParameters.TemplateParameterObject.adminPassword = $LabCredential.GetNetworkCredential().Password
}

# Start the deployment
New-AzureRmResourceGroupDeployment @DeploymentParameters
