# IX-Ray — zasady wspólne dla silnika i dodatków

Modyfikacje S.T.A.L.K.E.R. Call of Pripyat na silniku IX-Ray. Praca jest rozbita na
kilka repozytoriów: osobno silnik, osobno każdy dodatek. Ten plik spina je w całość
i jest **jedynym dokumentem czytanym zawsze** — resztę otwieraj, gdy zadanie tego wymaga.

## Co gdzie leży

| Co | Ścieżka |
| --- | --- |
| Silnik (fork) | `/home/tmz/Projects/ixray-1.6-stcop` |
| Dodatki | `/home/tmz/Projects/ixray-addons/<nazwa>` |
| Magazyn buildów | `/home/tmz/Projects/ixray-addons/engine-bin/<sha>[-debug]` |
| Gra | `/home/tmz/Games/Heroic/S.T.A.L.K.E.R. Call of Pripyat` |
| Zainstalowane dodatki | `<gra>/ixr_addons/<nazwa>` |
| Logi z gry | `<gra>/_appdata_ixray_/logs/` |
| Ta dokumentacja | `/home/tmz/Projects/ixray-docs` |

## Dodatek ↔ gałąź silnika

Każdy dodatek to dane (XML, LTX, tekstury). Jeśli potrzebuje zmian w C++, mają one
własną gałąź w repo silnika. To dwa różne tempa pracy: dane działają po restarcie gry,
silnik wymaga buildu z CI.

| Dodatek | Gałąź silnika | Pakiet w `patches/` | Testy |
| --- | --- | --- | --- |
| `ixray-hd-icons` | `feature/inventory-cell-grid`, `feature/inventory-drop-cell` | `inventory-cell-grid`, `inventory-drop-cell`, `inventory-drop-preview` | `tests/inventory-drop/` |
| `ixray-ui-params` | `feature/ui-param-bars`, `codex/equipment-condition-time` | `equipment-condition-time`, `hud-motion-cache` | `tests/condition-ui/`, `tests/hud-motions/` |
| `ixray-ttf-extended` | `feature/ttf-codepages` | — | — |

**Uwaga:** pakiety i testy `ixray-ui-params` (`equipment-condition-time`,
`hud-motion-cache`, `tests/condition-ui/`, `tests/hud-motions/`) istnieją **tylko na
gałęzi `feature/ui-param-bars`** — nie ma ich na `build/tmz`.

Stan prac i to, co realnie siedzi w graniu: [stan-projektu.md](stan-projektu.md).

## Reguły, których złamanie kosztuje rundę

1. **Zmiana w C++ nie działa w grze, dopóki nie przejdzie przez CI i instalację.**
   Edycja pliku źródłowego nie zmienia niczego w uruchomionej grze. Zanim uznasz
   poprawkę za niedziałającą, sprawdź, co siedzi w binarce:
   `strings "<gra>/bin/xrEngine.exe" | grep -m1 feature/` → pokazuje sha i gałąź.
   Szczegóły: [docs/wdrazanie.md](docs/wdrazanie.md).

2. **Zmiany nie-binarne idą do katalogu dodatku, nie do `gamedata/` w repo silnika.**
   Dodatek nadpisuje `gamedata` po ścieżce względnej. Szczegóły:
   [docs/dodatki.md](docs/dodatki.md).

3. **Katalog roboczy dodatku to nie ten, z którego czyta gra.** Trzeba skopiować do
   `<gra>/ixr_addons/<nazwa>/`. To osobne kopie, nie dowiązania.

4. **Praca idzie na `feature/*`, a po sprawdzeniu w grze scala się do `build/tmz`**
   jawnym `merge --no-ff`. `build/tmz` to gałąź, z której powstaje build do grania.
   Gałęzi `default` nie dotykamy — jest lustrem upstreamu.
   Szczegóły: [docs/galezie-i-scalanie.md](docs/galezie-i-scalanie.md).

5. **Pliki gry mają CRLF.** Edytuj bajtowo (`read_bytes`/`write_bytes`); `read_text`
   w Pythonie spłaszcza je do LF i diff rośnie z kilkunastu linii do kilkuset.
   Kodowania tekstów: `pol`/`cze` = Windows-1250, `eng`/`rus` = Windows-1251.

6. **Język: dokumentacja i opisy commitów po polsku, komentarze w kodzie silnika po
   angielsku.** Uzasadnienie i styl: [docs/konwencje.md](docs/konwencje.md).

## Gdzie szukać dalej

- [docs/srodowisko.md](docs/srodowisko.md) — pełna mapa katalogów, logi, co jest czym.
- [docs/repozytoria.md](docs/repozytoria.md) — rejestr repozytoriów i zdalnych.
- [docs/galezie-i-scalanie.md](docs/galezie-i-scalanie.md) — gałęzie, scalanie, upstream, CI.
- [docs/wdrazanie.md](docs/wdrazanie.md) — build silnika, instalacja, wdrożenie dodatku.
- [docs/dodatki.md](docs/dodatki.md) — `addon.init`, nadpisywanie, XMLOverride, DLTX, kodowania.
- [docs/pakiety-poprawek.md](docs/pakiety-poprawek.md) — `patches/`, `apply.py`, zależności.
- [docs/testy.md](docs/testy.md) — konwencja testów silnika.
- [docs/konwencje.md](docs/konwencje.md) — język, commity, utrzymywanie dokumentacji.
- [luzne-konce.md](luzne-konce.md) — znane rozjazdy czekające na decyzję.

Dokumentacja szczegółowa poszczególnych dodatków zostaje w ich własnych repozytoriach,
w `docs/`. Tu są tylko rzeczy wspólne.
