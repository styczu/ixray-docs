# Rejestr repozytoriów

Stan na 14 września 2026.

## Silnik

`/home/tmz/Projects/ixray-1.6-stcop` — fork IX-Ray 1.6 STCoP.

| Zdalne | Adres | Uwagi |
| --- | --- | --- |
| `origin` | `git@github.com:styczu/ixray-1.6-stcop.git` | tu wypychamy, tu buduje CI |
| `upstream` | `git@github.com:ixray-team/ixray-1.6-stcop.git` | `pushurl = DISABLE`, tylko pobieranie |

Gałęzie i zasady scalania: [galezie-i-scalanie.md](galezie-i-scalanie.md).

## Dodatki

Wszystkie leżą w `/home/tmz/Projects/ixray-addons/`.

### `ixray-hd-icons`

Ikony ekwipunku w wysokiej rozdzielczości i geometria siatki ekwipunku.

- Zdalne: **brak** — repo tylko lokalne.
- Zawiera: `configs/ui/actor_menu_16.xml`, `configs/ui/scroll_bar{,_16}.xml`
  (podmiana **całych plików**), `configs/misc/mod_items_hd_icons.ltx` (DLTX),
  `textures/ui/ui_icon_equipment_hd.dds`.
- Gałęzie silnika: łańcuch gałęzi źródłowych `fix/inventory-drop-cell` →
  `feature/inventory-drop-preview` → `feature/inventory-cell-grid`, każda na poprzedniej,
  pierwsza na czystym upstreamie ([pakiety-poprawek.md](pakiety-poprawek.md#łańcuch-gałęzi-źródłowych-inventory)).
- Pakiety: `inventory-drop-cell` → `inventory-drop-preview` → `inventory-cell-grid`.
- Testy: `tests/inventory-drop/`.

Ten dodatek świadomie podmienia całe pliki XML zamiast używać XMLOverride — bo zmienia
geometrię siatki, a nie pojedyncze węzły. Konsekwencja: kłóci się z każdym innym
dodatkiem ruszającym `actor_menu_16.xml` (patrz [luzne-konce.md](../luzne-konce.md)).

### `ixray-ui-params`

Panel parametrów postaci: paski, ochrony, regeneracja, tooltipy.

- Zdalne: `https://github.com/styczu/ixray-ui-params.git`
- Zawiera: XML-e panelu przez **XMLOverride** (`mod_*_uiparams.xml`), pliki DLTX
  `mod_system_*`, teksty w czterech językach, tekstury.
- Gałęzie silnika: `feature/ui-param-bars` (duża), `fix/equipment-condition-time` (jeden commit, źródło pakietu `equipment-condition-time`).
- Pakiety: `equipment-condition-time`, `hud-motion-cache`.
- Testy: `tests/condition-ui/`, `tests/hud-motions/`.
- Najbogatsza dokumentacja własna — `docs/` z kilkunastoma plikami.

### `ixray-ttf-extended`

Fonty TTF i obsługa stron kodowych dla polskiego i czeskiego.

- Zdalne: `https://github.com/styczu/ixray-ttf-extended.git`
- Zawiera: fonty w `fonts/pol/` i `fonts/cze/`, `configs/mod_system_ttfext.ltx`, teksty.
- Gałąź silnika: `feature/ttf-codepages`.
- Własne narzędzia w `tools/`:
  - `install-build.sh` — pobiera artefakt CI i instaluje silnik do gry;
  - `rebase-patch.sh` — przenosi gałąź na nowy upstream i eksportuje patch;
  - `check_font.py` — sprawdza, czy font pokrywa wymaganą stronę kodową.

`install-build.sh` obsługuje **cały projekt**, nie tylko ten dodatek — mimo że leży
w jego repozytorium. Opis użycia: [wdrazanie.md](wdrazanie.md).

## Dodatki obce

W `<gra>/ixr_addons/` siedzi kilkanaście dodatków spoza tego projektu
(`ixray-hd-hud`, `ixray-stcop-wp-*`, `ixray-paradox-*`, `ixray-cnma` i inne).
Nie modyfikujemy ich, ale bywają istotne:

- dostarczają dane, na których opierają się nasze obliczenia (np. maksima ochron
  z `ixray-stcop-wp-outfits`);
- mogą dowozić ten sam plik co nasz dodatek i wtedy o wyniku decyduje kolejność
  montowania.
