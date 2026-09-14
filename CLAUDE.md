# ixray-docs — wspólna dokumentacja projektu IX-Ray

To repozytorium spina silnik i dodatki. Nie ma tu kodu ani danych gry, tylko opis
zasad i stanu projektu.

## Zasady

Wejściem jest `README.md` i to **on ładuje się do kontekstu każdej sesji w każdym
repozytorium projektu**. Dlatego:

- trzymaj go poniżej ~100 linii;
- szczegóły dopisuj do `docs/<temat>.md`, nie do `README.md`;
- nowy dokument w `docs/` dopisz do listy odsyłaczy w `README.md`.

## Co gdzie

- `README.md` — mapa, rejestr „dodatek ↔ gałąź", reguły kosztujące rundę.
- `docs/` — rozwinięcia tematów, otwierane na żądanie.
- `stan-projektu.md` — co zrobione i co realnie jest w graniu. To dwie różne rzeczy
  i mają zostać rozdzielone.
- `luzne-konce.md` — znalezione rozjazdy. Zapisujemy, nie naprawiamy po cichu.
- `szablony/wzor-CLAUDE.md` — wzorzec dla nowego repozytorium w projekcie.

## Zasady pisania

Po polsku. Wpis powstaje po wykonaniu zmiany, nie przed — plany nie trafiają do
rejestru zrobionych rzeczy. Rozróżniaj: w źródłach / zainstalowane / sprawdzone w grze.
Pełne konwencje w `docs/konwencje.md`.
