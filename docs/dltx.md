# DLTX — nadpisywanie sekcji LTX

Pliki konfiguracji można rozszerzać bez kopiowania oryginału. Mechanizm siedzi
w `src/xrCore/Xr_ini.cpp`; wszystko poniżej o jego działaniu jest odczytane ze źródeł.

## Składnia

**Wykrzyknik oznacza nadpisanie:**

```ini
![sekcja]
parametr = wartość
```

Zwykłe `[sekcja]` to próba utworzenia drugiej sekcji o tej samej nazwie — silnik
przerywa ładowanie błędem:

```
Duplicate section ... wasn't marked as an override
```

`Xr_ini.cpp` zna też `DLTX_DELETE` i modyfikatory list (`>` / `<` przed nazwą parametru).
Nasze dodatki ich nie używają i nie są tu opisane — przed użyciem sprawdź zachowanie w kodzie.

## Skąd silnik bierze pliki `mod_*`

- **Tylko dla pliku korzeniowego**, czyli otwartego jako osobna konfiguracja (np.
  `configs/system.ltx`). Pliki dołączane przez `#include` nie mają własnych `mod_*`.
- **Z katalogu pliku korzeniowego**, maską `mod_<korzeń>_*.ltx`. Dodatek nakłada się na
  `gamedata` po ścieżce, więc `configs/mod_system_*.ltx` w dodatku ląduje obok `system.ltx`.
- Jeśli w tym katalogu leży `<korzeń>_<x>.ltx`, plik `mod_<korzeń>_<x>_*.ltx` jest uznany za
  należący do tamtego pliku i dla `<korzeń>` jest pomijany.
- **Kolejność alfabetyczna po nazwie pliku**, łącznie ze wszystkich dodatków
  (`FS_FileSet` to `xr_set`). Przy dwóch nadpisaniach tego samego parametru wygrywa
  wczytany później — stąd prefiks `zzzz_`, gdy trzeba wygrać z innym dodatkiem:
  `mod_system_zzzz_uiparams_environment_upgrades.ltx`.
- Pliki `mod_*` wczytują się **po całym drzewie korzenia** (z jego `#include`), a nadpisania
  są scalane z bazą na końcu. Kolejność `#include` nie ma więc znaczenia — liczy się tylko to,
  czy sekcja bazowa w ogóle jest w tym drzewie.

## Korzeń to nie to samo, co "plik dołączony gdzieś w drzewie"

