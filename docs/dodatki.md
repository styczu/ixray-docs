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
