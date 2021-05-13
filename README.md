# *ProServ Demo Handbook*


## *Prerequisites* : 
 - Azure Subscription with a Resource Group to deploy
 - An Azure DevOps account with Organization name and Project name configured
 - Users must be added to the AD group which has owner access to the resource group
 
**Contents**
<!-- TOC -->
- [Task 1: Generating Personal Access Token(PAT)](#generating-personal-access-token)
- [Task 2: Creating Service Connection](#creating-service-connection)
- [Task 3: Running Pipelines](#running-pipelines)
  - [Install Synapse Workspace Deployment Extension](#install-synapse-workspace-deployment-extension)
  - [ProServ Demo Variables](#proserv-demo-variables)
    - [Variable Details](#variable-details) 
  - [ProServ Demo Infra and Code](#proserv-demo-infra-code)
- [Task 4: Power BI Configuration](#power-bi-config)

<!-- /TOC -->

***

<a name="generating-personal-access-token"/>

## *Generating Personal Access Token(PAT)*

Click User Settings and select Personal Access Tokens

![Personal Access Token](images/pat-1.PNG)

Click new Token and enter the name, check the organization name is reflecting correct, set the expiration date and select scopes as Full Access and then click on create

![New PAT Key](images/pat-2.PNG)

![Create New PAT Key](images/pat-3.PNG)

Remember to copy the name and pat key and paste it in notepad as it’s visible for one time only and it will be used during updation of library variables

![Generate Key](images/pat-4.PNG)

***

<a name="creating-service-connection"/>

## *Creating Service Connection*

Once organization and project are created, then service connection needs to be created

- Go to Project Settings

![Project Settings](images/service-con-1.PNG)

- Click service connection and then click New service connection and select Azure Resource Manage and then select Service Principal(automatic) and click next

![New Service Connection](images/service-con-2.PNG)

![New Service Connection](images/service-con-3.PNG)  ![New Service Connection](images/service-con-4.PNG)

- Select the option Subscription, azure subscription and then the resource group under that subscription, then give proper service connection name and then save

![Creating Service Connection](images/service-con-5.PNG)

- Once created, need to map that connection with the resource group. For that go under the service connection, click manage service principal and copy the name

![Map Service Connection with RG](images/service-con-6.PNG)

![Map Service Connection with RG](images/service-con-7.png)

- DevOps Secret Creation

![Certificate Creation](images/cert-1.PNG)

![Certificate Description](images/cert-2.PNG)

![Create Certificate](images/cert-3.PNG)

- After copying the service principal display name, go to the resource group, select Access control(IAM), then click Add and select Add role assignment and then paste the copied name under select field, select Role as “Owner” and save

![Map Service Connection with RG](images/service-con-8.PNG)

![Map Service Connection with RG](images/service-con-9.PNG)

***
<a name="running-pipelines"/>

## *Running Pipelines*

<a name="install-synapse-workspace-deployment-extension"/>

#### Install Synapse Workspace Deployment Extension

  - Go to Market place and type synapse workspace deployment extension
    
    ![Get extension](images/ext-1.PNG)
    
    ![Get extension](images/ext-2.PNG)
    
  - Click "Get if free"
  
    ![Select extension](images/ext-3.PNG)

  - Select "Organization" from dropdown and click install

    ![Install extension](images/ext-4.PNG)
    
*** 

<a name="proserv-demo-variables"/>

#### ProServ Demo Variables

  - Go To pipelines in ADO -> click new pipeline -> select Github Repo
    
    ![New Pipeline](images/sip-inf-1.PNG)
    
  - Then select the repository
    
    ![Select Repository](images/sip-inf-2.PNG)
    
  - Select “Existing Azure Pipelines YAML  file”. Select the branch from the dropdown and path of the yaml file and then continue
    
    ![Select Branch](images/sip-var-3.PNG)

  - In the review phase, click on “variables” and the click “New Variables”
    
    ![Select Variables](images/sip-var-4.PNG)
    
  - Now 4 variables needs to be created whose values will be passed as parameters. Remember to tick mark the “Let users override this value when running this pipeline” while         creating the variables
  
    | Variable Name | Description |
    |---------------|-------------|
    | DEVOPS_USER_PAT | PAT key which were copied in above step |
    | DEVOPS_ORG | From ADO, Mention the organization name in the value field ![Select Organisation](images/sip-var-9.PNG) |
    | DEVOPS_PROJECT | From ADO, Mention the project name in the value field ![Select Project](images/sip-var-10.PNG) |
    
    ![New Variables Creation](images/sip-var-5.PNG)  ![Create Repository](images/sip-var-6.PNG)
  
  - After click the dropdown and save
    
    ![Save Pipeline](images/sip-var-7.PNG)
  
  - Select Run pipeline and then Run
  
    ![Run Pipeline](images/sip-var-8.PNG)
    
  - Following the Step,  “Variable Group” will be created which will contain all the list of necessary variables
		and will be seen under Pipelines -> Library -> VariableGroupName
  
    ![Variable Group Name](images/sip-var-11.PNG)
    
  - Click the variable group and fill the variable accordingly  

***
<a name="variable-details"/>

## Variable Details

#### Populate Variables In Variable Group - Azure Portal : These variables needs to be populated in variable group from azure portal

| Variable Name		       | Description	             					    | How to Get			      |
|----------------------------- | -------------------------------------------------------------------|------------------------------------------
|AzureActiveDirectoryTenantID | Unique identifier (Tenant ID) of the Azure Active Directory instance | Azure portal -> Azure Active Directory -> Copy TenantId |
|AzureServiceConnectionName | Service connection name using which the deployment has to be done | ADO -> Project Settings -> Service Connection -> Copy Service Connection Name |
|ContributorADGroupObjectID | Object ID of contributor AD group to which Storage blob contributor access is provided. The person running this demo must be a member of this AD Group. | Azure portal -> Azure Active Directory -> groups -> Select AD group -> Copy Object Id |
|DevOpsApplicationClientID | DevOps Service Principal Application (client) ID. This is used to generate Bearer Token to invoke Synapse role assignment REST APIs. Note: It is not the Client Secret ID | ADO Project Settings -> Service Connection ->  Select Service Connection -> Manage Service Pricipal -> Copy Application (client) ID |
|DevOpsApplicationClientSecret | DevOps Service Principal Application Client Secret Value. This is used generating Bearer Token to invoke Synapse role assignment REST APIs | refer Creating Service Connection |
|ResourceGroupName | Resource Group name where the deployment to be made | Azure Portal -> Copy Resource Group Name |
|SubscriptionId | Subscription Id where the deployment has to be done | Azure Portal -> Subscriptions ->  Select the subscription Name -> Copy Subscription ID |
|SynapseWorkspaceAdminObjectID | Object ID of a valid user or security-enabled group (Eg: Azure-Synapse-WS-Admins) in Azure Active Directory | Keep it same value as ContributorADGroupObjectID |

#### Populate Variables In Variable Group - Manual Entry : These variables needs to be manually entered in variable group with proper name 

| Variable Name		       | Description							    | 
|----------------------------- | -------------------------------------------------------------------|
|SyanpseDefaultADLSFileSystemName | Dafualt ADLS Container name to be linked with Syanpse |
|SyanpseDefaultADLSName | Default ADLS Storage account name to be linked with Synapse |
|SynapseWorkspaceName |	Synapse workspace name. No dashes allowed |

***

<a name="proserv-demo-infra-code"/>

#### ProServ Demo Infra and Code
	
  - Go To pipelines in ADO -> click new pipeline -> select Github Repo
  	
     ![New Infra Pipeline](images/sip-inf-1.PNG)
	
  - Select the repository
    
     ![Select Repo](images/sip-inf-2.PNG)
    
  - Select “Existing Azure Pipelines YAML  file”. Select branch from the dropdown and path of the yaml file and then continue
     
     ![Select Existing Pipeline](images/sip-inf-3.PNG)
     
  - Then click save from the dropdown
  
     ![Save Pipeline](images/sip-inf-6.PNG)
  
  - Now we have to link the Variable group with the pipeline. For that Click “Edit” and then go to more actions and select triggers
     
     ![Select Edit](images/sip-inf-7.PNG)  ![Select Triggers](images/sip-inf-8.PNG)
     
  - Then select Variable -> Variable Groups -> Link variable group -> select your variable group -> Link
     
     ![Link Variable Group](images/sip-inf-9.PNG)
     
  - Once Linked, click save from dropdown and run the pipeline
     
     ![Save Trigger](images/sip-inf-10.PNG)
     
     ![Run Pipeline](images/sip-inf-11.PNG)
     
  - After the pipeline has ran successfully, go to portal.azure.com and check under resouce group whether the resources has been created or not. 3 resources will get created – 
    - Storage Account
    - Synapse Workspace

    ![Resource Created](images/sip-inf-12.png)

   - Also, access synapse workspace and check whether adf pipeline, dataflow and linked services are created or not

	 ![Open Workspace](images/sip-code-12.png)  ![Click Open](images/sip-code-14.PNG)  ![ADF Pipeline](images/sip-code-15.PNG)  ![ADF Linked Services](images/sip-code-16.PNG)

   - Then enable the Dataflow debug and run the adf pipelines once it is enabled.
   
   - Once the pipeline is successful, verify that the data files are created in the models container under the data foler
   
	 ![Verify Data](images/sip-code-17.png)

 
 
<a name="power-bi-config"/>

#### Power BI Configuration
 
  - Publish PBIX file available under "proserv-cdm-demo-power-bi" folder to PowerBI workspace
  
  - Access PowerBI worksapce and verify both report and dataset are available
     ![Open Workspace](images/pbi-1.png)
  
  - Go to dataset settings
     ![Dataset Settings](images/pbi-2.png)
  
  - Expand Parameters
     ![Parameters](images/pbi-3.png)
  
  - Copy dfs url of data folder under models container from storage account and paste it for CDMSource parameter in above screen
     ![DFS URL](images/pbi-4.png)
  
  - Expand Datasource credentials under dataset settings and click Edit Credentials
     ![Datasource Credentials](images/pbi-5.png)
  
  - Select OAuth2, and login to Azure once prompted.
     ![Azure Login](images/pbi-6.png)
  
  - Go back to PowerBI workspace, and refresh the dataset. Wait for the refresh to complete; once dataset refresh is done open the report and refresh.
     
     ![Refresh Dataset](images/pbi-7.png)
