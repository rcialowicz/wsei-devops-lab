# Laboratorium 7 – Monitoring i Logi

## Prerekwizyty
1. **Subskrypcja Azure**
2. **Azure CLI**

---

## 📋 Struktura laboratorium

W tym laboratorium nauczysz się:
1. ✅ Deployować aplikację z gotowego obrazu Docker
2. ✅ Konfigurować Application Insights w Azure Portal
3. ✅ Testować aplikację i generować dane telemetryczne
4. ✅ Używać KQL (Kusto Query Language) do analizy logów
5. ✅ Tworzyć dashboardy i wizualizacje w Azure Portal
6. ✅ Konfigurować alerty na metryki i błędy

---

## Przygotowanie infrastruktury Azure

**ℹ️ Informacje od prowadzącego:**
- ACR Name: `<prowadzący poda>`
- Docker Image: `<prowadzący poda>` (np. `acrobcialab7.azurecr.io/monitoring-demo:v1`)
- ACR Password: `<prowadzący poda>`

### 0.1 Zaloguj się do Azure CLI

```powershell
az login
az account show
az account set --subscription "<your-subscription-id>"
```

### 0.2 Utwórz Resource Group

```powershell
$NAZWISKO = "kowalski"  # ZMIEŃ
$RESOURCE_GROUP = "rg-$NAZWISKO-lab7"
$LOCATION = "germanywestcentral"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 0.3 Utwórz Application Insights

```powershell
$APP_INSIGHTS_NAME = "appi-$NAZWISKO-lab7"

# Najpierw utwórz Log Analytics Workspace
$WORKSPACE_NAME = "law-$NAZWISKO-lab7"

az monitor log-analytics workspace create `
  --resource-group $RESOURCE_GROUP `
  --workspace-name $WORKSPACE_NAME `
  --location $LOCATION

# Pobierz Workspace ID
$WORKSPACE_ID = az monitor log-analytics workspace show `
  --resource-group $RESOURCE_GROUP `
  --workspace-name $WORKSPACE_NAME `
  --query id -o tsv

# Utwórz Application Insights połączony z Workspace
az monitor app-insights component create `
  --app $APP_INSIGHTS_NAME `
  --location $LOCATION `
  --resource-group $RESOURCE_GROUP `
  --workspace $WORKSPACE_ID

# Pobierz Connection String (będzie potrzebny w aplikacji)
$CONNECTION_STRING = az monitor app-insights component show `
  --app $APP_INSIGHTS_NAME `
  --resource-group $RESOURCE_GROUP `
  --query connectionString -o tsv

Write-Host "Application Insights Connection String:" -ForegroundColor Green
Write-Host $CONNECTION_STRING

```

---

## Ćwiczenie 1 – Deployment aplikacji do Azure Web App

**Cel:** Wdrożyć gotową aplikację z obrazu Docker do Azure Web App

### 1.1 Pobierz dane od prowadzącego

Prowadzący poda:
- **ACR Name:** np. `acrobcialab7`
- **Image Name:** np. `acrobcialab7.azurecr.io/monitoring-demo:v1`
- **ACR Password:** hasło do registry

```powershell
# Ustaw zmienne (ZMIEŃ wartości na te podane przez prowadzącego)
$ACR_NAME = "acrrcilab7"
$DOCKER_IMAGE = "$ACR_NAME.azurecr.io/monitoring-demo:v1"
$ACR_PASSWORD = "<haslo-podane-przez-prowadzacego>"
```

### 1.2 Utwórz App Service Plan (F1 - Free Tier)

```powershell
$APP_PLAN = "plan-$NAZWISKO-lab7"

az appservice plan create `
  --name $APP_PLAN `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --is-linux `
  --sku F1
```

### 1.3 Utwórz Web App z kontenerem Docker

```powershell
$APP_NAME = "app-$NAZWISKO-lab7"

az webapp create `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --plan $APP_PLAN `
  --deployment-container-image-name $DOCKER_IMAGE

# Skonfiguruj dostęp do ACR (private registry)
az webapp config container set `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --docker-custom-image-name $DOCKER_IMAGE `
  --docker-registry-server-url "https://$ACR_NAME.azurecr.io" `
  --docker-registry-server-user $ACR_NAME `
  --docker-registry-server-password $ACR_PASSWORD
```

### 1.4 Skonfiguruj Application Insights connection string

```powershell
# Ustaw connection string jako environment variable
az webapp config appsettings set `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --settings "ApplicationInsights__ConnectionString=$CONNECTION_STRING"

az webapp config appsettings set `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --settings "WEBSITES_PORT=8080"
```

### 1.5 Pobierz URL aplikacji

```powershell
$APP_URL = az webapp show `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --query defaultHostName -o tsv

Write-Host "`n✅ Application deployed!" -ForegroundColor Green
Write-Host "URL: https://$APP_URL" -ForegroundColor Cyan
Write-Host "Swagger: https://$APP_URL/swagger" -ForegroundColor Cyan

