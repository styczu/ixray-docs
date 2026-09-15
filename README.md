# IX-Ray — zasady wspólne dla silnika i dodatków

Modyfikacje S.T.A.L.K.E.R. Call of Pripyat na silniku IX-Ray. Praca jest rozbita na
kilka repozytoriów: osobno silnik, osobno każdy dodatek. Ten plik spina je w całość
i jest **jedynym dokumentem czytanym zawsze** — resztę otwieraj według routera niżej.

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

## Router: co przeczytać przed pracą

Szczegóły nie ładują się same. **Jeśli zadanie pasuje do punktu poniżej, przeczytaj wskazany
dokument przed pierwszą zmianą, nie po pierwszym błędzie.** Pasuje kilka punktów — przeczytaj
każdy. Nie pasuje żaden — nie otwieraj niczego na zapas. Przypadki szczególne wewnątrz domeny
wskazuje dopiero dokument domeny. Ścieżki są bezwzględne, bo ten plik jest importowany do
innych repozytoriów.

- **LTX / DLTX**: `mod_*.ltx`, `![sekcja]`, kolejność wczytywania LTX, prefiks `zzzz_`, `!!!DLTX ERROR` w logu → `/home/tmz/Projects/ixray-docs/docs/dltx.md`
- **XML dodatku**: XMLOverride, `AsureXML`, `mod_*.xml`, podmiana całego pliku XML, `FAILED TO COMPILE` w logu → `/home/tmz/Projects/ixray-docs/docs/xml-override.md`
- **Mechanika dodatków**: `addon.init`, `<gra>/ixr_addons`, kolejność montowania, ten sam plik w kilku dodatkach, tekstury i `textures_descr` → `/home/tmz/Projects/ixray-docs/docs/dodatki.md`
- **Teksty i kodowanie**: `text/<język>/`, strony kodowe, CRLF, fonty, polskie/czeskie znaki, `! duplicate string table id`, `! Glyph not found` → `/home/tmz/Projects/ixray-docs/docs/teksty-i-kodowania.md`
- **Gałęzie i CI**: `feature/*`, `fix/*`, `codex/*`, merge do `build/tmz`, `default`, upstream, `gh run` → `/home/tmz/Projects/ixray-docs/docs/galezie-i-scalanie.md`
- **Instalacja do gry**: build z CI, `install-build.sh`, kopiowanie dodatku do `<gra>/ixr_addons`, `addon-sync`, „poprawka nie działa w grze" → `/home/tmz/Projects/ixray-docs/docs/wdrazanie.md`
- **Pakiety poprawek**: `patches/*`, `apply.py`, `patch.json`, `format-patch`, przenoszenie poprawki na inną wersję → `/home/tmz/Projects/ixray-docs/docs/pakiety-poprawek.md`
- **Testy silnika**: `tests/*`, pisanie lub uruchamianie testu, `IXRAY_TEST_ROOT` → `/home/tmz/Projects/ixray-docs/docs/testy.md`
- **Środowisko**: ścieżki spoza tabeli wyżej, logi gry, `fsgame.ltx`, magazyn buildów, Release vs RelWithDebInfo → `/home/tmz/Projects/ixray-docs/docs/srodowisko.md`
- **Repozytoria**: zdalne, co zawiera który dodatek, zależności między komponentami, dodatki obce → `/home/tmz/Projects/ixray-docs/docs/repozytoria.md`
- **Commit, komentarz w kodzie, pisanie dokumentacji** → `/home/tmz/Projects/ixray-docs/docs/konwencje.md`
- **Stan projektu**: co działa, co jest w graniu, znane rozjazdy, planowanie kolejnego kroku → `/home/tmz/Projects/ixray-docs/stan-projektu.md`

Temat jednego dodatku → `docs/` w jego własnym repozytorium. Tu są tylko rzeczy wspólne.

## Dodatek ↔ gałąź silnika

Każdy dodatek to dane (XML, LTX, tekstury). Jeśli potrzebuje zmian w C++, mają one
własną gałąź w repo silnika. To dwa różne tempa pracy: dane działają po restarcie gry,
silnik wymaga buildu z CI.

| Dodatek | Gałąź silnika | Pakiet w `patches/` | Testy |
| --- | --- | --- | --- |
| `ixray-hd-icons` | łańcuch `fix/inventory-drop-cell` → `feature/inventory-drop-preview` → `feature/inventory-cell-grid` | `inventory-drop-cell`, `inventory-drop-preview`, `inventory-cell-grid` | `tests/inventory-drop/` |
| `ixray-ui-params` | `feature/ui-param-bars`, `fix/equipment-condition-time` | `equipment-condition-time`, `hud-motion-cache` | `tests/condition-ui/`, `tests/hud-motions/` |
| `ixray-ttf-extended` | `feature/ttf-codepages` | — | — |

## Reguły, których złamanie kosztuje rundę

1. **Zmiana w C++ nie działa w grze, dopóki nie przejdzie przez CI i instalację.**
   Edycja pliku źródłowego nie zmienia niczego w uruchomionej grze. Zanim uznasz
   poprawkę za niedziałającą, sprawdź, co siedzi w binarce:
   `strings "<gra>/bin/xrEngine.exe" | grep -m1 feature/` → pokazuje sha i gałąź.

2. **Zmiany nie-binarne idą do katalogu dodatku, nie do `gamedata/` w repo silnika.**
   Dodatek nadpisuje `gamedata` po ścieżce względnej.

3. **Katalog roboczy dodatku to nie ten, z którego czyta gra.** Trzeba skopiować do
   `<gra>/ixr_addons/<nazwa>/`. To osobne kopie, nie dowiązania.

4. **Praca idzie na `feature/*`, a po sprawdzeniu w grze scala się do `build/tmz`**
   jawnym `merge --no-ff`. `build/tmz` to gałąź, z której powstaje build do grania.
   Gałęzi `default` nie dotykamy — jest lustrem upstreamu.

5. **Pliki gry mają CRLF i strony kodowe Windows** (`pol`/`cze` = 1250, `eng`/`rus` = 1251).
   Edytuj bajtowo (`read_bytes`/`write_bytes`); `read_text` w Pythonie spłaszcza CRLF do LF
   i diff rośnie z kilkunastu linii do kilkuset.

6. **Język: dokumentacja i opisy commitów po polsku, komentarze w kodzie silnika po
   angielsku.**
