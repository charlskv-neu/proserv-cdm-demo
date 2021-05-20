#Parameters needed by the script.
Param(     
    [Parameter(Mandatory=$True)]
    [string] $FilePath,
    [Parameter(Mandatory=$True)]
    [string] $ParameterName,
    [Parameter(Mandatory=$True)]
    [string] $ParameterValue
)

$filesToUpdate = Get-ChildItem -Path $FilePath -Recurse -Force
Write-Host "Retrieved files from source directory."
foreach ($file in $filesToUpdate)
{
    (Get-Content -Path $file.PSPath) | Foreach-Object -Process { $_ -replace "$ParameterName", $ParameterValue } | Set-Content -Path $file.PSPath   
}
Write-Host "Updated files in source directory."