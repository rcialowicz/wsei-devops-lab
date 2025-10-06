# 🔹 Ćwiczenia krok po kroku

## Ćwiczenie 1 – Logowanie do Azure

1. Uruchom **PowerShell**:
   ```
   powershell -ExecutionPolicy -Bypass
   ```
2. Zainstaluj moduł Azure:
   ```
   Install-Module -Name Az -Scope CurrentUser -Repository PSGallery
   ```
3. Zaloguj się:
   ```
   Connect-AzAccount
   ```
4. Sprawdź subskrypcję:
   ```
   Get-AzSubscription
   Set-AzContext -Subscription "<your-subscription-id>"
   ```

---

## Ćwiczenie 2 – Utworzenie Resource Group

1. Wybierz region (np. `westeurope`):
   ```
   $location = "westeurope"
   ```
2. Utwórz grupę zasobów:
   ```
   New-AzResourceGroup -Name "rg-imienazwisko" -Location $location
   ```
3. Sprawdź, czy została utworzona:
   ```
   Get-AzResourceGroup
   ```

---

## Ćwiczenie 3 – Utworzenie pierwszego zasobu (Storage Account)

1. Wybierz unikalną nazwę:
   ```
   $storageName = "stimienazwiskodemo"
   ```
2. Utwórz konto Storage:
   ```
   New-AzStorageAccount -ResourceGroupName "rg-imienazwisko" `
                        -Name $storageName `
                        -Location $location `
                        -SkuName Standard_LRS `
                        -Kind StorageV2
   ```
3. Sprawdź:
   ```
   Get-AzStorageAccount -ResourceGroupName "rg-imienazwisko"
   ```

Uwaga — jeśli pojawi się błąd "Subscription not found" lub podobny komunikat:

- Przy kontach Azure for Students niektóre providery zasobów (resource providers) mogą być domyślnie niezarejestrowane. W takim wypadku trzeba zarejestrować providera dla Storage (`Microsoft.Storage`) i ponowić próbę utworzenia konta Storage.

Kroki naprawcze (PowerShell):

1. Sprawdź stan providera Storage:
   ```
   Get-AzResourceProvider -ProviderNamespace Microsoft.Storage
   ```

2. Jeśli polecenie wykaże, że provider ma stan inny niż "Registered", zarejestruj go:
   ```
   Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
   ```

3. Poczekaj aż provider zostanie zarejestrowany (może to zająć kilkadziesiąt sekund). Możesz ponownie sprawdzić stan:
   ```
   Get-AzResourceProvider -ProviderNamespace Microsoft.Storage | Select-Object ProviderNamespace, RegistrationState
   ```

4. Po statusie `Registered` ponów polecenie tworzenia Storage Account (krok 2 powyżej).

FAQ / przydatne źródła:
https://learn.microsoft.com/en-us/answers/questions/1465448/new-azstorageaccount-claims-subscription-not-found


---

## Ćwiczenie 4 – Weryfikacja w portalu

1. Student loguje się do **Azure Portal**.  
2. Otwiera **Resource Groups → rg-imienazwisko**.  
3. Widzi swoje **Storage Account** → kliknięcie pokazuje konfigurację, endpointy, zasady dostępu.  

---

## Ćwiczenie 5 – Upload pliku do Storage Account

1. Pobierz kontekst połączenia do Storage Account (tylko raz – będzie używany w kolejnych poleceniach):  
   Utwórz go, jeśli nie istnieje:
   ```
   $ctx = (Get-AzStorageAccount -ResourceGroupName "rg-imienazwisko" -Name $storageName).Context
   ```

2. Wybierz kontener blob w swoim Storage Account (np. `studentdata`).  
   Utwórz go, jeśli nie istnieje:
   ```
   New-AzStorageContainer -Name "studentdata" -Context $ctx
   ```

3. Przygotuj plik tekstowy z nazwiskiem w nazwie (np. `kowalski.txt`):
   ```
   echo "To jest plik testowy studenta Kowalski" > "kowalski.txt"
   ```

4. Prześlij plik do kontenera:
   ```
   Set-AzStorageBlobContent -File "kowalski-info.txt" -Container "studentdata" -Context $ctx
   ```

5. Sprawdź, czy plik został wrzucony:
   ```
   Get-AzStorageBlob -Container "studentdata" -Context $ctx
   ```
