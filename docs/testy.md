# Testy silnika

Leżą w `<ixray>/tests/<rodzina>/`, jeden plik Pythona na temat. **Nie ma runnera ani
pytest** — każdy plik jest samodzielnym skryptem uruchamianym wprost:

```sh
python3 tests/inventory-drop/test_cell_grid.py
```

Katalog nazywa się od **rodziny pakietów**, nie od gałęzi — trzy pakiety inventory
dzielą `tests/inventory-drop/`.

| Katalog | Dotyczy |
| --- | --- |
| `tests/inventory-drop/` | siatka i upuszczanie w ekwipunku (`ixray-hd-icons`) |
| `tests/condition-ui/` | panel parametrów postaci (`ixray-ui-params`) |
| `tests/hud-motions/` | pamięć animacji HUD (`ixray-ui-params`) |

**Żaden workflow CI ich nie uruchamia.** Weryfikacja jest lokalna i ręczna.

## Jak te testy działają

Dominujący wzorzec: test **wyciąga ciało funkcji produkcyjnej z pliku `.cpp`
tekstowo**, wkleja je do wygenerowanego pliku C++ z atrapami typów silnika,
kompiluje i uruchamia.

Dzięki temu testowany jest **kod produkcyjny**, a nie jego kopia — jeśli ktoś zmieni
funkcję w silniku, test kompiluje nową wersję.

Elementy wspólne:

- korzeń repozytorium z `IXRAY_TEST_ROOT`, z zapasem na ścieżkę wyliczoną z położenia
  pliku — dzięki temu test da się wycelować w inny checkout;
- wycinanie ciała funkcji przez dopasowanie nawiasów klamrowych (funkcja `body`,
  skopiowana do każdego pliku, bez wspólnego modułu);
- kompilacja z sanitizerami:
  ```
  g++ -std=c++17 -Wall -Wextra -Werror -fsanitize=address,undefined -g
  ```
- uruchomienie z `ASAN_OPTIONS=detect_leaks=0` — LeakSanitizer nie działa
  w środowisku z ograniczonym `ptrace`;
- na końcu **jedna linia `PASS:`** wyliczająca, co konkretnie zostało pokryte.

Wymagania: Python 3 i `g++` z ASan/UBSan.

## Linia PASS

Format: `PASS: <funkcje produkcyjne>; <lista przypadków>; ASan/UBSan`

Sufiks `ASan/UBSan` tylko wtedy, gdy sanitizery faktycznie były użyte. Ta linia jest
de facto spisem treści testu — przy dopisywaniu przypadków trzeba ją rozszerzyć.

## Dwie odmiany

Konwencja nie jest jednolita i to jest celowe:

- **logika silnika** — wyciąganie ciał + ASan/UBSan (testy inventory, HUD);
- **okablowanie XML i formatowanie tekstu** — zwykła kompilacja z `-Werror` przeciw
  prawdziwym nagłówkom silnika, bez sanitizerów (część testów `condition-ui`).

## Granica testu

Część testów **modeluje** zachowanie silnika zamiast je kompilować — na przykład
rasteryzację ikon odtworzono ręcznie, bo prawdziwa funkcja siedzi w warstwie
renderowania. Taki test sprawdza model, nie rzeczywistość.

Stąd zasada: **próba w grze jest obowiązkowa, nie kurtuazyjna.** Zielony test i zielone
CI nie zastępują obejrzenia zmiany w grze.

## Test regresyjny ma padać przed poprawką

Przy dopisywaniu testu do poprawki warto sprawdzić, że **bez niej test faktycznie pada**
— inaczej nie wiadomo, czy cokolwiek pilnuje. Sposób: skierować test na checkout
sprzed poprawki przez `IXRAY_TEST_ROOT`.

```sh
mkdir -p /tmp/prefix/src/xrGame/ui
git show HEAD~1:src/xrGame/ui/<plik>.cpp > /tmp/prefix/src/xrGame/ui/<plik>.cpp
IXRAY_TEST_ROOT=/tmp/prefix python3 tests/<rodzina>/<test>.py   # ma paść
```
