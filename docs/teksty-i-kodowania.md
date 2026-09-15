# Teksty, kodowania, końce linii

To źródło cichych błędów — warto mieć przed oczami.

## Strony kodowe

| Język | Strona kodowa |
| --- | --- |
| `pol`, `cze` | Windows-1250 |
| `eng`, `rus` | Windows-1251 |

- **Deklaracja XML nie konwertuje bajtów.** Zmiana `encoding=` w nagłówku nie zmienia
  zawartości pliku — trzeba przekodować rzeczywiste bajty.
- Fonty muszą pokrywać użytą stronę kodową; sprawdza to `check_font.py`
  z `ixray-ttf-extended/tools/`. Brak znaku widać w logu jako `! Glyph not found`.
- Mapowanie języków na strony kodowe w silniku wnosi gałąź `feature/ttf-codepages`
  (`src/xrCore/Localization/Codepage.{cpp,h}`).

## Końce linii

**Pliki gry mają CRLF** i trzeba je zachować. W Pythonie czytaj i zapisuj bajtowo
(`read_bytes` / `write_bytes`); `read_text` + `write_text` spłaszcza CRLF do LF
i zamienia zmianę kilkunastu linii w diff całego pliku.

## Kolejność plików tekstów i zdublowane identyfikatory

Pliki w `text/<język>/` są wczytywane **alfabetycznie po nazwie** (`FS_FileSet` to
`xr_set`), łącznie ze wszystkich dodatków. Przy zdublowanym identyfikatorze wygrywa
**ostatni wczytany** (`string_table.cpp`), a w logu zostaje `! duplicate string table id`.

Stąd prefiks `zz_` w nazwach plików tekstów dodatków — np. `zz_uiparams_panel.xml`
w `ixray-ui-params` wygrywa z `ui_st_inventory.xml` z `ixray-ttf-extended`.
Zamierzone nadpisanie i tak zostawia ostrzeżenie w logu — znane przypadki są
w [luzne-konce.md](../luzne-konce.md).
