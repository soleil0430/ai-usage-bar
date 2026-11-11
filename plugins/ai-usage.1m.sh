#!/bin/bash
# AI 서비스(Claude·Codex·Cursor) 구독 한도 잔여량을 메뉴바에 배터리 아이콘으로 표시
# SwiftBar 플러그인. 파일명의 1m = 1분마다 다시 그림(대기 시간 카운트다운용). 실제 조회는 서비스당 5분에 한 번.
# shortcut: 셋 다 비공식 조회 주소이고 토큰 갱신은 안 함. 배터리에 "?"가 뜨면 해당 도구를 한 번 실행(토큰 갱신)하거나, 응답 형식이 바뀐 것이니 그 서비스의 jq 식을 고칠 것.
#
# 드롭다운에서 SwiftBar 기본 항목을 숨긴다
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
PATH=/usr/bin:/bin
DIR=$(cd "$(dirname "$0")" && pwd)
SELF="$DIR/$(basename "$0")"
CONF="$DIR/../enabled"   # 켜진 서비스 이름을 공백으로 나열한 한 줄. 없으면 전부 켜짐
CACHE="$DIR/../.cache"   # 서비스별: <이름> = 마지막 조회 값, <이름>.hdr = 마지막 응답 헤더, <이름>.wait = 다시 조회해도 되는 시각
ALL="claude codex cursor"
mkdir -p "$CACHE"
ENABLED=$(cat "$CONF" 2>/dev/null || echo "$ALL")
on() { case " $ENABLED " in *" $1 "*) return 0 ;; esac; return 1; }

# 드롭다운 항목이 부르는 경로
case "$1" in
toggle) # toggle <서비스>: 체크박스
  case " $ALL " in *" $2 "*) ;; *) echo "unknown service: $2" >&2; exit 1 ;; esac
  NEW=""
  for s in $ALL; do
    if [ "$s" = "$2" ]; then on "$s" || NEW="$NEW $s"; else on "$s" && NEW="$NEW $s"; fi
  done
  echo $NEW > "$CONF"
  exit ;;
force) # 새로고침: 5분 캐시를 지워 다음 실행에서 바로 조회하게 한다 (.wait는 서버가 정한 대기라 남긴다)
  for s in $ALL; do rm -f "$CACHE/$s"; done
  exit ;;
esac

# 공통 조회: 인증 헤더 한 줄을 stdin으로 받는다(토큰이 프로세스 목록에 안 보이게). 응답 헤더는 429 판별용으로 남긴다
req() { local s=$1; shift; "${AI_USAGE_CURL:-curl}" -sf -m 10 -D "$CACHE/$s.hdr" "$@" -H @-; }   # AI_USAGE_CURL: 시험용 가짜 curl

# fetch_* 출력: 남은 % 한 줄 (한도가 둘이면 "짧은한도 긴한도"). 실패하면 0이 아닌 종료값
# 토큰이 비면 요청하지 않는다: 빈 토큰 요청에 Claude 서버가 429와 50분짜리 대기를 돌려주기 때문
fetch_claude() {
  local t
  t=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
  [ -n "$t" ] || return 1
  printf 'Authorization: Bearer %s' "$t" |
    req claude https://api.anthropic.com/api/oauth/usage -H "anthropic-beta: oauth-2025-04-20" |
    jq -er '"\(100 - .five_hour.utilization | floor) \(100 - .seven_day.utilization | floor)"'
}

fetch_codex() {
  local t a
  t=$(jq -r '.tokens.access_token // empty' ~/.codex/auth.json 2>/dev/null)
  a=$(jq -r '.tokens.account_id // empty' ~/.codex/auth.json 2>/dev/null)
  [ -n "$t" ] || return 1
  printf 'Authorization: Bearer %s' "$t" |
    req codex https://chatgpt.com/backend-api/wham/usage -H "ChatGPT-Account-Id: $a" -H "User-Agent: codex-cli" |
    jq -er '.rate_limit | "\(100 - .primary_window.used_percent | floor) \(100 - .secondary_window.used_percent | floor)"'
}

