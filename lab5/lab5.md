# Laboratorium 5 – Continuous Integration (CI)

## Prerekwizyty
1. **Konto GitHub** (https://github.com/signup) - **WYMAGANE**
2. Git zainstalowany lokalnie

> **Uwaga:** W tym laboratorium używamy **GitHub Actions** jako platformy CI/CD. Azure DevOps wymaga approval dla Microsoft-hosted agents w free tier, dlatego koncentrujemy się na GitHub.

---

## Przygotowanie

### 0.1 Załóż konto GitHub (jeśli nie masz)

1. Przejdź do https://github.com/signup
2. Załóż konto zgodnie z przedstawioną intrukcją
4. Jeśli zostaniesz poproszony o wybór planu wybierz **Free plan**

### 0.2 Stwórz fork repozytorium na GitHub

1. Otwórz https://github.com/rcialowicz/wsei-devops-lab
2. Kliknij **Fork** (prawy górny róg)
3. Stwórz fork w swoim koncie GitHub
4. Poczekaj aż fork się utworzy

> **Uwaga:** Jeśli masz problem ze stworzeniem forka, możesz sklonować repozytorium lokalnie, skopiować pliki, a następnie zrobić ich push do swojego repozytorium.

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
    │   ├── ProductApi/
    │   │   ├── Program.cs
    │   │   ─── ProductApi.csproj
    │   ─── ProductApi.Tests/
    │       ├── ProductTests.cs
    │       ─── ProductApi.Tests.csproj
    └── frontend/               # Frontend (HTML/JS)
        ├── index.html
        ├── app.js
        ├── package.json
        └── app.test.js
```

---

## Ćwiczenie 1 – Uruchomienie nieoptymalizowanego workflow CI

W tym ćwiczeniu uruchomisz workflow GitHub Actions, który automatycznie zbuduje i przetestuje backend (.NET) oraz frontend (Node.js) przy każdym push do brancha `main`.

### 1.1 Przejrzyj plik .github/workflows/ci.yml

W swoim sklonowanym repozytorium otwórz plik `.github/workflows/ci.yml` (w root repozytorium). Spróbuj znaleźć potencjalne problemy.

### 1.2 Push do swojego forka aby uruchomić workflow

Workflow uruchomi się automatycznie przy push do `main`. Zrób małą zmianę:

```powershell
cd ~/wsei-devops-lab
git checkout main
echo "# Lab 5 - CI Optimization" >> lab5/sample-ci/README.md
git add .
git commit -m "Trigger CI workflow"
git push origin main
```

### 1.3 Obserwuj wykonanie workflow

1. Otwórz swoje repo na GitHub: `https://github.com/<twoj-username>/wsei-devops-lab`
2. Przejdź do zakładki **Actions**
3. Zobaczysz workflow **CI** - kliknij na ostatni run
4. Zobacz jobs:
   - **backend-restore** → **backend-build** → **backend-test** → **backend-publish**
   - **frontend-install** → **frontend-test** → **frontend-build**

**Zapisz całkowity czas wykonania workflow** - będziesz go porównywać po optymalizacji!

### 1.4 Przeanalizuj logi

Kliknij na każdy job i zobacz logi:

- Czy `.NET SDK` / `Node.js` jest setupowane wielokrotnie?
- Czy `dotnet restore` / `npm install` jest wykonywany wielokrotnie?
- Ile czasu zajmuje każda operacja?
- Czy widzisz "Cache restored" gdziekolwiek?

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

Skopiuj plik `ci.yml` i stwórz nową, zoptymalizowaną wersję:

```powershell
cd ~/wsei-devops-lab
cp .github/workflows/ci.yml .github/workflows/ci-optimized.yml
```

#### Optymalizacja 1: Połącz backend jobs w jeden

Obecny workflow ma 4 osobne jobs dla backendu (`backend-restore` → `backend-build` → `backend-test` → `backend-publish`). **Usuń je wszystkie i stwórz jeden job `backend`** z tą samą nazwą `Backend (.NET)`.

**Co zmienić:**
1. Połącz wszystkie steps z 4 jobs w jeden job
2. Setup .NET tylko raz na początku
3. **Dodaj cache dla NuGet packages** przed krokiem restore:
   ```yaml
   - name: Cache NuGet packages
     uses: actions/cache@v4
     with:
       path: ~/.nuget/packages
       key: ${{ runner.os }}-nuget-${{ hashFiles('lab5/sample-ci/backend/**/*.csproj') }}
   ```
4. W kroku build dodaj flagę `--no-restore`:
   ```bash
   dotnet build --no-restore --configuration Release
   ```
5. W krokach test i publish dodaj flagę `--no-build`:
   ```bash
   dotnet test --no-build --configuration Release --logger trx
   dotnet publish --no-build --configuration Release --output ./publish
   ```

**Rezultat:** Jeden job zamiast czterech, jeden setup SDK, cache dla dependencies.

#### Optymalizacja 2: Połącz frontend jobs w jeden

Analogicznie, **usuń 3 frontend jobs i stwórz jeden job `frontend`** z nazwą `Frontend (Node.js)`.

**Co zmienić:**
1. Połącz wszystkie steps w jeden job
2. W setup-node **włącz built-in cache**:
   ```yaml
   - name: Setup Node.js
     uses: actions/setup-node@v4
     with:
       node-version: '20'
       cache: 'npm'
       cache-dependency-path: lab5/sample-ci/frontend/package-lock.json
   ```
3. Użyj `npm ci` zamiast `npm install`:
   ```bash
   npm ci
   ```

**Rezultat:** Jeden job zamiast trzech, built-in cache dla node_modules.

#### Optymalizacja 3: Usuń dependencies między backend a frontend

W oryginalnym workflow backend i frontend czekają na siebie poprzez `needs:`. **Usuń wszystkie `needs:`** między nimi - mogą działać **równolegle**!

Upewnij się, że w pliku **NIE MA** takich linii:
```yaml
needs: backend  # USUŃ!
needs: frontend  # USUŃ!
```

**Rezultat:** Backend i frontend startują jednocześnie, nie czekają na siebie.

### 2.3 Uruchom zoptymalizowany workflow

Zapisz plik `.github/workflows/ci-optimized.yml` i zrób commit:

```powershell
git add .github/workflows/ci-optimized.yml
git commit -m "Add optimized CI workflow"
git push origin main
```

### 2.4 Porównaj czasy wykonania

1. Otwórz swoje repo na GitHub: `https://github.com/<twoj-username>/wsei-devops-lab`
2. Przejdź do zakładki **Actions**
3. Zobaczysz dwa workflows działające równocześnie:
   - **CI** (wolny, nieoptymalizowany - 9 jobs sekwencyjnych)
   - **CI - Optimized** (szybki, zoptymalizowany - 2 jobs równoległe)
4. Poczekaj aż oba się zakończą
5. **Zmierz czas wykonania** każdego workflow i porównaj!

**Oczekiwany wynik:**
- ✅ Czas buildu skrócony o **50-70%** (np. z 8 minut do 3 minut)
- ✅ Backend i Frontend działają **równolegle** (zobacz timeline)
- ✅ Każdy komponent ma tylko **1 job** zamiast 3-4

**Zrób zrzut ekranu porównujący czasy obu workflows.**

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
    <p>© 2025 WSEI | CI/CD Demo</p>
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
8. Approve, zmerguj PR (**Merge pull request**)

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
   - PR zmergowany

3. **Krótki opis optymalizacji** (2-3 zdania):
   - Jakie optymalizacje zastosowałeś?
   - Czy cache działa poprawnie?
   - O ile % skrócił się czas buildu?

---
