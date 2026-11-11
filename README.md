# ai-usage-bar

맥 상단 바에 AI 서비스 구독 한도의 남은 양을 배터리 아이콘으로 보여 주는 [SwiftBar](https://github.com/swiftbar/SwiftBar) 플러그인입니다.

```
[Claude 아이콘][97]  [ChatGPT 아이콘][100]  [Cursor 아이콘][100]
```

- **지원 서비스**: Claude(Claude Code 구독 한도), Codex(ChatGPT 구독의 Codex 한도), Cursor(월 한도)
- 서비스별 표시 여부를 드롭다운의 체크박스로 고릅니다.
- 서비스를 하나만 켜면 5시간 한도(시계)와 주간 한도(달력)를 둘 다 보여 줍니다. 둘 이상 켜면 서비스마다 배터리 하나(5시간 한도, Cursor는 월 한도)입니다.
- 서버가 요청 과다로 조회를 잠시 거절하면 배터리 대신 시계 아이콘과 남은 대기 시간이 나옵니다.
- 조회에 실패하면 배터리 안에 `?`가 나옵니다.

## 주의 사항

- **비공식 조회 주소를 씁니다.** 세 서비스 모두 공개 문서에 없는 주소라서, 서비스 쪽 변경으로 언제든 동작하지 않을 수 있습니다. 각 서비스의 이용 약관에 맞는지는 직접 판단하세요.
- **이 맥에 저장된 로그인 토큰을 읽습니다.** Claude Code는 키체인, Codex는 `~/.codex/auth.json`, Cursor는 앱 내부 저장소에서 읽습니다. 토큰은 해당 서비스의 조회 주소로만 보내고 파일에 남기지 않습니다. 코드는 [plugins/ai-usage.1m.sh](plugins/ai-usage.1m.sh) 한 파일이니 쓰기 전에 읽어 보세요.
- 토큰을 갱신하지 않습니다. `?`가 계속 뜨면 해당 도구(Claude Code, Codex, Cursor)를 한 번 실행해 로그인 상태를 갱신하세요.
- 서비스 아이콘은 이 저장소에 들어 있지 않습니다. 맥에 설치된 앱(`/Applications/Claude.app`, `ChatGPT.app`, `Cursor.app`)의 아이콘을 실행 때 읽어 씁니다. 앱이 없으면 기본 아이콘이 나옵니다.

## 필요한 것

- macOS (macOS 15에서 확인)
- [SwiftBar](https://github.com/swiftbar/SwiftBar)
- Xcode 명령줄 도구 (`swiftc`. 아이콘 도우미를 한 번 컴파일할 때만 필요)
- `jq`, `sqlite3`, `curl` (macOS 15에는 기본으로 들어 있습니다)

## 설치

```bash
brew install --cask swiftbar
```

```bash
git clone https://github.com/soleil0430/ai-usage-bar.git ~/ai-usage-bar
```

```bash
swiftc -O ~/ai-usage-bar/plugins/.baticon.swift -o ~/ai-usage-bar/plugins/.baticon
```

SwiftBar를 실행하고 플러그인 폴더로 `~/ai-usage-bar/plugins`를 고릅니다. 이미 다른 폴더를 쓰고 있다면 SwiftBar 설정에서 바꾸면 됩니다.

macOS가 키체인 접근을 물으면 "항상 허용"을 눌러야 매번 다시 묻지 않습니다.

## 설정

- **표시할 서비스**: 상단 바 항목을 클릭해 체크박스로 켜고 끕니다. 상태는 `enabled` 파일에 저장됩니다.
- **갱신 주기**: 1분마다 다시 그리고, 실제 조회는 서비스당 5분에 한 번 합니다.
- **SwiftBar 기본 메뉴**: 숨겨 두었습니다. Option 키를 누른 채 클릭하면 다시 보입니다.

## 구조

| 파일 | 역할 |
|---|---|
| `plugins/ai-usage.1m.sh` | 서비스 조회, 설정 읽기, 메뉴 출력, 체크박스 처리 |
| `plugins/.baticon.swift` | 아이콘과 배터리를 그림 한 장으로 그리는 도우미 |

시험할 때는 `AI_USAGE_DEBUG=1 plugins/ai-usage.1m.sh`로 그림 대신 도우미에 넘길 인자를 볼 수 있습니다.

## 라이선스

[MIT](LICENSE)

Claude, ChatGPT, Codex, Cursor는 각 회사의 상표입니다. 이 프로젝트는 해당 회사들과 관련이 없습니다.
