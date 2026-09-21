# Pakiety poprawek — `patches/`

Poprawka silnika żyje w dwóch postaciach: jako gałąź w forku (do pracy) i jako
**samodzielny pakiet** w `patches/<nazwa>/` (do przeniesienia na inną wersję IX-Ray).

Zasada od 15 września 2026:

| Gdzie | Co |
| --- | --- |
| gałąź źródłowa `fix/*` / `feature/*` | kod poprawki i jej testy, nic więcej |
| `build/tmz:patches/<nazwa>/` | przenośne artefakty pakietów, wygenerowane z gałęzi źródłowej |

Pakiet zmienia się więc commitem na `build/tmz`, a nie na gałęzi źródłowej. `.gitignore`
na `build/tmz` wyłącza `patches/` z upstreamowej reguły `patch*/`, więc nowe i zmienione
pliki pakietów widać w `git status` i dodaje się je zwykłym `git add`.

## Zawartość pakietu

| Plik | Rola |
| --- | --- |
| `0001-fix-<nazwa>.patch` | eksport `git format-patch` |
| `apply.py` | sprawdza i nakłada patch |
| `patch.json` | metadane: commity źródłowe, baza upstreamu, suma kontrolna, zależności |
| `README.md` | opis problemu, rozwiązania i tego, co sprawdzono |

## Konwencja README

Pakiety mają powtarzalną budowę sekcji i warto ją utrzymać:

