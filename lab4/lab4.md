# Laboratorium 4 – Docker Compose i budowanie obrazów

## Prerekwizyty
1. Połącz się z maszyną wirtualną używając ssh:
   ```bash
   ssh studentwsei@134.149.58.187 -p (50000 + N)
   # np. ssh studentwsei@134.149.58.187 -p 50023
   ```
2. Upewnij się, że Docker i Docker Compose są zainstalowane:
   ```bash
   docker --version
   docker compose version
   ```

---

## Przygotowanie

### 0.1 Pobierz projekt przykładowy
```bash
cd ~/
git clone https://github.com/rcialowicz/wsei-devops-lab.git
cd wsei-devops-lab/lab4/sample-app
```

### 0.2 Struktura projektu
Sprawdź strukturę:
```bash
tree
# lub
ls -R
```

Powinieneś zobaczyć:
```
sample-app/
├── backend/          # Backend API (.NET 8)
│   ├── Program.cs
│   ├── ProductApi.csproj
│   ├── Dockerfile
│   └── appsettings.json
├── frontend/         # Frontend (HTML/JS)
│   ├── index.html
│   └── Dockerfile
├── gateway/          # Nginx reverse proxy
│   ├── nginx.conf
│   └── Dockerfile
├── docker-compose.yml        # Podstawowa wersja (starter)
└── docker-compose-final.yml  # Finalna wersja (z ulepszeniami)
```

---

## Ćwiczenie 1 – Ręczne uruchomienie (bez Docker Compose)

W tym ćwiczeniu uruchomisz **wszystkie komponenty aplikacji w kontenerach**, ale **ręcznie** używając `docker run` dla każdego kontenera osobno, aby zobaczyć ile kroków wymaga uruchomienie aplikacji wielokontenerowej **bez orkiestracji**.

### 1.1 Zbuduj obrazy Docker dla wszystkich komponentów

```bash
# Zbuduj obraz backendu
docker build -t manual-backend:latest ./backend

# Zbuduj obraz frontendu
docker build -t manual-frontend:latest ./frontend

# Zbuduj obraz gateway
docker build -t manual-gateway:latest ./gateway
```

**To może zająć kilka minut** przy pierwszym buildzie.

### 1.2 Uruchom SQL Server ręcznie
```bash
docker run -d \
  --name manual-db \
  -e ACCEPT_EULA=Y \
  -e SA_PASSWORD='YourStrong@Passw0rd' \
  -e MSSQL_PID=Express \
  mcr.microsoft.com/mssql/server:2022-latest
```

### 1.3 Poczekaj aż SQL Server będzie gotowy
```bash
# Sprawdź logi - poczekaj na "SQL Server is now ready for client connections"
docker logs -f manual-db
# (Ctrl+C aby wyjść z logów)
```

**To może zająć 30-60 sekund.**

### 1.4 Uruchom backend ręcznie
```bash
docker run -d \
  --name manual-backend \
  --link manual-db:manual-db \
  -e ConnectionStrings__DefaultConnection="Server=manual-db;Database=ProductsDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;" \
  manual-backend:latest
```

### 1.5 Uruchom frontend ręcznie
```bash
docker run -d \
  --name manual-frontend \
  manual-frontend:latest
```

### 1.6 Uruchom gateway ręcznie
```bash
docker run -d \
  --name manual-gateway \
  --link manual-backend:backend \
  --link manual-frontend:frontend \
  -p 8080:80 \
  manual-gateway:latest
```

### 1.7 Sprawdź czy wszystkie kontenery działają
```bash
docker ps

# Powinieneś zobaczyć 4 kontenery:
# - manual-db
# - manual-backend
# - manual-frontend
# - manual-gateway
```

### 1.8 Przetestuj aplikację
Otwórz w przeglądarce:
```
http://134.149.58.187:(51000+N)
# lub lokalnie: http://localhost:8080
```

Dodaj kilka produktów aby sprawdzić czy backend komunikuje się z bazą danych.

### 1.9 Zatrzymaj i usuń wszystko ręcznie
```bash
# Zatrzymaj kontenery (UWAGA: muszą być w odpowiedniej kolejności - gateway przed backend/frontend!)
docker stop manual-gateway manual-frontend manual-backend manual-db

# Usuń kontenery
docker rm manual-gateway manual-frontend manual-backend manual-db

# Usuń obrazy (opcjonalnie)
docker rmi manual-gateway:latest manual-frontend:latest manual-backend:latest
```

### 1.10 Policz ile kroków było potrzebnych:
1. 📥 Pobranie kodu źródłowego
2. 🔨 Zbudowanie 3 obrazów Docker (backend, frontend, gateway)
3. 🗄️ Uruchomienie SQL Server z długą komendą
4. ⏰ Ręczne czekanie aż SQL Server będzie gotowy (sprawdzanie logów)
5. 🏃 Uruchomienie backendu z --link do bazy danych
6. 🌐 Uruchomienie frontendu
7. 🚪 Uruchomienie gateway z --link do backend i frontend + mapowanie portów
8. 🧹 Ręczne czyszczenie: zatrzymanie 4 kontenerów **we właściwej kolejności** + usunięcie 4 kontenerów + usunięcie 3 obrazów

**Podsumowanie:** To jest **chaotyczne, podatne na błędy i niepowtarzalne!** Musisz pamiętać o:
- Kolejności uruchamiania (baza → backend → frontend → gateway)
- Każdym --link między kontenerami
- Kolejności zatrzymywania (odwrotnej niż uruchamianie!)
- Jedna literówka w nazwie kontenera i nic nie działa

