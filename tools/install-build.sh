#!/usr/bin/env bash
#
# Pobiera binarki z CI do magazynu buildów i instaluje je do katalogu gry.
#
#   ./tools/install-build.sh [opcje]
#
#   --branch NAZWA    gałąź w forku            (domyślnie build/tmz)
#   --config NAZWA    Release | RelWithDebInfo (domyślnie Release)
#   --run ID          konkretny przebieg CI zamiast ostatniego udanego
#   --game ŚCIEŻKA    katalog gry
#   --builds ŚCIEŻKA  magazyn buildów          (domyślnie ~/Projects/ixray-addons/engine-bin)
#   --check-only      pokaż co by zrobił, nie ruszaj niczego
#   --list            wypisz buildy w magazynie i zakończ
#
# Każdy build ląduje w osobnym katalogu:
#
#   ~/Projects/ixray-addons/engine-bin/engine-bin.<hash>.<gałąź>.<konfiguracja>
#
# dzięki czemu nic się nie nadpisuje, da się wrócić do dowolnej wersji,
# a ponowne uruchomienie dla tego samego commitu nie pobiera niczego drugi
# raz. Dowiązanie "current" pokazuje na to, co jest zainstalowane w grze.
#
# Konfiguracje: Release nie ma menu edytora ImGui (CMake nie definiuje
# DEBUG_DRAW, definiuje MASTER_GOLD), RelWithDebInfo ma je włączone od
# startu. Do grania Release, do dłubania RelWithDebInfo.
#
# Kody wyjścia: 0 sukces, 1 błąd, 2 błąd użycia.

set -uo pipefail

REPO_SLUG="styczu/ixray-1.6-stcop"
WORKFLOW="Build engine"
BRANCH="build/tmz"
CONFIG="Release"
RUN_ID=""
GAME_DIR="$HOME/Games/Heroic/S.T.A.L.K.E.R. Call of Pripyat"
BUILDS_DIR="$HOME/Projects/ixray-addons/engine-bin"
CHECK_ONLY=0
DO_LIST=0

while [ $# -gt 0 ]; do
	case "$1" in
		--branch)     BRANCH="$2"; shift 2 ;;
		--config)     CONFIG="$2"; shift 2 ;;
		--run)        RUN_ID="$2"; shift 2 ;;
		--game)       GAME_DIR="$2"; shift 2 ;;
		--builds)     BUILDS_DIR="$2"; shift 2 ;;
		--repo)       REPO_SLUG="$2"; shift 2 ;;
		--check-only) CHECK_ONLY=1; shift ;;
		--list)       DO_LIST=1; shift ;;
		-h|--help)    awk 'NR>1 && /^#/{sub(/^# ?/,"");print;next} NR>1{exit}' "$0"; exit 0 ;;
		*)            echo "Nieznany argument: $1 (użyj --help)" >&2; exit 2 ;;
	esac
done

say()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok()   { printf '   \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '   \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\n\033[31m✗ %s\033[0m\n' "$1" >&2; exit "${2:-1}"; }

BIN_DIR="$GAME_DIR/bin"

# ---------------------------------------------------------------- --list
if [ "$DO_LIST" = "1" ]; then
	say "Magazyn buildów: $BUILDS_DIR"
	[ -d "$BUILDS_DIR" ] || die "nie ma takiego katalogu"
	CUR="$(readlink -f "$BUILDS_DIR/current" 2>/dev/null)"
	for d in "$BUILDS_DIR"/engine-bin.*; do
		[ -d "$d" ] || continue
		MARK="  "; [ "$(readlink -f "$d")" = "$CUR" ] && MARK="->"
		printf '   %s %-52s %6s  %s\n' "$MARK" "$(basename "$d")" \
			"$(du -sh "$d" 2>/dev/null | cut -f1)" \
			"$(date -r "$d" '+%Y-%m-%d %H:%M' 2>/dev/null)"
	done
	echo
	echo "   -> = zainstalowany w grze"
	exit 0
fi

# ---------------------------------------------------------------- kontrole
say "Kontrole wstępne"
command -v gh >/dev/null 2>&1 || die "brak 'gh' w PATH" 2
gh auth status >/dev/null 2>&1 || die "gh nie jest zalogowany — uruchom: gh auth login" 2
ok "gh zalogowany"

[ -d "$BIN_DIR" ] || die "nie ma katalogu $BIN_DIR (użyj --game)" 2
ok "gra: $GAME_DIR"

case "$CONFIG" in
	Release)        ok "konfiguracja: Release (bez menu edytora)" ;;
	RelWithDebInfo) ok "konfiguracja: RelWithDebInfo (z menu edytora ImGui)" ;;
	*)              warn "nietypowa konfiguracja: $CONFIG" ;;
