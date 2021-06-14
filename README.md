# *ProServ Demo Handbook*


## *Prerequisites* : 
 - Azure Subscription with a Resource Group to deploy
 - User must have owner access to the resource group
 - [Download and install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli) the current release of the Azure CLI to run the deployment script. After the installation is complete, you will need to close and reopen any active Windows Command Prompt or PowerShell windows to use the Azure CLI.


## Collect data needed to run the scripts

Before you get started, copy and paste below variables in a text editor for later use.:


| Variable Name		       | Description	             					    | How to Get			      |
|----------------------------- | -------------------------------------------------------------------|------------------------------------------
|TenantID | Unique identifier (Tenant ID) of the Azure Active Directory instance | Azure portal -> Azure Active Directory -> Copy TenantId |
|SubscriptionId | Subscription Id where the deployment has to be done | Azure Portal -> Subscriptions ->  Select the subscription Name -> Copy Subscription ID |
|ResourceGroupName | Resource Group name where the deployment to be made | Azure Portal -> Copy Resource Group Name |
|SynapseWorkspaceName |	Synapse workspace name | A globally unique name with at most 50 characters long, must contain only lower-case letters, digits and hyphens but can not start or end with '-', and must not contain the string '-ondemand' anywhere in the name.
|SyanpseDefaultADLSName | Default ADLS Storage account name to be linked with Synapse. | A globally unique name with only lowercase letters and numbers. Name must be between 3 and 24 characters.

## Prepare starter kit and run the client-side setup scripts

1. [Download the starter kit](https://github.com/charlskv-neu/proserv-cdm-demo/tree/development) , and extract its contents to the location of your choice.

2. On your computer, enter **PowerShell** in the search box on the Windows taskbar. In the search list, right-click **Windows PowerShell**, and then select **Run as administrator**.


3. Use the following command to navigate to the directory where the setup script is residing in the Powershell IDE. Replace path-to-starter-kit with the folder path of the extracted Setup-ProServ-Demo-Environment.ps1 file.

	```powershell
	cd <path-to-starter-kit>
	dir -Path <path-to-starter-kit> -Recurse | Unblock-File
	```

4. Use the following command to run the setup kit. 

	- Replace the TenantID, SubscriptionID, ResourceGroupName, SynapseWorkspaceName and SyanpseDefaultADLSName placeholders using the data collected earlier.
	
	```powershell
	.\Setup-ProServ-Demo-Environment.ps1 -TenantId <TenantID> -SubscriptionId <SubscriptionId> -ResourceGroupName <ResourceGroupName> -SynapseWorkspaceName <SynapseWorkspaceName> -SyanpseDefaultADLSName <SyanpseDefaultADLSName>
	```
	
	- Complete the Azure login when prompted
	
5. Once the deployment is complete, verify the synapse and storage account are created. Also, confirm if the Synapse artifacts are deployed too.

## Share and Recieve data using Azure Data Share for demo

- Refer this [tutorial](https://docs.microsoft.com/en-us/azure/data-share/share-your-data?tabs=azure-portal) to share and recieve data using Azure Data Share for demo

***
