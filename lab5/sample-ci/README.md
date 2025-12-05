# Sample CI/CD Application

Przykładowa aplikacja .NET i Node.js do ćwiczeń z Continuous Integration.

## Struktura projektu

```
backend/
├── Program.cs              # Główna aplikacja API (.NET)
├── ProductApi.csproj       # Plik projektu
└── ProductApi.Tests/       # Testy jednostkowe
    ├── ProductApi.Tests.csproj
    └── ProductTests.cs

frontend/
├── index.html              # Strona główna
├── app.js                  # Logika aplikacji
├── package.json            # Zależności npm
└── app.test.js             # Testy jednostkowe (Jest)
```

## Lokalne uruchomienie

### Wymagania
- .NET 8 SDK
- Node.js 20

### Uruchomienie backend (.NET)

```bash
cd backend
dotnet restore
dotnet run
```

Aplikacja będzie dostępna na: http://localhost:5000

### Uruchomienie testów backend

```bash
cd backend
dotnet test ProductApi.Tests/ProductApi.Tests.csproj
```

### Uruchomienie frontend (Node.js)

```bash
cd frontend
npm install
npm start
```

### Uruchomienie testów frontend

```bash
cd frontend
npm test
```

## API Endpoints

- `GET /` - Status API
- `GET /api/products` - Lista wszystkich produktów
- `GET /api/products/{id}` - Pojedynczy produkt
- `POST /api/products` - Dodaj nowy produkt
- `DELETE /api/products/{id}` - Usuń produkt

## CI/CD Pipeline

### Azure DevOps
Pipeline zdefiniowany w: `azure-pipelines.yml`

**Etapy:**
1. **Backend Build** - Kompilacja, testy i publish aplikacji .NET
2. **Frontend Build** - npm install, testy i build aplikacji Node.js

### GitHub Actions
Workflow zdefiniowany w: `.github/workflows/ci.yml`

**Jobs:**
1. **backend** - Kompilacja, testy i publish .NET (równolegle)
2. **frontend** - npm install, testy i build Node.js (równolegle)

## Przykłady użycia

### Testowanie API lokalnie

```bash
# Dodaj produkt
curl -X POST http://localhost:5000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99}'

# Lista produktów
curl http://localhost:5000/api/products

# Usuń produkt
curl -X DELETE http://localhost:5000/api/products/1
```

## Rozszerzenia (do samodzielnej nauki)

1. **Dodaj code coverage gate** - minimum 80% pokrycia
2. **Integracja z SonarCloud** - analiza jakości kodu
3. **Performance tests** - testy obciążeniowe (k6, JMeter)
4. **Deployment** - automatyczny deploy do Azure App Service