fetch_cursor() {
  local db t sub
  db="$HOME/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
  t=$(sqlite3 "file:$db?mode=ro" "select value from ItemTable where key='cursorAuth/accessToken'" 2>/dev/null)
  # 세션 쿠키에 필요한 사용자 id는 토큰(JWT) 가운데 토막의 sub 값에 들어 있다
  sub=$(printf '%s' "$t" | cut -d. -f2 | tr '_-' '/+' |
    awk '{n=length($0)%4; if(n==2)$0=$0"=="; if(n==3)$0=$0"="; print}' | base64 -d 2>/dev/null | jq -r '.sub // empty' | sed 's/.*|//')
  [ -n "$t" ] && [ -n "$sub" ] || return 1
  printf 'Cookie: WorkosCursorSessionToken=%s%%3A%%3A%s' "$sub" "$t" |
    req cursor https://cursor.com/api/usage-summary |
    jq -er '"\(100 - .individualUsage.plan.totalPercentUsed | floor)"'
}

title() { case $1 in claude) echo Claude ;; codex) echo Codex ;; cursor) echo Cursor ;; esac; }
icon() { case $1 in claude) echo /Applications/Claude.app ;; codex) echo /Applications/ChatGPT.app ;; cursor) echo /Applications/Cursor.app ;; esac; }

COUNT=0
for s in $ALL; do on "$s" && COUNT=$((COUNT + 1)); done
NOW=$(date +%s)

ARGS=()
for s in $ALL; do
  on "$s" || continue
  UNTIL=$(cat "$CACHE/$s.wait" 2>/dev/null)
  case "$UNTIL" in '' | *[!0-9]*) UNTIL=0 ;; esac
  if [ "$NOW" -ge "$UNTIL" ]; then
    if [ -n "$(find "$CACHE/$s" -mmin -5 2>/dev/null)" ]; then
      OUT=$(cat "$CACHE/$s")   # 5분 안에 조회한 값이 있으면 다시 묻지 않는다
    elif : > "$CACHE/$s.hdr"; OUT=$("fetch_$s"); then
      echo "$OUT" > "$CACHE/$s"
    elif grep -q '^HTTP/[0-9.]* 429' "$CACHE/$s.hdr" 2>/dev/null; then
      # 서버가 "요청 과다, N초 뒤 다시"라고 한 경우: 그때까지 조회를 멈추고 남은 시간을 보인다
      RA=$(tr -d '\r' < "$CACHE/$s.hdr" | awk 'tolower($1)=="retry-after:"{print int($2)}')
      [ "${RA:-0}" -ge 60 ] || RA=60
      UNTIL=$((NOW + RA))
      echo "$UNTIL" > "$CACHE/$s.wait"
    else
      OUT="?"
    fi
  fi
  if [ "$NOW" -lt "$UNTIL" ]; then
    ARGS+=("$(icon "$s")" - clock "$(((UNTIL - NOW + 59) / 60))분")
    continue
  fi
  read -r P1 P2 <<<"$OUT"
  if [ "$COUNT" = 1 ] && [ -n "$P2" ]; then
    # 서비스가 하나뿐이면 자리가 남으니 짧은 한도(시계)와 주간 한도(달력)를 모두 보인다
    ARGS+=("$(icon "$s")" - clock "$P1" calendar "$P2")
  else
    ARGS+=("$(icon "$s")" "$P1")
  fi
done

if [ -n "$AI_USAGE_DEBUG" ]; then   # 시험용: 그림 대신 도우미에 넘길 인자를 보인다
  echo "${ARGS[*]}"
elif [ "$COUNT" = 0 ]; then
  echo "AI"
else
  # 컬러 앱 아이콘 때문에 템플릿 이미지(자동 색 전환)를 못 쓴다. 대신 검정판,흰색판 두 장을 주면
  # SwiftBar가 상단 바의 실제 밝기에 맞는 쪽을 고른다 (맥 다크 모드여도 배경화면이 밝으면 상단 바는 밝다)
  IMG=$("$DIR/.baticon" "${ARGS[@]}"),$("$DIR/.baticon" --white "${ARGS[@]}") && echo "| image=$IMG" || echo "AI ?"
fi
echo "---"
echo "표시할 서비스"
for s in $ALL; do
  on "$s" && C=true || C=false
  echo "$(title "$s") | checked=$C bash=\"$SELF\" param1=toggle param2=$s terminal=false refresh=true"
done
echo "---"
echo "새로고침 | bash=\"$SELF\" param1=force terminal=false refresh=true"
