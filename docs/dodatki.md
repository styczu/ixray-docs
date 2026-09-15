# Jak działają dodatki

## `addon.init`

Katalog jest dodatkiem tylko wtedy, gdy zawiera plik `addon.init`. Bez niego silnik
w ogóle go nie zamontuje. Zawartość to jedna linia:

```
name: IX-Ray HD Icons [tmz]
```

## Mapowanie ścieżek

**Katalog dodatku mapuje się wprost na `gamedata`** — w środku nie ma poziomu
`gamedata/`. Czyli `configs/ui/actor_menu_16.xml` w dodatku przesłania
`gamedata/configs/ui/actor_menu_16.xml`.

Mechanizm jest w `src/xrCore/xrAddons.cpp` (`CAddonManager::CanApply`): plik dodatku
jest rejestrowany pod ścieżką `gamedata`, a `Desc.wrap` wskazuje na rzeczywisty plik.

**Dodatek zastępuje plik w całości, nie scala go.** Jeśli nadpisujesz plik, kopia
w dodatku musi być kompletna — nie da się dowieźć samego fragmentu.

Gdy ten sam plik dowozi kilka dodatków, o wyniku decyduje kolejność montowania.
Nie jest ona nigdzie udokumentowana; kolejność przetwarzania widać w logu gry.

## Kolizje między dodatkami — kontrola przy integracji

Przy każdej integracji w `build/tmz` sprawdzamy **wszystkie** dodatki z
`<gra>/ixr_addons/`, także cudze (`ixray-hd-hud`, `ixray-cnma`, paczki paradox, STCoP WP…).
Kolizja nie daje błędu — po prostu jeden plik wygrywa po cichu.

**Kolejność montowania jest alfabetyczna po nazwie katalogu** — widać ją na początku logu
(`Processing <nazwa>\ addon completed!`). Pliki tekstów w `text/<język>/` też idą
alfabetycznie (`FS_FileSet` to `xr_set`), a przy zdublowanym identyfikatorze wygrywa
ostatni wczytany (`string_table.cpp`, w logu `! duplicate string table id`) — stąd prefiks
`zz_` w nazwach plików tekstów dodatków.

Co sprawdzić:

1. **Te same ścieżki w kilku dodatkach** (podmiana całego pliku):
   ```sh
   cd "<gra>/ixr_addons" && find . -mindepth 2 -type f ! -name addon.init \
     | sed -E 's#^\./([^/]+)/(.*)$#\L\2\E\t\1#' | sort \
     | awk -F'\t' '{c[$1]++; l[$1]=l[$1]" "$2} END{for(k in c) if(c[k]>1) print k" :"l[k]}'
   ```
   Przy zdublowanym pliku porównaj obie kopie. Stan z 15.09: `configs/ui/actor_menu_16.xml`
   dowożą `ixray-hd-hud` i `ixray-hd-icons`, a różnią się **wyłącznie** sześcioma siatkami
   (`screen_cell_size`, `cols_num="8"`, `scroll_profile`). Wygrywa `hd-icons`; gdyby wygrał
   `hd-hud`, ekwipunek wróci do 7 kolumn bez śladu w logu.
2. **Te same sekcje LTX** nadpisywane (`![sekcja]`) przez więcej niż jeden dodatek oraz
   błędy `!!!DLTX ERROR` w logu — wskazują plik `mod_*`, którego nadpisanie nie weszło.
3. **XML oczekujący silnika:** `grep -a -c 'FAILED TO COMPILE' <log>` — każde trafienie to
   zmienna wyrażenia, której zainstalowany silnik nie rejestruje (tak wyglądała regresja
   panelu 14.09: 10 trafień `fltActor*ProtectionRatio`).
4. **Instalacja zgodna z repo:** `diff -rq -x .git -x docs -x src -x tools -x '*.md'
   <repo-dodatku> <gra>/ixr_addons/<nazwa>`. `cp -r` nie usuwa plików przemianowanych
   w repo — w `ixray-hd-icons` został tak stary `mod_items_hd_medkits.ltx`, nadpisujący
   apteczki teksturą z literówką.

## XMLOverride — lepsza droga dla XML

Zamiast podmieniać cały plik, można dowieźć **tylko zmienione węzły**. Silnik szuka
plików pasujących do maski `mod_<nazwa>_*.<rozszerzenie>` (obsługa w `AsureXML.cpp`)
i scala je z plikiem bazowym.

Nazwa pliku w dodatku wygląda wtedy tak: `mod_actor_menu_16_uiparams.xml`.

**Kiedy czego używać:**

| Sytuacja | Sposób |
| --- | --- |
| zmiana kilku węzłów, współistnienie z innymi dodatkami | XMLOverride |
| przebudowa geometrii całego okna | podmiana całego pliku |

`ixray-ui-params` używa XMLOverride. `ixray-hd-icons` świadomie podmienia całe pliki,
bo zmienia geometrię siatki ekwipunku — cena to konflikt z każdym innym dodatkiem
ruszającym ten sam plik.

## DLTX — nadpisywanie sekcji LTX

Pliki konfiguracji można rozszerzać bez kopiowania oryginału.

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

**Nazwa pliku wyznacza moment wczytania.** Plik musi zaczynać się od `mod_` i trafiać
do właściwego pliku korzeniowego (`mod_system_*` dla `system.ltx`, `mod_items_*` dla
plików przedmiotów — logika w `Xr_ini.cpp`). Prefiks `zzzz_` w nazwie odsuwa wczytanie
na koniec, gdy trzeba wygrać z innym dodatkiem:

```
mod_system_zzzz_uiparams_environment_upgrades.ltx
```

## Teksty, kodowania, końce linii

To źródło cichych błędów — warto mieć przed oczami.

| Język | Strona kodowa |
| --- | --- |
| `pol`, `cze` | Windows-1250 |
| `eng`, `rus` | Windows-1251 |

- **Deklaracja XML nie konwertuje bajtów.** Zmiana `encoding=` w nagłówku nie zmienia
  zawartości pliku — trzeba przekodować rzeczywiste bajty.
- **Końce linii to CRLF** i trzeba je zachować. W Pythonie czytaj i zapisuj bajtowo
  (`read_bytes` / `write_bytes`); `read_text` + `write_text` spłaszcza CRLF do LF
  i zamienia zmianę kilkunastu linii w diff całego pliku.
- Fonty muszą pokrywać użytą stronę kodową; sprawdza to `check_font.py`
  z `ixray-ttf-extended/tools/`.

## Tekstury

Format `.dds`, katalog `textures/`. Deskryptory wycinków są w
`configs/ui/textures_descr/*.xml` — opisują prostokąt w atlasie dla każdego
identyfikatora tekstury. Dodanie ikony to zwykle wpis w deskryptorze plus
odpowiedni fragment atlasu, nie osobny plik.