# Test health endpoint
Write-Host "\nTesting health endpoint..." -ForegroundColor Yellow
Start-Sleep -Seconds 30  # Poczekaj na start aplikacji
Invoke-WebRequest "https://$APP_URL/health" -UseBasicParsing
```

---

## Ćwiczenie 2 – Konfiguracja Application Insights w Azure Portal

**Cel:** Skonfigurować i poznać interfejs Application Insights w Azure Portal

### 2.1 Otwórz Application Insights

1. Zaloguj się do [Azure Portal](https://portal.azure.com)
2. Przejdź do Resource Group: `rg-<nazwisko>-lab7`
3. Kliknij na `appi-<nazwisko>-lab7`

### 2.2 Przegląd głównych sekcji

**Overview (Przegląd):**
- Failed requests
- Server response time
- Server requests
- Availability

**Live Metrics:**
- Real-time monitoring
- Live request rate
- Live failures
- Server metrics (CPU, Memory)

💡 **Zadanie:** Otwórz **Live Metrics** i zostaw otwarte w osobnej karcie - zobaczysz dane w czasie rzeczywistym!

### 2.3 Skonfiguruj Search

1. W Application Insights wybierz **Search** (w sekcji Investigate)
2. Ustaw time range: **Last 30 minutes**
3. Zobaczysz:
   - **Requests** - HTTP calls
   - **Dependencies** - External calls (jeśli są)
   - **Exceptions** - Błędy
   - **Traces** - Custom logs

### 2.4 Włącz Application Map

1. Wybierz **Application Map** (w sekcji Investigate)
2. Zobaczysz wizualizację:
   - Twoja aplikacja (okrąg)
   - Zależności (jeśli są)
   - Request rate i failure rate

---

## Ćwiczenie 3 – Testowanie aplikacji i generowanie telemetrii

**Cel:** Wygenerować dane w Application Insights przez testowanie aplikacji

**💡 Pamiętaj:** Live Metrics powinny być otwarte w osobnej karcie!

### 3.1 Podstawowe testy endpointów

```powershell
# 1. Health check
Invoke-WebRequest "https://$APP_URL/health" -UseBasicParsing

# 2. Get products
Invoke-WebRequest "https://$APP_URL/api/products" -UseBasicParsing

# 3. Get product by ID (sukces)
Invoke-WebRequest "https://$APP_URL/api/products/1" -UseBasicParsing

# 4. Get product by ID (not found - 404)
Invoke-WebRequest "https://$APP_URL/api/products/999" -UseBasicParsing

