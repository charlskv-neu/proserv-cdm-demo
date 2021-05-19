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

$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $SyanpseDefaultADLSName
$ctx = $storageAccount.Context

Function Create-StorageContainer($containerName, $ctx)
{
    if(Get-AzStorageContainer -Name $containerName -Context $ctx -ErrorAction SilentlyContinue)  
    {  
        Write-Host $containerName "- container already exists."  
    }  
    else  
    { 
        New-AzStorageContainer -Name $containerName -Context $ctx -Permission off
        Write-Host "Created container "$containerName
    }
}

Function Create-FolderInContainer($containerName, $ctx, $folderName)
{
    if(Get-AzDataLakeGen2Item -FileSystem $containerName -Path $folderName -Context $ctx -ErrorAction SilentlyContinue)  
    {  
        Write-Host $folderName "- folder already exists."  
    }  
    else  
    {              
        New-AzDataLakeGen2Item -Context $ctx -FileSystem $containerName -Path $folderName -Directory
        Write-Host "Created folder "$folderName
    }
}

Function Create-FileInFolder($containerName, $ctx, $folderName, $fileName, $filePath)
{
    $finalPath = $folderName + $fileName
    if(Get-AzDataLakeGen2Item -FileSystem $containerName -Path $finalPath -Context $ctx -ErrorAction SilentlyContinue)  
    {  
        Write-Host $fileName "- file already exists."  
    }  
    else  
    {              
        New-AzDataLakeGen2Item -Context $ctx -FileSystem $containerName -Path $finalPath -Source $filePath -Force
        Write-Host "Created file "$fileName" inside "$folderName
    }
}

$containerName = "crmdynamics"
Create-StorageContainer $containerName $ctx
$folderName = ""
$fileName = "General Journal.xlsx"
$filePath = $DataSourcePath + "\data\Dynamics\" + $fileName
Create-FileInFolder $containerName $ctx $folderName $fileName $filePath

$containerName = "models"
Create-StorageContainer $containerName $ctx
$folderName = "cdm/"
Create-FolderInContainer $containerName $ctx $folderName
$fileName = "_allImports.cdm.json"
$filePath = $DataSourcePath + "\cdm\GeneralLedger\" + $fileName
Create-FileInFolder $containerName $ctx $folderName $fileName $filePath
$fileName = "GeneralJournal.cdm.json"
$filePath = $DataSourcePath + "\cdm\GeneralLedger\" + $fileName
Create-FileInFolder $containerName $ctx $folderName $fileName $filePath
$fileName = "GeneralLedger.manifest.cdm.json"
$filePath = $DataSourcePath + "\cdm\GeneralLedger\" + $fileName
Create-FileInFolder $containerName $ctx $folderName $fileName $filePath
$folderName = "data/"
Create-FolderInContainer $containerName $ctx $folderName