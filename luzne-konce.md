# Luźne końce

Rozjazdy znalezione przy spisywaniu dokumentacji 14 września 2026, uzupełnione
15 września po integracji panelu z inventory. Każdy to osobna decyzja; rzeczy
rozwiązane są z listy usuwane. Kolejność od najbardziej wpływowych.

## Gałęzie

**`origin/codex/tooltip-real-seconds`** to nieaktualna migawka bez lokalnego
odpowiednika — leży na `origin` i nic z niej nie wynika.

**`stash@{0}`** na `feature/ui-param-bars` (`wip-gi3`) to te same 3 linie `.gitignore`,
które weszły commitem `ec3285d5a` — do usunięcia, niczego nie niesie.

**`CLAUDE.md` w repozytorium silnika jest na `build/tmz` i `feature/ui-param-bars`,
nie ma go na pięciu pozostałych gałęziach roboczych** (poza `default`, lustrem upstreamu,
i scaloną `build/ci-release`). To decyzja, nie przeoczenie. Gałęzie źródłowe pakietów
(`fix/equipment-condition-time` oraz łańcuch `fix/inventory-drop-cell` →
`feature/inventory-drop-preview` → `feature/inventory-cell-grid`) stoją celowo na czystym
upstreamie, żeby patche dało się czysto wyeksportować. Commit z dokumentacją zepsułby
ten cel. `feature/ttf-codepages` jest w całości scalona, a nowa praca odgałęzia się
od `build/tmz`, które plik ma. Gdyby wróciła do życia, trzeba tam przenieść
commit `1e4108d0f`.

## Dokumentacja odwołująca się w próżnię

**Notatka twierdzi, że jej kopia leży w zainstalowanym dodatku** — w całym
`<gra>/ixr_addons/` nie ma ani jednego pliku `.md`.

**Ścieżka magazynu buildów w `ixray-ttf-extended/docs/utrzymanie-patcha.md` jest
nieaktualna**: dokument mówi `~/Stalker/builds`, a realny magazyn to
`/home/tmz/Projects/ixray-addons/engine-bin`. Katalog `~/Stalker/builds` nie istnieje.

## Repozytoria

**`ixray-hd-icons` nie ma zdalnego repozytorium** — istnieje tylko lokalnie, bez kopii
zapasowej. Dwa commity.

**`cop-localization-fixes` to pusty katalog** bez `addon.init`, i w katalogu roboczym,
i w grze. Silnik go nie montuje.