# 5. Swagger UI (otwórz w przeglądarce)
Write-Host "Swagger UI: https://$APP_URL/swagger" -ForegroundColor Cyan
```

### 3.2 Generowanie ruchu (pętla)

```powershell
# Wygeneruj 50 requestów do różnych endpointów
1..50 | ForEach-Object {
    $endpoint = switch (Get-Random -Minimum 1 -Maximum 5) {
        1 { "/health" }
        2 { "/api/products" }
        3 { "/api/products/$(Get-Random -Minimum 1 -Maximum 5)" }
        default { "/api/products" }
    }
    
    Write-Host "Request $_ : $endpoint"
    try {
        Invoke-WebRequest -Uri "https://$APP_URL$endpoint" -UseBasicParsing | Out-Null
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Start-Sleep -Milliseconds 300
}

Write-Host "`nGenerated 50 requests" -ForegroundColor Green
```

### 3.3 Testowanie zamówień (Custom Events)

```powershell
# Sukces - wygeneruj 10 pomyślnych zamówień
1..10 | ForEach-Object {
    $order = @{
        productId = Get-Random -Minimum 1 -Maximum 4
        quantity = Get-Random -Minimum 1 -Maximum 50
        customerEmail = "student$_@example.com"
    } | ConvertTo-Json

    Write-Host "Creating order $_..."
    Invoke-WebRequest -Uri "https://$APP_URL/api/orders" `
        -Method POST `
        -ContentType "application/json" `
        -Body $order `
        -UseBasicParsing | Out-Null
}

Write-Host "`nCreated 10 successful orders" -ForegroundColor Green

# Błąd - wygeneruj 5 zamówień które zawodzą (out of stock)
1..5 | ForEach-Object {
    $order = @{
        productId = Get-Random -Minimum 1 -Maximum 4
        quantity = Get-Random -Minimum 150 -Maximum 200
    } | ConvertTo-Json

    Write-Host "Creating failed order $_..."
    try {
        Invoke-WebRequest -Uri "https://$APP_URL/api/orders" `
            -Method POST `
            -ContentType "application/json" `
            -Body $order `
            -UseBasicParsing -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "Expected error: Out of stock" -ForegroundColor Yellow
    }
}

Write-Host "`nCreated 5 failed orders (out of stock)" -ForegroundColor Green
```

### 3.4 Generowanie błędów (dla alertów)

```powershell
# Wygeneruj kilka wyjątków
1..10 | ForEach-Object {
    Write-Host "Triggering error $_..."
    try {
        Invoke-WebRequest -Uri "https://$APP_URL/api/crash" -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
    } catch {
        # Expected - ignore
    }
    Start-Sleep -Milliseconds 300
}

Write-Host "`n✅ Test data generated!" -ForegroundColor Green
Write-Host "Wait 2-3 minutes for data to appear in Application Insights" -ForegroundColor Yellow
```

---

## Ćwiczenie 4 – Analiza logów w Application Insights

**Cel:** Nauczyć się używać KQL do analizy logów

### 4.1 Otwórz Application Insights w Azure Portal

1. Zaloguj się do [Azure Portal](https://portal.azure.com)
2. Przejdź do Resource Group: `rg-<nazwisko>-lab7`
3. Kliknij na `appi-<nazwisko>-lab7`
4. Po lewej stronie wybierz **Logs** (w sekcji Monitoring)

### 4.2 Podstawowe zapytania KQL

**Zapytanie 1: Wszystkie requesty z ostatniej godziny**

```kql
requests
| where timestamp > ago(1h)
| project timestamp, name, url, resultCode, duration
| order by timestamp desc
| take 50
```

**Zapytanie 3: Najwolniejsze endpointy (p95 latency)**

```kql
requests
| where timestamp > ago(1h)
| summarize 
    Count = count(), 
    AvgDuration = avg(duration), 
    P95Duration = percentile(duration, 95),
    P99Duration = percentile(duration, 99)
    by name
| order by P95Duration desc
```

### 4.3 Utwórz własne zapytanie

**Zadanie:** Napisz zapytanie KQL, które:
- Pokazuje liczbę requestów per endpoint w ostatniej godzinie
- Filtruje tylko endpointy z `/api/products`
- Wyświetla average duration i error count
- Sortuje po liczbie requestów malejąco

<details>
<summary>Rozwiązanie (kliknij aby zobaczyć)</summary>

```kql
requests
| where timestamp > ago(1h)
| where url contains "/api/products"
| summarize 
    Count = count(), 
    AvgDuration = avg(duration),
    Errors = countif(tolong(resultCode) >= 400)
    by name
| order by Count desc
```

</details>

### 4.4 Zapisz zapytanie jako Favorites

1. Po uruchomieniu zapytania kliknij **Save** (góra)
2. Nazwij: "Products API Stats"
3. Teraz możesz szybko uruchomić to zapytanie w przyszłości

---

## Ćwiczenie 5 – Custom Metrics & Events

**Cel:** Przetestować własne metryki biznesowe (liczba zamówień, revenue)

**ℹ️ Informacja:** Aplikacja już zawiera implementację custom events i metrics w endpointcie `/api/orders`:
- **OrderCreated** - event generowany przy pomyślnym zamówieniu
- **OrderFailed** - event generowany przy błędzie (out of stock)
- **OrderRevenue** - metryka śledząca przychód z każdego zamówienia

### 5.1 Wygeneruj zamówienia testowe w Azure

```powershell
# Wygeneruj kilka zamówień przez HTTP requests do Web App

# Sukces
Invoke-RestMethod -Method POST -Uri "https://$APP_URL/api/orders" `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"productId": 1, "quantity": 10}'

Invoke-RestMethod -Method POST -Uri "https://$APP_URL/api/orders" `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"productId": 2, "quantity": 25}'

# Błąd (out of stock)
try {
    Invoke-RestMethod -Method POST -Uri "https://$APP_URL/api/orders" `
      -Headers @{"Content-Type"="application/json"} `
      -Body '{"productId": 3, "quantity": 200}'
} catch {
    Write-Host "Expected error: Out of stock" -ForegroundColor Yellow
}

