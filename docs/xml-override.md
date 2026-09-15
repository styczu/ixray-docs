# XML w dodatkach: XMLOverride albo cały plik

## XMLOverride

Zamiast podmieniać cały plik, można dowieźć **tylko zmienione węzły**. Silnik szuka
plików pasujących do maski `mod_<nazwa>_*.<rozszerzenie>` (obsługa w `AsureXML.cpp`)
i scala je z plikiem bazowym.

Nazwa pliku w dodatku wygląda wtedy tak: `mod_actor_menu_16_uiparams.xml`.

## Kiedy czego używać

| Sytuacja | Sposób |
| --- | --- |
| zmiana kilku węzłów, współistnienie z innymi dodatkami | XMLOverride |
| przebudowa geometrii całego okna | podmiana całego pliku |

`ixray-ui-params` używa XMLOverride. `ixray-hd-icons` świadomie podmienia całe pliki,
bo zmienia geometrię siatki ekwipunku — cena to konflikt z każdym innym dodatkiem
ruszającym ten sam plik. Podmiana całego pliku to zwykła mechanika dodatku: kopia musi być
kompletna, a przy kilku dodatkach wygrywa kolejność montowania
([dodatki.md](dodatki.md#kolizje-między-dodatkami--kontrola-przy-integracji)).

Pliki tekstów (`text/<język>/*.xml`) mają własne reguły kolejności i kodowania — jeśli
zadanie ich dotyczy, przeczytaj [teksty-i-kodowania.md](teksty-i-kodowania.md).

## XML oczekujący silnika — `FAILED TO COMPILE`

```sh
grep -a -c 'FAILED TO COMPILE' <log>
```

Każde trafienie to zmienna wyrażenia w XML, której zainstalowany silnik nie rejestruje.
XML z dodatku działa od razu po restarcie, a zmienna pojawia się dopiero w binarce
zbudowanej z gałęzi, która ją dodaje. Tak wyglądała regresja panelu 14.09: 10 trafień
`fltActor*ProtectionRatio`, bo w grze siedział build bez nowszych commitów panelu.

**Jeśli pojawia się `FAILED TO COMPILE`, zanim zaczniesz poprawiać XML, sprawdź, co siedzi
w binarce** — procedura w [wdrazanie.md](wdrazanie.md#4-sprawdź-co-naprawdę-siedzi-w-grze).
