# Agentforce Employee Chat Package

Salesforce Agentforce Employee Agent 기반의 Chat UI 컴포넌트 패키지입니다.

---

## 포함 컴포넌트

### Apex Classes
| 클래스 | 용도 |
|--------|------|
| `AgentforceEmployeeAgentService` | Agentforce Agent 호출 서비스 (sendMessage, sendMessageWithContext) |
| `AgentforceChatInjectRest` | 외부 시스템 → Chat 메시지 주입 REST API |
| `ClosingTaskProgressController` | 결산 진행 현황 조회 컨트롤러 |

### Lightning Web Components
| 컴포넌트 | 용도 |
|----------|------|
| `employeeAgentChatCard` | 레코드/앱 페이지 임베디드 채팅 카드 |
| `employeeAgentChatModal` | Quick Action 모달 채팅 |
| `employeeAgentChatFlowScreen` | Flow Screen 임베디드 채팅 |
| `launchEmployeeAgent` | Headless Quick Action (모달 런처) |
| `employeeAgentChatInjector` | 외부 메시지 주입 버튼 팔레트 (LMS publish) |
| `agentforceTestConsole` | 관리자/QA 테스트 콘솔 |
| `closingProgressDashboard` | 결산 마감 진행 현황 대시보드 |
| `closingTaskProgress` | 결산 태스크 진행률 표시 컴포넌트 |

### Platform Event
| 오브젝트 | 용도 |
|----------|------|
| `AgentforceChatInject__e` | 외부 시스템 → 브라우저 LWC 실시간 메시지 전달 |

### 기타
- **Lightning Message Channel**: `AgentforceChatInject` (동일 페이지 LWC 간 통신)
- **Flows**: `Ask_Employee_Agent_A`, `Ask_Employee_Agent_C`
- **Quick Actions**: Account.Ask_Employee_Agent_A/B/C
- **Custom Label**: `Agentforce_Employee_Agent_ApiName`

---

## 사전 요구사항

- Salesforce CLI (`sf`) v2 이상
- Agentforce Employee Agent 활성화된 org
- API version 66.0 이상

---

## 설치 방법

### 방법 1 — 설치 스크립트 (권장)

```bash
# macOS / Linux
chmod +x install.sh
./install.sh --target-org YOUR_ORG_ALIAS

# Windows PowerShell
.\install.ps1 -TargetOrg YOUR_ORG_ALIAS
```

### 방법 2 — CLI 직접 배포

```bash
sf project deploy start \
  --manifest package.xml \
  --source-dir main \
  --target-org YOUR_ORG_ALIAS \
  --ignore-conflicts
```

### 방법 3 — 검증 후 배포 (권장)

```bash
# 1) 검증만 (실제 배포 없음)
./install.sh --target-org YOUR_ORG_ALIAS --dry-run

# 2) 문제 없으면 실제 배포
./install.sh --target-org YOUR_ORG_ALIAS
```

---

## 설치 후 설정

### 1. Agent API 이름 설정 (필수)
```
Setup → Custom Labels → Agentforce_Employee_Agent_ApiName
→ 값을 실제 활성화된 Agent API Name으로 변경
```

### 2. LWC 컴포넌트 페이지 배치
Lightning App Builder에서 원하는 페이지에 드래그:
- **Employee Agent Chat Card** — 레코드 페이지 임베디드 채팅
- **Employee Agent Chat Injector** — 같은 페이지에 배치하면 버튼으로 메시지 주입
- **Agentforce Test Console** — QA/데모용 프롬프트 팔레트 + 채팅
- **Closing Progress Dashboard** — 결산 마감 태스크 대시보드

### 3. Account Quick Action 등록
```
Setup → Object Manager → Account → Buttons, Links, and Actions
→ Page Layouts에 다음 Quick Action 추가:
  • Ask Employee Agent (Flow)
  • Launch Employee Agent (Headless LWC Modal)
```

---

## 외부 시스템 연동 (REST API)

외부 레거시 시스템에서 현재 열려있는 Chat Card에 메시지를 주입:

### 1. OAuth 인증
```bash
curl -X POST "https://YOUR_DOMAIN.my.salesforce.com/services/oauth2/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=CONSUMER_KEY" \
  -d "client_secret=CONSUMER_SECRET"
```

### 2. 메시지 주입 (Agent 버블 — API 호출 없음)
```bash
curl -X POST "https://YOUR_DOMAIN.my.salesforce.com/services/apexrest/agentforce/inject" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "요청하신 결산마감 수행이 완료되었습니다.",
    "role": "agent",
    "targetCardTitle": "Agentforce Employee Agent",
    "sourceSystem": "LegacyCRM"
  }'
```

### 3. 에러 메시지 주입 (빨간 버블)
```bash
curl -X POST "https://YOUR_DOMAIN.my.salesforce.com/services/apexrest/agentforce/inject" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "마감 수행중 에러가 발생하였습니다. 에러 코드는 ERR-1234 입니다.",
    "role": "error",
    "targetCardTitle": "Agentforce Employee Agent",
    "sourceSystem": "LegacyCRM"
  }'
```

### 4. 사용자 메시지 주입 (Agent 응답 트리거)
```bash
curl -X POST "https://YOUR_DOMAIN.my.salesforce.com/services/apexrest/agentforce/inject" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "이번 달 영업 실적을 요약해줘",
    "role": "user",
    "sourceSystem": "LegacyCRM"
  }'
```

### Request Body 파라미터
| 필드 | 필수 | 기본값 | 설명 |
|------|------|--------|------|
| `message` | ✅ | — | 주입할 메시지 텍스트 |
| `role` | ❌ | `agent` | `agent` / `user` / `error` |
| `targetCardTitle` | ❌ | (broadcast) | 특정 Chat Card만 타겟팅 |
| `sessionId` | ❌ | (any) | 특정 Agentforce 세션만 타겟팅 |
| `sourceSystem` | ❌ | `unknown` | 발신 시스템 식별자 (감사용) |

---

## Quick Prompts 커스터마이징

`employeeAgentChatInjector` 의 App Builder 속성 `Quick Prompts` 에서 편집:

```
라벨 | 메시지 | role(optional)
✅ 결산 마감 수행완료 | 요청하신 결산마감 수행이 완료되었습니다. | agent
🚨 마감 수행중 에러 발생 | 마감 수행중 에러가 발생하였습니다. 에러 코드는 OOOOO 입니다. | error
📊 실적 요약 요청 | 이번 달 영업 실적을 요약해줘 | user
```

---

## 아키텍처

```
┌────────────────┐   REST POST    ┌──────────────────────┐  EventBus  ┌──────────────────┐
│  External CRM  │──────────────▶│ AgentforceChatInject  │───────────▶│ Platform Event   │
│  (Legacy)      │               │ Rest (Apex)           │            │ __e              │
└────────────────┘               └──────────────────────┘            └────────┬─────────┘
                                                                               │ CometD/empApi
                                          LMS (같은 페이지)                    │
┌──────────────────────┐  publish  ┌──────────────────────┐             ┌─────▼──────────┐
│ employeeAgentChat    │──────────▶│ AgentforceChatInject │             │ employeeAgent  │
│ Injector (LWC)       │           │ (MessageChannel)     │────────────▶│ ChatCard (LWC) │
└──────────────────────┘           └──────────────────────┘  subscribe  └────────────────┘
```

---

## 버전 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|-----------|
| 1.0.0 | 2026-04-17 | 최초 릴리즈 |
