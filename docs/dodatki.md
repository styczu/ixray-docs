# Jak działają dodatki

Mechanika montowania i kolizje między dodatkami. Nadpisywanie fragmentów plików ma osobne
dokumenty — patrz [Którą drogą nadpisać](#którą-drogą-nadpisać).

## `addon.init`

Katalog jest dodatkiem tylko wtedy, gdy zawiera plik `addon.init`. Bez niego silnik
w ogóle go nie zamontuje. Zawartość to jedna linia:

```
name: IX-Ray HD Icons [tmz]
```

**Silnik montuje katalog po samym istnieniu pliku** (`CanApply` w `src/xrCore/xrAddons.cpp`),
a zawartość czyta osobno, tylko na metadane dla Lua. Pusty albo uszkodzony `addon.init`
nie daje więc żadnego objawu: `Processing <nazwa>\ addon completed!` pojawia się w logu także
przy pliku 0 B. Rozjazd wychodzi dopiero przy porównaniu z repo
([wdrazanie.md](wdrazanie.md#dodatek)). Jeśli skrypt Lua potrzebuje nazwy dodatku, przeczytaj
wpis o `ReadMetaInfo` w [luzne-konce.md](../luzne-konce.md).

## Mapowanie ścieżek

**Katalog dodatku mapuje się wprost na `gamedata`** — w środku nie ma poziomu
`gamedata/`. Czyli `configs/ui/actor_menu_16.xml` w dodatku przesłania
`gamedata/configs/ui/actor_menu_16.xml`.

Mechanizm jest w `src/xrCore/xrAddons.cpp` (`CAddonManager::CanApply`): plik dodatku
jest rejestrowany pod ścieżką `gamedata`, a `Desc.wrap` wskazuje na rzeczywisty plik.

**Dodatek zastępuje plik w całości, nie scala go.** Jeśli nadpisujesz plik, kopia
w dodatku musi być kompletna — nie da się dowieźć samego fragmentu.

## Kolejność montowania

**Kolejność montowania jest alfabetyczna po nazwie katalogu** — widać ją na początku logu
(`Processing <nazwa>\ addon completed!`). Gdy ten sam plik dowozi kilka dodatków, o wyniku
decyduje ta kolejność. Zmiana nazwy katalogu potrafi więc zmienić wynik bez żadnego błędu.

## Którą drogą nadpisać

| Co zmieniasz | Droga | Przed pracą przeczytaj |
| --- | --- | --- |
| sekcje LTX | DLTX, pliki `mod_<korzeń>_*.ltx` | [dltx.md](dltx.md) |
| węzły XML | XMLOverride albo cały plik | [xml-override.md](xml-override.md) |
| teksty w `text/<język>/`, kodowanie, fonty | osobny plik z prefiksem `zz_` | [teksty-i-kodowania.md](teksty-i-kodowania.md) |
| tekstury | cały plik `.dds` plus wpis w deskryptorze | sekcja [Tekstury](#tekstury) niżej |

## Kolizje między dodatkami — kontrola przy integracji

Przy każdej integracji w `build/tmz` sprawdzamy **wszystkie** dodatki z
`<gra>/ixr_addons/`, także cudze (`ixray-hd-hud`, `ixray-cnma`, paczki paradox, STCoP WP…).
Kolizja nie daje błędu — po prostu jeden plik wygrywa po cichu.

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
2. **Te same sekcje LTX nadpisywane przez kilka dodatków i błędy `!!!DLTX ERROR`** —
   polecenie i procedura w [dltx.md](dltx.md#kontrola-przy-integracji).
3. **XML oczekujący silnika** (`FAILED TO COMPILE` w logu) —
   [xml-override.md](xml-override.md#xml-oczekujący-silnika--failed-to-compile).
4. **Zdublowane identyfikatory tekstów** (`! duplicate string table id`) —
   [teksty-i-kodowania.md](teksty-i-kodowania.md#kolejność-plików-tekstów-i-zdublowane-identyfikatory).
5. **Instalacja zgodna z repo**: szybko przez `addon-sync -c -a`, w pełni przez `diff -rq`
   katalogu roboczego z zainstalowanym. Tylko `diff -rq` widzi pliki przemianowane, które
   zostały w grze. Polecenia: [wdrazanie.md](wdrazanie.md#dodatek).

## Tekstury

Format `.dds`, katalog `textures/`. Deskryptory wycinków są w
`configs/ui/textures_descr/*.xml` — opisują prostokąt w atlasie dla każdego
identyfikatora tekstury. Dodanie ikony to zwykle wpis w deskryptorze plus
odpowiedni fragment atlasu, nie osobny plik.
