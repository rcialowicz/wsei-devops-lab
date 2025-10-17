# 🛠 Laboratorium 2 – Helper: Instalacja i Środowisko

Ten plik zawiera szczegółowe instrukcje instalacji oraz nietypowe kroki przygotowania środowiska dla ćwiczeń z pliku `lab2.md`. W samym `lab2.md` pozostają wyłącznie właściwe ćwiczenia.

## ✅ Minimalny zestaw narzędzi
1. Git
2. Terminal / powłoka (PowerShell, Bash, Zsh)
3. Opcjonalnie: edytor (VS Code)
4. (Opcjonalnie) `tree` do podglądu struktury katalogów

---
## 🔎 Sprawdzenie czy Git jest zainstalowany
```bash
git --version
```
Jeśli komenda zwraca numer wersji – przejdź dalej. Jeśli komunikat o braku polecenia, użyj metod poniżej.

---
## 🪟 Windows (bez uprawnień administratora)
### Portable Git (polecane w środowisku ograniczonym)
1. Wejdź na: https://git-scm.com/download/win
2. Pobierz wersję "Portable" (ZIP).
3. Rozpakuj do: `C:\Users\<user>\PortableGit`
4. Dodaj do PATH dla bieżącej sesji PowerShell:
```powershell
$env:Path += ";C:\Users\$env:USERNAME\PortableGit\bin"
git --version
```

### Scoop (jeśli możesz zmienić ExecutionPolicy)
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
irm get.scoop.sh | iex
scoop install git
```
> Jeśli ExecutionPolicy jest zablokowane – pozostań przy portable.

### `tree` w Windows
Polecenie jest dostępne natywnie (CMD). W PowerShell:
```powershell
tree /F /A
```

---
## 🐧 Linux (bez sudo)
Najpierw sprawdź:
```bash
git --version || echo "Git not found"
```
### Instalacja przez conda (jeśli dostępne)
```bash
conda install -y git
```

### Kompilacja ze źródeł (czasochłonne – tylko jeśli konieczne)
```bash
mkdir -p $HOME/src && cd $HOME/src
curl -L https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.46.0.tar.xz -o git.tar.xz
tar -xf git.tar.xz && cd git-2.46.0
make configure
./configure --prefix=$HOME/.local
make -j$(nproc)
make install
echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc
source $HOME/.bashrc
git --version
```
> Jeśli brakuje `curl` lub `make`, a nie masz sudo – wybierz środowisko alternatywne (Codespaces / GitPod).

### Zamiennik dla `tree`
```bash
find . -maxdepth 2 -type f
```

---
##  macOS (bez admina)
### Wbudowany Git (Xcode Command Line Tools)
```bash
git --version
```
Jeśli system prosi o instalację narzędzi – zaakceptuj (jeśli masz uprawnienia). W przeciwnym wypadku użyj conda.

### Instalacja przez conda
```bash
conda install -y git
```

### Zamiennik dla `tree`
```bash
find . -maxdepth 2 -print
```

---
## 🌐 Alternatywy bez lokalnej instalacji
| Opcja | Zalety | Wady |
|-------|--------|------|
| GitHub Codespaces | Kompletny VS Code w przeglądarce | Limit godzin / wymagane konto GH |
| GitPod | Szybkie startowe środowisko | Może wymagać konfigu pliku `.gitpod.yml` |
| Azure DevOps Hosted Agent (przez Pipeline) | Automatyczne środowisko CI | Nieinteraktywne dla nauki terminala |
| WSL (Windows) | Pełny Linux obok Windows | Często wymaga admina przy instalacji |

---
## 🔐 Dobre praktyki przy braku uprawnień
- Nie zapisuj nic do `C:\Windows`, `/usr`, `/etc`.
- Trzymaj narzędzia w katalogu domowym.
- Modyfikuj PATH tylko w bieżącej sesji (unikasz potrzeby edycji plików systemowych).
- Unikaj kompilacji jeśli ograniczony czas na zajęciach.

---
## 🧪 Weryfikacja środowiska przed startem ćwiczeń
```bash
git --version
whoami
pwd
echo $PATH | grep -i git || echo "(Git directory not visible in PATH)"
```
Jeśli Git nadal niedostępny: wybierz Codespaces / GitPod.

---
## 🔄 Konfiguracja Git (przypomnienie)
```bash
git config --global user.name "Imie Nazwisko"
git config --global user.email "twoj.email@example.com"
git config --global init.defaultBranch main
git config --global core.autocrlf true   # Windows zalecane
git config --global pull.ff only          # Wymuszaj fast-forward
```
Weryfikacja:
```bash
git config --list --show-origin | grep -E "user.name|user.email|init.defaultBranch"
```

---
## 🔑 Azure DevOps – uwierzytelnianie HTTPS (PAT)
Jeśli klonując repo przez HTTPS pojawia się prompt na hasło:
1. Przejdź: User Settings (ikonka w prawym górnym rogu) → Personal Access Tokens.
2. Utwórz nowy token (scope: minimalnie `Code (Read & Write)`), ustaw krótki czas ważności (np. 7 dni).
3. Podczas klonowania użyj tokenu jako hasło.

Regeneracja / odwołanie tokenu – zawsze usuń tokeny po zakończeniu kursu.

---
## 🧩 Useful (opcjonalne) aliasy Git
Dodaj do `~/.gitconfig` (sekcja `[alias]`):
```
[alias]
  st = status -sb
  co = checkout
  sw = switch
  br = branch
  lg = log --oneline --graph --decorate --all
  df = diff
  cia = commit --amend --no-edit
```
Użycie przykładowe:
```bash
git st
git lg
```

---
## 🧹 Porządkowanie środowiska
Katalogi tymczasowe do usunięcia po laboratorium:
- `PortableGit/` (jeśli chcesz zwolnić miejsce)
- `~/src/git-<version>` (po kompilacji)

Tokeny PAT w Azure DevOps – usuń w UI po zakończeniu.

---
## ❓ FAQ (skrót)
**Pyt:** Dlaczego `git push -u origin feature/xyz`?  
**Odp:** Ustawia upstream – kolejne `git push` / `git pull` bez parametrów będą odnosić się do tej gałęzi.

**Pyt:** Co jeśli `git pull --ff-only` zwraca błąd?  
**Odp:** Twoja lokalna historia rozchodzi się ze zdalną – potrzebny merge lub rebase (poza zakresem tego labu) albo sklonowanie od nowa jeśli to testowe repo.

**Pyt:** Czy mogę użyć SSH zamiast HTTPS?  
**Odp:** Tak, ale wymaga generacji kluczy (zwykle brak uprawnień / czasu na zajęcia). W tym labie preferujemy HTTPS + PAT.

---
## 📚 Dodatkowe materiały (instalacja)
- Git Downloads: https://git-scm.com/downloads
- Azure DevOps PAT docs: https://learn.microsoft.com/azure/devops/organizations/accounts/use-personal-access-tokens
- Git Config: https://git-scm.com/docs/git-config
- Scoop: https://scoop.sh/
- Conda: https://docs.conda.io/
- Codespaces: https://github.com/features/codespaces

> Ten plik jest dodatkiem. Jeśli studenci mają gotowe środowisko – mogą go pominąć.
