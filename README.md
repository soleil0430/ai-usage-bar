# ai-usage-bar

맥 상단 바에 AI 서비스 구독 한도의 남은 양을 배터리 아이콘으로 보여 주는 [SwiftBar](https://github.com/swiftbar/SwiftBar) 플러그인입니다.

```
[Claude 아이콘][97]  [ChatGPT 아이콘][100]  [Cursor 아이콘][100]
```

- **지원 서비스**: Claude(Claude Code 구독 한도), Codex(ChatGPT 구독의 Codex 한도), Cursor(월 한도)
- 서비스별 표시 여부를 드롭다운의 체크박스로 고릅니다.
- 서비스를 하나만 켜면 5시간 한도(시계)와 주간 한도(달력)를 둘 다 보여 줍니다. 둘 이상 켜면 서비스마다 배터리 하나(5시간 한도, Cursor는 월 한도)입니다.
- 상단 바 항목을 클릭하면 드롭다운 맨 위에 서비스별로 한도가 다시 차는 시각이 나옵니다(예: `Claude 리셋  5시간 20:10 (2시간 42분 후) · 주간 11/12 18:00 (1일 후)`).
- 서버가 요청 과다로 조회를 잠시 거절하면 배터리 대신 시계 아이콘과 남은 대기 시간이 나옵니다.
- 조회에 실패하면 배터리 대신 회전 화살표(⟳)가 나오고, 드롭다운 맨 위에 이유가 나옵니다. 1분마다 다시 시도합니다.

## 주의 사항

- **비공식 조회 주소를 씁니다.** 세 서비스 모두 공개 문서에 없는 주소라서, 서비스 쪽 변경으로 언제든 동작하지 않을 수 있습니다. 각 서비스의 이용 약관에 맞는지는 직접 판단하세요.
- **이 맥에 저장된 로그인 토큰을 읽습니다.** Claude Code는 키체인, Codex는 `~/.codex/auth.json`, Cursor는 앱 내부 저장소에서 읽습니다. 토큰은 해당 서비스의 조회 주소로만 보내고 파일에 남기지 않습니다. 코드는 [plugins/ai-usage.1m.sh](plugins/ai-usage.1m.sh) 한 파일이니 쓰기 전에 읽어 보세요.
- Claude 토큰이 곧 만료되면 Claude Code에 짧은 질문(haiku 모델, 'ok')을 한 번 보내 토큰을 갱신시킵니다(약 8시간마다, 한도를 아주 조금 씁니다). Codex·Cursor 토큰은 갱신하지 않으니, ⟳가 계속 뜨면 해당 도구를 한 번 실행해 로그인 상태를 갱신하세요.
- 서비스 아이콘은 이 저장소에 들어 있지 않습니다. 맥에 설치된 앱(`/Applications/Claude.app`, `ChatGPT.app`, `Cursor.app`)의 아이콘을 실행 때 읽어 씁니다. 앱이 없으면 기본 아이콘이 나옵니다.

## 설치

두 방법 중 하나를 고르면 됩니다. 결과는 같습니다.

### 방법 1: 터미널 한 줄 (권장)

```bash
curl -fsSL https://raw.githubusercontent.com/soleil0430/ai-usage-bar/main/install.sh | bash
```

### 방법 2: 설치 파일

1. [최신 릴리스](https://github.com/soleil0430/ai-usage-bar/releases/latest)에서 `ai-usage-bar.pkg`를 받아 더블클릭합니다.
2. 이 설치 파일은 Apple 개발자 서명이 없어서, 맥이 "확인되지 않은 개발자"라며 막습니다. **시스템 설정 → 개인정보 보호 및 보안**으로 가서 아래쪽의 **"그래도 열기"**를 누르세요. 처음 한 번만 하면 됩니다.
3. 설치 화면에서 "계속"을 누르면 끝납니다.

### 설치가 하는 일

1. 미리 컴파일된 플러그인을 `~/Library/Application Support/ai-usage-bar`에 내려받습니다.
2. SwiftBar가 없으면 SwiftBar 공식 릴리스에서 받아 `/Applications`에 넣습니다.
3. SwiftBar에 연결합니다. SwiftBar를 처음 쓰면 플러그인 폴더를 지정하고, 이미 쓰는 플러그인 폴더가 있으면 설정은 그대로 두고 그 폴더에 바로가기만 넣습니다.
4. SwiftBar를 실행합니다.

Homebrew, git, Xcode 도구는 필요 없습니다. 내용은 [install.sh](install.sh) 한 파일입니다.

### 설치 뒤에 할 일

- macOS가 키체인 접근을 물으면 "항상 허용"을 누릅니다.
- 재부팅 후에도 보이게 하려면 SwiftBar 설정에서 "Launch at Login"을 켭니다.

### 자동 업데이트

설치된 플러그인은 하루에 한 번 이 저장소의 최신 릴리스를 확인하고, 새 버전이 있으면 **묻지 않고 스스로 갱신**합니다. 켜고 끈 서비스 설정은 유지됩니다. 지금 바로 맞추려면 설치 명령을 다시 실행하면 됩니다.

자동 업데이트를 원하지 않으면 저장소를 `git clone`으로 직접 받아 쓰세요. `.git` 폴더가 있는 사본은 자동 업데이트하지 않습니다(이 경우 `swiftc -O plugins/.baticon.swift -o plugins/.baticon`으로 도우미를 직접 컴파일해야 합니다).

### 삭제

`~/Library/Application Support/ai-usage-bar` 폴더를 지우면 됩니다. 기존 SwiftBar 폴더에 바로가기가 들어간 경우 그 바로가기(`ai-usage.1m.sh`)도 지웁니다.

### 필요한 것

- macOS 15 이상
- Claude Code, Codex, Cursor 중 쓰는 도구에 로그인돼 있어야 그 서비스의 한도가 나옵니다.

## 설정

- **표시할 서비스**: 상단 바 항목을 클릭해 체크박스로 켜고 끕니다. 상태는 `enabled` 파일에 저장됩니다.
- **갱신 주기**: 1분마다 다시 그리고, 실제 조회는 서비스당 5분에 한 번 합니다.
- **SwiftBar 기본 메뉴**: 숨겨 두었습니다. Option 키를 누른 채 클릭하면 다시 보입니다.

## 구조

| 파일 | 역할 |
|---|---|
| `plugins/ai-usage.1m.sh` | 서비스 조회, 설정 읽기, 메뉴 출력, 체크박스 처리 |
| `plugins/.baticon.swift` | 아이콘과 배터리를 그림 한 장으로 그리는 도우미 |
| `install.sh` | 설치. 설치 파일(`.pkg`)도 이 스크립트를 실행합니다 |
| `release.sh` | 배포. 도우미 컴파일, 배포 묶음과 설치 파일 제작, GitHub 릴리스 등록 |
| `VERSION` | 현재 버전 |

시험할 때는 `AI_USAGE_DEBUG=1 plugins/ai-usage.1m.sh`로 그림 대신 도우미에 넘길 인자를 볼 수 있습니다.

새 버전을 낼 때는 `VERSION`의 숫자를 올려 커밋·푸시한 뒤 `./release.sh publish`를 실행합니다.

## 라이선스

[MIT](LICENSE)

Claude, ChatGPT, Codex, Cursor는 각 회사의 상표입니다. 이 프로젝트는 해당 회사들과 관련이 없습니다.
