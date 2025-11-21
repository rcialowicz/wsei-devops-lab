#!/bin/bash

# Product Manager - Kubernetes Cleanup Script
# Usuwa wszystkie zasoby aplikacji z klastra

echo "================================"
echo "Product Manager - K8s Cleanup"
echo "================================"
echo ""

read -p "Czy na pewno chcesz usunąć wszystkie zasoby Product Manager z Kubernetes? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Anulowano."
    exit 0
fi

echo ""
echo "Usuwanie namespace 'product-manager' (to usunie wszystkie zasoby wewnątrz)..."
kubectl delete namespace product-manager

echo ""
echo "✓ Cleanup zakończony"
echo ""
echo "Wszystkie zasoby Product Manager zostały usunięte."
echo ""
