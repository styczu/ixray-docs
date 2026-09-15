# Wdrażanie: silnik i dodatki

Dwie różne drogi i dwa różne tempa. Dane dodatku działają po restarcie gry. Zmiana
w C++ wymaga przejścia przez CI i instalacji binarek — kilkanaście minut.

## Dodatek

Katalog roboczy dodatku **nie jest** tym, z którego czyta gra. Dodatek trzeba wdrożyć.
Służy do tego narzędzie `ixray-docs/tools/addon-sync`; `~/bin/addon-sync` to symlink
do niego, dla wygody (PATH):

```sh
addon-sync -c -a            # sprawdź wszystkie dodatki (rsync -n -c, sumy kontrolne)
addon-sync -c -v -n <nazwa> # wypisz różniące się pliki z datami
addon-sync -s -n <nazwa>    # wdróż (rsync -av)
```

Źródłem są katalogi w `/home/tmz/Projects/ixray-addons` z wyjątkiem `engine-bin`.
Lista pomijanych plików — `RSYNC_EXCLUDES` w skrypcie, to źródło prawdy.
Bez narzędzia można użyć `cp -r <repo-dodatku>/. "<gra>/ixr_addons/<nazwa>/"`, ale to
kopiuje wszystko, także `.git` i dokumenty.

Alternatywnie zlinkować katalog, żeby się nie rozjeżdżał — dziś to osobne kopie.

**Ani `addon-sync -s`, ani `cp -r` nie usuwają plików przemianowanych ani usuniętych
w repo.** Po zmianie nazwy `mod_items_hd_medkits.ltx` → `mod_items_hd_icons.ltx`
w `ixray-hd-icons` stara kopia została w grze i nadpisywała apteczki teksturą z literówką.
**`addon-sync -c` takich plików też nie pokaże**, bo porównuje tylko pliki obecne w repo.

Potem restart gry. Zmiany w XML i LTX nie wymagają niczego więcej.

Pełne sprawdzenie, czy wdrożone jest to, co trzeba, widzi też pliki, których w repo już
nie ma. Porównaj cały katalog z roboczym:

```sh
diff -rq -x '.git*' -x docs -x src -x tools -x '*.md' <repo-dodatku> "<gra>/ixr_addons/<nazwa>"
```

Pusty wynik oznacza zgodność. Stan z 15.09: wszystkie trzy dodatki projektu są zgodne
według obu kontroli.

albo poszukaj konkretnej wartości:

```sh
grep -c 'cols_num="8"' "<gra>/ixr_addons/<nazwa>/configs/ui/actor_menu_16.xml"
```

**Jeśli instalacja jest zgodna z repo, a w grze działa inaczej**, ten sam plik lub sekcję
może nadpisywać inny dodatek — przeczytaj
[dodatki.md](dodatki.md#kolizje-między-dodatkami--kontrola-przy-integracji).

## Silnik

CI buduje **wyłącznie na Windows**, a gra chodzi pod Proton na binarkach Windows —
lokalnego builda na Linuksie nie da się użyć. Droga jest jedna:

### 1. Commit i push

```sh
git push origin <gałąź>
```

### 2. Poczekaj na CI

```sh
gh run list -R styczu/ixray-1.6-stcop --branch <gałąź> --limit 5
gh run watch <ID> -R styczu/ixray-1.6-stcop --exit-status
```

Budowanie silnika zajmuje ~13 minut, Non-Unity ~17.

### 3. Zainstaluj

Narzędzie: `ixray-docs/tools/install-build.sh`, w PATH jako `install-build`
(`~/bin/install-build` to symlink do niego).

```sh
install-build \
  --branch <gałąź> --config RelWithDebInfo --run <ID_PRZEBIEGU> \
  --game "/home/tmz/Games/Heroic/S.T.A.L.K.E.R. Call of Pripyat" \
  --builds /home/tmz/Projects/ixray-addons/engine-bin \
  --check-only
```

Najpierw `--check-only`, przeczytaj wynik, dopiero potem bez tej opcji.

**Zawsze przypinaj `--run <ID>`.** Bez tego skrypt bierze „ostatni udany przebieg"
dla gałęzi — a to zwykle build, który już jest zainstalowany. Instalacja „się uda"
i nic się nie zmieni. To kosztowało już jedną rundę.

Co skrypt robi sam: sprawdza, czy gra nie jest uruchomiona; weryfikuje, że pobrana
binarka **niesie oczekiwany sha, zanim cokolwiek podmieni**; robi kopię zapasową
nadpisywanych plików (`bin.backup-<data>`) z manifestami md5; po instalacji porównuje
sumy kontrolne.

### 4. Sprawdź, co naprawdę siedzi w grze

```sh
strings "<gra>/bin/xrEngine.exe" | grep -m1 "<gałąź>"
```

Ma pokazać nowy sha. Jeśli pokazuje stary — instalacja nie doszła i dalsze testy
w grze nie mają sensu.

Drugi sposób, gdy szukasz konkretnej nowej funkcji: poszukaj w binarce literału,
który wprowadza Twoja zmiana.

```sh
strings "<gra>/bin/xrGame.dll" | grep -c "^<nowy_literał>$"
```

## Najczęstsza pomyłka

**Zmiana w repo to nie zmiana w grze.** Objawy bywają mylące: jeśli część zmiany to
czyste dane z XML, a część wymaga silnika, to dane zadziałają od razu, a reszta nie —
i wygląda to jak nieudana poprawka, a jest niezbudowaną poprawką.

Zanim zaczniesz szukać błędu w kodzie: porównaj datę i sha binarki z datą commitu.
