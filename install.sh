#!/bin/bash
# Gear Atlas 맥 설치 — https://raw.githubusercontent.com/dec-codeon/Epic7_Gear_Atlas_Releases/main/install.sh
#
# 하는 일 넷: 최신 판을 받는다 → 응용 프로그램 폴더에 넣는다 → 맥이 인터넷에서
# 받은 파일에 붙이는 「열지 않음」 표시를 푼다 → 연다.
# Gear Atlas 는 애플 공증을 받지 않은 앱이라 그냥 열면 「악성 코드가 없음을 확인할 수
# 없습니다」가 뜬다. 이 스크립트는 그 표시만 풀고, 그 밖에는 아무것도 손대지 않는다.
set -euo pipefail

REPO="dec-codeon/Epic7_Gear_Atlas_Releases"
NAME="Gear Atlas"
APP="/Applications/$NAME.app"

say() { printf '\033[1;34m▸\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "맥에서만 됩니다."
[ "$(uname -m)" = "arm64" ] || die "Apple Silicon 맥(M1 이후)에서만 됩니다. 이 맥은 $(uname -m) 입니다."

if pgrep -xq "$NAME"; then
  say "실행 중인 $NAME 을(를) 닫습니다."
  osascript -e "tell application \"$NAME\" to quit" >/dev/null 2>&1 || pkill -x "$NAME" || true
  sleep 2
fi

say "최신 판을 찾습니다."
URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -o '"browser_download_url": *"[^"]*arm64\.dmg"' | head -1 | sed 's/.*"\(https[^"]*\)"/\1/') || true
[ -n "$URL" ] || die "최신 판 주소를 못 찾았습니다. https://github.com/$REPO/releases 에서 직접 받아 주세요."
VER=$(printf '%s' "$URL" | sed -n 's/.*Gear-Atlas-\([0-9.]*\)-arm64\.dmg/\1/p')

TMP=$(mktemp -d /tmp/gear-atlas-install.XXXXXX)
MNT="$TMP/mnt"
cleanup() { hdiutil detach "$MNT" -quiet >/dev/null 2>&1 || true; rm -rf "$TMP"; }
trap cleanup EXIT

say "$NAME ${VER:-} 을(를) 받습니다."
curl -fL --progress-bar -o "$TMP/Gear-Atlas.dmg" "$URL"

say "응용 프로그램 폴더에 넣습니다."
mkdir -p "$MNT"
hdiutil attach "$TMP/Gear-Atlas.dmg" -mountpoint "$MNT" -nobrowse -quiet
[ -d "$MNT/$NAME.app" ] || die "받은 파일 안에 $NAME.app 이 없습니다."
rm -rf "$APP"
ditto "$MNT/$NAME.app" "$APP"
hdiutil detach "$MNT" -quiet

say "「열지 않음」 표시를 풉니다."
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

say "엽니다."
open -a "$APP"
printf '\033[1;32m✓\033[0m %s %s 설치 끝. 다음부터는 응용 프로그램에서 그냥 열면 됩니다.\n' "$NAME" "${VER:-}"
