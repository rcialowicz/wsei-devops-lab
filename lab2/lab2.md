# Laboratorium 2 – Linux + Git Fundamentals

## Prerekwizyty / Instalacja narzędzi
Szczegółowe instrukcje (Windows/Linux/macOS, portable Git, conda, PAT Azure DevOps, aliasy) znajdują się w pliku: `lab2/lab2-helpers.md`.

1. Uruchom **PowerShell**:
   ```
   powershell -ExecutionPolicy -Bypass
   ```
2. Szybka weryfikacja środowiska przed startem:
   ```
   git --version
   whoami
   pwd
   ```
3. Jeśli `git --version` zwraca błąd – otwórz plik helper i wykonaj odpowiednie kroki

---


## 1. Stwórz repozytorium
1. Otwórz stronę dev.azure.com/*nazwaorganizacji*
2. Otwórz projekt
3. Po lewej z menu wybierz Repos
4. Stwórz nowe repo z domyślnymi ustawieniami, nazwij je np. devops-lab2
5. Naciśnij przycisk Clone i skopiuj adres url (https://rcialowicz@dev.azure.com/rcialowicz/wsei-devops-lab/_git/devops-lab2)

## 2. Lokalna praca z repozytorium
1. Stwórz katalog devops-lab2
   ```
   mkdir devops-lab2
   ```
2. Wejdź do nowego katalogu
   ```
   cd devops-lab2
   ```
3. Sklonuj repozytorium lokalnie
   ```
   git clone <skopiowany wcześniej url> .
   ```
4. Potwierdź poprawność operacji
   ```
   ls
   git remote -v
   ```
5. Stwórz plik .gitignore z następującą treścią
   ```
   [Dd]ebug/
   [Dd]ebugPublic/
   [Rr]elease/
   [Rr]eleases/
   x64/
   x86/
   [Ww][Ii][Nn]32/
   [Aa][Rr][Mm]/
   [Aa][Rr][Mm]64/
   bld/
   [Bb]in/
   [Oo]bj/
   [Ll]og/
   [Ll]ogs/
   ```

## 3. Przykładowy worflow pracy z repozytorium
### 3.1 Stwórz projekt
1. Będąc w katalogu devops-lab2 utwórz katalog projektu
   ```
   mkdir MyApp
   cd MyApp
   ```
2. Utwórz solucję
   ```
   dotnet new sln -n MyApp
   ```
3. Utwórz projekt Web API
   ```
   dotnet new web -n MyApp
   dotnet sln add MyApp/MyApp.csproj
   ```
4. Zweryfikuj poprawność operacji
   ```
   dotnet build
   ```
5. Popchnij swoje zmiany do zdalnego repozytorium
   Przed pierwszym pushem możliwe, że będzie trzeba dokonać wstępnej konfiguracji
   ```
   git config --global user.name "Imie Nazwisko"
   git config --global user.email "twoj.email@example.com"
   ```
   ```
   cd..
   git add *
   git commit -a -m "This is my first commit"
   git push
   ```

### 3.2 Stwórz nową funkcjonalność - testy
1. Będąc w katalogu devops-lab2 utwórz nową gałąź
   ```
   git switch -c feature/tests-added
   ```
2. Utwórz projekt testów xUnit
   ```
   cd MyApp
   dotnet new xunit -n MyApp.Tests
   dotnet sln add MyApp.Tests/MyApp.Tests.csproj
   dotnet add MyApp.Tests/MyApp.Tests.csproj reference MyApp/MyApp.csproj
   ```
5. Zweryfikuj poprawność operacji
   ```
   dotnet test
   ```
6. Popchnij swoje zmiany do zdalnego repozytorium na oddzielnej gałęzi
   ```
   cd..
   git add .
   git commit -a -m "Tests were added to the solution"
   git push -u origin feature/tests-added
   ```
6. Utwórz Pull Request w Azure DevOps (UI) i zmerguj
	- W ADO: Repos > Pull requests > New pull request
	- Źródło: `feature/tests-added` → Cel: `main`
	- Uzupełnij tytuł i opis (krótko)
	- Dodaj reviewera (rcialowicz@wsei.edu.pl)
	- Naciśnij przycisk Create
	- Zaakceptuj i kliknij "Complete"

7. Po zmergowaniu zaktualizuj local `main` i usuń gałąź
   ```
   git switch main
   git pull --ff-only origin main
   git branch -d feature/tests-added
   ```

### 3.3 Kontynuuj pracę z repozytorium
Powtórz punkt 3.2. z inną funkcjonalnością, tj.
1. Stwórz dowolną funkcjonalność w odrębnej branchy
2. Stwórz PR w Azure DevOps
3. Dodaj rcialowicz@wsei.edu.pl jako reviewer
4. Poczekaj na approve!
5. Zmerguj PR

Wymagane artefakty (do przesłania prowadzącemu):
- URL repo (Azure DevOps)
- Link do PR
- Approve prowadzącego w PR
