# Stan projektu

Stan na **14 września 2026**. Odczytany z repozytoriów i katalogu gry, nie z pamięci.

> Ten dokument odpowiada na **dwa różne pytania**: co jest zrobione i co z tego
> realnie siedzi w graniu. To nie to samo — część gotowej pracy czeka na scalenie.

## Co siedzi w graniu

| Co | Stan |
| --- | --- |
| Silnik w `<gra>/bin/` | build commitu **`a22572dde`** (`build/tmz`), wariant RelWithDebInfo, zainstalowany 14.09 o 23:11 |
| `ixray-hd-icons` | wdrożony, zgodny z katalogiem roboczym |
| `ixray-ui-params` | wdrożony, zgodny (różni się tylko `src/`, czyli pliki robocze, których się nie wdraża) |
| `ixray-ttf-extended` | wdrożony, zgodny |

`build/tmz` jest **32 commity** ponad `upstream/default` (`6c793faee`).

## Co jest zrobione, ale nie ma tego w graniu

| Gałąź | Ponad `build/tmz` | Czego dotyczy |
| --- | --- | --- |
| `feature/ui-param-bars` | **+26 commitów** | nowsze prace nad ochronami: tooltipy ochron środowiskowych, ochrona bojowa, ikony ulepszeń |
| `codex/equipment-condition-time` | +1 commit | naliczanie czasu efektów sprzętu |

To jest najważniejsza rozbieżność w projekcie. Panel parametrów działa w grze, ale
w wersji sprzed kilkunastu commitów. Razem z tymi commitami poza buildem zostają też
dwa dokumenty prozą (`docs/protection-model.md`,
`docs/environmental-protection-tooltips.md`), pakiety `equipment-condition-time`
i `hud-motion-cache` oraz **wszystkie testy** `tests/condition-ui/` i `tests/hud-motions/`.

Praktyczny skutek: odwołania do tych plików z dokumentacji `ixray-ui-params` nie
działają na `build/tmz` — trzeba przełączyć się na `feature/ui-param-bars`.

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

**Następne etapy, jeszcze nierozpoczęte:** szybkie sloty na `screen_cell_size`,
redesign slotów broni, hełmu, kombinezonu, detektora i pasa artefaktów.

### `ixray-ui-params` — panel parametrów postaci

Największy i najdłużej prowadzony temat. Zrobione (część poza buildem, patrz wyżej):

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