esac

if pgrep -f 'xrEngine\.exe' >/dev/null 2>&1; then
	die "gra jest uruchomiona — zamknij ją, bo podmiana DLL-i pod działającym procesem nic nie da"
fi
ok "gra nie działa"

# ---------------------------------------------------------------- przebieg CI
say "Szukam przebiegu CI"
if [ -z "$RUN_ID" ]; then
	LINE="$(gh run list -R "$REPO_SLUG" -b "$BRANCH" -w "$WORKFLOW" -s success -L 1 \
		--json databaseId,headSha,createdAt \
		--jq '.[0] | "\(.databaseId) \(.headSha) \(.createdAt)"' 2>/dev/null)"
	[ -n "$LINE" ] || die "brak udanego przebiegu '$WORKFLOW' dla gałęzi $BRANCH"
	read -r RUN_ID SHA WHEN <<<"$LINE"
else
	SHA="$(gh run view "$RUN_ID" -R "$REPO_SLUG" --json headSha -q .headSha 2>/dev/null)"
	WHEN="$(gh run view "$RUN_ID" -R "$REPO_SLUG" --json createdAt -q .createdAt 2>/dev/null)"
	[ -n "$SHA" ] || die "nie mogę odczytać przebiegu $RUN_ID"
fi
SHORT="${SHA:0:9}"
ok "run $RUN_ID  commit $SHORT  ($WHEN)"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." 2>/dev/null && pwd)/ixray-1.6-stcop"
LOCAL_HEAD="$(git -C "$REPO_DIR" rev-parse "$BRANCH" 2>/dev/null)"
if [ -n "$LOCAL_HEAD" ] && [ "$LOCAL_HEAD" != "$SHA" ]; then
	warn "lokalny $BRANCH to ${LOCAL_HEAD:0:9}, a artefakt jest z $SHORT — nie wypchnąłeś najnowszego commitu?"
fi

# ---------------------------------------------------------------- katalog docelowy
BRANCH_SAFE="${BRANCH//\//-}"
DEST="$BUILDS_DIR/engine-bin.$SHORT.$BRANCH_SAFE.$CONFIG"
echo "   katalog: $DEST"

NEED_DOWNLOAD=1
if [ -d "$DEST" ] && [ -f "$DEST/xrEngine.exe" ]; then
	NEED_DOWNLOAD=0
	ok "ten build jest już w magazynie — nie pobieram drugi raz"
fi

if [ "$CHECK_ONLY" = "1" ]; then
	say "Tryb --check-only — kończę bez zmian"
	[ "$NEED_DOWNLOAD" = "1" ] && echo "   pobrałbym artefakt do $DEST"
	echo "   zainstalowałbym z $DEST do $BIN_DIR"
	exit 0
fi

