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
Function New-SynapseIntegrationRuntime($workspaceName, $integrationRuntimeName, $definitionFilePath, $resourceGroupName) {
    try {
        if (!(Test-Path $definitionFilePath)) {        
            throw "Integration runtime definition file does not exist at path '$definitionFilePath'."
        }  
        else {
            $integrationRuntime = az synapse integration-runtime show --workspace-name $workspaceName --name $integrationRuntimeName --resource-group $resourceGroupName --only-show-errors
            $propertiesFromFile = Get-Content -Raw -Encoding UTF8 -Path $definitionFilePath | ConvertFrom-Json
            $properties = $propertiesFromFile.properties
            $typeProperties = $properties.typeProperties
            $computeProperties = $typeProperties.computeProperties
            $dataFlowProperties = $computeProperties.dataFlowProperties
            $createCommand = "az synapse integration-runtime create --workspace-name $workspaceName --name $integrationRuntimeName --resource-group $resourceGroupName";
            if ($properties.type) {
                $createCommand += " --type " + $properties.type
            }
            if ($dataFlowProperties.computeType) {
                $createCommand += " --compute-type " + $dataFlowProperties.computeType
            }
            if ($dataFlowProperties.coreCount) {
                $createCommand += " --core-count " + $dataFlowProperties.coreCount
            }
            if ($computeProperties.location) {
                $createCommand += " --location " + $computeProperties.location
            }
            if ($computeProperties.timeToLive) {
                $createCommand += " --time-to-live " + $computeProperties.timeToLive
            }
            $createCommand += " --only-show-errors --output none"
            if (!$integrationRuntime) {                
                Invoke-Expression $createCommand
                if (!$?) {
                    throw "An error occurred while creating integration runtime."
                }
                else {
                    Write-Host "Created integration runtime '$integrationRuntimeName' in synapse workspace '$workspaceName'."
                }
            }
            else {
                Invoke-Expression $createCommand           
                if (!$?) {
                    throw "An error occurred while updating integration runtime."
                }
                else {
                    Write-Host "Updated integration runtime '$integrationRuntimeName' in synapse workspace '$workspaceName'."
                }
            }                    
        }
    }
    catch {
        Write-Host "An error occurred." -ForegroundColor Red
        throw $_
    }
     
}
Function New-SynapseLinkedService($workspaceName, $linkedServiceName, $definitionFilePath) {
    try {
        if (!(Test-Path $definitionFilePath)) {        
            throw "Linked service definition file does not exist at path '$definitionFilePath'."
        }  
        else {
            $linkedService = az synapse linked-service show --workspace-name $workspaceName --name $linkedServiceName --only-show-errors
            if (!$linkedService) {
                az synapse linked-service create --workspace-name $workspaceName --name $linkedServiceName --file @$definitionFilePath --only-show-errors --output none               
                if (!$?) {
                    throw "An error occurred while creating linked service."
                }
                else {
                    Write-Host "Created linked service '$linkedServiceName' in synapse workspace '$workspaceName'."
                }
            }
            else {
                az synapse linked-service set --workspace-name $workspaceName --name $linkedServiceName --file @$definitionFilePath --only-show-errors --output none             
                if (!$?) {
                    throw "An error occurred while updating linked service."
                }
                else {
                    Write-Host "Updated linked service '$linkedServiceName' in synapse workspace '$workspaceName'."
                }
            }
                    
        }
    }
    catch {
        Write-Host "An error occurred." -ForegroundColor Red
        throw $_
    }
     
}
Function New-SynapseDataSet($workspaceName, $dataSetName, $definitionFilePath) {
    try {
        if (!(Test-Path $definitionFilePath)) {        
            throw "Dataset definition file does not exist at path '$definitionFilePath'."
        }  
        else {
            $dataSet = az synapse dataset show --workspace-name $workspaceName --name $dataSetName --only-show-errors
            if (!$dataSet) {
                az synapse dataset create --workspace-name $workspaceName --name $dataSetName --file @$definitionFilePath --only-show-errors --output none            
                if (!$?) {
                    throw "An error occurred while creating dataset."
                }
                else {
                    Write-Host "Created dataset '$dataSetName' in synapse workspace '$workspaceName'."
                }
            }
            else {
                az synapse dataset set --workspace-name $workspaceName --name $dataSetName --file @$definitionFilePath --only-show-errors --output none
                if (!$?) {
                    throw "An error occurred while updating dataset."
                }
                else {
                    Write-Host "Updated dataset '$dataSetName' in synapse workspace '$workspaceName'."
                }                
            }
                    
        }   
    }
    catch {
        Write-Host "An error occurred." -ForegroundColor Red
        throw $_
    }     
}
Function New-SynapseDataFlow($workspaceName, $dataFlowName, $definitionFilePath) {
    try {
        if (!(Test-Path $definitionFilePath)) {        
            throw "Dataflow definition file does not exist at path '$definitionFilePath'."
        }  
        else {
            $dataFlow = az synapse data-flow show --workspace-name $workspaceName --name $dataFlowName --only-show-errors
            if (!$dataFlow) {
                az synapse data-flow create --workspace-name $workspaceName --name $dataFlowName --file @$definitionFilePath --only-show-errors --output none
                if (!$?) {
                    throw "An error occurred while creating dataflow."
                }
                else {
                    Write-Host "Created dataflow '$dataFlowName' in synapse workspace '$workspaceName'."
                }                
            }
            else {
                az synapse data-flow set --workspace-name $workspaceName --name $dataFlowName --file @$definitionFilePath --only-show-errors --output none
                if (!$?) {
                    throw "An error occurred while updating dataflow."
                }
                else {
                    Write-Host "Updated dataflow '$dataFlowName' in synapse workspace '$workspaceName'."
                }                
            }                    
        }
    }
    catch {
        Write-Host "An error occurred." -ForegroundColor Red
        throw $_
    }        
}
Function New-SynapsePipeline($workspaceName, $pipelineName, $definitionFilePath) {
    try {
        if (!(Test-Path $definitionFilePath)) {        
            throw "Pipeline definition file does not exist at path '$definitionFilePath'."
        }  
        else {
            $pipeline = az synapse pipeline show --workspace-name $workspaceName --name $pipelineName --only-show-errors
            if (!$pipeline) {
                az synapse pipeline create --workspace-name $workspaceName --name $pipelineName --file @$definitionFilePath --only-show-errors --output none
                if (!$?) {
                    throw "An error occurred while creating pipeline."
                }
                else {
                    Write-Host "Created pipeline '$pipelineName' in synapse workspace '$workspaceName'."
                }                
            }
            else {
                az synapse pipeline set --workspace-name $workspaceName --name $pipelineName --file @$definitionFilePath --only-show-errors --output none
                if (!$?) {
                    throw "An error occurred while upating pipeline."
                }
                else {
                    Write-Host "Updated pipeline '$pipelineName' in synapse workspace '$workspaceName'."
                }                
            }                    
        }
    }
    catch {
        Write-Host "An error occurred." -ForegroundColor Red
        throw $_
    }        
}
Function Execute-SqlScript ($serverName, $databaseName, $userName, $userPassword, $scriptFile) {
    $Error.Clear()
    SqlServer\Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Username "$userName" -Password "$userPassword" -InputFile $scriptFile -OutputSqlErrors $true
    if ($Error -ne $null){
        throw $Error
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

az --version --only-show-errors --output none
if (!$?) {
    throw "Azure CLI is not installed in the system. Please complete the prerequisite step and restart this script in a new powershell instance."
}

Write-Host "Installing SqlServer module in the system."
Install-Module -Name SqlServer -AllowClobber -Scope CurrentUser
Import-Module SqlServer

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

$location = "East US"

## Set up the resource group for deployment.
Set-ResourceGroup $ResourceGroupName $location

## Deploy Azure Synapse Workspace resource.
$today = Get-Date -Format "MM-dd-yyyy-HH-mm-ss"
$currentUTCDate = Get-Date ((Get-Date).ToUniversalTime()) -f "yyyy-MM-dd"
$deploymentName = "AzureSynapseAnalyticsDeployment" + $today
$templateFilePath = "./proserv-cdm-demo-infra-code/infra/Synapse/AzureSynapseAnalytics.json"
$parametersFilePath = "./proserv-cdm-demo-infra-code/infra/Synapse/AzureSynapseAnalytics.parameters.json"
$defaultDataLakeStorageFilesystemName = $SyanpseDefaultADLSName + "defaultstorage"
$loggedInUserAccount = az ad signed-in-user show | ConvertFrom-Json
$loggedInUserId = $loggedInUserAccount.mail
$loggedInUserObjectId = $loggedInUserAccount.objectId
$adminUserName = 'sqladmin'
$adminPassword = 'Password@123'

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
    sqlAdministratorLogin                = $adminUserName
    sqlAdministratorLoginPassword        = $adminPassword
}
New-ResourceManagerTemplateDeployment $ResourceGroupName $deploymentName $templateFilePath $parametersFilePath $overridenParameters

## Deploy Azure Synapse SQL Pool
$deploymentName = "AzureSynapseSQLPoolsDeployment" + $today
$templateFilePath = "./proserv-cdm-demo-infra-code/infra/Synapse/AzureSynapseSQLPools.json"
$parametersFilePath = "./proserv-cdm-demo-infra-code/infra/Synapse/AzureSynapseSQLPools.parameters.json"
$sqlPoolName = "proservsqlpl"

$overridenParameters = @{
    sqlPoolName   = $sqlPoolName
    workspaceName = $SynapseWorkspaceName
    location      = $location
}
New-ResourceManagerTemplateDeployment $ResourceGroupName $deploymentName $templateFilePath $parametersFilePath $overridenParameters

## Add folders in ADLS
.\proserv-cdm-demo-infra-code\infra\Scripts\AddContainersInStorageAccount.ps1 -ResourceGroupName $ResourceGroupName -SyanpseDefaultADLSName $SyanpseDefaultADLSName -SyanpseDefaultADLSFileSystemName $defaultDataLakeStorageFilesystemName -DataSourcePath "./proserv-cdm-demo-infra-code/infra"

## Deploy Azure Synapse Artifacts
$artifactsBasePath = "./proserv-cdm-demo-infra-code/WorkspaceTemplates/";

$integrationRuntimeName = "IntegrationRuntimePerformance";
$definitionFilePath = $artifactsBasePath + "integrationRuntime/IntegrationRuntimePerformance.json";
New-SynapseIntegrationRuntime $SynapseWorkspaceName $integrationRuntimeName $definitionFilePath $ResourceGroupName;

## $linkedServiceName = "adls_cdm";
## $definitionFilePath = $artifactsBasePath + "linkedService/adls_cdm.json";
## .\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "<adls_cdm_url>" -ParameterValue "https://$SyanpseDefaultADLSName.dfs.core.windows.net"
## New-SynapseLinkedService $SynapseWorkspaceName $linkedServiceName $definitionFilePath;
## .\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "<adls_cdm_url>" -ParameterName "https://$SyanpseDefaultADLSName.dfs.core.windows.net"

$linkedServiceName = "AzureDataLakeStorageDemo";
$definitionFilePath = $artifactsBasePath + "linkedService/AzureDataLakeStorageDemo.json";
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "<AzureDataLakeStorageDemo_url>" -ParameterValue "https://$SyanpseDefaultADLSName.dfs.core.windows.net"
New-SynapseLinkedService $SynapseWorkspaceName $linkedServiceName $definitionFilePath;
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "<AzureDataLakeStorageDemo_url>" -ParameterName "https://$SyanpseDefaultADLSName.dfs.core.windows.net"

$linkedServiceName = "AzureSynapseAnalytics1";
$definitionFilePath = $artifactsBasePath + "linkedService/AzureSynapseAnalytics1.json";
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "<SynapseWorkspaceName>" -ParameterValue "$SynapseWorkspaceName"
New-SynapseLinkedService $SynapseWorkspaceName $linkedServiceName $definitionFilePath;
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "<SynapseWorkspaceName>" -ParameterName "$SynapseWorkspaceName"

$linkedServiceName = "SQLOnDemand";
$definitionFilePath = $artifactsBasePath + "linkedService/SQLOnDemand.json";
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "<SynapseWorkspaceName>" -ParameterValue "$SynapseWorkspaceName"
New-SynapseLinkedService $SynapseWorkspaceName $linkedServiceName $definitionFilePath;
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "<SynapseWorkspaceName>" -ParameterName "$SynapseWorkspaceName"

$dataSetName = "DynamicsGeneralJournalExcel";
$definitionFilePath = $artifactsBasePath + "dataset/DynamicsGeneralJournalExcel.json";
New-SynapseDataSet $SynapseWorkspaceName $dataSetName $definitionFilePath;

$dataSetName = "TaxiDataParquet";
$definitionFilePath = $artifactsBasePath + "dataset/TaxiDataParquet.json";
New-SynapseDataSet $SynapseWorkspaceName $dataSetName $definitionFilePath;

$dataSetName = "TaxiDataCDMParquet";
$definitionFilePath = $artifactsBasePath + "dataset/TaxiDataCDMParquet.json";
New-SynapseDataSet $SynapseWorkspaceName $dataSetName $definitionFilePath;

$dataSetName = "taxiDataDedicatedSQL";
$definitionFilePath = $artifactsBasePath + "dataset/taxiDataDedicatedSQL.json";
New-SynapseDataSet $SynapseWorkspaceName $dataSetName $definitionFilePath;

$dataFlowName = "DynamicsGL_CDM";
$definitionFilePath = $artifactsBasePath + "dataflow/DynamicsGL_CDM.json";
New-SynapseDataFlow $SynapseWorkspaceName $dataFlowName $definitionFilePath;

$dataFlowName = "NYTaxiDF_CDM";
$definitionFilePath = $artifactsBasePath + "dataflow/NYTaxiDF_CDM.json";
New-SynapseDataFlow $SynapseWorkspaceName $dataFlowName $definitionFilePath;

## $pipelineName = "GeneralLedger_CDM";
## $definitionFilePath = $artifactsBasePath + "pipeline/GeneralLedger_CDM.json";
## New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;
## 
## $pipelineName = "NYTaxiPL_CDM";
## $definitionFilePath = $artifactsBasePath + "pipeline/NYTaxiPL_CDM.json";
## New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;

$pipelineName = "GeneralLedger_CDM_Small";
$definitionFilePath = $artifactsBasePath + "pipeline/GeneralLedger_CDM_Small.json";
New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;

$pipelineName = "glCDMtoOnDemand_Small";
$definitionFilePath = $artifactsBasePath + "pipeline/glCDMtoOnDemand_Small.json";
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "<SyanpseDefaultADLSName>" -ParameterValue "$SyanpseDefaultADLSName"
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "/<currentUTCDate>/" -ParameterValue "/$currentUTCDate/"
New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "<SyanpseDefaultADLSName>" -ParameterName "$SyanpseDefaultADLSName"
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "/<currentUTCDate>/" -ParameterName "/$currentUTCDate/"

$pipelineName = "NYTaxi_CDM_Large";
$definitionFilePath = $artifactsBasePath + "pipeline/NYTaxi_CDM_Large.json";
New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;

$pipelineName = "NYTaxi_CDM_Medium";
$definitionFilePath = $artifactsBasePath + "pipeline/NYTaxi_CDM_Medium.json";
New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;

$pipelineName = "NYTaxiCDMtoSQLonDemand_Medium";
$definitionFilePath = $artifactsBasePath + "pipeline/NYTaxiCDMtoSQLonDemand_Medium.json";
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "<SyanpseDefaultADLSName>" -ParameterValue "$SyanpseDefaultADLSName"
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "/<currentUTCDate>/" -ParameterValue "/$currentUTCDate/"
New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "<SyanpseDefaultADLSName>" -ParameterName "$SyanpseDefaultADLSName"
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "/<currentUTCDate>/" -ParameterName "/$currentUTCDate/"

$pipelineName = "NYTaxiCDMtoSQLPool_Large";
$definitionFilePath = $artifactsBasePath + "pipeline/NYTaxiCDMtoSQLPool_Large.json";
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "/<currentUTCDate>" -ParameterValue "/$currentUTCDate/"
New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "/<currentUTCDate>" -ParameterName "/$currentUTCDate/"

$pipelineName = "NYTaxiCDMtoSQLPool_Medium";
$definitionFilePath = $artifactsBasePath + "pipeline/NYTaxiCDMtoSQLPool_Medium.json";
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "/<currentUTCDate>" -ParameterValue "/$currentUTCDate"
New-SynapsePipeline $SynapseWorkspaceName $pipelineName $definitionFilePath;
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "/<currentUTCDate>" -ParameterName "/$currentUTCDate"

## Create database objects in sql pool
$sqlScriptsBasePath = "./proserv-cdm-demo-infra-code/SqlPoolObjects/";

$onDemandSqlPoolName = "$SynapseWorkspaceName-ondemand.sql.azuresynapse.net"
$dedicatedSqlPoolName = "$SynapseWorkspaceName.sql.azuresynapse.net"
$masterDatabaseName = "master"
$proservDatabaseName = "proservod"


$scriptFile = $sqlScriptsBasePath + "Databases/proservod.sql"
Execute-SqlScript $onDemandSqlPoolName $masterDatabaseName $adminUserName $adminPassword $scriptFile
Write-Host "Created proservod database in on demand sql pool."

.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterName "<masterKeyPassword>" -ParameterValue $adminPassword
$scriptFile = $sqlScriptsBasePath + "External Resources/Credential.sql"
Execute-SqlScript $onDemandSqlPoolName $proservDatabaseName $adminUserName $adminPassword $scriptFile
Write-Host "Created master key in $proservDatabaseName database in on demand sql pool."
Execute-SqlScript $dedicatedSqlPoolName $sqlPoolName $adminUserName $adminPassword $scriptFile
Write-Host "Created master key in $sqlPoolName database in dedicated sql pool."
.\proserv-cdm-demo-infra-code\infra\Scripts\ReplaceTextInSource.ps1 -FilePath $definitionFilePath -ParameterValue "<masterKeyPassword>" -ParameterName $adminPassword

$scriptFile = $sqlScriptsBasePath + "Stored Procedures/usp_GeneralJournal_ext.sql"
Execute-SqlScript $onDemandSqlPoolName $proservDatabaseName $adminUserName $adminPassword $scriptFile
Write-Host "Created stored procedure usp_GeneralJournal_ext in $proservDatabaseName database in on demand sql pool."
$scriptFile = $sqlScriptsBasePath + "Stored Procedures/usp_NycTaxi_External_Table.sql"
Execute-SqlScript $onDemandSqlPoolName $proservDatabaseName $adminUserName $adminPassword $scriptFile
Write-Host "Created stored procedure usp_NycTaxi_External_Table in $proservDatabaseName database in on demand sql pool."

$scriptFile = $sqlScriptsBasePath + "Stored Procedures/uspDropAndCreateTaxiDataTable.sql"
Execute-SqlScript $dedicatedSqlPoolName $sqlPoolName $adminUserName $adminPassword $scriptFile
Write-Host "Created stored procedure uspDropAndCreateTaxiDataTable in $sqlPoolName database in dedicated sql pool."

$Stopwatch.Stop()
Write-Host "Total Execution Time : "$Stopwatch.Elapsed  -ForegroundColor DarkGray