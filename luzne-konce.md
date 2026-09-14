# Luźne końce

Rozjazdy znalezione przy spisywaniu dokumentacji 14 września 2026. **Żaden nie został
naprawiony** — każdy to osobna decyzja. Kolejność od najbardziej wpływowych.

## Gałęzie

**`feature/ui-param-bars` jest 26 commitów przed `build/tmz`.** Nowsze prace nad
ochronami są zrobione, ale nie ma ich w buildzie, w który grasz. Razem z nimi poza
buildem zostają dwa dokumenty prozą, dwa pakiety poprawek i wszystkie testy
`condition-ui` oraz `hud-motions`. Do decyzji: scalić czy zostawić do skończenia tematu.

**`codex/equipment-condition-time` jest 1 commit przed `build/tmz`** i nie ma go na
`origin`. Gałąź trzymana celowo jako pojedynczy commit na czystym upstreamie,
do czystego eksportu patcha.

**`origin/codex/tooltip-real-seconds`** to nieaktualna migawka bez lokalnego
odpowiednika — leży na `origin` i nic z niej nie wynika.

**`stash@{0}`** na `feature/ui-param-bars` trzyma niezacommitowaną pracę (`wip-gi3`).

## Dokumentacja odwołująca się w próżnię

**`ixray-ui-params/CLAUDE.md` wskazuje na pliki, których nie ma na `build/tmz`** —
`docs/protection-model.md` i `tests/condition-ui/test_protection.py` istnieją wyłącznie
na `feature/ui-param-bars`. Ktoś idący za tą instrukcją na bieżącym checkoucie trafia
w pustkę.

**Notatka twierdzi, że jej kopia leży w zainstalowanym dodatku** — w całym
`<gra>/ixr_addons/` nie ma ani jednego pliku `.md`.

**Ścieżka magazynu buildów w `ixray-ttf-extended/docs/utrzymanie-patcha.md` jest
nieaktualna**: dokument mówi `~/Stalker/builds`, a realny magazyn to
`/home/tmz/Projects/ixray-addons/engine-bin`. Katalog `~/Stalker/builds` nie istnieje.

**Dowiązanie `current` w magazynie buildów wskazuje na poprzedni build**
(`engine-bin.7fcb532af...`), bo ostatnia instalacja była ręczna, z pominięciem skryptu.

## Repozytoria

**`ixray-hd-icons` nie ma zdalnego repozytorium** — istnieje tylko lokalnie, bez kopii
zapasowej. Dwa commity.

**`cop-localization-fixes` to pusty katalog** bez `addon.init`, i w katalogu roboczym,
i w grze. Silnik go nie montuje.

**`ixray-hd-hud` (dodatek obcy) dowozi własny `configs/ui/actor_menu_16.xml`** —
waniliowy, z `cols_num="7"`. Dziś wygrywa `ixray-hd-icons`, ale kolejność
rozstrzygania remisu nie jest nigdzie udokumentowana. Jeśli ekwipunek kiedyś „wróci"
do siedmiu kolumn bez żadnej zmiany z naszej strony — to pierwsze miejsce do sprawdzenia.

## Silnik i pakiety

**`.gitignore:60` zawiera `patch*/`, co łapie `patches/`.** Nowe pliki w pakietach są
niewidoczne dla `git status` i wymagają `git add -f`. Reguła odziedziczona z upstreamu,
kolidująca z własną konwencją.

**Dwa niezgodne schematy `patch.json`.** Rodzina inventory używa
`verified_upstream_base` / `original_parent` / `original_commits`;
`equipment-condition-time` używa `upstream_base` / `branch` / `commit` / `files`.

**`apply.py` istnieje w pięciu niemal identycznych kopiach** i **nigdy nie czyta
`patch.json`** — `sha256` i `verified_upstream_base` to metadane bez egzekucji.

**Pakiet `inventory-cell-grid` jest nieaktualny.** Jego `patch.json` wymienia commity
`28424e0f3` i `e9fb81e26`, nie zna dwóch późniejszych (martwy pasek, fallback profilu),
a README opisuje XML w `gamedata/configs/ui/actor_menu_16.xml`, którego tam już nie ma —
konfiguracja przeniosła się do dodatku. Wszedł w tym stanie do `build/tmz`.

**Luźny `patches/0001-Wyb-r-strony-kodowej-*.patch`** jest nieśledzony i w formacie
sprzed konwencji katalogów.

**Lokalny `upstream/default` jest nieaktualny** (`6c793faee` kontra `612b165c9` na
żywo, stan z 6 września). Po `git fetch upstream` baza deklarowana we wszystkich
pakietach przestanie odpowiadać rzeczywistości. Refspec pobiera tylko `default`, więc
`rel1.4-new` nie pojawi się lokalnie.

**Dwa dokumenty prozą leżą w `docs/`, czyli w drzewie strony VitePress upstreamu** —
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
