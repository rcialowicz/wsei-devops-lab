# Laboratorium 3 – Docker Fundamentals

## Prerekwizyty
1. Połącz się z maszyną wirtualną używając użuywając ssh

	```
	ssh studentwsei@<public_ip> -p (50000 + N)
    np. studentwsei@75.10.75.100 -p 51023
	```

---

## Ćwiczenie 1 – Weryfikacja instalacji Dockera

1. Sprawdź wersję Dockera:
	```
	docker --version
	```
2. Upewnij się, że możesz uruchamiać kontenery:
	```
	docker run hello-world
	```
3. Sprawdź listę dostępnych lokalnie obrazów:
	```
	docker images
	```
4. Sprawdź lokalnie status kontenerów:
	```
	docker ps -a
	```

---

## Ćwiczenie 2 – Uruchomienie kontenera Nginx

1. Pobierz obraz Nginx:
	```
	docker pull nginx
	```
2. Uruchom kontener:
	```
	docker run -d -p 8080:80 --name webserver nginx
	```
	- `-d` – tryb detached
	- `-p 8080:80` – mapowanie portu: host 8080 → kontener 80
	- `--name webserver` – nazwa kontenera
3. Sprawdź działanie kontenera:
	```
	docker ps
	```
4. Otwórz stronę w przeglądarce:
	- http://localhost:8080

5. (Środowisko zdalne / VM) Jeśli korzystasz z maszyny współdzielonej z numerem studenta `N`, i obowiązuje formuła portu `51000 + N`, otwórz:
	- `http://<public_ip>:(51000 + N)`

---

## Ćwiczenie 3 – Modyfikacja strony (bind mount)

1. Stwórz katalog na własną stronę (PowerShell / Bash):
	```
	mkdir ~/myweb
	echo "<h1>Hello from student Imie Nazwisko </h1>" > ~/myweb/index.html
	```
2. Zatrzymaj poprzedni kontener (jeśli działa):
	```
	docker stop webserver
	docker rm webserver
	```
3. Uruchom nowy kontener z podmontowanym katalogiem (bind mount):
	```
	docker run -d -p 8080:80 -v ~/myweb:/usr/share/nginx/html --name customweb nginx
	```
	- `-v lokalny_katalog:ścieżka_w_kontenerze` – podmontowanie katalogu z hosta
4. Podejrzyj zawartość kontenera (interaktywnie, tylko do odczytu / inspekcji):
	```
	docker exec -it customweb /bin/sh
	```
	Wewnątrz kontenera:
	```
	ls -l /usr/share/nginx/html
	cat /usr/share/nginx/html/index.html
	exit
	```
5. Odśwież stronę w przeglądarce: http://localhost:8080 (lub port z formuły 51000+N na środowisku zdalnym). Powinno wyświetlać Twój własny HTML.
6. Zmień treść pliku i zobacz efekt bez restartu kontenera:
	```
	echo "<h1>Hello from student Imie Nazwisko NumerAlbumu</h1>" > ~/myweb/index.html
	```
	Odśwież stronę ponownie.

---

## Ćwiczenie 4 – Operacje na istniejącym kontenerze (utrzymanie)

Korzystamy z kontenera `customweb` utworzonego w ćwiczeniu 3. Nie tworzymy nowych obrazów – ćwiczymy diagnostykę i administrację.

1. Wyświetl listę kontenerów (działających):
	```
	docker ps
	```
2. Wyświetl wszystkie kontenery (również zatrzymane):
	```
	docker ps -a
	```
3. Sprawdź logi kontenera (Nginx może mieć minimalne logi access/error):
	```
	docker logs customweb
	```
4. Podejrzyj szczegółowe informacje (JSON) – porty, wolumeny, zmienne:
	```
	docker inspect customweb
	```
5. Sprawdź użycie zasobów (krótkie ‘top’ kontenerów):
	```
	docker stats --no-stream customweb
	```
6. Przetestuj restart kontenera (powinien wrócić szybko) i sprawdź status:
	```
	docker restart customweb
    docker ps -a
	```

---

## Artefakty wymagane do zaliczenia
- Zrzut ekrany zawierający działający kontener Nginx `customweb` z własnym `index.html`
- Zrzut ekrany spersonalizowanej strony internetowej na publicznym IP (lub lokalnie)
