# Wdrażanie: silnik i dodatki

Dwie różne drogi i dwa różne tempa. Dane dodatku działają po restarcie gry. Zmiana
w C++ wymaga przejścia przez CI i instalacji binarek — kilkanaście minut.

## Dodatek

Katalog roboczy dodatku **nie jest** tym, z którego czyta gra. Trzeba skopiować:

```sh
cp -r /home/tmz/Projects/ixray-addons/<nazwa>/. \
      "/home/tmz/Games/Heroic/S.T.A.L.K.E.R. Call of Pripyat/ixr_addons/<nazwa>/"
```

Alternatywnie zlinkować katalog, żeby się nie rozjeżdżał — dziś to osobne kopie.

**`cp -r` nie usuwa plików przemianowanych ani usuniętych w repo.** Po zmianie nazwy
`mod_items_hd_medkits.ltx` → `mod_items_hd_icons.ltx` w `ixray-hd-icons` stara kopia
została w grze i nadpisywała apteczki teksturą z literówką.

Potem restart gry. Zmiany w XML i LTX nie wymagają niczego więcej.

Sprawdzenie, czy wdrożone jest to, co trzeba — porównaj cały katalog z roboczym:

```sh
diff -rq -x '.git*' -x docs -x src -x tools -x '*.md' <repo-dodatku> "<gra>/ixr_addons/<nazwa>"
```

Pusty wynik oznacza zgodność (stan z 15.09: wszystkie trzy dodatki projektu zgodne).

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

Narzędzie: `/home/tmz/Projects/ixray-addons/ixray-ttf-extended/tools/install-build.sh`

```sh
cd /home/tmz/Projects/ixray-addons/ixray-ttf-extended
./tools/install-build.sh \
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

Domyślne `--game` i `--builds` skryptu nie odpowiadają temu układowi — podawaj je jawnie.

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