# ---------------------------------------------------------------- pobranie
if [ "$NEED_DOWNLOAD" = "1" ]; then
	say "Pobieram"
	ART="$(gh api "repos/$REPO_SLUG/actions/runs/$RUN_ID/artifacts" \
		--jq ".artifacts[] | select(.expired==false) | select(.name|startswith(\"engine-binaries-\")) | select(.name|contains(\"-$CONFIG-\")) | .name" 2>/dev/null | head -1)"
	if [ -z "$ART" ]; then
		echo "   dostępne artefakty w tym przebiegu:"
		gh api "repos/$REPO_SLUG/actions/runs/$RUN_ID/artifacts" \
			--jq '.artifacts[] | select(.expired==false) | "     " + .name' 2>/dev/null
		die "nie ma artefaktu engine-binaries dla konfiguracji $CONFIG (spróbuj --config RelWithDebInfo)"
	fi
	ok "artefakt: $ART"

	mkdir -p "$BUILDS_DIR" || die "nie mogę utworzyć $BUILDS_DIR"
	TMP="$(mktemp -d "$BUILDS_DIR/.tmp.XXXXXX")" || die "nie mogę utworzyć katalogu tymczasowego"
	# pobieramy do katalogu tymczasowego, bo gh nie nadpisuje istniejących
	# plików i przerywa rozpakowywanie na pierwszym, który już jest
	if ! gh run download "$RUN_ID" -R "$REPO_SLUG" -n "$ART" -D "$TMP"; then
		rm -rf "$TMP"; die "pobranie nie przeszło"
	fi
	[ -f "$TMP/xrEngine.exe" ] || { rm -rf "$TMP"; die "w artefakcie nie ma xrEngine.exe"; }
	rm -rf "$DEST" 2>/dev/null
	mv "$TMP" "$DEST" || { rm -rf "$TMP"; die "nie mogę przenieść do $DEST"; }
	ok "$(find "$DEST" -maxdepth 1 -type f | wc -l | tr -d ' ') plików w $DEST"
fi

# ---------------------------------------------------------------- weryfikacja PRZED instalacją
say "Sprawdzam, czy to na pewno ten commit"
if grep -aq "$SHORT" "$DEST/xrEngine.exe"; then
	ok "xrEngine.exe niesie hash $SHORT"
else
	FOUND="$(grep -aoE 'hash\[[0-9a-f]{9}\]' "$DEST/xrEngine.exe" | head -1)"
	die "xrEngine.exe NIE niesie $SHORT (znalazłem: ${FOUND:-nic}) — nie instaluję"
fi
grep -aq "$BRANCH" "$DEST/xrEngine.exe" \
	&& ok "gałąź w binarce: $BRANCH" \
	|| warn "w binarce nie ma napisu '$BRANCH' — sprawdź, z czego CI budowało"

# ---------------------------------------------------------------- kopia zapasowa
say "Kopia zapasowa"
BK="$GAME_DIR/bin.backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK" || die "nie mogę utworzyć $BK"
( cd "$BIN_DIR" && find . -maxdepth 1 -type f -exec md5sum {} + | sed 's|\./||' | sort -k2 ) > "$BK/MANIFEST-przed.md5"
NBK=0
while IFS= read -r f; do
	b="$(basename "$f")"
	[ -f "$BIN_DIR/$b" ] && cp -p "$BIN_DIR/$b" "$BK/$b" && NBK=$((NBK+1))
done < <(find "$DEST" -maxdepth 1 -type f)
ok "$NBK plików w $(basename "$BK")"

# ---------------------------------------------------------------- instalacja
say "Instaluję"
NINST=0
while IFS= read -r f; do
	cp -p "$f" "$BIN_DIR/" || die "nie mogę skopiować $(basename "$f")"
	NINST=$((NINST+1))
done < <(find "$DEST" -maxdepth 1 -type f)
ok "$NINST plików"
( cd "$BIN_DIR" && find . -maxdepth 1 -type f -exec md5sum {} + | sed 's|\./||' | sort -k2 ) > "$BK/MANIFEST-po.md5"

# ---------------------------------------------------------------- weryfikacja PO instalacji
say "Weryfikacja"
BAD=0
while IFS= read -r f; do
	b="$(basename "$f")"
	[ "$(md5sum "$f" | cut -d' ' -f1)" = "$(md5sum "$BIN_DIR/$b" 2>/dev/null | cut -d' ' -f1)" ] \
		|| { warn "$b — suma się nie zgadza"; BAD=$((BAD+1)); }
done < <(find "$DEST" -maxdepth 1 -type f)
[ "$BAD" = "0" ] && ok "wszystkie $NINST sum kontrolnych się zgadzają" || die "$BAD plików się nie zgadza"

grep -aq "$SHORT" "$BIN_DIR/xrEngine.exe" \
	&& ok "zainstalowany xrEngine.exe niesie $SHORT" \
	|| die "zainstalowany xrEngine.exe NIE niesie $SHORT"

ln -sfn "$DEST" "$BUILDS_DIR/current" && ok "current -> $(basename "$DEST")"

# ---------------------------------------------------------------- podsumowanie
say "Gotowe"
echo "   commit:  $SHORT ($BRANCH, $CONFIG)"
echo "   run:     $RUN_ID"
echo "   build:   $DEST"
echo "   kopia:   $BK"
echo
echo "   Powrót do poprzedniego builda:"
echo "       ./tools/install-build.sh --run <ID>          # albo:"
echo "       cp -p \"$BK\"/*.dll \"$BK\"/*.exe \"$BIN_DIR\"/"
echo
NOLD="$(find "$GAME_DIR" -maxdepth 1 -type d -name 'bin.backup-*' 2>/dev/null | wc -l | tr -d ' ')"
[ "$NOLD" -gt 3 ] && warn "$NOLD katalogów bin.backup-* w katalogu gry — warto skasować stare"
NB="$(find "$BUILDS_DIR" -maxdepth 1 -type d -name 'engine-bin.*' 2>/dev/null | wc -l | tr -d ' ')"
[ "$NB" -gt 6 ] && warn "$NB buildów w magazynie ($(du -sh "$BUILDS_DIR" 2>/dev/null | cut -f1)) — warto przejrzeć: --list"
exit 0
