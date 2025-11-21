# Kubernetes Demo - Cleanup Script
# Removes demo application and optionally AKS cluster

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "wsei-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "wsei-aks",
    
    [Parameter(Mandatory=$false)]
    [switch]$DeleteCluster
)

$ErrorActionPreference = "Stop"

# Make sure we're in the k8s directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Kubernetes Demo - Cleanup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Delete application from namespace
Write-Host "Removing demo application..." -ForegroundColor Yellow
$namespace = kubectl get namespace demo-app 2>$null
if ($namespace) {
    kubectl delete namespace demo-app
    Write-Host "✓ Namespace 'demo-app' removed" -ForegroundColor Green
} else {
    Write-Host "Namespace 'demo-app' does not exist" -ForegroundColor Gray
}
Write-Host ""

if ($DeleteCluster) {
    Write-Host "Removing AKS cluster and Resource Group..." -ForegroundColor Yellow
    Write-Host "This may take a few minutes..." -ForegroundColor Gray
    
    $confirmation = Read-Host "Are you sure you want to delete the ENTIRE cluster '$ClusterName'? (yes/no)"
    if ($confirmation -eq "yes") {
        az group delete --name $ResourceGroupName --yes --no-wait
        Write-Host "✓ Started removing Resource Group: $ResourceGroupName" -ForegroundColor Green
        Write-Host "Process running in background. Check status in Azure Portal." -ForegroundColor Gray
    } else {
        Write-Host "Cluster deletion cancelled" -ForegroundColor Yellow
    }
} else {
    Write-Host "AKS cluster kept (use -DeleteCluster to remove)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To completely remove the cluster run:" -ForegroundColor Yellow
    Write-Host "  .\cleanup.ps1 -DeleteCluster -ResourceGroupName $ResourceGroupName" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✓ Cleanup completed" -ForegroundColor Green
Write-Host ""
