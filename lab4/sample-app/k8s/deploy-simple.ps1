# Prosty deployment Kubernetes - Demo
# Używa tylko publicznych obrazów (nginx, httpbin)

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "wsei-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "wsei-aks",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "northeurope",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipClusterCreation
)

$ErrorActionPreference = "Stop"

# Upewnij się że jesteśmy w katalogu k8s
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Kubernetes Demo - Prosta Aplikacja" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Używa tylko publicznych obrazów:" -ForegroundColor Gray
Write-Host "  - nginx:alpine (frontend + gateway)" -ForegroundColor Gray
Write-Host "  - kennethreitz/httpbin (backend API)" -ForegroundColor Gray
Write-Host ""

# Sprawdź czy az CLI jest zainstalowane
Write-Host "Sprawdzam wymagania..." -ForegroundColor Yellow
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Azure CLI nie jest zainstalowane!" -ForegroundColor Red
    Write-Host "Pobierz z: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    exit 1
}

# Sprawdź czy kubectl jest zainstalowane
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "kubectl nie jest zainstalowane. Instaluję..." -ForegroundColor Yellow
    az aks install-cli
    Write-Host "✓ kubectl zainstalowane" -ForegroundColor Green
}

Write-Host "✓ Wymagania spełnione" -ForegroundColor Green
Write-Host ""

# Zaloguj się do Azure (jeśli nie jesteś zalogowany)
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Loguję do Azure..." -ForegroundColor Yellow
    az login
}

Write-Host "✓ Zalogowano do Azure: $($account.user.name)" -ForegroundColor Green
Write-Host ""

if (-not $SkipClusterCreation) {
    # Utwórz Resource Group
    Write-Host "[1/3] Tworzenie Resource Group..." -ForegroundColor Yellow
    $rg = az group show --name $ResourceGroupName 2>$null | ConvertFrom-Json
    if (-not $rg) {
        az group create --name $ResourceGroupName --location $Location | Out-Null
        Write-Host "✓ Resource Group utworzona: $ResourceGroupName" -ForegroundColor Green
    } else {
        Write-Host "✓ Resource Group już istnieje: $ResourceGroupName" -ForegroundColor Green
    }
    Write-Host ""

    # Utwórz klaster AKS
    Write-Host "[2/3] Tworzenie klastra AKS (to może zająć 5-10 minut)..." -ForegroundColor Yellow
    Write-Host "Parametry: 2 węzły, VM: Standard_B2s" -ForegroundColor Gray
    
    $aksExists = az aks show --resource-group $ResourceGroupName --name $ClusterName 2>$null
    if (-not $aksExists) {
        az aks create `
            --resource-group $ResourceGroupName `
            --name $ClusterName `
            --node-count 2 `
            --node-vm-size Standard_B2s `
            --enable-managed-identity `
            --generate-ssh-keys `
            --no-wait
        
        Write-Host "Czekam na utworzenie klastra..." -ForegroundColor Yellow
        az aks wait --resource-group $ResourceGroupName --name $ClusterName --created --timeout 600 2>$null
        Write-Host "✓ Klaster AKS utworzony" -ForegroundColor Green
    } else {
        Write-Host "✓ Klaster AKS już istnieje" -ForegroundColor Green
    }
    Write-Host ""

    # Pobierz credentials
    Write-Host "[3/3] Konfiguracja kubectl..." -ForegroundColor Yellow
    az aks get-credentials --resource-group $ResourceGroupName --name $ClusterName --overwrite-existing | Out-Null
    Write-Host "✓ kubectl skonfigurowane" -ForegroundColor Green
    Write-Host ""
}

# Sprawdź połączenie z klastrem
Write-Host "Sprawdzam połączenie z klastrem..." -ForegroundColor Yellow
$null = kubectl cluster-info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Brak połączenia z klastrem Kubernetes!" -ForegroundColor Red
    Write-Host "Upewnij się że klaster jest uruchomiony i kubectl jest skonfigurowane" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Połączenie z klastrem OK" -ForegroundColor Green
Write-Host ""

# Wdróż aplikację
Write-Host "Wdrażam aplikację demo..." -ForegroundColor Yellow
kubectl apply -f simple-demo.yaml
Write-Host "✓ Aplikacja wdrożona" -ForegroundColor Green
Write-Host ""

# Czekaj na pody
Write-Host "Czekam na uruchomienie podów (30 sekund)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "Status podów:" -ForegroundColor Yellow
kubectl get pods -n demo-app
Write-Host ""

# Czekaj na external IP
Write-Host "Czekam na przydzielenie External IP..." -ForegroundColor Yellow
Write-Host "(To może zająć 2-3 minuty w AKS)" -ForegroundColor Gray
Write-Host ""

$timeout = 300
$elapsed = 0
$externalIP = $null

while ((-not $externalIP) -and ($elapsed -lt $timeout)) {
    Start-Sleep -Seconds 5
    $elapsed += 5
    $service = kubectl get service gateway -n demo-app -o json 2>$null | ConvertFrom-Json
    if ($service.status.loadBalancer.ingress) {
        $externalIP = $service.status.loadBalancer.ingress[0].ip
    }
    Write-Host "." -NoNewline
}
Write-Host ""
Write-Host ""

if (-not $externalIP) {
    Write-Host "⚠ External IP jeszcze nie przydzielone." -ForegroundColor Yellow
    Write-Host "Sprawdź status: kubectl get service gateway -n demo-app" -ForegroundColor Gray
} else {
    Write-Host "✓ External IP: $externalIP" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Deployment zakończony!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Status:" -ForegroundColor Yellow
kubectl get all -n demo-app
Write-Host ""

Write-Host "Dostęp do aplikacji:" -ForegroundColor Yellow
if ($externalIP) {
    Write-Host "  http://$externalIP" -ForegroundColor Green
    Write-Host ""
    Write-Host "Otwórz w przeglądarce aby zobaczyć demo!" -ForegroundColor Cyan
} else {
    Write-Host "  kubectl get service gateway -n demo-app -w" -ForegroundColor Gray
}
Write-Host ""

Write-Host "Demo funkcji K8s:" -ForegroundColor Yellow
Write-Host "  # Skalowanie"
Write-Host "  kubectl scale deployment backend -n demo-app --replicas=5"
Write-Host ""
Write-Host "  # Self-healing (usuń pod - K8s go odtworzy)"
Write-Host "  kubectl delete pod -n demo-app -l app=backend --force"
Write-Host ""
Write-Host "  # Logi"
Write-Host "  kubectl logs -f deployment/backend -n demo-app"
Write-Host ""

Write-Host "Cleanup:" -ForegroundColor Yellow
Write-Host "  kubectl delete namespace demo-app"
Write-Host "  # lub: .\cleanup.ps1 -DeleteCluster"
Write-Host ""
