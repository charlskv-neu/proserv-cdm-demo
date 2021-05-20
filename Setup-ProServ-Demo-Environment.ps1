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
    .PARAMETER SynapseWorkspaceName
        Name to use for Azure Synapse Workspace
    .PARAMETER SyanpseDefaultADLSName
        Name to use for ADLS account associated with Synpase Workspace
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
    $SynapseWorkspaceName,

    [Parameter(Mandatory = $True)]
    [string]
    $SyanpseDefaultADLSName
)

Function Set-ResourceGroup($resourceGroupName, $location) {  
    
    Write-Host "Working with resource group name: '$resourceGroupName'"

    Write-Host "Checking whether the resource group exists"
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if (!$resourceGroup) {
        Write-Host "Resource group '$resourceGroupName' does not exist. Creating new resource group";
        
        Write-Host "Creating resource group '$resourceGroupName' in location '$location'";
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }
    else {
        Write-Host "Using existing resource group '$resourceGroupName'";
    }
}

Function New-ResourceManagerTemplateDeployment($resourceGroupName, $deploymentName, $templateFilePath, $parametersFilePath, $overridenParameters) {
    if (!(Test-Path $templateFilePath)) {        
        Write-Host "ARM template file does not exist at path '$templateFilePath'"
    }
    elseif (!(Test-Path $parametersFilePath)) {        
        Write-Host "ARM template parameter file does not exist at path '$parametersFilePath'"
    }
    else {       
        Write-Host "Loading parameters from file"
        $parametersFromFile = Get-Content -Raw -Encoding UTF8 -Path $parametersFilePath | ConvertFrom-Json
        
        Write-Host "Overriding parameters"        
        $parameterObject = @{}; 
        $parametersFromFile.parameters | Get-Member -MemberType *Property | % {
            $parameterObject.($_.name) = $parametersFromFile.parameters.($_.name).value; }
        foreach ($parameterName in $overridenParameters.Keys) {          
            $parameterValue = $overridenParameters.$parameterName            
            $parameterObject["$parameterName"] = $parameterValue     
        }        
        Write-Host "Starting deployment '$deploymentName'"        
        New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -Mode Incremental -TemplateFile $templateFilePath -TemplateParameterObject $parameterObject 
        Write-Host "Deployment '$deploymentName' completed"        
    }    
}

Function New-SynapseLinkedService($workspaceName, $linkedServiceName, $definitionFilePath) {
    try {
        if (!(Test-Path $definitionFilePath)) {        
            Write-Host "Linked service definition file does not exist at path '$definitionFilePath'"
        }  
        else {       
            Set-AzSynapseLinkedService -WorkspaceName $workspaceName -Name $linkedServiceName -DefinitionFile $definitionFilePath -ErrorAction Stop
            Write-Host "Created linked service '$linkedServiceName' in synapse workspace '$workspaceName'"        
        }
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }
     
}

Function New-SynapseDataSet($workspaceName, $dataSetName, $definitionFilePath) {
    try {
        if (!(Test-Path $definitionFilePath)) {        
            Write-Host "Dataset definition file does not exist at path '$definitionFilePath'"
        }  
        else {       
            Set-AzSynapseDataset -WorkspaceName $workspaceName -Name $dataSetName -DefinitionFile $definitionFilePath -ErrorAction Stop     
            Write-Host "Created dataset '$dataSetName' in synapse workspace '$workspaceName'"        
        }   
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }     
}

Function New-SynapseDataFlow($workspaceName, $dataFlowName, $definitionFilePath) {
    try {
        if (!(Test-Path $definitionFilePath)) {        
            Write-Host "Dataflow definition file does not exist at path '$definitionFilePath'"
        }  
        else {       
            Set-AzSynapseDataFlow -WorkspaceName $workspaceName -Name $dataFlowName -DefinitionFile $definitionFilePath -ErrorAction Stop
            Write-Host "Created dataflow '$dataFlowName' in synapse workspace '$workspaceName'"        
        }
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }        
}

Function New-SynapsePipeline($workspaceName, $pipelineName, $definitionFilePath) {
    try {
        if (!(Test-Path $definitionFilePath)) {        
            Write-Host "Pipeline definition file does not exist at path '$definitionFilePath'"
        }  
        else {       
            Set-AzSynapsePipeline -WorkspaceName $workspaceName -Name $pipelineName -DefinitionFile $definitionFilePath -ErrorAction Stop
            Write-Host "Created pipeline '$pipelineName' in synapse workspace '$workspaceName'"        
        }
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }        
}

##############################################################################
##
## Entry Method. Execution begins here.
##
##############################################################################

