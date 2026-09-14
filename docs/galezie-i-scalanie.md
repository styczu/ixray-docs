# Gałęzie, scalanie, upstream i CI

## Układ gałęzi w repo silnika

| Gałąź | Rola |
| --- | --- |
| `default` | lustro `upstream/default`. **Nie commitujemy tu nic.** Nigdy nie rozjechała się z upstreamem. |
| `build/tmz` | **gałąź integracyjna** — to z niej powstaje build, w który się gra |
| `build/ci-release` | zmiany w konfiguracji CI; scalona do `build/tmz` |
| `feature/<temat>` | pojedyncza zmiana w silniku, powiązana z jednym dodatkiem |
| `codex/<temat>` | to samo, ale prace prowadzone Codexem |

Nazewnictwo `feature/*` jest zgodne z `doc/branching-model.md` upstreamu. Prefiksy
`build/*` i `codex/*` to nasze rozszerzenie.

**Świadome odstępstwo:** upstream wymaga liniowej historii, a `build/tmz` jest oparta
na merge'ach. To celowe — merge commit z opisem jest tu nośnikiem informacji o tym, co
i kiedy weszło do buildu.

## Scalanie do `build/tmz`

Po sprawdzeniu zmiany **w grze**, nie zaraz po zielonym CI:

```sh
git checkout build/tmz
git merge --no-ff feature/<temat> -F <plik-z-opisem>
git push origin build/tmz
```

- **Zawsze `--no-ff`**, nawet gdy fast-forward byłby możliwy.
- Temat: `Merge feature/<temat>: <krótki opis po polsku>`.
- W treści: co gałąź wnosi, oraz **wynik CI z konkretnym sha** — wzór z istniejących
  merge'y: „Oba workflow przeszły na `<sha>`: Build engine w Release i RelWithDebInfo
  oraz Non-Unity build w Debug, RelWithDebInfo i Release."
- Jeśli sprawdzono w grze, napisz to wprost, razem z rozdzielczością.

**`git merge -F -` nie czyta ze stdin** (inaczej niż `git commit -F -`) — kończy się
`error: could not read file '-'`, przy czym wcześniejszy `checkout` już się wykonał
i zostajesz na gałęzi docelowej bez scalenia. Opis zapisz do pliku.

Push na `build/tmz` sam odpala CI i powstaje artefakt do zainstalowania.

## Upstream

```
remote.upstream.url      git@github.com:ixray-team/ixray-1.6-stcop.git
remote.upstream.pushurl  DISABLE
remote.upstream.fetch    +refs/heads/default:refs/remotes/upstream/default
```

- Push jest zablokowany wartownikiem, nie mechanizmem — próba skończy się błędem
  transportu, nie czytelną odmową.
- Refspec pobiera **tylko `default`**. Inne gałęzie upstreamu (np. `rel1.4-new`) nie
  pojawią się lokalnie bez rozszerzenia refspeca.
- `git fetch upstream` **przesuwa bazę** — wszystkie pakiety w `patches/` deklarują
  `verified_upstream_base` i po pobraniu nowego upstreamu ta deklaracja przestaje
  odpowiadać rzeczywistości. Aktualizacja pakietu to osobna praca, opisana
  w [pakiety-poprawek.md](pakiety-poprawek.md).

## CI

Workflow leżą w `.github/workflows/`. Istotne dwa:

| Workflow | Co robi |
| --- | --- |
| `Build engine` | buduje silnik na `windows-2022`, konfiguracje **Release** i **RelWithDebInfo**; produkuje artefakty do instalacji |
| `Non-Unity build` | kompilacja kontrolna bez sklejania jednostek translacji, w Debug, RelWithDebInfo i Release; **nie produkuje artefaktów** |

`Non-Unity build` jest wart pilnowania: wychwytuje brakujące `#include`, które
w buildzie unity przechodzą niezauważone, a Debug to jedyna konfiguracja kompilująca
gałęzie pod `#ifdef DEBUG`.

Oba odpalają się przy pushu na **dowolną gałąź**, z filtrem ścieżek obejmującym
`src/**`, `gamedata/**`, `cmake/**`, `**/*.ltx` i `**/*.json`. Katalogi `tests/`
i `doc/` nie są w filtrze — ale `patch.json` łapie się na `**/*.json`, więc commit
samego pakietu też uruchamia budowanie.

Nazwa artefaktu: `engine-binaries-windows-2022-x64-<konfiguracja>-<pełny sha>`.

**`gh` domyślnie rozwiązuje repozytorium na upstream, nie na fork.** Do przebiegów
własnych trzeba `-R styczu/ixray-1.6-stcop`:

```sh
gh run list -R styczu/ixray-1.6-stcop --branch build/tmz --limit 5
gh run watch <ID> -R styczu/ixray-1.6-stcop --exit-status
```

**Żaden workflow nie uruchamia testów** — testy są wyłącznie lokalne
([testy.md](testy.md)).
