# Środowisko: co gdzie leży

## Katalogi robocze

| Co | Ścieżka | Uwagi |
| --- | --- | --- |
| Silnik (fork) | `/home/tmz/Projects/ixray-1.6-stcop` | repo git, remote `origin` = `styczu/ixray-1.6-stcop`, `upstream` = `ixray-team/ixray-1.6-stcop` |
| Dodatki | `/home/tmz/Projects/ixray-addons/` | katalog zbiorczy, sam nie jest repozytorium |
| Magazyn buildów | `/home/tmz/Projects/ixray-addons/engine-bin/` | ~2,8 GB, nie jest repozytorium |
| Ta dokumentacja | `/home/tmz/Projects/ixray-docs` | repo git, remote prywatny |

## Gra

Katalog gry: `/home/tmz/Games/Heroic/S.T.A.L.K.E.R. Call of Pripyat`

Gra jest buildem Windows uruchamianym pod Heroic/Proton — dlatego binarki silnika to
`.exe` i `.dll`, a CI buduje wyłącznie na Windows.

| Co | Ścieżka |
| --- | --- |
| Binarki silnika | `<gra>/bin/` |
| Dodatki | `<gra>/ixr_addons/<nazwa>/` |
| Dane bazowe | `<gra>/gamedata/` |
| Logi i zapisy | `<gra>/_appdata_ixray_/` |
| Konfiguracja ścieżek | `<gra>/fsgame.ltx` |

`fsgame.ltx` wyznacza, skąd silnik czyta dodatki:

```
$arch_dir_addons$  = true| true|  $fs_root$|  ixr_addons\
$game_data$        = false| true|  $fs_root$|  gamedata\
```

## Logi

`<gra>/_appdata_ixray_/logs/ixray-<data>-<godzina>-<user>.log`

Najnowszy log to zwykle ten z największą nazwą. Przydatne przy diagnozie:

- linia z wersją buildu na starcie (`'xrCore' build ...`);
- lista montowanych dodatków — widać kolejność przetwarzania;
- `! Glyph not found` przy problemach z fontami i kodowaniem;
- komunikaty `!` z własnych poprawek w silniku.

## Magazyn buildów

`engine-bin/` trzyma rozpakowane artefakty CI, katalog na build. Dwie konwencje nazw
żyją obok siebie:

- `<sha>` i `<sha>-debug` — ręcznie rozpakowane, nazwa od skróconego sha commitu;
- `engine-bin.<sha>.<gałąź>.<konfiguracja>` — utworzone przez `install-build.sh`,
  razem z dowiązaniem `current` wskazującym na zainstalowany build.

Każdy katalog to ten sam zestaw ~37 plików (`xrEngine.exe`, `xrGame.dll`, `xrUI.dll`,
`xrCore.dll`, `xrRender_*.dll` i biblioteki towarzyszące).

Sufiks `-debug` oznacza konfigurację **RelWithDebInfo** (z menu edytora ImGui).
Bez sufiksu — **Release** (bez menu). Do grania Release, do dłubania RelWithDebInfo.

## Czego tu nie ma

`/home/tmz/Documents/ChatGPT/ixray-1.6-stcop PL/output` to archiwum starszych paczek
i raportów. Leżą tam kopie części dokumentacji dodatków, miejscami rozbieżne z tymi
w repozytoriach. **Źródłem prawdy są repozytoria**, nie archiwum.
