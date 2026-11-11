#!/bin/bash
# ai-usage-bar 설치: 최신 릴리스 묶음 내려받기 → SwiftBar 없으면 설치 → SwiftBar에 연결 → 실행
# 사용: curl -fsSL https://raw.githubusercontent.com/soleil0430/ai-usage-bar/main/install.sh | bash
# 설치 파일(ai-usage-bar.pkg)도 이 스크립트를 그대로 실행한다. Homebrew·git·컴파일이 필요 없다.
# 설치 뒤에는 플러그인이 하루 한 번 스스로 업데이트한다. 다시 실행하면 바로 최신으로 맞춘다.
set -euo pipefail

REL=${AI_USAGE_REL:-https://github.com/soleil0430/ai-usage-bar/releases/latest/download}   # AI_USAGE_REL: 시험용
DEST=${AI_USAGE_BAR_DIR:-$HOME/Library/Application Support/ai-usage-bar}
PLUGIN=ai-usage.1m.sh
die() { echo "설치 중단: $*" >&2; exit 1; }

[ "$(uname)" = Darwin ] || die "macOS 전용입니다."
command -v jq >/dev/null || die "jq가 없습니다. macOS 15 이상에서 사용하세요."
[ ! -e "$DEST/.git" ] || die "$DEST 는 저장소를 직접 받은 개발용 사본입니다. git pull 로 갱신하세요."

TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT

# 1) 플러그인 묶음
curl -fsSL "$REL/ai-usage-bar.tar.gz" | tar -xz -C "$TMP" || die "배포 묶음을 받지 못했습니다."
bash -n "$TMP/plugins/$PLUGIN" && [ -x "$TMP/plugins/.baticon" ] || die "받은 묶음이 올바르지 않습니다."
mkdir -p "$DEST/plugins"
mv -f "$TMP/plugins/.baticon" "$TMP/plugins/$PLUGIN" "$DEST/plugins/"
mv -f "$TMP/VERSION" "$DEST/VERSION"

# 2) SwiftBar (없을 때만, 공식 GitHub 릴리스에서)
APP=/Applications/SwiftBar.app
[ -d "$APP" ] || APP="$HOME/Applications/SwiftBar.app"
if [ ! -d "$APP" ]; then
  URL=$(curl -fsSL https://api.github.com/repos/swiftbar/SwiftBar/releases/latest |
    jq -r '[.assets[] | select(.name | endswith(".zip"))][0].browser_download_url // empty')
  [ -n "$URL" ] || die "SwiftBar 내려받기 주소를 찾지 못했습니다. https://swiftbar.app 에서 직접 설치한 뒤 다시 실행하세요."
  curl -fsSL "$URL" -o "$TMP/SwiftBar.zip"
  ditto -x -k "$TMP/SwiftBar.zip" "$TMP/sb"
  [ -d "$TMP/sb/SwiftBar.app" ] || die "받은 SwiftBar 파일이 올바르지 않습니다."
  if [ -w /Applications ]; then APP=/Applications/SwiftBar.app; else mkdir -p "$HOME/Applications"; fi
  mv "$TMP/sb/SwiftBar.app" "$APP"
  echo "SwiftBar를 $APP 에 설치했습니다."
fi

# 3) SwiftBar에 연결. 이미 쓰는 플러그인 폴더가 있으면 그 설정은 건드리지 않고 바로가기만 넣는다.
CUR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
if [ -z "$CUR" ] || [ ! -d "$CUR" ]; then
  defaults write com.ameba.SwiftBar PluginDirectory "$DEST/plugins"
elif [ "$CUR" != "$DEST/plugins" ]; then
  LINK="$CUR/$PLUGIN"
  if [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
    echo "주의: $LINK 파일이 이미 있어 바로가기를 만들지 않았습니다. 직접 정리한 뒤 다시 실행하세요." >&2
  else
    ln -sfn "$DEST/plugins/$PLUGIN" "$LINK"
    echo "기존 SwiftBar 플러그인 폴더($CUR)에 바로가기를 넣었습니다."
  fi
fi

# 4) 실행
if pgrep -xq SwiftBar; then open -g "swiftbar://refreshallplugins"; else open "$APP"; fi

cat <<EOF

ai-usage-bar $(cat "$DEST/VERSION") 설치 완료. 상단 바에 AI 서비스 아이콘과 배터리가 나타납니다.
- 키체인 접근을 물으면 "항상 허용"을 누르세요.
- 재부팅 후에도 보이게 하려면 SwiftBar 설정에서 "Launch at Login"을 켜세요.
- 표시할 서비스는 상단 바 항목을 클릭해 체크박스로 고릅니다.
- 새 버전은 하루 안에 자동으로 적용됩니다.
EOF