`mod_system_*.ltx` patchuje wyłącznie ten jeden obiekt konfiguracji, który silnik
zbudował z `system.ltx` i jego `#include`. Pliki ładowane **osobno** — inną
instancją `CInifile`, np. z Lua przez `ini_file("item_upgrades.ltx")`
(`inventory_upgrades.script`) — nie są tym drzewem, nawet jeśli logicznie
"dotyczą" tego samego tematu (upgrade'y) i nawet jeśli same coś `#include`ują.
Sekcja widoczna wyłącznie przez taki osobny plik jest dla `mod_system_*.ltx`
tak samo niewidoczna, jakby nie istniała.

**Zweryfikowany przypadek (15.09):** `item_upgrades.ltx` z `ixray-stcop-wp-3.8-cop`
jest ładowany właśnie tak — osobno, przez skrypt — więc jego `#include`
`misc\outfit_upgrades\o_svoboda_outfit_up.ltx` nie ma znaczenia dla
`mod_system_*.ltx`. To, co faktycznie wprowadziło część sekcji `o_svoboda_outfit_up.ltx`
do drzewa `system.ltx`, to zupełnie inna ścieżka: `system.ltx` dołącza
`misc\outfit.ltx`, a ten plik jest **nadpisany po ścieżce** przez
`ixray-stcop-wp-outfits/configs/misc/outfit.ltx`, który dokłada własny
`#include "outfit_upgrades\o_svoboda_outfit_up.ltx"`. Dodatek nakładający plik
o tej samej względnej ścieżce potrafi więc rozszerzyć drzewo korzenia — osobno
ładowany plik o pozornie tym samym include nie.

Wniosek praktyczny: przy `!!!DLTX ERROR` nie wystarczy znaleźć jakikolwiek
`#include` prowadzący do pliku z definicją. Trzeba ustalić, czy ten konkretny
`#include` leży w pliku, który faktycznie trafia do korzenia z komunikatu błędu
(`system.ltx`, `engine_external.ltx`, ...) — a nie w pliku ładowanym oddzielnie.

## Granica: `zzzz_` nie tworzy sekcji

Prefiks porządkuje wyłącznie pliki `mod_*` jednego korzenia. Jeśli sekcji bazowej nie ma
w drzewie tego korzenia, nadpisanie zostaje niewykorzystane i silnik wypisuje:

```
!!!DLTX ERROR Attemped to override section '<sekcja>', which doesn't exist. ...
Check this file and its DLTX mods: <plik korzeniowy>, mod file <plik mod_*>
```

To nie przerywa gry — nadpisanie po cichu nie działa, ślad jest tylko w logu.

**Dane bazowe nie leżą w plikach luźnych.** `system.ltx` i reszta konfigów bazowych są
w `<gra>/resources/configs.db`; w `<gra>/gamedata/configs/` jest tylko część plików. Brak
trafienia w grep znaczy „nie ma w plikach luźnych", nie „nie istnieje".

## Procedura dla `!!!DLTX ERROR`

Zakres to **cały aktywny runtime**: `<gra>/ixr_addons/*`, także dodatki obce. Nasze
nadpisania opierają się na sekcjach z obcych dodatków — szczególnie `ixray-stcop-wp-*` —
a obce dodatki same generują błędy DLTX.

1. **Zbierz błędy z najnowszego logu** i policz je na plik `mod_*`:
   ```sh
   L="<gra>/_appdata_ixray_/logs/$(ls -t "<gra>/_appdata_ixray_/logs/" | head -1)"
   grep -a 'DLTX ERROR' "$L" | tr -d '\r' | sed -E 's/.*mod file //' | sort | uniq -c
   ```
2. **Przypisz błąd według pliku `mod_*` z komunikatu**, nie według nazwy sekcji ani domysłu.
   Nazwa sekcji podpowiada, czego dotyczy nadpisanie, ale nie mówi, kto je dowozi.
3. **Znajdź dodatek, który dowozi plik** — nasz czy obcy:
   ```sh
   find "<gra>/ixr_addons" -iname '<plik mod_*>'
   ```
4. **Znajdź definicję sekcji** we wszystkich dodatkach (`-a`, bo pliki mają bajty spoza
   ASCII; definicja może mieć rodzica: `[sekcja]:rodzic`):
   ```sh
   grep -rnai --include='*.ltx' '^[[:space:]]*\[<sekcja>\]' "<gra>/ixr_addons"
   ```
5. **Sprawdź, czy plik z definicją jest w drzewie korzenia z komunikatu.** Szukaj, kto go
   dołącza: `grep -rnai --include='*.ltx' '#include.*<nazwa pliku>' "<gra>/ixr_addons"`.
   Porównuj nazwy dokładnie — różnica jednej spacji w nazwie pliku wystarcza, żeby `#include`
   trafił w coś innego. Brak trafienia może oznaczać dołączenie z pliku w `configs.db`.
6. **Sprawdź, czy tę samą sekcję nadpisuje więcej dodatków:**
   `grep -rnai --include='*.ltx' '^[[:space:]]*!\[<sekcja>\]' "<gra>/ixr_addons"`.
7. **Porównaj z poprzednim logiem** (błąd nowy czy znany) i zapisz wynik
   w [luzne-konce.md](../luzne-konce.md). Plików dodatków obcych nie modyfikujemy.

## Kontrola przy integracji

Sekcje nadpisywane (`![…]`) przez więcej niż jeden dodatek — o wyniku decyduje nazwa pliku
`mod_*`, a kolizja nie daje błędu:

```sh
cd "<gra>/ixr_addons" && grep -rHao --include='*.ltx' '^[[:space:]]*!\[[^]]*\]' . \
  | sed -E 's#^(\./)?([^/]+)/[^:]*:[[:space:]]*!\[([^]]*)\]#\L\3\E\t\2#' | sort -u \
  | awk -F'\t' '{c[$1]++; l[$1]=l[$1]" "$2} END{for(k in c) if(c[k]>1) print k" :"l[k]}'
```

Stan z 15.09: 10 sekcji (`zone_*`, `fireball_zone`), wszystkie wspólne dla
`ixray-paradox-sfx-v2.3` i `ixray-paradox-weather-unit-v2.3`. Żadna nie dotyczy naszych
dodatków.

Do tego liczba `!!!DLTX ERROR` w logu po integracji — porównana z poprzednią (procedura
wyżej). Stan z 15.09: 12 błędów, rozpisane w [luzne-konce.md](../luzne-konce.md).
