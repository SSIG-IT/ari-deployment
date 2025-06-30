# ===============================
# PARAMETER
# ===============================
$resourceGroupName = "rg-ari-prod"
$automationAccountName = "aa-ari-prod"
$logicAppName = "logic-ari-prod-blobemail"
$storagePrefix = "stariprod"

# Subscription automatisch setzen
$subscriptionId = (Get-AzContext).Subscription.Id

# ===============================
# STORAGE ACCOUNT via Präfix suchen
# ===============================
$storageAccount = Get-AzStorageAccount |
    Where-Object { $_.StorageAccountName -like "$storagePrefix*" -and $_.ResourceGroupName -eq $resourceGroupName } |
    Select-Object -First 1

if (-not $storageAccount) {
    Write-Error "❌ Kein Storage Account mit Prefix '$storagePrefix' in RG '$resourceGroupName' gefunden."
    exit 1
}

$storageAccountName = $storageAccount.StorageAccountName
Write-Host "✅ Gefundener Storage Account: $storageAccountName"

# Rollenzuweisungs-Scope für Storage
$scopeStorage = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
$scopeSubscription = "/subscriptions/$subscriptionId"

# ===============================
# AUTOMATION ACCOUNT: Identity ermitteln
# ===============================
$automationIdentity = (Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -Name $automationAccountName).Identity.PrincipalId

if (-not $automationIdentity) {
    Write-Error "❌ Automation Account hat keine System Managed Identity. Bitte im Portal aktivieren."
    exit 1
}

Write-Host "`n➡️ Berechtigungen für Automation Account: $automationAccountName"

# Rollen prüfen
$roleReader = Get-AzRoleDefinition -Name "Reader"
$roleStorage = Get-AzRoleDefinition -Name "Storage Blob Data Contributor"

if (-not $roleReader -or -not $roleStorage) {
    Write-Error "❌ Rollen konnten nicht gefunden werden. Prüfe 'Reader' und 'Storage Blob Data Contributor'."
    exit 1
}

# Rollen zuweisen
New-AzRoleAssignment -ObjectId $automationIdentity `
                     -RoleDefinitionName "Reader" `
                     -Scope $scopeSubscription

New-AzRoleAssignment -ObjectId $automationIdentity `
                     -RoleDefinitionName "Storage Blob Data Contributor" `
                     -Scope $scopeStorage

Write-Host "✅ Automation Account Berechtigungen abgeschlossen."

# ===============================
# LOGIC APP: Identity ermitteln
# ===============================
Write-Host "`n➡️ Berechtigungen für Logic App: $logicAppName"

$logicApp = Get-AzResource -ResourceType "Microsoft.Logic/workflows" `
                           -ResourceGroupName $resourceGroupName `
                           -Name $logicAppName

$logicAppPrincipalId = $logicApp.Identity.PrincipalId

if (-not $logicAppPrincipalId) {
    Write-Error "❌ Logic App hat keine System Managed Identity. Bitte im Portal aktivieren."
    exit 1
}

# Rollenzuweisung durchführen
New-AzRoleAssignment -ObjectId $logicAppPrincipalId `
                     -RoleDefinitionName "Storage Blob Data Contributor" `
                     -Scope $scopeStorage

Write-Host "✅ Logic App Berechtigungen abgeschlossen."