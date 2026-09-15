# Stan projektu

Stan na **15 września 2026**. Odczytany z repozytoriów i katalogu gry, nie z pamięci.

> Ten dokument odpowiada na **dwa różne pytania**: co jest zrobione i co z tego
> realnie siedzi w graniu. To nie to samo — część gotowej pracy czeka na scalenie.

## Co siedzi w graniu

| Co | Stan |
| --- | --- |
| Silnik w `<gra>/bin/` | build commitu **`236edf3a7`** (ostatni commit `build/tmz` ze zmianami kodu; nowszy `7382923aa` zmienia tylko metadane pakietu `equipment-condition-time`, bez `src/`), wariant RelWithDebInfo, zainstalowany 15.09 o 07:44; binarka niesie nazwę gałęzi `build/tmz-fix-panel`, z której zbudowało ją CI przed przesunięciem `build/tmz` |
| `ixray-hd-icons` | wdrożony, zgodny z repo (`e308b84`) poza pustym `addon.init` w grze |
| `ixray-ui-params` | wdrożony, zgodny (różni się tylko `src/`, czyli pliki robocze, których się nie wdraża) |
| `ixray-ttf-extended` | wdrożony, zgodny |

Sprawdzone w grze 15.09: użytkownik potwierdził, że wizualnie wszystko jest poprawne
(ekwipunek i panel ochron). Log tego uruchomienia: `hash[236edf3a7]`, zero
`FAILED TO COMPILE` (wcześniej 10) i brak nowych linii `!` względem ostatniego buildu
samego panelu (`1506c06da`).

`build/tmz` jest **63 commity** ponad `upstream/default` (`6c793faee`).

## Co jest zrobione, ale nie ma tego w graniu

Nic z gałęzi feature. `feature/ui-param-bars` jest w całości scalona (merge `236edf3a7`),
razem z dokumentami prozą, pakietami `equipment-condition-time` i `hud-motion-cache` oraz
testami `tests/condition-ui/` i `tests/hud-motions/`.

