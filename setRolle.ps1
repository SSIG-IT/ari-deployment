# -------------------------------
# Parameter ggf. anpassen
# -------------------------------
$resourceGroupName   = "rg-ari-prod"
$automationAccount   = "aa-ari-prod"
$logicAppName        = "logic-ari-prod-blobemail"
$storagePrefix       = "stariprod"      # Prefix für Storage Account
# -------------------------------

# Login, falls nötig
if (-not (Get-AzContext)) { Connect-AzAccount }

# Subscription auslesen
$subscriptionId = (Get-AzContext).Subscription.Id

# Storage Account dynamisch suchen
$storageAccounts = Get-AzStorageAccount -ResourceGroupName $resourceGroupName | Where-Object { $_.StorageAccountName -like "$storagePrefix*" }

if ($storageAccounts.Count -eq 1) {
    $storageAccountName = $storageAccounts.StorageAccountName
    Write-Host "Gefundener Storage Account: $storageAccountName"
} elseif ($storageAccounts.Count -gt 1) {
    Write-Host "Mehrere Storage Accounts gefunden, bitte auswählen:"
    $storageAccountName = $storageAccounts | Select-Object -ExpandProperty StorageAccountName | Out-GridView -Title "Storage Account auswählen" -PassThru
} else {
    throw "Kein Storage Account gefunden, der mit '$storagePrefix' beginnt!"
}

# Storage Account ResourceId
$stg = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
$storageId = $stg.Id

# 1. Automation Account Objekt holen + Managed Identity
$aa = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -Name $automationAccount
$aaId = $aa.Identity.PrincipalId

# 2. Logic App Managed Identity holen
$logicApp = Get-AzResource -ResourceType 'Microsoft.Logic/workflows' -ResourceGroupName $resourceGroupName -Name $logicAppName
$logicAppId = $null

# Bis zu 10 Versuche, falls die Managed Identity noch nicht provisioniert ist
for ($i = 0; $i -lt 10; $i++) {
    $logicAppId = $logicApp.Properties.identity.principalId
    if ($logicAppId) { break }
    Write-Host "Managed Identity ObjectId der Logic App noch nicht verfügbar – warte 15 Sekunden..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    $logicApp = Get-AzResource -ResourceType 'Microsoft.Logic/workflows' -ResourceGroupName $resourceGroupName -Name $logicAppName
}

if (-not $logicAppId) {
    throw "ObjectId der Logic App konnte nicht ermittelt werden! Bitte überprüfe die Identität im Portal."
} else {
    Write-Host "ObjectId der Managed Identity gefunden: $logicAppId" -ForegroundColor Green
}

# 3. Role Definition Ids
$readerRole = Get-AzRoleDefinition -Name "Reader"
$blobContributorRole = Get-AzRoleDefinition -Name "Storage Blob Data Contributor"

# 4. Reader auf Subscription für Automation Account
try {
    New-AzRoleAssignment -ObjectId $aaId -RoleDefinitionId $readerRole.Id -Scope "/subscriptions/$subscriptionId" -ErrorAction Stop
    Write-Host "Reader-Role für Automation Account zugewiesen." -ForegroundColor Green
} catch { Write-Host "Reader-Role evtl. schon zugewiesen: $_" -ForegroundColor Yellow }

# 5. Storage Blob Data Contributor auf Storage für Automation Account
try {
    New-AzRoleAssignment -ObjectId $aaId -RoleDefinitionId $blobContributorRole.Id -Scope $storageId -ErrorAction Stop
    Write-Host "Storage Blob Data Contributor für Automation Account zugewiesen." -ForegroundColor Green
} catch { Write-Host "Blob Data Contributor für AA evtl. schon zugewiesen: $_" -ForegroundColor Yellow }

# 6. Storage Blob Data Contributor auf Storage für Logic App
try {
    New-AzRoleAssignment -ObjectId $logicAppId -RoleDefinitionId $blobContributorRole.Id -Scope $storageId -ErrorAction Stop
    Write-Host "Storage Blob Data Contributor für Logic App zugewiesen." -ForegroundColor Green
} catch { Write-Host "Blob Data Contributor für Logic App evtl. schon zugewiesen: $_" -ForegroundColor Yellow }

Write-Host "`nAlle Rollen erfolgreich zugewiesen!" -ForegroundColor Cyan
