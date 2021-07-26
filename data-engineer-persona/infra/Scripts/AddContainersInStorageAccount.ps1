#Parameters needed by the script .
Param(
    [Parameter(Mandatory=$True)]
    [string] $ResourceGroupName,
    [Parameter(Mandatory=$True)]
    [string] $SynapseDefaultADLSName,
    [Parameter(Mandatory=$True)]
    [string] $AmericasADLSName,
    [Parameter(Mandatory=$True)]
    [string] $ApacADLSName,
    [Parameter(Mandatory=$True)]
    [string] $SynapseDefaultADLSFileSystemName,
    [Parameter(Mandatory=$True)]
    [string] $DataSourcePath
)

$storageAccount = az storage account show --resource-group $ResourceGroupName --name $SynapseDefaultADLSName --only-show-errors
$storageAccount = az storage account show --resource-group $ResourceGroupName --name $AmericasADLSName --only-show-errors
$storageAccount = az storage account show --resource-group $ResourceGroupName --name $ApacADLSName --only-show-errors

Function Create-StorageContainer($containerName, $ADLSName)
{
    $container = az storage container show --name $containerName --account-name $ADLSName --only-show-errors
    if($container)  
    {  
        Write-Host "$containerName - container already exists."
    }  
    else  
    { 
        az storage container create --name $containerName --account-name $ADLSName --public-access off --only-show-errors --output none
        if (!$?) {
            throw "An error occurred while creating container."
        }
        else {
            Write-Host "Created container $containerName ."
        }        
    }
}
Function Create-FolderInContainer($containerName, $ADLSName, $folderName)
{
    $folder = az storage fs directory show --file-system $containerName --name $folderName --account-name $ADLSName --only-show-errors
    if($folder)  
    {  
        Write-Host "$folderName - folder already exists."
    }  
    else  
    {              
        az storage fs directory create --account-name $ADLSName --file-system $containerName --name $folderName --only-show-errors --output none
        if (!$?) {
            throw "An error occurred while creating folder."
        }
        else {
            Write-Host "Created folder $folderName ."
        }        
    }
}
Function Create-FileInFolder($containerName, $ADLSName, $folderName, $fileName, $filePath)
{
    $finalPath = $folderName + $fileName
    $file = az storage fs file show --file-system $containerName --path $finalPath --account-name $ADLSName --only-show-errors
    if($file)  
    {  
        Write-Host "$fileName - file already exists."
    }  
    else  
    {              
        az storage fs file upload --account-name $ADLSName --file-system $containerName --path $finalPath --source $filePath --only-show-errors --output none
        if (!$?) {
            throw "An error occurred while creating file."
        }
        else {
            Write-Host "Created file $fileName inside $folderName ."
        }        
    }
}
Function Upload-FilesFromFolder($containerName, $ADLSName, $folderName, $folderPath)
{
    $filesToUpload = Get-ChildItem -Path $folderPath
    for ($i=0; $i -lt $filesToUpload.Count; $i++) {
        $fileName = $filesToUpload[$i].Name
        $filePath = $folderPath +$fileName
        Create-FileInFolder $containerName $ADLSName $folderName $fileName $filePath
    }
}

$containerName = "cdmproservdataintegration"
Create-StorageContainer $containerName $SynapseDefaultADLSName

$folderName = "RAW/"
Create-FolderInContainer $containerName $SynapseDefaultADLSName $folderName

$folderName = "RAW/Dynamics/"
Create-FolderInContainer $containerName $SynapseDefaultADLSName $folderName

$filePath = $DataSourcePath + "/data/Dynamics/"
Upload-FilesFromFolder $containerName $SynapseDefaultADLSName $folderName $filePath

$folderName = "RAW/SAP/"
Create-FolderInContainer $containerName $SynapseDefaultADLSName $folderName

$filePath = $DataSourcePath + "/data/SAP/"
Upload-FilesFromFolder $containerName $SynapseDefaultADLSName $folderName $filePath

$folderName = "CDM/"
Create-FolderInContainer $containerName $SynapseDefaultADLSName $folderName

$filePath = $DataSourcePath + "/cdm/SAP/"
Upload-FilesFromFolder $containerName $SynapseDefaultADLSName $folderName $filePath

$folderName = "Data/"
Create-FolderInContainer $containerName $SynapseDefaultADLSName $folderName


##Americas Container and Folders

##sageworks container and its folders
$containerName = "sageworks"
Create-StorageContainer $containerName $AmericasADLSName

$folderName = "sageworks-sap/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "sageworks-sap/general-ledger/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "sageworks-sap/general-ledger/config/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "sageworks-sap/general-ledger/config/cdm-model/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "sageworks-sap/general-ledger/output/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "sageworks-sap/general-ledger/output/cdm/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "sageworks-sap/general-ledger/source/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "sageworks-sap/general-ledger/staging/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "sageworks-sap/general-ledger/staging/dataverse/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

##thirdpartydata container and its folders
$containerName = "thirdpartydata"
Create-StorageContainer $containerName $AmericasADLSName

$folderName = "taxidata/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "taxidata/nyctaxidata/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "taxidata/nyctaxidata/config/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "taxidata/nyctaxidata/config/cdm-model/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$filePath = $DataSourcePath + "/cdm/TaxiData/"
Upload-FilesFromFolder $containerName $AmericasADLSName $folderName $filePath

$folderName = "taxidata/nyctaxidata/output/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "taxidata/nyctaxidata/output/cdm/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "taxidata/nyctaxidata/output/cdm/nyctaximediumoutput/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "taxidata/nyctaxidata/output/cdm/nyctaxilargeoutput/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "taxidata/nyctaxidata/source/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "taxidata/nyctaxidata/staging/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

$folderName = "taxidata/nyctaxidata/staging/dataverse/"
Create-FolderInContainer $containerName $AmericasADLSName $folderName

##APAC Container and Folders

##Contoso container and its folders
$containerName = "contoso"
Create-StorageContainer $containerName $ApacADLSName

$folderName = "contoso-dynamics/"
Create-FolderInContainer $containerName $ApacADLSName $folderName

$folderName = "contoso-dynamics/general-ledger/"
Create-FolderInContainer $containerName $ApacADLSName $folderName

$folderName = "contoso-dynamics/general-ledger/config/"
Create-FolderInContainer $containerName $ApacADLSName $folderName

$folderName = "contoso-dynamics/general-ledger/config/cdm-model/"
Create-FolderInContainer $containerName $ApacADLSName $folderName

$filePath = $DataSourcePath + "/cdm/GeneralLedger/"
Upload-FilesFromFolder $containerName $ApacADLSName $folderName $filePath

$folderName = "contoso-dynamics/general-ledger/output/"
Create-FolderInContainer $containerName $ApacADLSName $folderName

$folderName = "contoso-dynamics/general-ledger/output/cdm/"
Create-FolderInContainer $containerName $ApacADLSName $folderName

$folderName = "contoso-dynamics/general-ledger/source/"
Create-FolderInContainer $containerName $ApacADLSName $folderName

$fileName = "General Journal.xlsx"
$filePath = $DataSourcePath + "/data/GeneralLedger/" + $fileName
Create-FileInFolder $containerName $ApacADLSName $folderName $fileName $filePath

$folderName = "contoso-dynamics/general-ledger/staging/"
Create-FolderInContainer $containerName $ApacADLSName $folderName

$folderName = "contoso-dynamics/general-ledger/staging/dataverse/"
Create-FolderInContainer $containerName $ApacADLSName $folderName
