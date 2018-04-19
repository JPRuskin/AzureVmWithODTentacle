<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template
#>
[CmdletBinding()]
param(
    # Purpose of the deployed template
    [string]$Purpose = 'QA',

    # SiteLocation to deploy the template to
    [ValidateNotNullOrEmpty()]
    [string]$SiteLocation = 'AUSE2',

    # Template to deploy
    [ValidateScript( {Test-Path (Resolve-Path $_)})]
    [string]$TemplateFilePath = "$PSScriptRoot\azuredeploy.json",

    # The URI to the OctopusDeploy server to connect to
    [Parameter(ParameterSetName = 'OctopusDeploy', Mandatory)]
    [string]$OctopusDeployApiUrl = "https://dev.deployment.questionmark.com",

    # If the VM should be connected to dev.deployment.questionmark.com, please provide a key here
    [Parameter(ParameterSetName = 'OctopusDeploy', Mandatory)]
    [string]$OctopusDeployApiKey,

    [PSCredential]$LabCredential
)
$ErrorActionPreference = "Stop"

$null = Set-AzureRmContext -SubscriptionName 'Forge Dev/Test'

$ResourceGroupLocation = (Get-AzureRmLocation | Where DisplayName -eq (Get-QMAzureSiteLocation -SiteLocation $SiteLocation)[1]).Location
$ResourceGroupName = Get-QMAzureResourceGroupName -Site $SiteLocation -DeploymentType FRG -Product $Purpose

# Create or check for existing resource group
if (-not ($ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Verbose "Creating resource group '$ResourceGroupName' in location '$ResourceGroupLocation'"
    $null = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation
} else {
    Write-Verbose "Using existing resource group '$ResourceGroupName'"
}

# Start the deployment
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
if ($PSBoundParameters.ContainsKey('LabCredential')) {
    $DeploymentParameters.TemplateParameterObject.adminUsername = $LabCredential.Username
    $DeploymentParameters.TemplateParameterObject.adminPassword = $LabCredential.GetNetworkCredential().Password
}

New-AzureRmResourceGroupDeployment @DeploymentParameters