`fix/equipment-condition-time` to utrzymywana gałąź źródłowa samodzielnego patcha
`equipment-condition-time`, wypchnięta na `origin` 15.09. Formalnie ma 1 commit poza
`build/tmz`, ale jego treść weszła z `feature/ui-param-bars` (identyczny patch-id jak
`e39632874`), więc nie czeka na scalenie i nie scala się jej. Zasady:
[docs/pakiety-poprawek.md](docs/pakiety-poprawek.md#gałąź-źródłowa-samodzielnego-pakietu).

Łańcuch gałęzi źródłowych inventory odtworzono 15.09 na czystym upstreamie:
`fix/inventory-drop-cell` (`36e469d8f`) → `feature/inventory-drop-preview` (`15e6b828d`) →
`feature/inventory-cell-grid` (`ea5103d0e`). Wypchnięty na `origin`, a dawną
`feature/inventory-drop-cell` usunięto. Nic tu nie czeka na scalenie: kod jest identyczny
z tym w `build/tmz`. Zregenerowane pakiety z czubka (`ea5103d0e`) skopiowano 1:1 na `build/tmz`
(`5c3e60bfd`), gdzie od 15.09 utrzymuje się wszystkie pakiety. Binarka w grze się nie zmieniła.
- Sprawdzone: wszystkie testy `tests/inventory-drop/` na każdym commicie łańcucha
  i nałożenie trzech pakietów przez `apply.py` na czystym `6c793faee`.
- CI zielone na `02915a7da` (kod) i na `ea5103d0e` (kod + pakiety).
- Buildu z samych pakietów nie grano.

Zasady:
[docs/pakiety-poprawek.md](docs/pakiety-poprawek.md#łańcuch-gałęzi-źródłowych-inventory).

**Skąd wzięła się regresja z 14.09:** do 13:50 grano na binarce zbudowanej wprost
z `feature/ui-param-bars`, potem na buildach inventory i `build/tmz`, które nigdy nie
dostały 27 nowszych commitów panelu. Merge inventory niczego nie cofnął.

## Zrobione, per dodatek

### `ixray-hd-icons` — ekwipunek

Ikony w wysokiej rozdzielczości plus przebudowa geometrii siatki ekwipunku.
Trzy etapy, wszystkie scalone i sprawdzone w grze przy 2560x1440:

1. **Komórka docelowa przy upuszczaniu** liczona od kursora, nie od lewego górnego rogu
   ikony — z uwzględnieniem podkomórki, za którą złapano wielokomórkowy przedmiot.
2. **Podgląd upuszczania** — podświetlanie komórek, w które przedmiot trafi.
3. **Stały rozmiar komórki w pełnych pikselach ekranu.** Nowy atrybut XML
   `screen_cell_size` daje kwadratową komórkę o zadanym rozmiarze niezależnie od
   asymetrycznej skali; obie krawędzie ikony są zaokrąglane do pełnego piksela, więc
   zniknęły szczeliny i nachodzenia. Ustawione na `75` dla sześciu dużych siatek.
4. **Osiem kolumn zamiast siedmiu** plus cienki pasek przewijania — nowy profil
   `<inventory>` w `scroll_bar*.xml` (`height_v="6"` zamiast 15) wskazywany atrybutem
   `scroll_profile`. Pasek pokazuje się teraz tylko wtedy, gdy ma niepusty zakres, co
   usunęło martwe paski przy szybkich slotach i przy pasie.

**Ikony HD przez `mod_system_*`** (`e308b84`, 15.09): nadpisania ikon przeniesiono
z `configs/misc/mod_items_hd_icons.ltx` do `configs/mod_system_hd_icons.ltx`, bo `items.ltx`
dołączany przez `system.ltx` nie wyszukuje własnych plików `mod_*`. Ścieżka tekstury to teraz
`ui\ui_icon_equipment_hd.dds`. Plik jest zainstalowany, stara kopia z `configs/misc/` usunięta.
**W grze efektu nie potwierdzono.**

**Następne etapy, jeszcze nierozpoczęte:** szybkie sloty na `screen_cell_size`,
redesign slotów broni, hełmu, kombinezonu, detektora i pasa artefaktów.

### `ixray-ui-params` — panel parametrów postaci

Największy i najdłużej prowadzony temat. Zrobione, scalone do `build/tmz` 15.09:

- przebudowa panelu postaci: paski zdrowia, kondycji, sytości, długi pasek sytości,
  dopasowanie tekstury monitora, pozycje tekstów;
- ujednolicone tempo regeneracji w `%/s` rzeczywistej sekundy niepauzowanej, z podziałem
  na bazę, spoczynek, artefakty, wyposażenie i efekty czasowe w podpowiedziach;
- ochrony środowiskowe przeliczone na **punkty** zamiast mylących procentów, z nową
  skalą i wskaźnikiem siły źródła;
- ochrona bojowa: progi pancerza, rozszarpanie, uderzenie, wybuch, balistyka;
- panel krwawienia i skażenia z intensywnością;
- korekta interpretacji ulepszeń ochron środowiskowych (`+N%` to `+N` punktów na skali
  stupunktowej, nie procent bazy kombinezonu);
- ikony właściwości ulepszeń z atlasu.

Dokumentacja własna jest obszerna — `ixray-ui-params/docs/`, wejście przez
`docs/dziennik.md` i `docs/parametry-postaci-i-zmiany.md`.

### `ixray-ttf-extended` — fonty i strony kodowe

Silnik twardo zakładał Windows-1251 przy zamianie bajtów na Unicode, a pliki `pol`
i `cze` są w Windows-1250. Gałąź `feature/ttf-codepages` dodaje
`src/xrCore/Localization/Codepage.{cpp,h}` i mapuje języki na właściwe strony kodowe.
Dodatek dowozi fonty pokrywające polskie i czeskie znaki oraz nazwy języków w wyborze.

Scalone do `build/tmz`, działa w grze.

## Narzędzia, które powstały po drodze

| Narzędzie | Gdzie | Do czego |
| --- | --- | --- |
| `install-build.sh` | `ixray-ttf-extended/tools/` | pobiera artefakt CI i instaluje silnik do gry, z kopią zapasową i weryfikacją sha |
| `rebase-patch.sh` | `ixray-ttf-extended/tools/` | przenosi gałąź na nowy upstream i eksportuje patch |
| `check_font.py` | `ixray-ttf-extended/tools/` | sprawdza pokrycie strony kodowej przez font |
| `apply.py` | `<ixray>/patches/*/` | sprawdza i nakłada pakiet poprawki |

## Rzeczy otwarte

Lista rozjazdów i decyzji do podjęcia: [luzne-konce.md](luzne-konce.md).

**Jeśli znalazłeś rozjazd albo podejrzewasz nowy błąd, najpierw sprawdź tę listę** — może
być już znany i opisany. Nowy dopisz tam, nie naprawiaj po cichu.
