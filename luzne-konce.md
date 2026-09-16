# Luźne końce

Rozjazdy znalezione przy spisywaniu dokumentacji 14 września 2026, uzupełnione
15 września po integracji panelu z inventory. Każdy to osobna decyzja; rzeczy
rozwiązane są z listy usuwane. Kolejność od najbardziej wpływowych.

## Dane dodatków

**Dwa błędy DLTX w logu pochodzą z dodatków obcych**, nie z `ixray-ui-params`:
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

**Podgląd attempted/final przy upuszczaniu (`inventory-drop-final-preview`) porzucony
16 września 2026 po czterech rundach diagnostyki w grze.** Miał pokazywać czerwony
footprint pod kursorem i osobny zielony footprint miejsca, w które trafi automatic
placement — rozszerzenie ponad istniejący, pojedynczy footprint z `inventory-cell-grid`.
Cztery kolejne wersje (dwie Codexa, dwie w tej sesji) miały poprawną geometrię, kolory,
predykcję i wywołania renderowania — potwierdzone diagnostyką `Msg()` wprost z gry — a
mimo to nic się nie rysowało. **Ustalona przyczyna:** `CUIDragItem` (ikona trzymana
w ręku podczas przeciągania) rejestruje się na `Device.seqRender` jako niezależny obiekt
`pureRender` (`REG_PRIORITY_LOW-5000`, `src/xrGame/ui/UICellItem.cpp`), poza normalnym
przejściem drzewa okien, którym rysuje się plecak i podświetlenie. Nawet bezwarunkowy,
w pełni nieprzezroczysty, geometrycznie poprawny prostokąt wysłany z jego callbacku
`Draw()` był niewidoczny w grze — więc problem nie leżał w logice tej funkcji (kolorach,
UV, przycinaniu, kolejności), tylko w tym konkretnym, odroczonym miejscu wywołania
renderowania. Przeniesienie wywołania z powrotem do zwykłego `CUICellContainer::Draw()`
(tego samego przebiegu co działająca siatka) też nie pomogło. `build/tmz` wrócił do stanu
sprzed tej funkcjonalności (`ce6f8da75`); gałąź źródłowa `feature/inventory-drop-final-preview`
zostaje na `origin`, nieużywana, z pełną historią diagnostyki. Kolejna próba tego tematu
nie powinna zaczynać od rysowania z callbacku `CUIDragItem::Draw()`.

**Dwa niezgodne schematy `patch.json`.** Rodzina inventory używa
`verified_upstream_base` / `original_parent` / `original_commits` (drop-* mają
`original_integrated_commit`, cell-grid `original_commits` i `integrated_commits`),
od 15.09 także `branch`; `equipment-condition-time` używa
`upstream_base` / `branch` / `commit` / `files`.

**`apply.py` istnieje w pięciu niemal identycznych kopiach** i **nigdy nie czyta
`patch.json`** — `sha256` i `verified_upstream_base` to metadane bez egzekucji.

**Na czubku `feature/inventory-cell-grid` został commit pakietów `ea5103d0e`**, wbrew
zasadzie „gałąź źródłowa = kod, `build/tmz:patches/` = pakiety". Jego treść jest 1:1 na
`build/tmz` (`5c3e60bfd`). Gałęzi celowo nie przepisano; commit pomija się przy najbliższej
przebudowie łańcucha. Szczegóły:
[docs/pakiety-poprawek.md](docs/pakiety-poprawek.md#łańcuch-gałęzi-źródłowych-inventory).

**`hud-motion-cache` nie ma własnej gałęzi źródłowej.** `patch.json` zna tylko
`original_integrated_commit` i `original_parent`. Pakietu nie da się więc wygenerować
z gałęzi, jak wymaga zasada.

**`apply.py` pakietów `inventory-drop-*` nie rozpoznaje własnej poprawki po nałożeniu
`inventory-cell-grid`.** Zwraca 1 (drop-cell) albo 2 (drop-preview) zamiast 0, bo cell-grid
przepisuje ich linie. Sprawdzone 15.09 na czystym `6c793faee`. Odnotowane w README obu
pakietów, nie naprawione.

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

**Silnik nie czyta `name:` z `addon.init`.** W `CAddonManager::ReadMetaInfo`
(`src/xrCore/xrAddons.cpp`) warunek jest odwrócony: `if (NameEntryIndex == xr_string::npos)`.
Gdy `name:` jest w pliku, `AddonName` zostaje puste. Gdy go nie ma, silnik tnie tekst od
pozycji `npos + 6`, czyli 5. Przy niepustym pliku krótszym niż 5 B `substr` rzuci
`std::out_of_range`, a tego wyjątku nic nie łapie. Warunek wprowadził upstreamowy commit
`f2e2761bf` (2024-08-04), `build/tmz` go nie zmienia. Czy żywy upstream nadal ma ten błąd,
nie sprawdzano; lokalne `upstream/default` jest z 6.09. Dziś nie ma skutków. Każdy
zainstalowany `addon.init` ma 0 B (wtedy silnik wychodzi wcześniej) albo co najmniej 13 B.
`AddonName` widzi tylko Lua (`src/xrGame/addon_manager_script.cpp`), a żaden `*.script`
w `gamedata/` ani `ixr_addons/` go nie używa.

**Obie kontrole zgodności instalacji dodatku pomijają różne zbiory plików**:
`addon-sync` tylko `README.md`, `AGENTS.md` i `CLAUDE.md` (patrz `RSYNC_EXCLUDES`
w skrypcie), a ręczne `diff -rq -x '*.md'` z
[docs/wdrazanie.md](docs/wdrazanie.md#dodatek) wszystkie `.md`. Dziś bez znaczenia,
bo w trzech dodatkach nie ma innych `.md`.

**Testów nie uruchamia żadne CI** — weryfikacja jest wyłącznie lokalna i ręczna.

**Konwencja testów nie jest jednolita**: część używa ASan/UBSan i wyciągania ciał
funkcji, część zwykłej kompilacji z `-Werror` przeciw prawdziwym nagłówkom. Funkcja
`body()` jest skopiowana do każdego pliku testu.
