#Parameters needed by the script .
Param(
    [Parameter(Mandatory=$True)]
    [string] $ResourceGroupName,
    [Parameter(Mandatory=$True)]
    [string] $SyanpseDefaultADLSName,
    [Parameter(Mandatory=$True)]
    [string] $SyanpseDefaultADLSFileSystemName,
    [Parameter(Mandatory=$True)]
    [string] $DataSourcePath
)

$storageAccount = az storage account show --resource-group $ResourceGroupName --name $SyanpseDefaultADLSName --only-show-errors

Function Create-StorageContainer($containerName, $syanpseDefaultADLSName)
{
    $container = az storage container show --name $containerName --account-name $syanpseDefaultADLSName --only-show-errors
    if($container)  
    {  
        Write-Host "$containerName - container already exists."
    }  
    else  
    { 
        az storage container create --name $containerName --account-name $syanpseDefaultADLSName --public-access off --only-show-errors --output none
        if (!$?) {
            throw "An error occurred while creating container."
        }
        else {
            Write-Host "Created container $containerName ."
        }        
    }
}
Function Create-FolderInContainer($containerName, $syanpseDefaultADLSName, $folderName)
{
    $folder = az storage fs directory show --file-system $containerName --name $folderName --account-name $syanpseDefaultADLSName --only-show-errors
    if($folder)  
    {  
        Write-Host "$folderName - folder already exists."
    }  
    else  
    {              
        az storage fs directory create --account-name $syanpseDefaultADLSName --file-system $containerName --name $folderName --only-show-errors --output none
        if (!$?) {
            throw "An error occurred while creating folder."
        }
        else {
            Write-Host "Created folder $folderName ."
        }        
    }
}
Function Create-FileInFolder($containerName, $syanpseDefaultADLSName, $folderName, $fileName, $filePath)
{
    $finalPath = $folderName + $fileName
    $file = az storage fs file show --file-system $containerName --path $finalPath --account-name $syanpseDefaultADLSName --only-show-errors
    if($file)  
    {  
        Write-Host "$fileName - file already exists."
    }  
    else  
    {              
        az storage fs file upload --account-name $syanpseDefaultADLSName --file-system $containerName --path $finalPath --source $filePath --only-show-errors --output none
        if (!$?) {
            throw "An error occurred while creating file."
        }
        else {
            Write-Host "Created file $fileName inside $folderName ."
        }        
    }
}
Function Upload-FilesFromFolder($containerName, $syanpseDefaultADLSName, $folderName, $folderPath)
{
    $filesToUpload = Get-ChildItem -Path $folderPath
    for ($i=0; $i -lt $filesToUpload.Count; $i++) {
        $fileName = $filesToUpload[$i].Name
        $filePath = $folderPath +$fileName
        Create-FileInFolder $containerName $SyanpseDefaultADLSName $folderName $fileName $filePath
    }
}

$containerName = "cdmtaxidata"
Create-StorageContainer $containerName $SyanpseDefaultADLSName

$containerName = "staging"
Create-StorageContainer $containerName $SyanpseDefaultADLSName

$containerName = "crmdynamics"
Create-StorageContainer $containerName $SyanpseDefaultADLSName

$folderName = ""
$fileName = "General Journal.xlsx"
$filePath = $DataSourcePath + "/data/Dynamics/" + $fileName
Create-FileInFolder $containerName $SyanpseDefaultADLSName $folderName $fileName $filePath

$containerName = "models"
Create-StorageContainer $containerName $SyanpseDefaultADLSName

$folderName = "gldata/"
Create-FolderInContainer $containerName $SyanpseDefaultADLSName $folderName

$folderName = "gldata/cdm-model/"
Create-FolderInContainer $containerName $SyanpseDefaultADLSName $folderName
$filePath = $DataSourcePath + "/cdm/GeneralLedger/"
Upload-FilesFromFolder $containerName $SyanpseDefaultADLSName $folderName $filePath

$folderName = "gldata/glsmalloutput/"
Create-FolderInContainer $containerName $SyanpseDefaultADLSName $folderName

$folderName = "taxidata/"
Create-FolderInContainer $containerName $SyanpseDefaultADLSName $folderName

$folderName = "taxidata/cdm-model/"
Create-FolderInContainer $containerName $SyanpseDefaultADLSName $folderName
$filePath = $DataSourcePath + "/cdm/TaxiData/"
Upload-FilesFromFolder $containerName $SyanpseDefaultADLSName $folderName $filePath

$folderName = "taxidata/nyctaxilargeoutput/"
Create-FolderInContainer $containerName $SyanpseDefaultADLSName $folderName

$folderName = "taxidata/nyctaximediumoutput/"
Create-FolderInContainer $containerName $SyanpseDefaultADLSName $folderName