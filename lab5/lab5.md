# Laboratorium 5 – Continuous Integration (CI)

## Prerekwizyty
1. **Konto GitHub** (https://github.com/signup) - **WYMAGANE**
2. Git zainstalowany lokalnie
3. .NET 8 SDK i Node.js 20 zainstalowane lokalnie (do testowania lokalnie)
4. Edytor kodu (VS Code, Visual Studio, lub inny)

> **Uwaga:** W tym laboratorium używamy **GitHub Actions** jako platformy CI/CD. Azure DevOps wymaga approval dla Microsoft-hosted agents w free tier, dlatego koncentrujemy się na GitHub.

---

## Przygotowanie

### 0.1 Załóż konto GitHub (jeśli nie masz)

1. Przejdź do https://github.com/signup
2. Wprowadź email, hasło, username
3. Zweryfikuj email
4. Wybierz **Free plan**

### 0.2 Stwórz fork repozytorium na GitHub

1. Otwórz https://github.com/rcialowicz/wsei-devops-lab
2. Kliknij **Fork** (prawy górny róg)
3. Stwórz fork w swoim koncie GitHub
4. Poczekaj aż fork się utworzy

### 0.3 Sklonuj swojego forka lokalnie

```powershell
cd ~
git clone https://github.com/<twoj-username>/wsei-devops-lab.git
cd wsei-devops-lab/lab5/sample-ci
```

Zastąp `<twoj-username>` swoim username na GitHub.

### 0.4 Struktura projektu
```
wsei-devops-lab/
├── .github/workflows/
│   ├── ci.yml                 # Workflow GitHub Actions (NIEOPTYMALIZOWANY)
│   └── ci-optimized.yml       # Workflow zoptymalizowany
└── lab5/sample-ci/
    ├── backend/                # Backend API (.NET 8)
    │   ├── Program.cs
    │   ├── ProductApi.csproj
    │   └── ProductApi.Tests/
    └── frontend/               # Frontend (HTML/JS)
        ├── index.html
        ├── app.js
        ├── package.json
        └── app.test.js
```

---

## Ćwiczenie 1 – Uruchomienie nieoptymalizowanego workflow CI

W tym ćwiczeniu uruchomisz workflow GitHub Actions, który automatycznie zbuduje i przetestuje backend (.NET) oraz frontend (Node.js) przy każdym push do brancha `main`.

**UWAGA:** Workflow jest celowo **NIEOPTYMALIZOWANY** - Twoje zadanie w dalszej części to go zoptymalizować!

### 1.1 Przejrzyj plik .github/workflows/ci.yml

W swoim sklonowanym repozytorium otwórz plik `lab5/sample-ci/.github/workflows/ci.yml`. Zauważ problemy:
.github/workflows/ci.yml` (w root repozytorium)
**Problemy do znalezienia:**
- ❌ Backend ma 4 osobne jobs (restore, build, test, publish) - wszystkie **sekwencyjne**
- ❌ Każdy job robi `dotnet restore` od nowa (brak cache)
- ❌ Build jest powtarzany w wielu job'ach
- ❌ Frontend ma 3 osobne jobs (install, test, build) - też **sekwencyjne**
- ❌ Każdy job robi `npm install` od nowa (brak cache)
- ❌ Backend i frontend czekają na siebie (needs), mimo że mogłyby działać równolegle

**Przeczytaj komentarze w YAML - są oznaczone jako `# PROBLEM:`**

### 1.2 Push do swojego forka aby uruchomić workflow

Workflow uruchomi się automatycznie przy push do `main`. Zróbmy małą zmianę:

```powershell
cd ~/wsei-devops-lab
git checkout main
echo "# Lab 5 - CI Optimization" >> lab5/sample-ci/README.md
git add .
git commit -m "Trigger CI workflow"
git push origin main
```

### 1.3 Obserwuj (wolne) wykonanie workflow

1. Otwórz swoje repo na GitHub: `https://github.com/<twoj-username>/wsei-devops-lab`
2. Przejdź do zakładki **Actions**
3. Zobaczysz workflow **CI** - kliknij na ostatni run
4. Zobacz jobs:
   - **backend-restore** → **backend-build** → **backend-test** → **backend-publish** (wszystkie **sekwencyjne** ❌)
   - **frontend-install** → **frontend-test** → **frontend-build** (też **sekwencyjne** ❌)
   - Backend i Frontend czekają na siebie mimo że mogłyby działać równolegle ❌

**Zapisz całkowity czas wykonania workflow** - będziesz go porównywać po optymalizacji!

### 1.4 Przeanalizuj logi

Kliknij na każdy job i zobacz logi:

- Czy `.NET SDK` / `Node.js` jest setupowane wielokrotnie?
- Czy `dotnet restore` / `npm install` jest wykonywany wielokrotnie?
- Ile czasu zajmuje każda operacja?
- Czy widzisz "Cache restored" gdziekolwiek? (Nie - brak cache! ❌)

**Zrób zrzut ekranu pokazujący czasy poszczególnych jobs.**

---

## Ćwiczenie 2 – Optymalizacja workflow (GitHub Actions)

W tym ćwiczeniu zoptymalizujesz workflow, aby był **znacznie szybszy**. Zastosujesz najlepsze praktyki CI/CD.

### 2.1 Analiza problemów

Workflow z Ćwiczenia 1 ma następujące problemy:

1. **Jobs są sekwencyjne** - backend jobs czekają na siebie, frontend jobs czekają na siebie
2. **Backend i frontend czekają na siebie** - mimo że mogłyby działać równolegle
3. **Brak cache** - każdy job robi `dotnet restore` / `npm install` od nowa
4. **Powtarzanie operacji** - `dotnet build` jest wykonywany w każdym job
5. **Brak optymalizacji** - nie używamy flag `--no-restore`, `--no-build`, `npm ci`

**Twoje zadanie:** Napraw te problemy!

### 2.2 Stwórz zoptymalizowany workflow

W swoim repozytorium już jest plik `.github/workflows/ci-optimized.yml` (w root repozytorium) - to wzorcowa implementacja. Przejrzyj go:

```powershell
cd ~/wsei-devops-lab
cat .github/workflows/ci-optimized.yml
```

**Zaobserwuj optymalizacje:**
- ✅ Backend i frontend działają **równolegle** (brak `needs` między nimi)
- ✅ Każdy komponent ma **jeden job** zamiast wielu (wszystkie kroki w jednym miejscu)
- ✅ **Cache** dla NuGet packages (`actions/cache`) i node_modules (built-in w `setup-node`)
- ✅ Używamy `--no-restore`, `--no-build` w .NET
- ✅ Używamy `npm ci` zamiast `npm install` (szybsze w CI)

### 2.3 Uruchom zoptymalizowany workflow

Workflow `ci-optimized.yml` uruchomi się automatycznie przy każdym pushu. Zróbmy push:

```powershell
git add .
git commit -m "Add optimized workflow" --allow-empty
git push origin main
```

### 2.4 Porównaj czasy wykonania

1. Otwórz swoje repo na GitHub: `https://github.com/<twoj-username>/wsei-devops-lab`
2. Przejdź do zakładki **Actions**
3. Zobaczysz dwa workflows:
   - **CI** (wolny, nieoptymalizowany)
   - **CI - Optimized** (szybki, zoptymalizowany)
4. Kliknij na ostatni run workflow **CI - Optimized**
5. **Zmierz czas wykonania** i porównaj z workflow **CI**!

**Oczekiwany wynik:**
- ✅ Czas buildu skrócony o 40-60%
- ✅ Cache działa (zobacz "Cache restored" w logach Setup .NET i Setup Node.js)
- ✅ Backend i Frontend działają równolegle
- ✅ Jobs są krótsze i prostsze (jeden job na komponent)

**Zrób zrzut ekranu porównujący czasy obu workflows.**

### 2.5 Przetestuj cache

1. Uruchom workflow ponownie (bez zmian w kodzie):

```powershell
git commit -m "Test cache" --allow-empty
git push origin main
```

2. Zobacz logi **CI - Optimized** workflow:
   - W kroku **Setup .NET** → **Cache NuGet packages** powinno być "Cache hit" ✅
   - W kroku **Setup Node.js** powinno być "Cache restored" ✅
3. Zauważ że `dotnet restore` i `npm ci` są **znacznie szybsze** (pomijają download)

### 2.6 (Opcjonalnie) Stwórz własną optymalizację

Zamiast używać gotowego `ci-optimized.yml`, możesz samodzielnie zoptymalizować `ci.yml`:

1. Skopiuj `.github/workflows/ci.yml` do `.github/workflows/ci-my-optimization.yml`
2. Połącz backend jobs w jeden (wszystkie kroki w `backend` job)
3. Połącz frontend jobs w jeden (wszystkie kroki w `frontend` job)
4. Usuń `needs` między backend a frontend (niech działają równolegle)
5. Dodaj cache dla NuGet i npm
6. Dodaj flagi `--no-restore`, `--no-build`, użyj `npm ci`
7. Push i porównaj czasy!

---

## Ćwiczenie 3 – Branch protection i Pull Request validation

W tym ćwiczeniu skonfigurujesz branch protection na GitHub, aby wymagać przejścia zoptymalizowanego workflow CI przed merge'em.

### 3.1 Skonfiguruj branch protection na GitHub

1. W swoim repo na GitHub, przejdź do **Settings** → **Branches**
2. W sekcji **Branch protection rules** kliknij **Add rule**
3. **Branch name pattern:** `main`
4. ✅ **Require a pull request before merging**
   - ✅ **Require approvals:** 1
5. ✅ **Require status checks to pass before merging**
   - Wyszukaj i zaznacz: `Backend (.NET)`, `Frontend (Node.js)` (z workflow CI - Optimized)
6. ✅ **Require branches to be up to date before merging**
7. Kliknij **Create**

### 3.2 Przetestuj branch protection – stwórz Pull Request

1. Lokalnie stwórz nowy branch:

```powershell
cd ~/wsei-devops-lab
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
7. Workflow **CI - Optimized** uruchomi się automatycznie – poczekaj na sukces
8. Dodaj prowadzącego (rcialowicz) jako **Reviewer**
9. Po approve, zmerguj PR (**Merge pull request**)

### 3.3 (Opcjonalnie) Przetestuj failed check

Zrób PR który **nie przejdzie** testów:

1. Stwórz branch `feature/break-tests`
2. W `lab5/sample-ci/backend/ProductApi.Tests/ProductTests.cs` zmień oczekiwaną wartość:

```csharp
// Zmień z 0 na 999
Assert.Equal(999, products.Count);  // To failuje!
```

3. Push i stwórz PR
4. Workflow failuje ❌
5. PR jest zablokowany – nie można zmergować!
6. Popraw test, push ponownie → workflow przechodzi ✅ → można mergować

---

## Artefakty wymagane do zaliczenia

Prześlij prowadzącemu:

1. **Zrzut ekranu** pokazujący:
   - Lista workflow runs w GitHub Actions
   - **Workflow "CI"** (nieoptymalizowany) - długi czas
   - **Workflow "CI - Optimized"** (zoptymalizowany) - krótszy czas
   - Porównanie czasów wykonania (np. "CI: 8m 23s" vs "CI - Optimized: 3m 12s")
   - Widok jobów zoptymalizowanego workflow - wszystkie zielone ✅

2. **Link do Pull Request** w GitHub:
   - PR z feature brancha do main
   - Workflow **CI - Optimized** przeszedł ✅ (wszystkie checks zielone)
   - Approve prowadzącego (rcialowicz)
   - PR zmergowany

3. **Krótki opis optymalizacji** (2-3 zdania):
   - Jakie optymalizacje zastosowałeś?
   - Czy cache działa poprawnie?
   - O ile % skrócił się czas buildu?

**Przykład opisu optymalizacji:**
> "Połączyłem wszystkie backend jobs w jeden (restore+build+test+publish) i analogicznie frontend. Dodałem cache dla NuGet packages (actions/cache) i node_modules (setup-node cache). Użyłem flag --no-restore, --no-build w .NET oraz npm ci zamiast npm install. Czas buildu skrócił się z 8m 23s do 3m 12s (62% redukcja). Cache działa - drugi run był jeszcze szybszy (2m 45s)."

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

- [GitHub Actions documentation](https://docs.github.com/actions)
- [GitHub Actions: Caching dependencies](https://docs.github.com/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [SonarCloud documentation](https://docs.sonarcloud.io/)
- [.NET testing in CI/CD](https://learn.microsoft.com/dotnet/core/testing/unit-testing-best-practices)

---

> Powodzenia! Jeśli masz pytania podczas ćwiczeń, zgłoś się do prowadzącego.
