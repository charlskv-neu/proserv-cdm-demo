<#
 .SYNOPSIS    
 .DESCRIPTION
    Deploys the resources required to run ProServ Demo.
    .PARAMETER TenantId
        Tenant Id associated with your azure subscription
    .PARAMETER SubscriptionId
        Id of your azure subscription
    .PARAMETER ResourceGroupName
        The name for the resource group to use
    .PARAMETER PurviewAccountName
        Name to use for Azure Purview Account
    .PARAMETER SynapseWorkspaceName
        Name of Azure Synapse Workspace
    .PARAMETER SyanpseDefaultADLSName
        Name of ADLS account associated with Synpase Workspace
    .PARAMETER AmericasADLSName
        Name of ADLS account associated with Americas region
    .PARAMETER ApacADLSName
        Name of ADLS account associated with Apac   
#>

param(

    [Parameter(Mandatory = $True)]
    [string]
    $TenantId,

    [Parameter(Mandatory = $True)]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory = $True)]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $True)]
    [string]
    $PurviewAccountName,

    [Parameter(Mandatory = $True)]
    [string]
    $SynapseWorkspaceName,

    [Parameter(Mandatory = $True)]
    [string]
    $SyanpseDefaultADLSName,

    [Parameter(Mandatory = $True)]
    [string]
    $AmericasADLSName,

    [Parameter(Mandatory = $True)]
    [string]
    $ApacADLSName    
)

Function Set-ResourceGroup($resourceGroupName, $location) {  
    
    Write-Host "Working with resource group name: '$resourceGroupName'."

    Write-Host "Checking whether the resource group exists."
    $resourceGroup = az group show --name $resourceGroupName --only-show-errors
    if (!$resourceGroup) {
        Write-Host "Resource group '$resourceGroupName' does not exist. Creating new resource group."
        
        Write-Host "Creating resource group '$resourceGroupName' in location '$location'."
        az group create --name $resourceGroupName --location $location --only-show-errors --output none
        if (!$?) {
            throw "An error occurred while creating resource group."
        }
    }
    else {
        Write-Host "Using existing resource group '$resourceGroupName'."
    }
}
Function New-ResourceManagerTemplateDeployment($resourceGroupName, $deploymentName, $templateFilePath, $parametersFilePath, $overridenParameters) {
    if (!(Test-Path $templateFilePath)) {        
        throw "ARM template file does not exist at path '$templateFilePath'."
    }
    elseif (!(Test-Path $parametersFilePath)) {        
        throw "ARM template parameter file does not exist at path '$parametersFilePath'."
    }
    else {       
        Write-Host "Loading parameters from file."
        $templateParametersFromFile = Get-Content -Raw -Encoding UTF8 -Path $parametersFilePath | ConvertFrom-Json
        $originalParameterContent = $templateParametersFromFile | ConvertTo-Json 
        $parametersFromFile = $templateParametersFromFile
        Write-Host "Overriding parameters."
        foreach ($parameterName in $overridenParameters.Keys) {          
            $parameterValue = $overridenParameters.$parameterName            
            $parametersFromFile.parameters.$parameterName.value = $parameterValue     
        }        
        $parametersFromFile | ConvertTo-Json | Out-File -FilePath $parametersFilePath
        Write-Host "Starting deployment '$deploymentName'."
        az deployment group create --resource-group $resourceGroupName --name $deploymentName --mode Incremental --template-file $templateFilePath --parameters $parametersFilePath --only-show-errors --output none
        if (!$?) {
            $originalParameterContent | Out-File -FilePath $parametersFilePath
            throw "An error occurred while deploying '$deploymentName' to resource group '$resourceGroupName'."
        }
        else {
            $originalParameterContent | Out-File -FilePath $parametersFilePath
            Write-Host "Deployment '$deploymentName' completed."
        }                
    }    
}
Function New-StorageBlobDataReaderAccess($purviewAccountName, $resourceGroupName, $subscriptionId, $adlsName) {
    try {
        $role = "Storage Blob Data Reader"
        $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$adlsName"
        $assignment = az role assignment list --assignee $purviewAccountName --role $role --scope $scope --only-show-errors --output tsv
        if (!$assignment) {
            az role assignment create --assignee $purviewAccountName --role $role --scope $scope --only-show-errors --output none               
            if (!$?) {
                throw "An error occurred while adding $role role for '$purviewAccountName' at '$adlsName'."
            }
            else {
                Write-Host "Added $role role for '$purviewAccountName' at '$adlsName'."
            }
        }
        else {               
            Write-Host "$role role already exists for '$purviewAccountName' at '$adlsName'."
        }
    }
    catch {
        Write-Host "An error occurred." -ForegroundColor Red
        throw $_
    }     
}
Function New-PurviewAccess($purviewAccountName, $resourceGroupName, $subscriptionId, $assigneeName, $role) {
    try {        
        $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Purview/accounts/$purviewAccountName"
        $assignment = az role assignment list --assignee $assigneeName --role $role --scope $scope --only-show-errors --output tsv
        if (!$assignment) {
            az role assignment create --assignee $assigneeName --role $role --scope $scope --only-show-errors --output none               
            if (!$?) {
                throw "An error occurred while adding $role role for '$assigneeName' at '$purviewAccountName'."
            }
            else {
                Write-Host "Added $role role for '$assigneeName' at '$purviewAccountName'."
            }
        }
        else {               
            Write-Host "$role role already exists for '$assigneeName' at '$purviewAccountName'."
        }
    }
    catch {
        Write-Host "An error occurred." -ForegroundColor Red
        throw $_
    }     
}


