#!/bin/bash

# Product Manager - Kubernetes Deployment Script
# Automatyczne wdrożenie aplikacji na klaster Kubernetes

set -e

echo "================================"
echo "Product Manager - K8s Deployment"
echo "================================"
echo ""

# Kolory dla outputu
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Sprawdź czy kubectl jest zainstalowane
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl nie jest zainstalowane.${NC}"
    echo "Instaluję kubectl..."
    sudo snap install kubectl --classic
    echo -e "${GREEN}✓${NC} kubectl zainstalowane"
    echo ""
fi

# 1. Namespace i Secret
echo -e "${YELLOW}[1/5]${NC} Tworzenie namespace i secret..."
kubectl apply -f namespace.yaml
echo -e "${GREEN}✓${NC} Namespace i secret utworzone"
echo ""

# 2. Database
echo -e "${YELLOW}[2/5]${NC} Wdrażanie SQL Server..."
kubectl apply -f db-deployment.yaml
echo -e "${GREEN}✓${NC} SQL Server deployment utworzony"
echo ""

# Czekaj na gotowość bazy danych
echo "Czekam na gotowość bazy danych (może zająć 1-2 minuty)..."
kubectl wait --for=condition=ready pod -l app=db -n product-manager --timeout=180s
echo -e "${GREEN}✓${NC} Baza danych gotowa"
echo ""

# 3. Backend
echo -e "${YELLOW}[3/5]${NC} Wdrażanie Backend API..."
kubectl apply -f backend-deployment.yaml
echo -e "${GREEN}✓${NC} Backend deployment utworzony"
echo ""

# Czekaj na gotowość backendu
echo "Czekam na gotowość backend (może zająć 30-60 sekund)..."
kubectl wait --for=condition=ready pod -l app=backend -n product-manager --timeout=120s
echo -e "${GREEN}✓${NC} Backend gotowy"
echo ""

# 4. Frontend
echo -e "${YELLOW}[4/5]${NC} Wdrażanie Frontend..."
kubectl apply -f frontend-deployment.yaml
echo -e "${GREEN}✓${NC} Frontend deployment utworzony"
echo ""

# 5. Gateway
echo -e "${YELLOW}[5/5]${NC} Wdrażanie Gateway (Nginx reverse proxy)..."
kubectl apply -f gateway-deployment.yaml
echo -e "${GREEN}✓${NC} Gateway deployment utworzony"
echo ""

# Czekaj na external IP
echo "Czekam na przydzielenie External IP dla gateway..."
echo "(To może zająć kilka minut w zależności od klastra)"
echo ""

# Funkcja do pobrania external IP
get_external_ip() {
    kubectl get service gateway -n product-manager -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null
}

# Czekaj maksymalnie 5 minut na external IP
TIMEOUT=300
ELAPSED=0
while [ -z "$(get_external_ip)" ] && [ $ELAPSED -lt $TIMEOUT ]; do
    echo -n "."
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done
echo ""

EXTERNAL_IP=$(get_external_ip)

if [ -z "$EXTERNAL_IP" ]; then
    echo -e "${YELLOW}⚠${NC}  External IP jeszcze nie przydzielone."
    echo "Sprawdź status ręcznie: kubectl get service gateway -n product-manager"
else
    echo -e "${GREEN}✓${NC} External IP przydzielone: ${GREEN}${EXTERNAL_IP}${NC}"
fi

echo ""
echo "================================"
echo "Deployment zakończony!"
echo "================================"
echo ""
echo "Status deploymentu:"
kubectl get all -n product-manager
echo ""
echo "Aby sprawdzić aplikację:"
if [ -n "$EXTERNAL_IP" ]; then
    echo -e "  ${GREEN}http://${EXTERNAL_IP}${NC}"
else
    echo "  kubectl get service gateway -n product-manager"
    echo "  (poczekaj aż EXTERNAL-IP zostanie przydzielone)"
fi
echo ""
echo "Przydatne komendy:"
echo "  kubectl get pods -n product-manager           # Status podów"
echo "  kubectl logs -f deployment/backend -n product-manager   # Logi backendu"
echo "  kubectl logs -f deployment/gateway -n product-manager   # Logi gateway"
echo "  kubectl describe pod <pod-name> -n product-manager      # Szczegóły poda"
echo ""
echo "Aby usunąć deployment:"
echo "  ./cleanup.sh"
echo "  # lub: kubectl delete namespace product-manager"
echo ""
