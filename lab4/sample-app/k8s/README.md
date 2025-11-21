# Product Manager - Kubernetes Deployment

Ten katalog zawiera manifesty Kubernetes do wdrożenia aplikacji Product Manager na klastrze K8s.

## Architektura

- **Namespace**: `product-manager` - izolacja zasobów
- **Database**: SQL Server 2022 Express z PersistentVolumeClaim (1Gi)
- **Backend**: ASP.NET Core API (3 repliki) z health checks
- **Frontend**: Nginx serving static HTML/JS (2 repliki)
- **Gateway**: Nginx reverse proxy (2 repliki) - dostęp przez LoadBalancer

## Wymagania

- Klaster Kubernetes (AKS, GKE, EKS, minikube, kind, etc.)
- `kubectl` skonfigurowane do komunikacji z klastrem
- Klaster z obsługą LoadBalancer (dla cloud providers) lub Ingress Controller

## Szybkie wdrożenie

```bash
# Automatyczne wdrożenie wszystkich komponentów
chmod +x deploy.sh
./deploy.sh
```

Skrypt automatycznie:
1. Tworzy namespace i secret
2. Wdraża SQL Server z PVC
3. Wdraża backend (czeka na gotowość bazy)
4. Wdraża frontend
5. Wdraża gateway z LoadBalancer
6. Czeka na przydzielenie External IP
7. Wyświetla informacje o dostępie

## Ręczne wdrożenie (krok po kroku)

```bash
# 1. Namespace i Secret
kubectl apply -f namespace.yaml

# 2. Database
kubectl apply -f db-deployment.yaml
kubectl wait --for=condition=ready pod -l app=db -n product-manager --timeout=180s

# 3. Backend
kubectl apply -f backend-deployment.yaml
kubectl wait --for=condition=ready pod -l app=backend -n product-manager --timeout=120s

# 4. Frontend
kubectl apply -f frontend-deployment.yaml

# 5. Gateway
kubectl apply -f gateway-deployment.yaml

# 6. Sprawdź status
kubectl get all -n product-manager

# 7. Pobierz External IP
kubectl get service gateway -n product-manager
```

## Dostęp do aplikacji

Po wdrożeniu sprawdź External IP:

```bash
kubectl get service gateway -n product-manager
```

Otwórz w przeglądarce: `http://<EXTERNAL-IP>`

Gateway routuje:
- `/` → frontend (static HTML)
- `/api/*` → backend (REST API)

## Monitorowanie

```bash
# Wszystkie zasoby
kubectl get all -n product-manager

# Status podów
kubectl get pods -n product-manager -o wide

# Logi backendu
kubectl logs -f deployment/backend -n product-manager

# Logi gateway
kubectl logs -f deployment/gateway -n product-manager

# Logi SQL Server
kubectl logs -f deployment/db -n product-manager

# Szczegóły poda
kubectl describe pod <pod-name> -n product-manager

# Events w namespace
kubectl get events -n product-manager --sort-by='.lastTimestamp'
```

## Skalowanie

```bash
# Zwiększ repliki backendu
kubectl scale deployment backend -n product-manager --replicas=5

# Zmniejsz repliki gateway
kubectl scale deployment gateway -n product-manager --replicas=1

# Obserwuj zmiany
kubectl get pods -n product-manager -w
```

## Aktualizacja aplikacji

```bash
# Rolling update backendu (zero downtime)
kubectl set image deployment/backend api=rcialowicz/product-backend:v2 -n product-manager

# Obserwuj rollout
kubectl rollout status deployment/backend -n product-manager

# Historia rolloutów
kubectl rollout history deployment/backend -n product-manager

# Cofnij update
kubectl rollout undo deployment/backend -n product-manager
```

## Debugowanie

```bash
# Uruchom interaktywny shell w podzie
kubectl exec -it deployment/backend -n product-manager -- /bin/bash

# Port-forward do lokalnego dostępu (bez LoadBalancer)
kubectl port-forward service/gateway 8080:80 -n product-manager
# Następnie otwórz: http://localhost:8080

# Sprawdź połączenie między backend a bazą
kubectl exec -it deployment/backend -n product-manager -- \
  curl http://db:1433
```

## Cleanup

```bash
# Automatyczne usunięcie wszystkich zasobów
chmod +x cleanup.sh
./cleanup.sh

# Lub ręcznie
kubectl delete namespace product-manager
```

## Zasoby Kubernetes użyte w projekcie

- **Namespace**: Izolacja zasobów
- **Secret**: Hasło do bazy danych
- **PersistentVolumeClaim**: Trwałe dane SQL Server (1Gi)
- **Deployment**: Deklaratywne zarządzanie replikami (db=1, backend=3, frontend=2, gateway=2)
- **Service**: 
  - `ClusterIP` dla db/backend (wewnętrzna komunikacja)
  - `LoadBalancer` dla gateway (dostęp z zewnątrz)

## Różnice Docker Compose vs Kubernetes

| Aspekt | Docker Compose | Kubernetes |
|--------|----------------|------------|
| **Repliki** | 1 per service | backend=3, frontend=2, gateway=2 |
| **Load Balancing** | Brak | Automatyczny Service LB |
| **Self-healing** | restart policy | Automatyczne odtwarzanie podów |
| **Health checks** | healthcheck w compose | liveness/readiness probes |
| **Skalowanie** | Manualne edit | `kubectl scale` |
| **Storage** | named volumes | PersistentVolumeClaim |
| **Secrets** | env vars w YAML | Kubernetes Secret |

## Produkcyjne ulepszenia (TODO)

Dla środowiska produkcyjnego rozważ:

1. **Ingress** zamiast LoadBalancer (lepsza kontrola, SSL/TLS)
2. **HorizontalPodAutoscaler** - auto-skalowanie na podstawie CPU/pamięci
3. **NetworkPolicy** - ograniczenie komunikacji między podami
4. **ResourceRequests/Limits** - kontrola zużycia zasobów
5. **ConfigMap** - zewnętrzna konfiguracja
6. **Helm Chart** - package manager dla K8s
7. **Monitoring** - Prometheus + Grafana
8. **Logging** - ELK/EFK stack
9. **Service Mesh** - Istio/Linkerd dla zaawansowanego routingu
10. **GitOps** - ArgoCD/Flux dla continuous deployment