**`ixray-hd-hud` (dodatek obcy) dowozi własny `configs/ui/actor_menu_16.xml`** —
z `cols_num="7"`. Kopia z `ixray-hd-icons` różni się od niej wyłącznie sześcioma siatkami.
Dziś wygrywa `ixray-hd-icons` (montowanie jest alfabetyczne, widać to w logu), ale
wystarczy zmiana nazwy katalogu, żeby ekwipunek „wrócił" do siedmiu kolumn bez żadnego
błędu. Kontrola: [docs/dodatki.md](docs/dodatki.md#kolizje-między-dodatkami--kontrola-przy-integracji).

**`ixray-ui-params` ma 4 commity niewypchnięte na `origin/main`** (stan z 15.09).

## Dane dodatków

**12 błędów `!!!DLTX ERROR` w logu z 15.09; 10 z nich to nasze.**
`ixray-ui-params/configs/mod_system_zzzz_uiparams_environment_upgrades_extra.ltx`
nadpisuje 10 sekcji `up_sect_*` kombinezonów `soldier`, `neutral_assault` i `svoboda`
(m.in. `up_sect_second_soldier_outfit`, `up_sect_fiftha_neutral_assault_outfit`,
`up_sect_seconf_svoboda_outfit`), których nie ma w chwili wczytania `system.ltx`.
Te nadpisania dziś **nie działają**. Definiuje je wyłącznie `ixray-stcop-wp-outfits`
w `configs/misc/outfit_upgrades/` (`o_soldier_outfit_up.ltx`,
`o_neutral_assault_outfit_up.ltx`, `o_svoboda_ outfit_up.ltx` — ten ostatni **ze spacją**
w nazwie). Pliki z tego katalogu dołącza przez `#include`
`ixray-stcop-wp-3.8-cop/configs/item_upgrades.ltx`, ale plików `soldier` i `neutral_assault`
nie dołącza wcale, a `svoboda` dołącza jako `o_svoboda_outfit_up.ltx`, bez spacji.
Hipoteza, niesprawdzona w grze: definicje nie trafiają do żadnego łańcucha wczytywania.
Czy bazowy plik z `configs.db` dołącza je inaczej — nie sprawdzono. Procedura:
[docs/dltx.md](docs/dltx.md#procedura-dla-dltx-error).

**Dwa pozostałe błędy DLTX pochodzą z dodatków obcych**, nie z `ixray-ui-params`:
`wpn_protecta_nimble` z `ixray-pattern-recoil-stcop/configs/mod_system_wpn_pattern.ltx`
i `spawn_supplies` z `lxrd-loadout-stcop/configs/mod_engine_external_lxrd_loadout.ltx`.
Definicji bazowej `[wpn_protecta_nimble]` nie ma w żadnym dodatku ani w plikach luźnych
`gamedata` (archiwów `.db` nie przeszukano). Dodatków obcych nie modyfikujemy.

**Zdublowane identyfikatory `ui_inv_outfit_*_protection`** w `ixray-ttf-extended/configs/text/pol/ui_st_inventory.xml`
i `ixray-ui-params/configs/text/*/zz_uiparams_panel.xml`. Wygrywa `zz_` (np. „Ochrona
mechaniczna” zamiast „Tłumienie uderzeń”) — zamierzone, ale sześć ostrzeżeń w logu.

**`feature/ui-param-bars` zmienia XML w `gamedata/` repo silnika** (`actor_menu*.xml`,
`af_params*.xml`, `ui_protection_points.xml`), wbrew regule 2. Do gry to nie trafia, ale
`tests/condition-ui/test_protection.py` sprawdza te pliki — przeniesienie wymaga zmiany testu.

## Silnik i pakiety

**`.gitignore:60` zawiera `patch*/`, co łapie `patches/`.** Nowe pliki w pakietach są
niewidoczne dla `git status` i wymagają `git add -f`. Reguła odziedziczona z upstreamu,
kolidująca z własną konwencją.

**Dwa niezgodne schematy `patch.json`.** Rodzina inventory używa
`verified_upstream_base` / `original_parent` / `original_commits` (drop-* mają
`original_integrated_commit`, cell-grid `original_commits` i `integrated_commits`),
od 15.09 także `branch`; `equipment-condition-time` używa
`upstream_base` / `branch` / `commit` / `files`.

**`apply.py` istnieje w pięciu niemal identycznych kopiach** i **nigdy nie czyta
`patch.json`** — `sha256` i `verified_upstream_base` to metadane bez egzekucji.

**`build/tmz` niesie nieaktualne kopie pakietów inventory.** Aktualne leżą od 15.09 na
czubku `feature/inventory-cell-grid` (`ea5103d0e`). Kopia w `build/tmz` jest starsza:
- `inventory-cell-grid` zna tylko `28424e0f3` i `e9fb81e26`, bez martwego paska i fallbacku
  profilu, a README opisuje XML w `gamedata`;
- drop-* mają dawny format eksportu i inne `sha256`.

`build/tmz` celowo zostawiono nietknięte. Pakiet biorący się z `build/tmz` jest niekompletny.
Szczegóły: [docs/pakiety-poprawek.md](docs/pakiety-poprawek.md#łańcuch-gałęzi-źródłowych-inventory).

**`apply.py` pakietów `inventory-drop-*` nie rozpoznaje własnej poprawki po nałożeniu
`inventory-cell-grid`.** Zwraca 1 (drop-cell) albo 2 (drop-preview) zamiast 0, bo cell-grid
przepisuje ich linie. Sprawdzone 15.09 na czystym `6c793faee`. Odnotowane w README obu
pakietów, nie naprawione.

**Luźny `patches/0001-Wyb-r-strony-kodowej-*.patch`** jest nieśledzony i w formacie
sprzed konwencji katalogów.

**Lokalny `upstream/default` jest nieaktualny** (`6c793faee` kontra `612b165c9` na
żywo, stan z 6 września). Po `git fetch upstream` baza deklarowana we wszystkich
pakietach przestanie odpowiadać rzeczywistości. Refspec pobiera tylko `default`, więc
`rel1.4-new` nie pojawi się lokalnie.

**Dwa dokumenty prozą leżą w `docs/` (od 15.09 także na `build/tmz`), czyli w drzewie strony VitePress upstreamu** —
kolizja przy każdej synchronizacji, a gdyby kiedyś trafiły na `default`, wciągnąłby je
workflow publikujący dokumentację.

**Historia `build/tmz` jest oparta na merge'ach**, a `doc/branching-model.md` upstreamu
wymaga liniowej. To świadome odstępstwo, ale warto o nim pamiętać przy ewentualnym PR-ze.

## Drobne

**Testów nie uruchamia żadne CI** — weryfikacja jest wyłącznie lokalna i ręczna.

**Konwencja testów nie jest jednolita**: część używa ASan/UBSan i wyciągania ciał
funkcji, część zwykłej kompilacji z `-Werror` przeciw prawdziwym nagłówkom. Funkcja
`body()` jest skopiowana do każdego pliku testu.

**`ixray-ui-params/tools/` jest pustym katalogiem**, mimo że dokumentacja odwołuje się
do testów uruchamianych z katalogu silnika.