## Setting up the development environment
if (!(Get-InstalledModule -Name Az)) {
    Write-Host "Installing Az module in the system"
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
    Import-Module Az
}

if (!(Get-InstalledModule -Name Az.Synapse)) {
    Write-Host "Installing Az.Synapse module in the system"
    Install-Module -Name Az.Synapse -AllowClobber -Scope CurrentUser
    Import-Module Az.Synapse
}

## Login to Azure Account.
Connect-AzAccount
## Select the subscription you will be operating on.
if ($TenantId) {
    Select-AzSubscription -Subscription $SubscriptionId -TenantId $TenantId
}
else {
    Write-Output "Unable to select the subscription. Please provide the tenant Id and subscription you're connecting to."
}

$location = "East US"

## Set up the resource group for deployment.
Set-ResourceGroup $ResourceGroupName $location

## Deploy Azure Synapse Workspace resource.
$today = Get-Date -Format "MM-dd-yyyy-HH-mm-ss" 
$deploymentName = "AzureSynapseAnalyticsDeployment" + $today
$templateFilePath = "./proserv-cdm-demo-infra-code/infra/Synapse/AzureSynapseAnalytics.json"
$parametersFilePath = "./proserv-cdm-demo-infra-code/infra/Synapse/AzureSynapseAnalytics.parameters.json"
$defaultDataLakeStorageFilesystemName = $SyanpseDefaultADLSName + "defaultstorage"
$loggedInUserAccount = (Get-AzContext).Account
$loggedInUserId = $loggedInUserAccount.Id
$loggedInUserObjectId = $loggedInUserAccount.ExtendedProperties.HomeAccountId.Split('.')[0]

$overridenParameters = @{
    name                                 = $SynapseWorkspaceName
    location                             = $location
    defaultDataLakeStorageAccountName    = $SyanpseDefaultADLSName
    defaultDataLakeStorageFilesystemName = $defaultDataLakeStorageFilesystemName
    storageSubscriptionID                = $SubscriptionId
    storageResourceGroupName             = $ResourceGroupName
    storageLocation                      = $location
    sqlActiveDirectoryAdminName          = $loggedInUserId
    sqlActiveDirectoryAdminObjectId      = $loggedInUserObjectId
    userObjectId                         = $loggedInUserObjectId    
}
New-ResourceManagerTemplateDeployment $ResourceGroupName $deploymentName $templateFilePath $parametersFilePath $overridenParameters

## Add folders in ADLS
.\proserv-cdm-demo-infra-code\infra\Scripts\AddContainersInStorageAccount.ps1 -ResourceGroupName $ResourceGroupName -SyanpseDefaultADLSName $SyanpseDefaultADLSName -SyanpseDefaultADLSFileSystemName $defaultDataLakeStorageFilesystemName -DataSourcePath "./proserv-cdm-demo-infra-code/infra"

## Deploy Azure Synapse Artifacts
$artifactsBasePath = "./proserv-cdm-demo-infra-code/WorkspaceTemplates/";

$linkedServiceName = "adls_cdm";
$definitionFilePath = $artifactsBasePath + "linkedService/adls_cdm.json";
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "<adls_cdm_url>" -ParameterValue "https://$SyanpseDefaultADLSName.dfs.core.windows.net"
New-SynapseLinkedService $SynapseWorkspaceName $linkedServiceName $definitionFilePath;
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "<adls_cdm_url>" -ParameterName "https://$SyanpseDefaultADLSName.dfs.core.windows.net"

$linkedServiceName = "AzureDataLakeStorageDemo";
$definitionFilePath = $artifactsBasePath + "linkedService/AzureDataLakeStorageDemo.json";
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "<AzureDataLakeStorageDemo_url>" -ParameterValue "https://$SyanpseDefaultADLSName.dfs.core.windows.net"
New-SynapseLinkedService $SynapseWorkspaceName $linkedServiceName $definitionFilePath;
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "<AzureDataLakeStorageDemo_url>" -ParameterName "https://$SyanpseDefaultADLSName.dfs.core.windows.net"

$dataSetName = "DynamicsGeneralJournalExcel";
$definitionFilePath = $artifactsBasePath + "dataset/DynamicsGeneralJournalExcel.json";
New-SynapseDataSet $SynapseWorkspaceName $dataSetName $definitionFilePath;

$dataFlowName = "DynamicsGL_CDM";
$definitionFilePath = $artifactsBasePath + "dataflow/DynamicsGL_CDM.json";
New-SynapseDataFlow $SynapseWorkspaceName $dataFlowName $definitionFilePath;

<#$pipelineName = "GeneralLedger_CDM";
$definitionFilePath = $artifactsBasePath + "pipeline/GeneralLedger_CDM.json";
New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;#>
