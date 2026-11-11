#!/bin/bash
# ai-usage-bar 설치: SwiftBar 설치 → 내려받기 → 아이콘 도우미 컴파일 → SwiftBar에 연결 → 실행
# 사용: curl -fsSL https://raw.githubusercontent.com/soleil0430/ai-usage-bar/main/install.sh | bash
# 다시 실행하면 최신 버전으로 갱신한다. 설치 위치는 AI_USAGE_BAR_DIR 로 바꿀 수 있다 (기본 ~/ai-usage-bar)
set -euo pipefail

REPO=https://github.com/soleil0430/ai-usage-bar.git
DEST=${AI_USAGE_BAR_DIR:-$HOME/ai-usage-bar}
PLUGIN=ai-usage.1m.sh
die() { echo "설치 중단: $*" >&2; exit 1; }

[ "$(uname)" = Darwin ] || die "macOS 전용입니다."
command -v brew >/dev/null || die "Homebrew가 필요합니다. https://brew.sh 의 안내대로 설치한 뒤 다시 실행하세요."
command -v swiftc >/dev/null && xcode-select -p >/dev/null 2>&1 ||
  die "Xcode 명령줄 도구가 필요합니다. 'xcode-select --install' 을 실행해 설치한 뒤 다시 실행하세요."
command -v jq >/dev/null || brew install jq

[ -d /Applications/SwiftBar.app ] || brew install --cask swiftbar

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
elif [ -e "$DEST" ]; then
  die "$DEST 가 이미 있는데 이 프로젝트의 저장소가 아닙니다. AI_USAGE_BAR_DIR 로 다른 위치를 지정하세요."
else
  git clone --depth 1 "$REPO" "$DEST"
fi

swiftc -O "$DEST/plugins/.baticon.swift" -o "$DEST/plugins/.baticon"
chmod +x "$DEST/plugins/$PLUGIN"

# 이미 SwiftBar를 쓰는 사람은 자기 플러그인 폴더가 있다. 그 설정은 건드리지 않고 바로가기만 넣는다.
CUR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
if [ -z "$CUR" ] || [ ! -d "$CUR" ]; then
  defaults write com.ameba.SwiftBar PluginDirectory "$DEST/plugins"
  echo "SwiftBar 플러그인 폴더를 $DEST/plugins 로 지정했습니다."
elif [ "$CUR" != "$DEST/plugins" ]; then
  LINK="$CUR/$PLUGIN"
  if [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
    echo "주의: $LINK 파일이 이미 있어 바로가기를 만들지 않았습니다. 직접 정리한 뒤 다시 실행하세요." >&2
  else
    ln -sfn "$DEST/plugins/$PLUGIN" "$LINK"
    echo "기존 SwiftBar 플러그인 폴더($CUR)에 바로가기를 넣었습니다."
  fi
fi

if pgrep -xq SwiftBar; then
  open -g "swiftbar://refreshallplugins"
else
  open /Applications/SwiftBar.app
fi

cat <<EOF

설치 완료. 상단 바에 AI 서비스 아이콘과 배터리가 나타납니다.
- 키체인 접근을 물으면 "항상 허용"을 누르세요.
- 재부팅 후에도 보이게 하려면 SwiftBar 설정에서 "Launch at Login"을 켜세요.
- 표시할 서비스는 상단 바 항목을 클릭해 체크박스로 고릅니다.
EOF