Write-Host "`n✅ Orders generated. Wait 2-3 minutes for data in Application Insights" -ForegroundColor Green
```

### 5.2 Sprawdź custom events w Application Insights

Po ~2 minutach przejdź do Application Insights → **Logs** i uruchom:

```kql
// Custom events
customEvents
| where timestamp > ago(1h)
| where name in ("OrderCreated", "OrderFailed")
| project timestamp, name, customDimensions, customMeasurements
| order by timestamp desc
```

```kql
// Revenue metric
customMetrics
| where timestamp > ago(1h)
| where name == "OrderRevenue"
| summarize TotalRevenue = sum(value), AvgOrderValue = avg(value), OrderCount = count()
```

---

## Ćwiczenie 6 – Dashboardy i Alerty

**Cel:** Stworzyć dashboard do monitorowania aplikacji i skonfigurować alerty

### 6.1 Utwórz Dashboard w Azure Portal

1. W Application Insights kliknij **Workbooks** (lewy panel)
2. Kliknij **+ New**
3. Dodaj następujące kafelki (kliknij **Add** → **Add query**):

**Kafelek 1: Request Rate**
```kql
requests
| where timestamp > ago(1h)
| summarize Count = count() by bin(timestamp, 1m)
| render timechart
```

**Kafelek 2: Response Time (P95)**
```kql
requests
| where timestamp > ago(1h)
| summarize P95 = percentile(duration, 95) by bin(timestamp, 5m)
| render timechart
```

**Kafelek 3: Error Rate**
```kql
requests
| where timestamp > ago(1h)
| summarize 
    Total = count(), 
    Errors = countif(tolong(resultCode) >= 400)
    by bin(timestamp, 5m)
| extend ErrorRate = (Errors * 100.0) / Total
| project timestamp, ErrorRate
| render timechart
```

**Kafelek 4: Top Endpoints by Volume**
```kql
requests
| where timestamp > ago(1h)
| summarize Count = count() by name
| top 10 by Count desc
| render barchart
```

4. Kliknij **Done Editing** → **Save** → Nazwij: "MonitoringDemo Dashboard"

### 6.2 Utwórz Alert na wysoki Error Rate

**UWAGA:** Zastąp `TWOJ_EMAIL@example.com` prawdziwym adresem email

```powershell
# Pobierz Resource ID Application Insights
$APPI_ID = az monitor app-insights component show `
  --app $APP_INSIGHTS_NAME `
  --resource-group $RESOURCE_GROUP `
  --query id -o tsv

# Utwórz Action Group (email notification)
az monitor action-group create `
  --name "ag-$NAZWISKO-lab7" `
  --resource-group $RESOURCE_GROUP `
  --short-name "AlertTeam" `
  --action email admin TWOJ_EMAIL@example.com

# Utwórz Scheduled Query Alert (KQL-based)
az monitor scheduled-query create `
  --name "High Error Rate - $NAZWISKO" `
  --resource-group $RESOURCE_GROUP `
  --scopes $APPI_ID `
  --condition "count 'ErrorQuery' > 5" `
  --condition-query ErrorQuery="requests | where timestamp > ago(5m) | where tolong(resultCode) >= 500" `
  --description "Alert when error rate exceeds 5 errors in 5 minutes" `
  --evaluation-frequency 5m `
  --window-size 5m `
  --severity 2 `
  --action-groups "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/microsoft.insights/actionGroups/ag-$NAZWISKO-lab7"
```

### 6.3 Wyzwól alert (test)

```powershell
# Wygeneruj dużo błędów aby wyzwolić alert
1..20 | ForEach-Object {
    Write-Host "Triggering error $_"
    try {
        Invoke-WebRequest "https://$APP_URL/api/crash" -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
    } catch {
        # Ignore errors
    }
    Start-Sleep -Milliseconds 200
}

Write-Host "Alert should trigger in ~5 minutes. Check your email!" -ForegroundColor Yellow
```

---

## Ćwiczenie 7 – Azure Managed Grafana Dashboard (Opcjonalne)

**Cel:** Stworzyć dashboard w Azure Managed Grafana podłączony do Application Insights

**ℹ️ Uwaga:** Azure Managed Grafana nie jest dostępny w Free Tier. To ćwiczenie jest opcjonalne i pokazuje jak korzystać z zarządzanej usługi Grafana w Azure.

### 7.1 Utwórz Dashboard w Grafanie

1. Kliknij **APPI** → **Monitoring** → **Dashboards with Grafana**
2. Kliknij **Add visualization**
3. Utwórz wykres z dowolnymi danymi pochodzącymi z Application Insights
4. Zapisz dashboard: **Save** → Nazwa: "MonitoringDemo - Lab7"

**💡 Zaleta:** Grafana oferuje bardziej zaawansowane możliwości wizualizacji i alertowania niż Application Insights Workbooks.

---

## 🎓 Podsumowanie i ocena

### Co należy przesłać prowadzącemu:

1. **Screenshot Application Insights Dashboard** pokazujący:
   - Request rate chart
   - Error rate chart  
   - Latency (P95) chart
   - Custom events/metrics visible

2. **Screenshot alertu** (email lub Azure Portal):
   - Showing alert rule created
   - Opcjonalnie: triggered alert w emailu

3. **Screenshot Grafana Dashboard** (opcjonalnie):

lub screenshot pokazujący ostatnie zrobione ćwiczenie.

---

## Cleanup

```powershell
# Usuń Resource Group (wszystkie zasoby)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```
