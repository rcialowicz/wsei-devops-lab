# Laboratorium 5 – Continuous Integration (CI)

## Prerekwizyty
1. Konto Azure DevOps (https://dev.azure.com)
2. Konto GitHub (opcjonalnie, dla ćwiczenia z GitHub Actions)
3. Azure CLI zainstalowane lokalnie
4. Git zainstalowany lokalnie
5. .NET 8 SDK i Node.js 20 zainstalowane lokalnie (do testowania lokalnie)

---

## Przygotowanie

### 0.1 Sklonuj repozytorium z materiałami
```powershell
cd ~
git clone https://github.com/rcialowicz/wsei-devops-lab.git
cd wsei-devops-lab/lab5/sample-ci
```

Lub jeśli już masz repo sklonowane, upewnij się że masz najnowszą wersję:
```powershell
cd ~/wsei-devops-lab
git pull origin main
cd lab5/sample-ci
```

### 0.2 Struktura projektu
```
sample-ci/
├── backend/                    # Backend API (.NET 8)
│   ├── Program.cs             # Główna aplikacja
│   ├── ProductApi.csproj      # Plik projektu
│   └── ProductApi.Tests/      # Testy jednostkowe
│       ├── ProductApi.Tests.csproj
│       └── ProductTests.cs
├── frontend/                   # Frontend (HTML/JS)
│   ├── index.html             # Strona główna
│   ├── app.js                 # Logika aplikacji
│   ├── package.json           # Zależności npm
│   └── app.test.js            # Testy jednostkowe
├── azure-pipelines.yml        # Pipeline Azure DevOps
└── .github/workflows/ci.yml   # Workflow GitHub Actions
```

---

## Ćwiczenie 1 – Stworzenie pipeline CI w Azure DevOps

W tym ćwiczeniu stworzysz pipeline CI w Azure DevOps, który automatycznie zbuduje i przetestuje backend (.NET) oraz frontend (Node.js) przy każdym push do brancha `main`.

**UWAGA:** Pipeline jest celowo **NIEOPTYMALIZOWANY** - Twoje zadanie w dalszej części to go zoptymalizować!

### 1.1 Stwórz nowe repozytorium w Azure DevOps

1. Zaloguj się do https://dev.azure.com
2. Otwórz swój projekt (lub stwórz nowy: `wsei-devops-ci`)
3. Przejdź do **Repos** → **Files**
4. Kliknij **Import repository**
5. Wklej URL: `https://github.com/rcialowicz/wsei-devops-lab.git`
6. Kliknij **Import**

### 1.2 Przejrzyj plik azure-pipelines.yml

W repozytorium znajduje się plik `lab5/sample-ci/azure-pipelines.yml`. Otwórz go i zauważ problemy:

**Problemy do znalezienia:**
- ❌ Każdy job instaluje .NET SDK od nowa
- ❌ Każdy job robi `dotnet restore` od nowa (brak cache)
- ❌ Jobs są sekwencyjne zamiast równoległych
- ❌ Build jest powtarzany w wielu job'ach
- ❌ To samo dla frontend (npm install powtarzany wielokrotnie)

**Przeczytaj komentarze w YAML - są oznaczone jako `# PROBLEM:`**

### 1.3 Stwórz pipeline w Azure DevOps

1. Przejdź do **Pipelines** → **Pipelines**
2. Kliknij **New pipeline**
3. Wybierz **Azure Repos Git**
4. Wybierz swoje repozytorium
5. Wybierz **Existing Azure Pipelines YAML file**
6. Path: `/lab5/sample-ci/azure-pipelines.yml`
7. Kliknij **Continue**
8. Przejrzyj YAML i kliknij **Run**

### 1.4 Obserwuj (wolne) wykonanie pipeline

Pipeline powinien się uruchomić automatycznie. Obserwuj logi i **mierz czas**:

1. Kliknij na uruchomiony pipeline
2. Zobacz etapy: **BackendBuild** i **FrontendBuild** (działają równolegle ✅)
3. W **BackendBuild** zobacz joby: DotNetRestore → DotNetBuild → DotNetTest → DotNetPublish (wszystkie **sekwencyjne** ❌)
4. W **FrontendBuild** zobacz joby: NpmInstall → NpmTest → NpmBuild (też **sekwencyjne** ❌)

**Zapisz całkowity czas wykonania pipeline** - będziesz go porównywać po optymalizacji!

### 1.5 Przeanalizuj logi

Kliknij na każdy job i zobacz logi:

- Czy `.NET SDK` jest instalowany wielokrotnie?
- Czy `dotnet restore` / `npm install` jest wykonywany wielokrotnie?
- Ile czasu zajmuje każda operacja?

**Zrób zrzut ekranu pokazujący czasy poszczególnych jobs.**

---

## Ćwiczenie 2 – Optymalizacja pipeline (Azure DevOps)

W tym ćwiczeniu zoptymalizujesz pipeline, aby był **znacznie szybszy**. Zastosujesz najlepsze praktyki CI/CD.

### 2.1 Analiza problemów

Pipeline z Ćwiczenia 1 ma następujące problemy:

1. **Jobs są sekwencyjne** - restore → build → test → publish wykonują się kolejno
2. **Brak cache** - każdy job instaluje .NET SDK i robi `dotnet restore` od nowa
3. **Powtarzanie operacji** - `dotnet build` jest wykonywany w każdym job
4. **Brak optymalizacji .NET** - nie używamy flag `--no-restore`, `--no-build`

**Twoje zadanie:** Napraw te problemy!

### 2.2 Optymalizacja #1: Połącz jobs w jeden

Zamiast 4 jobs (restore, build, test, publish), zrób **jeden job** który wykonuje wszystko sekwencyjnie:

1. W Azure DevOps, przejdź do **Repos** → **Files**
2. Otwórz `lab5/sample-ci/azure-pipelines.yml`
3. Kliknij **Edit**
4. Zastąp stage `BackendBuild` następującym kodem:

```yaml
# Etap 1: Backend .NET (ZOPTYMALIZOWANY)
- stage: BackendBuild
  displayName: 'Backend Build'
  jobs:
  - job: BackendJob
    displayName: 'Build, Test and Publish Backend'
    steps:
    # Zainstaluj .NET SDK (tylko raz!)
    - task: UseDotNet@2
      displayName: 'Install .NET 8 SDK'
      inputs:
        packageType: 'sdk'
        version: '8.x'
    
    # Restore (tylko raz!)
    - script: |
        cd lab5/sample-ci/backend
        dotnet restore
      displayName: 'Restore dependencies'
    
    # Build (tylko raz!)
    - script: |
        cd lab5/sample-ci/backend
        dotnet build --configuration Release --no-restore
      displayName: 'Build application'
    
    # Test (używa już zbudowanej aplikacji)
    - script: |
        cd lab5/sample-ci/backend
        dotnet test ProductApi.Tests/ProductApi.Tests.csproj \
          --configuration Release \
          --no-build \
          --logger trx
      displayName: 'Run unit tests'
    
    - task: PublishTestResults@2
      displayName: 'Publish test results'
      condition: always()
      inputs:
        testResultsFormat: 'VSTest'
        testResultsFiles: '**/TestResults/*.trx'
    
    # Publish (używa już zbudowanej aplikacji)
    - script: |
        cd lab5/sample-ci/backend
        dotnet publish --configuration Release --no-build --output $(Build.ArtifactStagingDirectory)/backend
      displayName: 'Publish artifacts'
    
    - task: PublishBuildArtifacts@1
      displayName: 'Upload artifacts'
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)/backend'
        ArtifactName: 'backend'
```

5. **Analogicznie zoptymalizuj stage `FrontendBuild`** - połącz 3 jobs w jeden!

### 2.3 Optymalizacja #2: Dodaj cache

Dodaj cache dla NuGet packages i node_modules:

**Dla backendu (przed `dotnet restore`):**
```yaml
    # Cache dla NuGet packages
    - task: Cache@2
      displayName: 'Cache NuGet packages'
      inputs:
        key: 'nuget | "$(Agent.OS)" | lab5/sample-ci/backend/**/packages.lock.json,lab5/sample-ci/backend/**/*.csproj'
        path: '$(NUGET_PACKAGES)'
        restoreKeys: |
          nuget | "$(Agent.OS)"
```

**Dla frontendu (przed `npm install`):**
```yaml
    # Cache dla node_modules
    - task: Cache@2
      displayName: 'Cache node_modules'
      inputs:
        key: 'npm | "$(Agent.OS)" | lab5/sample-ci/frontend/package-lock.json'
        path: 'lab5/sample-ci/frontend/node_modules'
        restoreKeys: |
          npm | "$(Agent.OS)"
```

### 2.4 Uruchom zoptymalizowany pipeline

1. Kliknij **Commit**
2. Pipeline uruchomi się automatycznie
3. **Zmierz nowy czas wykonania** i porównaj z poprzednim!

**Oczekiwany wynik:**
- ✅ Czas buildu skrócony o 50-70%
- ✅ Cache działa (zobacz "Cache hit" w logach)
- ✅ Jobs są krótsze i prostsze

### 2.5 Przetestuj cache

1. Uruchom pipeline ponownie (bez zmian w kodzie)
2. Zobacz logi task'a **Cache** - powinno być "Cache restored" ✅
3. Zauważ że `dotnet restore` i `npm install` są **znacznie szybsze**

### 2.6 (Opcjonalnie) Dodaj parallel jobs

Jeśli masz więcej testów, możesz je uruchomić równolegle:

```yaml
    strategy:
      matrix:
        unit_tests:
          testProject: 'ProductApi.Tests'
        integration_tests:
          testProject: 'ProductApi.IntegrationTests'
```

---

## Ćwiczenie 3 – GitHub Actions i optymalizacja

W tym ćwiczeniu stworzysz workflow GitHub Actions i od razu go zoptymalizujesz, stosując najlepsze praktyki.

### 3.1 Stwórz fork repozytorium na GitHub

1. Otwórz https://github.com/rcialowicz/wsei-devops-lab
2. Kliknij **Fork** (prawy górny róg)
3. Stwórz fork w swoim koncie GitHub

### 3.2 Sklonuj swojego forka lokalnie

```powershell
cd ~
git clone https://github.com/<twoj-username>/wsei-devops-lab.git
cd wsei-devops-lab
```

### 3.3 Przeanalizuj nieoptymalizowany workflow

Otwórz plik `lab5/sample-ci/.github/workflows/ci.yml` i znajdź problemy:

- ❌ Każdy job setup'uje .NET/Node od nowa
- ❌ Każdy job robi restore/install od nowa
- ❌ Jobs są sekwencyjne (czekają na siebie)
- ❌ Brak cache dla dependencies

### 3.4 Stwórz zoptymalizowany workflow

Stwórz nowy plik `.github/workflows/ci-optimized.yml`:

```yaml
name: CI (Optimized)

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  # Backend - wszystko w jednym job
  backend:
    name: Backend (.NET)
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: '8.0.x'
    
    # Cache dla NuGet packages
    - name: Cache NuGet packages
      uses: actions/cache@v4
      with:
        path: ~/.nuget/packages
        key: ${{ runner.os }}-nuget-${{ hashFiles('**/packages.lock.json') }}
        restore-keys: |
          ${{ runner.os }}-nuget-
    
    - name: Restore
      run: |
        cd lab5/sample-ci/backend
        dotnet restore
    
    - name: Build
      run: |
        cd lab5/sample-ci/backend
        dotnet build --configuration Release --no-restore
    
    - name: Test
      run: |
        cd lab5/sample-ci/backend
        dotnet test ProductApi.Tests/ProductApi.Tests.csproj \
          --configuration Release \
          --no-build \
          --logger trx
    
    - name: Publish test results
      uses: EnricoMi/publish-unit-test-result-action@v2
      if: always()
      with:
        files: '**/TestResults/*.trx'
    
    - name: Publish artifacts
      run: |
        cd lab5/sample-ci/backend
        dotnet publish --configuration Release --no-build --output ./publish
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v4
      with:
        name: backend
        path: lab5/sample-ci/backend/publish

  # Frontend - wszystko w jednym job (równolegle z backend!)
  frontend:
    name: Frontend (Node.js)
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
        cache-dependency-path: 'lab5/sample-ci/frontend/package-lock.json'
    
    - name: Install dependencies
      run: |
        cd lab5/sample-ci/frontend
        npm ci  # Szybsze niż npm install!
    
    - name: Run tests
      run: |
        cd lab5/sample-ci/frontend
        npm test
    
    - name: Build
      run: |
        cd lab5/sample-ci/frontend
        npm run build
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v4
      with:
        name: frontend
        path: lab5/sample-ci/frontend/dist
```

**Zaobserwuj optymalizacje:**
- ✅ Backend i frontend działają **równolegle** (brak `needs`)
- ✅ Każdy komponent ma **jeden job** zamiast wielu
- ✅ **Cache** dla NuGet i npm (actions/cache + setup-node cache)
- ✅ Używamy `--no-restore`, `--no-build` w .NET
- ✅ Używamy `npm ci` zamiast `npm install` (szybsze w CI)

### 3.5 Commit i push

```powershell
git add .github/workflows/ci-optimized.yml
git commit -m "Add optimized CI workflow"
git push origin main
```

### 3.6 Porównaj czas wykonania

1. Otwórz swoje repo na GitHub: `https://github.com/<twoj-username>/wsei-devops-lab`
2. Przejdź do zakładki **Actions**
3. Zobaczysz dwa workflows: **CI** (wolny) i **CI (Optimized)** (szybki)
4. Porównaj czas wykonania obu!

**Oczekiwany wynik:**
- **CI (wolny):** ~5-10 minut
- **CI (Optimized):** ~2-3 minuty

### 3.7 (Opcjonalnie) Matrix builds

Jeśli chcesz testować na wielu wersjach Node.js:

```yaml
  frontend:
    name: Frontend (Node.js)
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
        cache-dependency-path: 'lab5/sample-ci/frontend/package-lock.json'
    # ... reszta steps
```

---

## Ćwiczenie 4 – Branch policies i Pull Request validation

W tym ćwiczeniu skonfigurujesz branch protection, aby wymagać przejścia zoptymalizowanego pipeline CI przed merge'em.

### 4.1 (Azure DevOps) Skonfiguruj branch policy

1. W Azure DevOps, przejdź do **Repos** → **Branches**
2. Znajdź branch `main` i kliknij ikonę **...** (więcej opcji) → **Branch policies**
3. W sekcji **Build Validation** kliknij **+** (Add)
4. Wybierz swój pipeline (azure-pipelines.yml - zoptymalizowany)
5. **Build expiration:** Immediately
6. ✅ **Policy requirement:** Required
7. Kliknij **Save**
8. W sekcji **Require a minimum number of reviewers:**
   - ✅ **Require a minimum number of reviewers:** 1
   - Kliknij **Save**

### 4.2 Przetestuj branch policy – stwórz Pull Request

1. Lokalnie stwórz nowy branch:

```powershell
git checkout -b feature/improve-ui
```

2. Zmień coś w frontend (np. dodaj style w `lab5/sample-ci/frontend/index.html`):

```html
<style>
    /* ...istniejące style... */
    .container {
        background: white;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1); /* Zmiana z 4px na 8px */
    }
</style>
```

3. Commit i push:

```powershell
git add .
git commit -m "Improve UI shadow"
git push -u origin feature/improve-ui
```

4. W Azure DevOps, przejdź do **Repos** → **Pull requests**
5. Kliknij **New pull request**
6. Source: `feature/improve-ui` → Target: `main`
7. Wypełnij tytuł i opis, kliknij **Create**
8. Zauważ, że PR jest blokowany – pipeline CI (zoptymalizowany) musi przejść ✅
9. Pipeline uruchomi się automatycznie – poczekaj na sukces
10. Dodaj rcialowicz@wsei.edu.pl jako **Reviewer**
11. Po approve prowadzącego, zmerguj PR (**Complete**)

### 4.3 (GitHub) Skonfiguruj branch protection

1. W swoim repo na GitHub, przejdź do **Settings** → **Branches**
2. W sekcji **Branch protection rules** kliknij **Add rule**
3. **Branch name pattern:** `main`
4. ✅ **Require a pull request before merging**
   - ✅ **Require approvals:** 1
5. ✅ **Require status checks to pass before merging**
   - Wyszukaj i zaznacz: `Backend (.NET)`, `Frontend (Node.js)`
6. ✅ **Require branches to be up to date before merging**
7. Kliknij **Create**

### 4.4 Przetestuj branch protection – stwórz Pull Request

1. Lokalnie stwórz nowy branch:

```powershell
git checkout main
git pull origin main
git checkout -b feature/add-footer
```

2. Dodaj footer w frontend (`lab5/sample-ci/frontend/index.html`):

```html
<!-- Na końcu <body>, przed </body> -->
<footer style="text-align: center; margin-top: 20px; padding: 10px; background: #f5f5f5;">
    <p>© 2025 Product Manager | CI/CD Demo</p>
</footer>
```

3. Commit i push:

```powershell
git add .
git commit -m "Add footer with CI/CD info"
git push -u origin feature/add-footer
```

4. W GitHub, otwórz swoje repo → kliknij **Compare & pull request**
5. Wypełnij tytuł i opis, kliknij **Create pull request**
6. Zauważ, że PR jest blokowany – checks muszą przejść ✅
7. Workflow CI (Optimized) uruchomi się automatycznie – poczekaj na sukces
8. Dodaj prowadzącego (rcialowicz) jako **Reviewer**
9. Po approve, zmerguj PR (**Merge pull request**)

---

## Artefakty wymagane do zaliczenia

Prześlij prowadzącemu:

### Opcja A: Azure DevOps
1. **Zrzut ekranu** pokazujący:
   - Lista uruchomionych pipeline'ów w Azure DevOps (Pipelines → Pipelines)
   - **Przed optymalizacją:** Pipeline z wieloma sekwencyjnymi jobs (długi czas)
   - **Po optymalizacji:** Pipeline ze zoptymalizowaną strukturą (krótszy czas)
   - Widok etapów zoptymalizowanego buildu - wszystkie zielone ✅
   - Porównanie czasów: "Przed: X minut" vs "Po: Y minut"

2. **Link do Pull Request** w Azure DevOps:
   - PR z feature brancha do main
   - Pipeline CI (zoptymalizowany) przeszedł ✅
   - Approve prowadzącego (rcialowicz@wsei.edu.pl)
   - PR zmergowany

3. **Krótki opis optymalizacji** (2-3 zdania):
   - Jakie problemy znalazłeś w oryginalnym pipeline?
   - Jakie optymalizacje zastosowałeś?
   - O ile % skrócił się czas buildu?

### Opcja B: GitHub Actions
1. **Zrzut ekranu** pokazujący:
   - Lista workflow runs w GitHub Actions
   - **Workflow "CI"** (nieoptymalizowany) - długi czas
   - **Workflow "CI (Optimized)"** (zoptymalizowany) - krótszy czas
   - Porównanie czasów wykonania
   - Widok jobów zoptymalizowanego workflow - wszystkie zielone ✅

2. **Link do Pull Request** w GitHub:
   - PR z feature brancha do main
   - Workflow CI (Optimized) przeszedł ✅ (wszystkie checks zielone)
   - Approve prowadzącego (rcialowicz)
   - PR zmergowany

3. **Krótki opis optymalizacji** (2-3 zdania):
   - Jakie optymalizacje zastosowałeś?
   - Czy cache działa poprawnie?
   - O ile % skrócił się czas buildu?

### Opcja C: Obie platformy (bonus)
Jeśli zrobiłeś oba ćwiczenia (Azure DevOps + GitHub Actions), prześlij artefakty z obu platform – otrzymasz dodatkowe punkty! 🎉

---

## Troubleshooting

### Problem: Pipeline failuje na etapie Build (.NET)
**Rozwiązanie:**
- Sprawdź logi buildu – szukaj błędów kompilacji
- Upewnij się, że ścieżki do projektów .csproj są prawidłowe
- Zweryfikuj wersję .NET SDK (powinna być 8.x)

### Problem: Pipeline failuje na etapie Test
**Rozwiązanie:**
- Sprawdź, czy testy przechodzą lokalnie: `dotnet test`
- Upewnij się, że wszystkie pliki testowe są zacommitowane
- Zobacz dokładny błąd w logach task'a Test

### Problem: npm install jest bardzo wolny
**Rozwiązanie:**
- Upewnij się, że używasz cache (actions/cache lub Cache@2)
- Użyj `npm ci` zamiast `npm install` w CI
- Sprawdź czy package-lock.json jest zacommitowany

### Problem: Cache nie działa (zawsze "Cache miss")
**Rozwiązanie:**
- Sprawdź klucz cache - czy hashFiles() wskazuje na prawidłowe pliki?
- Dla .NET: packages.lock.json musi istnieć (generowany przez `dotnet restore --use-lock-file`)
- Dla npm: package-lock.json musi być zacommitowany
- Zobacz logi task'a Cache - pokaże dlaczego cache miss

### Problem: Jobs wykonują się sekwencyjnie zamiast równolegle
**Rozwiązanie:**
- Usuń `dependsOn` / `needs` między jobs, które mogą działać równolegle
- Backend i Frontend mogą działać równolegle - nie powinny od siebie zależeć

### Problem: dotnet build powtarza restore
**Rozwiązanie:**
- Użyj flagi `--no-restore` w `dotnet build`
- Użyj flagi `--no-build` w `dotnet test` i `dotnet publish`
- Upewnij się że restore jest wykonany **przed** buildem w tym samym job

---

## Co dalej?

Gratulacje! Właśnie stworzyłeś i **zoptymalizowałeś** kompletny pipeline CI, który:
- ✅ Automatycznie buduje backend (.NET) i frontend (Node.js) przy każdym commicie
- ✅ Uruchamia testy jednostkowe dla obu komponentów
- ✅ Publikuje artefakty (binaria .NET, built frontend)
- ✅ Używa cache dla przyspieszenia buildów
- ✅ Wykonuje joby równolegle gdzie to możliwe
- ✅ Wymusza code review i przejście CI przed merge'em (branch policies)

**Najważniejsze lekcje z optymalizacji:**
1. 🚀 **Łącz related steps w jeden job** - unikaj powtarzania setup i restore
2. 💾 **Używaj cache** - NuGet packages, node_modules
3. ⚡ **Paralelizuj** - backend i frontend mogą działać równocześnie
4. 🎯 **Używaj flag optymalizacyjnych** - `--no-restore`, `--no-build`, `npm ci`
5. 📊 **Mierz i porównuj** - zawsze sprawdzaj czy optymalizacja zadziałała

**Typowe oszczędności czasu po optymalizacji:**
- Cache dla dependencies: **30-50%** szybciej
- Połączenie jobs: **20-40%** szybciej
- Paralelizacja: **40-60%** szybciej
- **Łącznie: 50-80% redukcja czasu buildu!** 🎉

**Następne kroki:**
- **Lab 6 (Continuous Delivery):** Automatyczny deployment do Azure (App Service, AKS)
- **Lab 7 (GitOps):** Deployment zarządzany przez Git (ArgoCD, Flux)

**Dalsze nauki (self-paced):**
- Dodaj code coverage gate (np. minimum 80% pokrycia testami)
- Zintegruj security scanning (Snyk, Trivy dla zależności)
- Dodaj notification do Microsoft Teams / Slack przy failed build
- Eksperymentuj z matrix builds (testuj na wielu wersjach .NET / Node.js)
- Dodaj performance tests (np. k6, Apache Bench)
- Zintegruj SonarCloud dla analizy jakości kodu (opcjonalne ćwiczenie poniżej)

---

## Ćwiczenie bonus – Integracja z SonarCloud (opcjonalnie)

Jeśli chcesz dodać analizę jakości kodu, możesz zintegrować SonarCloud:

### 1. Stwórz konto SonarCloud
1. Otwórz https://sonarcloud.io
2. Zaloguj się przez GitHub
3. Dodaj swoje repo do analizy

### 2. Dodaj do GitHub Actions workflow

```yaml
  sonarcloud:
    name: SonarCloud Analysis
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0  # Full history dla lepszej analizy
    
    - name: SonarCloud Scan
      uses: SonarSource/sonarcloud-github-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### 3. Stwórz sonar-project.properties

```properties
sonar.projectKey=<twoj-username>_wsei-devops-lab
sonar.organization=<twoja-org>
sonar.sources=lab5/sample-ci
sonar.exclusions=**/node_modules/**,**/bin/**,**/obj/**
```

---

## Dodatkowe zasoby

- [Azure Pipelines documentation](https://learn.microsoft.com/azure/devops/pipelines/)
- [GitHub Actions documentation](https://docs.github.com/actions)
- [SonarCloud documentation](https://docs.sonarcloud.io/)
- [.NET testing in CI/CD](https://learn.microsoft.com/dotnet/core/testing/unit-testing-best-practices)

---

> Powodzenia! Jeśli masz pytania podczas ćwiczeń, zgłoś się do prowadzącego.
