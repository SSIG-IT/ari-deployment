# ARI / Azure Resource Inventory – Deployment Guide

# Step 1: Deploy Storage Account
Deploy the Storage Account using the button below

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSSIG-IT%2Fari-deployment%2Fmain%2Fstorage-account.json)



# Step 2: Deploy Automation Account
Deploy the Automation Account using the button below:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSSIG-IT%2Fari-deployment%2Fmain%2Fautomation-account.json)



# Step 3: Deploy Logic App
Deploy the Logic App using the button below:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSSIG-IT%2Fari-deployment%2Fmain%2Flogic-app.json)



# Step 4: Assign Required Roles
After deployment, you must assign the required roles so that the Automation Account and Logic App can access the Storage Account.

Simply use the script setRolle.ps1 to automatically assign all roles.


Assign Reader at Subscription level to your Automation Account

Assign Storage Blob Data Contributor on the Storage Account to both your Automation Account and Logic App

Make sure to adjust the parameters inside the script as needed.

# Step 5: Configure PowerShell Runtime & Import Modules
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

# Step 6: Create and Configure PowerShell Runbook
In the Automation Account, go to Runbooks → Create new runbook:

Name: e.g. rb-ari-prod

Type: PowerShell (use the Runtime Environment you created)

Paste this script and adjust Tenant ID and Storage Account as needed:

Import-Module AzureResourceInventory

Invoke-ARI -TenantID "<YOUR_TENANT_ID>" -Automation -SkipDiagram -SkipAPIs -StorageAccount "stariprodCompany" -StorageContainer "reports"

Save and publish the runbook.

Create a schedule to run monthly (e.g., last day, 07:00 AM).


