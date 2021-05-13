Param(     
    [Parameter(Mandatory=$True)]
    [string] $FilePath
)
$url = $FilePath + "\Data\Variables.json"
$PAT = ${env:DEVOPS_USER_PAT} #Destination Personal Access Token
$ORG = ${env:DEVOPS_ORG}
$PROJECT = ${env:DEVOPS_PROJECT}
$VARIABLE_GROUP_NAME = "Proserv-CDM-Demo-Variables"
Write-Output $ORG
Write-Output $PROJECT
Write-Output $PAT
Write-Output $VARIABLE_GROUP_NAME
$base64AuthInfo1 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
Write-Output $base64AuthInfo1
$destUrl = "https://dev.azure.com/$ORG/$PROJECT/_apis/distributedtask/variablegroups?api-version=5.1-preview.1"
Write-Output $destUrl
$body = Get-Content $url| out-string
Write-Output "3"
$body = $body.replace("<Variable_Group_Name>",$VARIABLE_GROUP_NAME)
Write-Output $body
Invoke-RestMethod -Uri $destUrl -Headers @{Authorization = "Basic {0}" -f $base64AuthInfo1} -ContentType "application/json"  -Method post -Body $body