##############################################################################
##
## Entry Method. Execution begins here.
##
##############################################################################

## Setting up the development environment
$stopwatch = [System.Diagnostics.Stopwatch]::new()
$Stopwatch.Start()

$directorypath = Split-Path $MyInvocation.MyCommand.Path
dir -Path $directorypath -Recurse | Unblock-File

az --version --only-show-errors --output none
if (!$?) {
    throw "Azure CLI is not installed in the system. Please complete the prerequisite step and restart this script in a new powershell instance."
}

<# Write-Host "Installing SqlServer module in the system."
Install-Module -Name SqlServer -AllowClobber -Scope CurrentUser
Import-Module SqlServer #>

Write-Host "Starting setting up the demo environment."
## Login to Azure Account with the subscription you will be operating on.
if ($TenantId -And $SubscriptionId) {
    az login --tenant $TenantId --output none
    az account set --subscription $SubscriptionId --only-show-errors --output none
    Write-Host "Completed logging in to azure account."
}
else {
    throw "Unable to select the subscription. Please provide the tenant Id and subscription you're connecting to."
}

$location = "East US2"

## Set up the resource group for deployment.
Set-ResourceGroup $ResourceGroupName $location

## Deploy Azure Purview Account resource.
$today = Get-Date -Format "MM-dd-yyyy-HH-mm-ss"
$deploymentName = "AzurePurviewAccountDeployment" + $today
$templateFilePath = "./infra/Purview/AzurePurviewAccount.json"
$parametersFilePath = "./infra/Purview/AzurePurviewAccount.parameters.json"

$overridenParameters = @{
    name     = $PurviewAccountName
    location = $location    
}
New-ResourceManagerTemplateDeployment $ResourceGroupName $deploymentName $templateFilePath $parametersFilePath $overridenParameters

## Add storage blob data reader access for ADLS accounts.
$purviewAccountManagedIdentity = az resource list -n $PurviewAccountName --query [*].identity.principalId --out tsv
New-StorageBlobDataReaderAccess $purviewAccountManagedIdentity $ResourceGroupName $SubscriptionId $SyanpseDefaultADLSName
New-StorageBlobDataReaderAccess $purviewAccountManagedIdentity $ResourceGroupName $SubscriptionId $AmericasADLSName
New-StorageBlobDataReaderAccess $purviewAccountManagedIdentity $ResourceGroupName $SubscriptionId $ApacADLSName

## Add Purview Data Source Administrator access.
$loggedInUserAccount = az ad signed-in-user show | ConvertFrom-Json
$synapseWorkspaceManagedIdentity = az resource list -n $SynapseWorkspaceName --query [*].identity.principalId --out tsv
$role = "Purview Data Source Administrator"
$assigneeName = $loggedInUserAccount.mail
New-PurviewAccess $PurviewAccountName $ResourceGroupName $SubscriptionId $assigneeName $role
$assigneeName = $synapseWorkspaceManagedIdentity
New-PurviewAccess $PurviewAccountName $ResourceGroupName $SubscriptionId $assigneeName $role
$role = "Purview Data Curator"
$assigneeName = $loggedInUserAccount.mail
New-PurviewAccess $PurviewAccountName $ResourceGroupName $SubscriptionId $assigneeName $role
$assigneeName = $synapseWorkspaceManagedIdentity
New-PurviewAccess $PurviewAccountName $ResourceGroupName $SubscriptionId $assigneeName $role

$Stopwatch.Stop()
Write-Host "Total Execution Time : "$Stopwatch.Elapsed  -ForegroundColor DarkGray
