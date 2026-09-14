# Konwencje

## Język

| Co | Język |
| --- | --- |
| Dokumentacja (ta i w dodatkach) | polski |
| Opisy commitów — repozytoria dodatków | polski |
| Opisy commitów — własne gałęzie w silniku | polski |
| **Komentarze w kodzie silnika** | **angielski** |
| Nazwy gałęzi, plików, identyfikatorów | angielski |

**Dlaczego komentarze po angielsku, a commity po polsku.** Upstream wymaga angielskich
commitów (`doc/commit-style.md`), ale `remote.upstream.pushurl` jest ustawiony na
`DISABLE` i nie było tam ani jednego PR-a. Dystrybucja idzie przez pakiety w `patches/`,
których README są polskie. Angielski realnie pracuje tylko w jednym miejscu:
komentarze siedzą w plikach upstreamu i wędrują z patchem do cudzego, anglojęzycznego
drzewa. Tam mają być zrozumiałe dla kogoś z zewnątrz.

Gdyby kiedyś powstał commit przeznaczony do PR-a w upstreamie — ten jeden pisz po
angielsku, wedle `doc/commit-style.md` (czasownik w bezokoliczniku, nagłówek do 72 znaków).

## Opisy commitów

Wzorzec z istniejących commitów, wart utrzymania:

- **nagłówek nazywa skutek, nie czynność** — „Pasek przewijania tylko wtedy, gdy ma
  dokąd przewijać", a nie „Popraw ReinitScroll";
- w treści: objaw → przyczyna → co zmieniono → świadome konsekwencje;
- liczby i konkrety zamiast ogólników („41 jedn. → 77 px → 41.07 jedn. przy 1440p");
- jeśli coś **nie** zostało sprawdzone, napisz to wprost;
- merge commity: patrz [galezie-i-scalanie.md](galezie-i-scalanie.md).

## Styl kodu w silniku

Dostosowuj się do otoczenia, nie do własnych upodobań — pliki silnika mają swoje
formatowanie (wyrównania tabulatorami, `IC` zamiast `inline`, `R_ASSERT`). Nowy kod
ma się nie wyróżniać.

Nie refaktoryzuj przy okazji. Pakiety poprawek muszą dać się nałożyć na inną wersję
IX-Ray; każda zmiana niezwiązana z tematem podnosi ryzyko konfliktu.

## Utrzymywanie dokumentacji

Reguły wypracowane wcześniej w `ixray-ui-params` i warte stosowania wszędzie:

- **Wpis powstaje po wykonaniu zmiany, nie przed.** Plany, pomysły i propozycje nie
  trafiają do rejestru zrobionych rzeczy.
- **Rozróżniaj status:** w źródłach / zainstalowane / sprawdzone w grze. To trzy różne
  rzeczy i mylenie ich już raz kosztowało rundę.
- **Zmianę obliczeń gry odróżniaj od zmiany prezentacji.**
- Dokument, który coś zastępuje, ma to powiedzieć wprost i wskazać następcę.
- Obalone hipotezy warto zapisać — oszczędzają ponownego sprawdzania.

## Podział dokumentacji

- **Tu (`ixray-docs`)** — rzeczy wspólne: środowisko, gałęzie, wdrażanie, mechanika
  dodatków, konwencje, ogólny obraz projektu.
- **W repozytorium dodatku (`docs/`)** — wszystko, co dotyczy tylko jego: decyzje
  projektowe, geometria, katalogi zmienionych przedmiotów, dziennik prac.
- **W `patches/<nazwa>/README.md`** — opis konkretnej poprawki silnika.

Zasada: jeśli informacja dotyczy więcej niż jednego komponentu, jej miejsce jest tutaj.
Jeśli tylko jednego — zostaje u niego. Nie kopiuj między repozytoriami; linkuj.

`README.md` w tym repozytorium **ładuje się w całości do kontekstu każdej sesji**
w każdym repozytorium projektu. Trzymaj go poniżej ~100 linii; szczegóły dopisuj do
dokumentów w `docs/`, które są otwierane dopiero wtedy, gdy zadanie ich wymaga.