- tytuł nazywający problem, nie rozwiązanie;
- **„To nie jest wina X"** — sprostowanie błędnej hipotezy, jeśli taka była;
- `## Co zmienia patch`;
- `## Świadome konsekwencje` i `## Czego patch nie zmienia`;
- `## Sprawdzone` — co pokrywa test, wyniki CI z konkretnymi sha, **jawny status próby
  w grze** (łącznie z „nie wykonano");
- `## Użycie`.

Ta struktura jest sama w sobie wartością: zmusza do rozdzielenia tego, co sprawdzone,
od tego, co założone.

## `apply.py`

```sh
python3 <pakiet>/apply.py --repo <ixray>            # samo sprawdzenie
python3 <pakiet>/apply.py --repo <ixray> --apply    # nałożenie jako commit
```

Kolejność kontroli:

1. czy to repozytorium git;
2. **czy patch już jest nałożony** (`git apply --reverse --check`) — celowo **przed**
   sprawdzeniem zależności, bo po nałożeniu zależności nie dają się już wykryć;
3. czy patch pasuje (`git apply --check`);
4. czy drzewo jest czyste i nie trwa rebase/merge;
5. nałożenie przez `git am --keep-cr --3way`.

`--keep-cr` jest konieczne — zachowuje CRLF wewnątrz patcha.

Kody wyjścia: `0` sukces lub już nałożone, `1` patch nie pasuje, `2` problem
środowiska (nie repo, brak zależności, brudne drzewo).

**`apply.py` nie czyta `patch.json`.** Pola `sha256` i `verified_upstream_base` to
metadane weryfikowane ręcznie przy pakowaniu, nie kontrola w czasie działania.

## Zależności

```
inventory-drop-cell
    └── inventory-drop-preview
            └── inventory-cell-grid

equipment-condition-time   (samodzielny)
hud-motion-cache           (samodzielny)
```

Pakiety zależne muszą leżeć jako **katalogi obok siebie** — układ jest nośny, nie
ozdobny.

Wykrywanie zależności ma dwie odmiany:

- **odwrotne sprawdzenie patcha zależności** — działa, gdy pakiety ruszają różne linie;
- **znacznik w źródłach** (np. obecność `m_drop_offset` w `UICellItem.h`) — konieczne,
  gdy pakiet przepisuje linie wniesione przez zależność, bo wtedy tamten patch nie daje
  się już odwrócić.

## Pułapki

- **`patches/` jest jawnie wyłączone z reguły `patch*/`.** Upstreamowy `.gitignore` ignoruje
  tymczasowe katalogi `patch*/`, co łapało też `patches/`. Na `build/tmz` zaraz po tej
  regule stoi `!patches/` (w obecnym kształcie od `c43e3262f`). Przywraca sam katalog, a
  pliki w nim podlegają zwykłym regułom: `patches/foo.log` łapie `*.log`, a
  `patches/patch_tmp/` i `patch_tmp/` łapie `patch*/`. **Nie dopisuj `!patches/**`** — nie
  jest potrzebne, a wyłączyłoby w `patches/` wszystkie wcześniejsze reguły (tak było
  w `356b52de7`). Gałęzie źródłowe stoją
  na czystym upstreamie i wyjątku nie mają. Nie potrzebują go, bo pakietów nie niosą.
  Sprawdzając plik już śledzony, dodaj `git check-ignore -v --no-index`. Bez tej opcji
  polecenie pomija pliki śledzone i milczy także wtedy, gdy reguła je łapie.
- **Dwa niezgodne schematy `patch.json`.** Rodzina inventory używa
  `verified_upstream_base` / `original_parent` / `original_commits` (od 15.09 także `branch`,
  od 21.09 we wszystkich trzech pakietach; wcześniej drop-* miały `original_integrated_commit`);
  `equipment-condition-time` używa `upstream_base` / `branch` / `commit` / `files`.
  Przy nowym pakiecie wybierz jeden i trzymaj się go.
- **Zintegrowanej gałęzi nie patchuje się ponownie.** Pakiet służy do przeniesienia
  poprawki na czysty checkout, nie do nakładania na własne, już zawierające ją repo.
- **Baza upstreamu się przesuwa.** `verified_upstream_base` odpowiada konkretnemu
  commitowi; po `git fetch upstream` patch trzeba sprawdzić na nowej bazie
  (`rebase-patch.sh` z `ixray-ttf-extended/tools/` robi to dla gałęzi fontów).
  `feature/ttf-codepages` nie ma pakietu w `build/tmz:patches/`. Skrypt zapisuje więc
  patche, po jednym na commit, do katalogu spoza repo silnika (`--out` albo `mktemp -d`),
  a do `patches/` nic nie trafia.

## Gałąź źródłowa samodzielnego pakietu

Pakiet `equipment-condition-time` ma w forku **utrzymywaną gałąź źródłową
`fix/equipment-condition-time`**, wypchniętą na `origin`. Z niej powstaje patch i na niej
przenosi się poprawkę na przyszłe wersje upstreamu. Do 15 września 2026 nazywała się
`codex/equipment-condition-time` — ta nazwa została w kopii pakietu na scalonej
`feature/ui-param-bars`. Rodzina inventory ma zamiast pojedynczej gałęzi
[łańcuch gałęzi źródłowych](#łańcuch-gałęzi-źródłowych-inventory).

- Gałąź to **dokładnie jeden commit poprawki na czystym upstreamie** (dziś `0e76d116e`
  na `6c793faee`). Nie dokładaj tam pakietu, dokumentacji ani `CLAUDE.md` — drugi commit
  psuje eksport `format-patch -1`.
- `patch.json` wskazuje ją w polach `branch` i `commit`.
- **Nie scala się jej do `build/tmz`.** Ta sama poprawka weszła tam z
  `feature/ui-param-bars` jako `e39632874`. `git log build/tmz..fix/equipment-condition-time`
  pokazuje więc jeden commit i to stan zamierzony, nie zaległość. Równoważność potwierdza
  `git cherry build/tmz fix/equipment-condition-time` — znak `-` przy commicie.
- Przy nowym upstreamie przenieś commit wg [aktualizacji pakietu](#aktualizacja-pakietu),
  a gałąź wypchnij ponownie. Rebase przepisuje historię, więc push wymaga `--force-with-lease`.
  Nowy patch i pola `upstream_base`, `commit` i `sha256` w `patch.json` trafiają do
  `patches/equipment-condition-time/` na `build/tmz`.

## Łańcuch gałęzi źródłowych inventory

Trzy pakiety inventory zależą od siebie, więc ich gałęzie źródłowe tworzą łańcuch.
Odtworzono go 15 września 2026 z historii `build/tmz`. 21 września przebudowano go o własny
shader podglądu (`38d143702`) i przy okazji wypadł z czubka commit pakietów `ea5103d0e`,
pozostałość sprzed zasady „gałąź = kod". Wcześniej `feature/inventory-cell-grid`
odgałęziała się od `build/tmz` i niosła merge'e panelu, fontów i CI, a
`feature/inventory-drop-cell` łączyła dwa pakiety.

```
default 6c793faee
 └ 36e469d8f                                    ← fix/inventory-drop-cell
   └ 15e6b828d 38d143702                        ← feature/inventory-drop-preview
     └ 749023fc9 fdd20e29d 88d04a085 7ce0fdf74  ← feature/inventory-cell-grid
```

- Każda gałąź niesie tylko swój kod z testami i gałęzie poprzednie: bez merge'y, bez
  `CLAUDE.md`, bez zmian w `gamedata`, bez `patches/`. `fix/inventory-drop-cell` to jeden
  commit na czystym upstreamie, jak `fix/equipment-condition-time`.
- Eksport z gałęzi, uruchamiany w katalogu głównym checkoutu `build/tmz`:
  ```sh
  F="--stdout --full-index --no-signature"
  git format-patch $F -1 fix/inventory-drop-cell > patches/inventory-drop-cell/0001-fix-inventory-drop-cell.patch
  git format-patch $F fix/inventory-drop-cell..feature/inventory-drop-preview > patches/inventory-drop-preview/0001-fix-inventory-drop-preview.patch
  git format-patch $F feature/inventory-drop-preview..feature/inventory-cell-grid -- src tests > patches/inventory-cell-grid/0001-fix-inventory-cell-grid.patch
  ```
  `-- src tests` ogranicza patch do kodu i testów. Gdyby kod cell-grid zaczął ruszać coś
  poza tymi katalogami, listę trzeba rozszerzyć, bo inaczej patch po cichu to zgubi.
  Plik drop-preview ma dwa commity, plik cell-grid cztery.
- `patch.json` wskazuje gałąź w `branch`, a `original_commits` to SHA na gałęzi. W cell-grid
  `integrated_commits` to odpowiedniki w `build/tmz`, łącznie z merge'em `e9103f55e`.
- **Do `build/tmz` scala się czubek `feature/inventory-cell-grid`** jawnym `merge --no-ff`
  (21.09: `e9103f55e`). Jeden merge wnosi zmianę z dowolnego ogniwa, bo czubek niesie cały
  łańcuch. Kod sprzed 21.09 wszedł dawnymi merge'ami `cc2b71d18`, `0cea6397d` i `a22572dde`,
  więc przy konflikcie w plikach inventory wersja z gałęzi jest właściwa. Po merge'u
  sprawdź, że `git diff HEAD^1 HEAD` równa się zmianie w łańcuchu. Stan zamierzony:
  `git log build/tmz..<każda z trzech gałęzi>` jest pusty.

  Równoważność kodu:
  ```sh
  git diff build/tmz feature/inventory-cell-grid -- $(git diff --name-only fix/inventory-drop-cell^ feature/inventory-cell-grid -- src tests)
  ```
  → puste. Bazą jest rodzic `fix/inventory-drop-cell`, nie `default`: `default` przesuwa się
  z upstreamem, a łańcuch nie, więc lista złapałaby też pliki upstreamu.
- **`apply.py` pakietów drop-* nie rozpoznaje własnej poprawki po nałożeniu cell-grid**
  (kody 1 i 2 zamiast 0), bo cell-grid przepisuje ich linie. Stan takiego repozytorium
  zgłasza dopiero `apply.py` pakietu cell-grid.
- CI: push refa wskazującego commit, który już jest na `origin`, nie uruchamia workflow.
  Nowy kod idzie więc do CI przez tymczasową gałąź `rebuild/*`, a właściwe gałęzie
  podmienia się dopiero po zielonym wyniku. Gałąź tymczasową usuwa się osobnym pushem,
  gdy zielone jest też CI na nowym czubku.
  Na czystym `default` workflow upstreamu buduje `Build engine` tylko w RelWithDebInfo.

**Przeniesienie łańcucha na nowy upstream** w osobnym checkoucie (worktree):

1. `git rebase --update-refs --onto upstream/default <verified_upstream_base> feature/inventory-cell-grid`
   przesuwa wszystkie trzy gałęzie naraz.
2. W checkoucie `build/tmz` wygeneruj patche poleceniami wyżej, zaktualizuj `patch.json`
   (baza, commity, `sha256`) i README pakietów, po czym zrób commit na `build/tmz`.
3. Uruchom testy na każdym commicie łańcucha i macierz `apply.py` z pakietów `build/tmz`
   na czystym nowym upstreamie.
4. Wypchnij trzy gałęzie z `--force-with-lease=<ref>:<stary sha>`, a `build/tmz` zwykłym pushem.

## Aktualizacja pakietu

Przenieś commit na nową bazę w **osobnym, czystym checkoucie**, rozwiąż konflikty,
uruchom testy ([testy.md](testy.md) — m.in. jak wycelować test w inny checkout przez
`IXRAY_TEST_ROOT`) i dopiero wtedy eksportuj ponownie:

```sh
git format-patch -1 HEAD --stdout --full-index --no-signature > <checkout build/tmz>/patches/<pakiet>/0001-fix-<nazwa>.patch
```

Potem zaktualizuj `patch.json` w tym samym katalogu, sprawdź nałożenie na czystej bazie
i zrób commit pakietu na `build/tmz`. Gałąź źródłowa dostaje tylko przeniesiony kod.
