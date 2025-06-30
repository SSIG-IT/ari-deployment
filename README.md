# ARI / Azure Resource Inventory – Deployment Guide

# Step 1: Deploy Storage Account
Deploy the Storage Account using the button below

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSSIG-IT%2Fari-deployment%2Fmain%2Fstorage-account.json)



# Step 2: Deploy Automation Account
Deploy the Automation Account using the button below:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSSIG-IT%2Fari-deployment%2Fmain%2Fautomation-account.json)

Make sure Microsoft.Web and Microsoft.Logic are registered in your subscription before you deploy!




# Step 3: Deploy Logic App
Deploy the Logic App using the button below:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSSIG-IT%2Fari-deployment%2Fmain%2Flogic-app.json)


# step 4: Configure the Logic App Workflow
After deploying the Logic App ARM template, you need to manually configure the workflow to connect it to your Storage Account and email action.

1. Add the Trigger: When a blob is added or modified (properties only) (V2)
Search for "When a blob is added or modified (properties only) (V2)" in the Logic App designer and add it as the first trigger.

Storage Account Name or Blob Endpoint:
Enter your storage account prefix (e.g. stariprod).

Tip: You can use the account name, not the full endpoint.

Container:
Enter /reports (including the slash).


Example: Storage Account = stariprod, Container = /reports

2. Add the Action: Get blob content (V2)
Click the "+" sign below your trigger and search for "Get blob content (V2)".

Storage Account Name or Blob Endpoint:
Enter the same storage account (e.g. stariprod).

Blob:
Enter: reports/@{triggerBody()?['Name']}
In the designer, select reports/ and then insert the dynamic value List of Files Name from the previous trigger.

Infer Content Type:
Set to Yes (default).


Example: Blob = reports/@{triggerBody()?['Name']}

Set Managed Identity Connections
After deploying the Logic App Design, follow these steps to finalize the workflow configuration:

For both the trigger and the first action (typically "When a blob is added or modified (properties only)" and "Get blob content (V2)"):

Click on the connection field.

Click "Add new connection".

Set Authentication Type to "Logic Apps Managed Identity".

Important: Use the same connection for both steps!

Save the workflow after updating both connections.

Note: Only after saving the workflow with the Managed Identity connection, the Managed Identity will be visible in Azure and you can assign the necessary permissions to the Storage Account.

3. Add the Action: Send an email (V2)
Click the "+" sign below your previous action and search for "Send an email (V2)" (from the Outlook/Office 365 connector).

To:
email eingeben

Subject:
ARI Monatlicher Report - @{formatDateTime(utcNow(),'yyyy-MM')}

Body:

Hallo,

im Anhang finden Sie den monatlichen ARI Report für @{formatDateTime(utcNow(),'yyyy-MM')}

Bei Fragen oder Rückmeldungen stehen wir Ihnen gerne zur Verfügung.

Viele Grüße
SSIG-IT Team
Attachments:

Click "Add new parameter" and check "Attachments".
Enter:

[
  {
    "Name": "@{triggerBody()?['Name']}",
    "ContentBytes": "@{body('Get_blob_content_(V2)')}"
  }
]


# Step 5: Assign Required Roles
After deployment, you must assign the required roles so that the Automation Account and Logic App can access the Storage Account.

Simply use the script setRolle.ps1 to automatically assign all roles.


Assign Reader at Subscription level to your Automation Account

Assign Storage Blob Data Contributor on the Storage Account to both your Automation Account and Logic App

Make sure to adjust the parameters inside the script as needed.

# Step 6: Configure PowerShell Runtime & Import Modules

Important:
Before you can create custom PowerShell runtime environments, you must activate the "Test Run Environment" feature in your Automation Account.
Go to your Automation Account, open the Overview page (left menu), and enable "Test Run Environment" ("Laufzeitumgebungsoberfläche testen") at the top if it is not already enabled.
Without this, you will not be able to add PowerShell 7.x runtimes!

In the Automation Account:
Go to Runtime environments and create a new Runtime Environment (e.g., PowerShell 7.4).

Import the following modules from the Gallery:

AzureResourceInventory

ImportExcel

Az.ResourceGraph

Az.Accounts

Az.Storage

Az.Compute

PowerShellGet

Microsoft.PowerShell.ThreadJob

(Optional: Az.CostManagement if you use -IncludeCosts)

# Step 7: Create and Configure PowerShell Runbook
In the Automation Account, go to Runbooks → Create new runbook:

Name: e.g. rb-ari-prod

Type: PowerShell (use the Runtime Environment you created)

Paste this script and adjust Tenant ID and Storage Account as needed:

Import-Module AzureResourceInventory

Invoke-ARI -TenantID "<YOUR_TENANT_ID>" -Automation -SkipDiagram -SkipAPIs -StorageAccount "stariprodCompany" -StorageContainer "reports"

Save and publish the runbook.

Create a schedule to run monthly (e.g., last day, 07:00 AM).


