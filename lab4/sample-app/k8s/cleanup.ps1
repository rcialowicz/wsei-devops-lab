# Product Manager - Kubernetes Cleanup Script
# Usuwa aplikację i opcjonalnie klaster AKS

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "product-manager-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "product-manager-aks",
    
    [Parameter(Mandatory=$false)]
    [switch]$DeleteCluster
)

$ErrorActionPreference = "Stop"

# Upewnij się że jesteśmy w katalogu k8s
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Product Manager - K8s Cleanup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Usuń aplikację z namespace
Write-Host "Usuwanie aplikacji Product Manager..." -ForegroundColor Yellow
$namespace = kubectl get namespace product-manager 2>$null
if ($namespace) {
    kubectl delete namespace product-manager
    Write-Host "✓ Namespace 'product-manager' usunięty" -ForegroundColor Green
} else {
    Write-Host "Namespace 'product-manager' nie istnieje" -ForegroundColor Gray
}
Write-Host ""

if ($DeleteCluster) {
    Write-Host "Usuwanie klastra AKS i Resource Group..." -ForegroundColor Yellow
    Write-Host "To może zająć kilka minut..." -ForegroundColor Gray
    
    $confirmation = Read-Host "Czy na pewno chcesz usunąć CAŁY klaster '$ClusterName'? (yes/no)"
    if ($confirmation -eq "yes") {
        az group delete --name $ResourceGroupName --yes --no-wait
        Write-Host "✓ Rozpoczęto usuwanie Resource Group: $ResourceGroupName" -ForegroundColor Green
        Write-Host "Proces działa w tle. Sprawdź status w Azure Portal." -ForegroundColor Gray
    } else {
        Write-Host "Anulowano usuwanie klastra" -ForegroundColor Yellow
    }
} else {
    Write-Host "Klaster AKS pozostawiony (użyj -DeleteCluster aby usunąć)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Aby całkowicie usunąć klaster uruchom:" -ForegroundColor Yellow
    Write-Host "  .\cleanup.ps1 -DeleteCluster -ResourceGroupName $ResourceGroupName" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✓ Cleanup zakończony" -ForegroundColor Green
Write-Host ""
