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
  na czystym upstreamie i wyjątku nie mają. Nie potrzebują go, bo pakietów nie niosą
  (wyjątkiem jest pozostałość `ea5103d0e`, niżej).
  Sprawdzając plik już śledzony, dodaj `git check-ignore -v --no-index`. Bez tej opcji
  polecenie pomija pliki śledzone i milczy także wtedy, gdy reguła je łapie.
- **Dwa niezgodne schematy `patch.json`.** Rodzina inventory używa
  `verified_upstream_base` / `original_parent` / `original_commits` (od 15.09 także `branch`);
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
Odtworzono go 15 września 2026 z historii `build/tmz`. Wcześniej `feature/inventory-cell-grid`
odgałęziała się od `build/tmz` i niosła merge'e panelu, fontów i CI, a
`feature/inventory-drop-cell` łączyła dwa pakiety.

```
default 6c793faee
 └ 36e469d8f                                    ← fix/inventory-drop-cell
   └ 15e6b828d                                  ← feature/inventory-drop-preview
     └ 60564a6bf fe243d080 2b665a2b0 02915a7da    kod inventory-cell-grid
       └ ea5103d0e  pakiety, pozostałość        ← feature/inventory-cell-grid
```

- Każda gałąź niesie tylko swój kod z testami i gałęzie poprzednie: bez merge'y, bez
  `CLAUDE.md`, bez zmian w `gamedata`. `fix/inventory-drop-cell` to jeden commit na czystym
  upstreamie, jak `fix/equipment-condition-time`.
- **`ea5103d0e` z pakietami na czubku `feature/inventory-cell-grid` jest pozostałością sprzed
  zasady „gałąź = kod".** Jego treść leży 1:1 na `build/tmz` od `5c3e60bfd` i tam pakiety
  się zmienia. Gałęzi nie przepisano tylko po to, żeby go usunąć. Przy najbliższej
  przebudowie łańcucha ten commit się pomija.
- Eksport z gałęzi, uruchamiany w katalogu głównym checkoutu `build/tmz`:
  ```sh
  F="--stdout --full-index --no-signature"
  git format-patch $F -1 fix/inventory-drop-cell > patches/inventory-drop-cell/0001-fix-inventory-drop-cell.patch
  git format-patch $F fix/inventory-drop-cell..feature/inventory-drop-preview > patches/inventory-drop-preview/0001-fix-inventory-drop-preview.patch
  git format-patch $F feature/inventory-drop-preview..feature/inventory-cell-grid -- src tests > patches/inventory-cell-grid/0001-fix-inventory-cell-grid.patch
  ```
  `-- src tests` ogranicza patch do kodu i testów, a dziś pomija też `ea5103d0e`. Gdyby kod
  cell-grid zaczął ruszać coś poza tymi katalogami, listę trzeba rozszerzyć, bo inaczej patch
  po cichu to zgubi.
- `patch.json` wskazuje gałąź w `branch`. W cell-grid `original_commits` to SHA na gałęzi,
  a `integrated_commits` to odpowiedniki w `build/tmz`.
- **Nie scala się ich do `build/tmz`.** Treść weszła tam dawnymi merge'ami `cc2b71d18`,
  `0cea6397d` i `a22572dde`. Stan zamierzony wygląda tak:
  - `git log build/tmz..fix/inventory-drop-cell` i `..feature/inventory-drop-preview` są
    puste, bo to te same commity;
  - `git cherry build/tmz feature/inventory-cell-grid` daje `- + + - +`. Środkowe `+` to
    `fe243d080` i `2b665a2b0`, które od `e9fb81e26` i `8c031bfb9` różnią się wyłącznie
    wyciętym dodaniem i cofnięciem `screen_cell_size` w `gamedata`. Ostatni `+` to
    `ea5103d0e`. Na `build/tmz` te same pliki weszły commitem `5c3e60bfd`, który podmienia
    starsze kopie, więc patch-id jest inny.

  Równoważność kodu:
  ```sh
  git diff build/tmz feature/inventory-cell-grid -- $(git diff --name-only default feature/inventory-cell-grid -- src tests)
  ```
  → puste.
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
2. Jednorazowo, dopóki na czubku leży pozostałość `ea5103d0e`, usuń jej przeniesioną kopię.
   `git show --stat HEAD` ma pokazać wyłącznie `patches/`, potem `git reset --hard HEAD~1`.
3. W checkoucie `build/tmz` wygeneruj patche poleceniami wyżej, zaktualizuj `patch.json`
   (baza, commity, `sha256`) i README pakietów, po czym zrób commit na `build/tmz`.
4. Uruchom testy na każdym commicie łańcucha i macierz `apply.py` z pakietów `build/tmz`
   na czystym nowym upstreamie.
5. Wypchnij trzy gałęzie z `--force-with-lease=<ref>:<stary sha>`, a `build/tmz` zwykłym pushem.

## Aktualizacja pakietu

Przenieś commit na nową bazę w **osobnym, czystym checkoucie**, rozwiąż konflikty,
uruchom testy ([testy.md](testy.md) — m.in. jak wycelować test w inny checkout przez
`IXRAY_TEST_ROOT`) i dopiero wtedy eksportuj ponownie:

```sh
git format-patch -1 HEAD --stdout --full-index --no-signature > <checkout build/tmz>/patches/<pakiet>/0001-fix-<nazwa>.patch
```

Potem zaktualizuj `patch.json` w tym samym katalogu, sprawdź nałożenie na czystej bazie
i zrób commit pakietu na `build/tmz`. Gałąź źródłowa dostaje tylko przeniesiony kod.