---

## Ćwiczenie 2 – Docker Compose (prosta wersja)

### 2.1 Przejrzyj plik docker-compose.yml (podstawowa wersja)
```bash
cat docker-compose.yml
```

**Zauważ, że plik jest bardzo prosty:**
- ✅ 4 serwisy: db, backend, frontend, **gateway** (Nginx jako reverse proxy)
- ✅ Gateway wystawia tylko 1 port (8080) na zewnątrz

### 2.2 Uruchom podstawową wersję aplikacji
```bash
docker compose up -d --build
```

**Uwaga:** Pierwsze uruchomienie może zająć kilka minut:

**Możliwe problemy:**
- Backend może crashować kilka razy zanim SQL Server będzie gotowy (brak healthcheck)
- To jest normalne - Docker automatycznie restartuje kontenery

### 2.3 Sprawdź status kontenerów
```bash
docker compose ps
```

Możesz zobaczyć że backend jest w stanie `Restarting` - to dlatego że SQL Server jeszcze nie jest gotowy.

### 2.4 Zobacz logi
```bash
# Wszystkie serwisy
docker compose logs

# Tylko SQL Server
docker compose logs db

# Tylko backend
docker compose logs backend

# Logi na żywo
docker compose logs -f
```

### 2.5 Sprawdź frontend w przeglądarce
Otwórz w przeglądarce:
```
http://134.149.58.187:(51000+N)
# lub lokalnie: http://localhost:8080
```

### 2.6 Przetestuj aplikację
1. Dodaj kilka produktów

### 2.7 PROBLEM: Dane znikają po restarcie!
```bash
docker compose down
docker compose up -d
# Poczekaj na inicjalizację i odśwież stronę w przeglądarce
```

**Wszystkie produkty zniknęły!** 😱 To dlatego, że w `docker-compose.yml` nie ma zdefiniowanych volumes.

### 2.9 Zatrzymaj aplikację
```bash
docker compose down
```

---

## Ćwiczenie 2B – Ulepsz docker-compose.yml

**Twoim zadaniem jest naprawić problemy w podstawowej wersji docker-compose.yml.**

### 2B.1 Zidentyfikowane problemy

1. ❌ Dane znikają po `docker compose down`
2. ❌ Backend restartuje się kilka razy na starcie (SQL Server nie jest gotowy)
3. ❌ Brak izolacji sieciowej (wszystkie serwisy w jednej sieci)
4. ❌ Brak polityki restartu (kontenery nie restartują się automatycznie po błędzie)

### 2B.2 **Podpowiedzi do ulepszenia:**

1. **Volumes** - dodaj volume dla SQL Server:
   ```yaml
   volumes:
     db-data:
   
   # I w serwisie db:
   volumes:
     - db-data:/var/opt/mssql
   ```

2. **Healthcheck** - dodaj do serwisu db:
   ```yaml
   healthcheck:
     test: ["CMD", "/opt/mssql-tools18/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "YourStrong@Passw0rd", "-Q", "SELECT 1"]
     interval: 10s
     timeout: 3s
     retries: 5
     start_period: 30s
   ```

3. **depends_on** - dodaj zależności między serwisami:
   ```yaml
   # Backend zależy od bazy danych
   backend:
     depends_on:
       db:
         condition: service_healthy
   
   # Gateway zależy od backend i frontend
   gateway:
     depends_on:
       - backend
       - frontend

    # Samodzielnie dodaj kolejną zależność: frontend czeka na backend
   ```

4. **Networks** - stwórz 2 sieci dla lepszej izolacji:
   
   Najpierw zdefiniuj sieci na poziomie głównym:
   ```yaml
   networks:
     app-network:
       driver: bridge
     backend-network:
       driver: bridge
       internal: true  # Bez dostępu z zewnątrz!
   ```
   
   Następnie przypisz wszystkie serwisy do sieci:
   ```yaml
   # np. Backend - obie sieci (łączy app z database)
   backend:
     networks:
       - app-network
       - backend-network
   ```
   
5. **Restart policy** - dodaj do wszystkich serwisów:
   ```yaml
   restart: unless-stopped
   ```

**Zadanie:** Ulepsz plik `docker-compose.yml` wdrażając powyższe zmiany. Staraj się zaimplementować tyle ulepszeń ile zdążysz podczas zajęć. Nawet częściowe rozwiązanie (np. tylko volumes + healthcheck) jest wartościowe!

### 2B.5 Testuj swoje ulepszenia
```bash
# Zatrzymaj
docker compose down

# Uruchom ponownie
docker compose up -d --build
```

---

## Artefakty wymagane do zaliczenia

Prześlij prowadzącemu:

1. **Zrzut ekranu** z Ćwiczenia 2 (docker-compose.yml - podstawowa wersja):
   - Wynik polecenia: `docker compose ps` pokazujący działające kontenery (zadanie 2.3)
   - Okno przeglądarki z działającą aplikacją (co najmniej 2-3 produkty dodane - zadanie 2.5)

2. **Plik docker-compose.yml** z Twoimi ulepszeniami z Ćwiczenia 2B:
   - Twoja ulepszona DZIAŁAJĄCA wersja pliku docker-compose.yml
   - Nie musi być kompletna - liczy się każde wdrożone ulepszenie!

---
