# ARI / Azure Resource Inventory – Deployment Guide


## 🧱 Schritt 1: Storage Account bereitstellen

Deploy über Azure Button:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSSIG-IT%2Fari-deployment%2Fmain%2Fstorage-account.json)

- Ressourcengruppe: `rg-ari-prod` (neu erstellen)
- Region: West Europe
- Name: `stariprod<firmenname>` (z. B. `stariprodmeba`)
- Bereitstellung abwarten


## ⚙️ Schritt 2: Automation Account bereitstellen

Deploy über Azure Button:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSSIG-IT%2Fari-deployment%2Fmain%2Fautomation-account.json)

- Ressourcengruppe: `rg-ari-prod`
- Region: West Europe
- Name: `aa-ari-prod`

**Hinweis:** Sicherstellen, dass folgende Ressourcenanbieter registriert sind:

- `Microsoft.Web`
- `Microsoft.Logic`


## 🔁 Schritt 3: Logic App bereitstellen

Deploy über Azure Button:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSSIG-IT%2Fari-deployment%2Fmain%2Flogic-app.json)

- Ressourcengruppe: `rg-ari-prod`
- Region: Germany West Central
- Name: `logic-ari-prod-blobemail`


## 🧩 Schritt 4: Logic App Workflow konfigurieren

**Logik-App öffnen > Designer starten > Automatisierung erstellen:**

### 1. Trigger: Beim Hinzufügen oder Ändern eines Blobs (V2)

- Authentifizierung: Microsoft Entra ID integrated
- Name/Endpunkt: `stariprod<firmenname>` (z. B. `stariprodmeba`)
- Container: `reports`

### 2. Aktion: Blobinhalt abrufen (V2)

- Name/Endpunkt: `stariprod<firmenname>`
- Blob: `reports/@{triggerBody()?['Name']}`
- Inhaltstyp erkennen: `Yes`

### 3. Managed Identity Verbindung

- Trigger auswählen > Verbindung ändern > verwaltete Identität
- Verbindung auch bei „Blobinhalt abrufen (V2)“ auswählen

**Hinweis:** Erst nach Speichern ist die Managed Identity sichtbar.

### 4. Aktion: E-Mail senden (V2)

- An: Empfängeradresse
- Betreff:
  ```
  ARI Monatlicher Report - @{formatDateTime(utcNow(),'yyyy-MM')}
  ```
- Text:
  ```
  Hallo,

  im Anhang finden Sie den monatlichen ARI Report für @{formatDateTime(utcNow(),'yyyy-MM')}.

  Bei Fragen oder Rückmeldungen stehen wir Ihnen gerne zur Verfügung.

  Viele Grüße  
  SSIG-IT Team
  ```

- Anhänge:
  ```json
  [
    {
      "Name": "@{triggerBody()?['Name']}",
      "ContentBytes": "@{body('Get_blob_content_(V2)')}"
    }
  ]
  ```

- Oben links auf "Speichern" klicken


## 🛡️ Schritt 5: Rollen zuweisen

PowerShell-Skript `setRolle.ps1` ausführen (Terminal oben rechts).


## 🧪 Schritt 6: PowerShell Runtime & Module konfigurieren

### Voraussetzungen

- Automation-Konto `aa-ari-prod` öffnen
- Option „Laufzeitumgebungsoberfläche testen“ aktivieren

### Runtime-Umgebung erstellen

- Name: `rt-ari-prod`
- Sprache: PowerShell
- Version: 7.4

**Module aus der Gallery importieren:**

- AzureResourceInventory  
- ImportExcel  
- Az.ResourceGraph  
- Az.Accounts  
- Az.Storage  
- Az.Compute  
- PowerShellGet  
- Microsoft.PowerShell.ThreadJob  
- Az.CostManagement

> Danach auf "Speichern" klicken


## 🧾 Schritt 7: PowerShell Runbook erstellen & konfigurieren

### Neues Runbook erstellen

- Name: `rb-ari-prod`
- Typ: PowerShell
- Laufzeit: `rt-ari-prod` auswählen

> „Bewerten + Erstellen“ > „Erstellen“ klicken

### Runbook-Skript einfügen

```powershell
Import-Module AzureResourceInventory

Invoke-ARI -TenantID "<DIE_TENANT_ID>" -Automation -SkipDiagram -SkipAPIs -StorageAccount "stariprod<firma>" -StorageContainer "reports"
```

- Skript speichern und veröffentlichen

**Testlauf durchführen, ob Mail zugestellt wird**

### Zeitplan einrichten

- Beispiel: monatlich, letzter Tag, 07:00 Uhr
