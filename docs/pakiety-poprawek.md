# Pakiety poprawek — `patches/`

Poprawka silnika żyje w dwóch postaciach: jako gałąź w forku (do pracy) i jako
**samodzielny pakiet** w `patches/<nazwa>/` (do przeniesienia na inną wersję IX-Ray).

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

- **`.gitignore` łapie `patches/`.** Reguła `patch*/` (odziedziczona z upstreamu)
  powoduje, że nowe pliki w pakietach są niewidoczne dla `git status` i wymagają
  `git add -f`. Zmiany w plikach już śledzonych `git status` pokazuje, ale
  `git add <ścieżka>` też odmawia („paths are ignored") — użyj `git add -u -- <pakiet>`.
- **Dwa niezgodne schematy `patch.json`.** Rodzina inventory używa
  `verified_upstream_base` / `original_parent` / `original_commits`;
  `equipment-condition-time` używa `upstream_base` / `branch` / `commit` / `files`.
  Przy nowym pakiecie wybierz jeden i trzymaj się go.
- **Zintegrowanej gałęzi nie patchuje się ponownie.** Pakiet służy do przeniesienia
  poprawki na czysty checkout, nie do nakładania na własne, już zawierające ją repo.
- **Baza upstreamu się przesuwa.** `verified_upstream_base` odpowiada konkretnemu
  commitowi; po `git fetch upstream` patch trzeba sprawdzić na nowej bazie
  (`rebase-patch.sh` z `ixray-ttf-extended/tools/` robi to dla gałęzi fontów).

## Gałąź źródłowa samodzielnego pakietu

Pakiet `equipment-condition-time` ma w forku **utrzymywaną gałąź źródłową
`fix/equipment-condition-time`**, wypchniętą na `origin`. Z niej powstaje patch i na niej
przenosi się poprawkę na przyszłe wersje upstreamu. Do 15 września 2026 nazywała się
`codex/equipment-condition-time` — ta nazwa została w kopii pakietu na scalonej
`feature/ui-param-bars`. Inne pakiety takiej gałęzi dziś nie mają.

- Gałąź to **dokładnie jeden commit poprawki na czystym upstreamie** (dziś `0e76d116e`
  na `6c793faee`). Nie dokładaj tam pakietu, dokumentacji ani `CLAUDE.md` — drugi commit
  psuje eksport `format-patch -1`.
- `patch.json` wskazuje ją w polach `branch` i `commit`.
- **Nie scala się jej do `build/tmz`.** Ta sama poprawka weszła tam z
  `feature/ui-param-bars` jako `e39632874`. `git log build/tmz..fix/equipment-condition-time`
  pokazuje więc jeden commit i to stan zamierzony, nie zaległość. Równoważność potwierdza
  `git cherry build/tmz fix/equipment-condition-time` — znak `-` przy commicie.
- Przy nowym upstreamie przenieś commit wg [aktualizacji pakietu](#aktualizacja-pakietu),
  zaktualizuj w `patch.json` pola `upstream_base`, `commit` i `sha256`, a gałąź wypchnij
  ponownie. Rebase przepisuje historię, więc push wymaga `--force-with-lease`.

## Aktualizacja pakietu

Przenieś commit na nową bazę w **osobnym, czystym checkoucie**, rozwiąż konflikty,
uruchom testy ([testy.md](testy.md) — m.in. jak wycelować test w inny checkout przez
`IXRAY_TEST_ROOT`) i dopiero wtedy eksportuj ponownie:

```sh
git format-patch -1 HEAD --stdout --full-index --no-signature > <pakiet>/0001-fix-<nazwa>.patch
```

Potem zaktualizuj `patch.json` i sprawdź nałożenie na czystej bazie.
