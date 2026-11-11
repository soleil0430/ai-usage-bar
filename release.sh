#!/bin/bash
# 배포용. dist/ 에 배포 파일 세 개(VERSION, ai-usage-bar.tar.gz, ai-usage-bar.pkg)를 만든다.
#   ./release.sh           만들기만 한다
#   ./release.sh publish   만든 뒤 GitHub 릴리스 v<VERSION> 으로 올린다 (사용자들에게 자동 업데이트로 퍼진다)
# 새 버전을 낼 때: VERSION 숫자를 올리고 커밋·푸시한 뒤 ./release.sh publish
set -euo pipefail
cd "$(dirname "$0")"
export COPYFILE_DISABLE=1   # tar 에 맥 전용 ._ 파일이 섞이지 않게

V=$(cat VERSION)
case "$V" in '' | *[!0-9.]*) echo "VERSION 형식이 잘못됐습니다: $V" >&2; exit 1 ;; esac
if [ "${1:-}" = publish ]; then
  [ -z "$(git status --porcelain)" ] || { echo "커밋하지 않은 변경이 있습니다. 커밋·푸시한 뒤 다시 실행하세요." >&2; exit 1; }
  [ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ] || { echo "푸시하지 않은 커밋이 있습니다." >&2; exit 1; }
fi

B=$(mktemp -d)
trap 'rm -rf -- "$B"' EXIT
mkdir -p "$B/root/plugins" "$B/scripts" dist

# 도우미를 인텔·애플 실리콘 겸용으로 컴파일 (받는 사람은 컴파일 도구가 필요 없다)
for arch in arm64 x86_64; do
  swiftc -O -target "$arch-apple-macos12" plugins/.baticon.swift -o "$B/baticon-$arch"
done
lipo -create "$B/baticon-arm64" "$B/baticon-x86_64" -output "$B/root/plugins/.baticon"

cp plugins/ai-usage.1m.sh "$B/root/plugins/"
chmod +x "$B/root/plugins/ai-usage.1m.sh" "$B/root/plugins/.baticon"
cp VERSION "$B/root/"
cp VERSION dist/VERSION
tar -czf dist/ai-usage-bar.tar.gz -C "$B/root" VERSION plugins

# 설치 파일: 내용물 없이 install.sh 만 담고, 설치가 끝날 때 로그인한 사용자 권한으로 실행한다
cp install.sh "$B/scripts/install.sh"
cat > "$B/scripts/postinstall" <<'EOF'
#!/bin/bash
U=$(stat -f %Su /dev/console)
[ -n "$U" ] && [ "$U" != root ] || { echo "로그인한 사용자를 찾지 못했습니다." >&2; exit 1; }
launchctl asuser "$(id -u "$U")" sudo -u "$U" -H bash "$(dirname "$0")/install.sh"
EOF
chmod +x "$B/scripts/postinstall" "$B/scripts/install.sh"
pkgbuild --nopayload --scripts "$B/scripts" --identifier io.github.soleil0430.ai-usage-bar --version "$V" dist/ai-usage-bar.pkg >/dev/null

echo "dist/ 에 v$V 배포 파일을 만들었습니다:"
ls -l dist | awk 'NR>1 {print "  " $NF, $5 " bytes"}'

if [ "${1:-}" = publish ]; then
  gh release create "v$V" dist/VERSION dist/ai-usage-bar.tar.gz dist/ai-usage-bar.pkg --title "v$V" --generate-notes
fi
