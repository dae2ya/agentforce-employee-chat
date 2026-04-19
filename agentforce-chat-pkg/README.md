# Agentforce Employee Chat — 패키지 상세 가이드

> 이 문서는 각 컴포넌트의 내부 동작, 설정 방법, 외부 시스템 연동 방법을 상세히 설명합니다.  
> 빠른 설치는 [루트 README](../README.md)를 참고하세요.

---

## 목차

1. [컴포넌트 상세](#컴포넌트-상세)
   - [employeeAgentChatCard](#1-employeeagentchatcard)
   - [employeeAgentChatInjector](#2-employeeagentchatinjector)
   - [agentforceTestConsole](#3-agentforcetestconsole)
   - [closingProgressDashboard](#4-closingprogressdashboard)
   - [Quick Action 컴포넌트들](#5-quick-action-컴포넌트들)
2. [Chat Injector 동작 원리](#chat-injector-동작-원리)
3. [외부 시스템 REST API](#외부-시스템-rest-api)
4. [Apex 서비스 레이어](#apex-서비스-레이어)
5. [설치 및 설정](#설치-및-설정)
6. [버전 이력](#버전-이력)

---

## 컴포넌트 상세

### 1. `employeeAgentChatCard`

레코드 페이지 또는 앱 페이지에 임베디드하는 **핵심 채팅 UI 컴포넌트**입니다.

#### 주요 기능

| 기능 | 설명 |
|------|------|
| 멀티턴 대화 | Agentforce Agent와 세션 기반 대화 유지 |
| 레코드 컨텍스트 | 레코드 페이지에 배치 시 해당 레코드의 필드값을 자동으로 메시지에 포함 |
| 사용자 프로필 아바타 | 로그인 사용자의 `SmallPhotoUrl`을 아바타로 표시 (미설정 시 기본 아이콘 폴백) |
| 역할별 버블 | `agent`(흰색) / `user`(파란색) / `error`(빨간색) / `success`(초록색) |
| 메시지 주입 수신 | LMS(동일 페이지) 및 Platform Event(외부 시스템) 양쪽에서 수신 |
| 타이핑 인디케이터 | Agent 응답 대기 중 3-dot 애니메이션 표시 |
| Enter 키 전송 | `Enter` 키로 전송, `Shift+Enter`로 줄바꿈 |

#### App Builder 속성

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `cardTitle` | String | `DS Agentic Office Agent` | 카드 헤더 제목 |
| `recordId` | String | (자동) | 레코드 페이지 배치 시 자동 바인딩 |

#### 레코드 컨텍스트 자동 주입

레코드 페이지에 배치되면 `AgentforceEmployeeAgentService.sendMessageWithContext()`를 호출합니다.  
Apex에서 해당 레코드의 접근 가능한 필드를 동적으로 조회하여 메시지 앞에 컨텍스트를 자동 추가합니다.

```
[레코드 컨텍스트]
Account Name: Acme Corp
Industry: Technology
AnnualRevenue: 5,000,000
...

[사용자 메시지]
이 고객의 갱신 가능성은?
```

#### 메시지 주입 수신 흐름

```
┌──────────────────────────────────────────────┐
│  connectedCallback()                         │
│    ├─ subscribeToInjectChannel()  ← LMS      │
│    └─ subscribeToPlatformEvent()  ← empApi   │
└──────────────────────┬───────────────────────┘
                       │
          ┌────────────┴────────────┐
          │ handleInject(event)     │  ← LMS 수신
          │ handlePlatformEvent(e)  │  ← PE 수신
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │ enqueueOrRun(payload)   │  ← 로딩 중이면 큐에 적재
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │ dispatchInjected()      │
          │  role=user  → send()    │  Agentforce API 호출
          │  role=agent → appendMessage()  │  API 없이 버블만 표시
          │  role=error → appendMessage()  │
          │  role=success→ appendMessage() │
          └─────────────────────────┘
```

---

### 2. `employeeAgentChatInjector`

같은 Lightning Page에 `employeeAgentChatCard`와 함께 배치하여 **버튼 한 번으로 메시지를 주입**하는 팔레트 컴포넌트입니다.

#### 동작 방식

1. 버튼 클릭 → `lightning/messageService`로 `AgentforceChatInject` 채널에 publish
2. `employeeAgentChatCard`가 동일 채널을 subscribe하여 수신
3. `role`에 따라 버블 색상 및 Agentforce API 호출 여부 결정

#### App Builder 속성

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `prompts` | String | (기본 2개) | 퀵 프롬프트 정의. `라벨\|메시지\|role` 형식으로 줄바꿈 구분 |
| `targetCardTitle` | String | (전체) | 특정 Chat Card 타겟팅 |

#### Quick Prompts 형식

```
라벨 | 메시지 | role(optional)
```

예시 (App Builder 속성값):
```
✅ 결산 마감 수행완료 | 요청하신 결산마감 수행이 완료되었습니다. | success
🚨 마감 수행중 에러 발생 | 마감 수행중 에러가 발생하였습니다. 에러 코드는 OOOOO 입니다. | error
📋 실적 요약 | 이번 달 영업 실적을 요약해줘 | user
```

#### 버튼 색상 규칙

| role | 버튼 스타일 |
|------|------------|
| `success` | 초록색 테두리 |
| `error` | 빨간색 테두리 |
| `user` | 파란색 (브랜드 컬러) |
| `agent` (기본) | 기본 neutral |

---

### 3. `agentforceTestConsole`

관리자/QA 담당자가 Agent 동작을 테스트하기 위한 **통합 테스트 콘솔**입니다.

- 직접 Agent에 메시지 전송 및 응답 확인
- LMS를 통해 같은 페이지의 Chat Card로 메시지 주입 테스트
- 앱 페이지, Record 페이지, Tab 모두 배치 가능

---

### 4. `closingProgressDashboard`

결산 마감 업무 진행 현황을 보여주는 **태스크 대시보드** 컴포넌트입니다.

- KPI 카드 (전체/완료/진행중/오류 건수)
- 메인/서브 카테고리 메뉴 (좌측 사이드바)
- 태스크 그리드 (상태별 아이콘, 담당자, 진행률)
- `ClosingTaskProgressController` Apex로 실제 데이터 연결 가능

---

### 5. Quick Action 컴포넌트들

| 컴포넌트 | Quick Action 타입 | 설명 |
|----------|------------------|------|
| `employeeAgentChatModal` | LWC Quick Action | Account 레코드에서 모달 팝업 채팅 오픈 |
| `launchEmployeeAgent` | Headless LWC | Agent 세션 초기화 후 Flow/Modal 런치 |
| `employeeAgentChatFlowScreen` | Flow Screen | Flow 내 임베디드 채팅 (Flow Action과 연동) |

---

## Chat Injector 동작 원리

### 전체 흐름도

```
[방법 A — 같은 페이지 LWC]              [방법 B — 외부 시스템]

employeeAgentChatInjector               외부 서버 (ERP/CRM/배치)
       │                                        │
       │ publish(LMS)                           │ HTTP POST /apexrest/agentforce/inject
       ▼                                        ▼
AgentforceChatInject              AgentforceChatInjectRest.cls
(MessageChannel)                         │
       │                                 │ EventBus.publish()
       │                                 ▼
       │                      AgentforceChatInject__e
       │                         (Platform Event)
       │                                 │
       │                                 │ CometD (empApi)
       └──────────────┬──────────────────┘
                      ▼
          employeeAgentChatCard
          enqueueOrRun(payload)
                      │
          ┌───────────┴──────────────┐
          │ role === 'user'          │
          │   → send()              │ Agentforce API 호출 → Agent 응답
          │ role === 'agent'         │
          │   → appendMessage()     │ API 없이 Agent 버블만 표시
          │ role === 'error'         │
          │   → appendMessage()     │ 빨간 버블 표시
          │ role === 'success'       │
          │   → appendMessage()     │ 초록 버블 표시
          └──────────────────────────┘
```

### 큐잉(Queuing) 메커니즘

Agent가 응답 중(`loading=true`)일 때 주입 메시지가 도착하면 즉시 처리하지 않고 큐에 적재한 뒤, 응답 완료 후 순서대로 처리합니다.

```javascript
// employeeAgentChatCard.js 내부 로직
enqueueOrRun(payload) {
    if (this.loading) {
        this._injectQueue.push(payload);  // 큐에 적재
    } else {
        this.runInjected(payload);        // 즉시 처리
    }
}
```

---

## 외부 시스템 REST API

### 엔드포인트

```
POST /services/apexrest/agentforce/inject
```

### 인증 — OAuth 2.0 Client Credentials Flow

```bash
# Step 1: Access Token 발급
curl -X POST "https://YOUR_DOMAIN.my.salesforce.com/services/oauth2/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=YOUR_CONSUMER_KEY" \
  -d "client_secret=YOUR_CONSUMER_SECRET"

# 응답 예시
# { "access_token": "00D...", "instance_url": "https://YOUR_DOMAIN.my.salesforce.com" }
```

> Connected App 설정 시 **OAuth Policies → Permitted Users: All users may self-authorize** 또는 Client Credentials Flow 활성화 필요

### 요청 파라미터

| 필드 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `message` | String | ✅ | — | 주입할 메시지 본문 |
| `role` | String | ❌ | `agent` | `agent` / `user` / `error` / `success` |
| `targetCardTitle` | String | ❌ | (전체 broadcast) | 이 값과 일치하는 Card Title을 가진 Chat Card에만 표시 |
| `sessionId` | String | ❌ | (전체) | 특정 Agentforce 세션에만 표시 |
| `sourceSystem` | String | ❌ | `unknown` | 발신 시스템 식별자 (로그/감사용) |

### 사용 예시

```bash
ACCESS_TOKEN="00D..."
DOMAIN="https://YOUR_DOMAIN.my.salesforce.com"

# ✅ 결산 완료 알림 (초록 버블)
curl -X POST "$DOMAIN/services/apexrest/agentforce/inject" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "요청하신 결산마감 수행이 완료되었습니다.",
    "role": "success",
    "targetCardTitle": "DS Agentic Office Agent",
    "sourceSystem": "ClosingSystem"
  }'

# 🚨 에러 알림 (빨간 버블)
curl -X POST "$DOMAIN/services/apexrest/agentforce/inject" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "마감 수행중 에러가 발생하였습니다. 에러 코드는 ERR-2024-001 입니다.",
    "role": "error",
    "sourceSystem": "ClosingSystem"
  }'

# 💬 사용자 대신 질문 주입 (Agent 응답 트리거)
curl -X POST "$DOMAIN/services/apexrest/agentforce/inject" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "이번 달 마감 현황을 요약해줘",
    "role": "user",
    "sourceSystem": "ExternalPortal"
  }'
```

### 응답 형식

```json
// 성공
{ "success": true, "message": "Event published successfully" }

// 실패
{ "success": false, "message": "message is required" }
```

---

## Apex 서비스 레이어

### `AgentforceEmployeeAgentService`

#### 주요 메서드

```apex
// 단순 메시지 전송
@AuraEnabled
public static Map<String, String> sendMessage(String userMessage, String sessionId)

// 레코드 컨텍스트 포함 메시지 전송 (employeeAgentChatCard에서 호출)
@AuraEnabled
public static Map<String, String> sendMessageWithContext(String userMessage, String sessionId, String recordId)

// Flow에서 호출 (InvocableMethod)
@InvocableMethod(label='Ask Employee Agent')
public static List<AgentResponse> askAgent(List<AgentRequest> requests)
```

#### 레코드 컨텍스트 빌드 로직

`buildRecordContext(recordId)` 내부 동작:

1. `recordId`로 sObject 타입 감지 (`Id.getSObjectType()`)
2. Schema Describe로 접근 가능(`isAccessible()`)한 필드 목록 동적 구성
3. `LongTextArea`, `Base64`, `Reference` 등 불필요 타입 제외
4. 동적 SOQL로 해당 레코드 조회
5. `필드명: 값` 형식의 문자열로 포맷팅 후 사용자 메시지 앞에 추가

---

## 설치 및 설정

### Unlocked Package 설치 (권장)

```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tIT000001ONqSYAW
```

### CLI 배포 (소스 배포)

```bash
# 1. 저장소 클론
git clone https://github.com/dae2ya/agentforce-employee-chat.git
cd agentforce-employee-chat

# 2. Org 인증
sf org login web --alias MY_ORG

# 3. 배포
sf project deploy start \
  --manifest agentforce-chat-pkg/package.xml \
  --source-dir agentforce-chat-pkg/main \
  --target-org MY_ORG
```

### 설치 후 필수 설정

#### ① Agent API Name 지정

```
Setup → Custom Labels → Agentforce_Employee_Agent_ApiName
→ Value: AEA_for_SEC_DS_Full_Service  (실제 활성 Agent API Name)
```

#### ② Lightning Page 배치

App Builder에서 레코드 페이지를 열고:

```
1. "DS Agentic Office Agent" (employeeAgentChatCard) 드래그
2. 같은 페이지에 "Employee Agent Chat Injector" 추가 (선택)
   → Quick Prompts 속성 편집:
      ✅ 결산 마감 수행완료 | 요청하신 결산마감 수행이 완료되었습니다. | success
      🚨 마감 수행중 에러 발생 | 마감 수행중 에러가 발생하였습니다. 에러 코드는 OOOOO 입니다. | error
3. Save & Activate
```

#### ③ Quick Actions 등록 (선택)

```
Setup → Object Manager → Account → Buttons, Links, and Actions
→ Page Layout에 아래 Quick Action 추가:
   • Ask Employee Agent (Flow) — Ask_Employee_Agent_A
   • Launch Employee Agent (Headless) — Launch_Employee_Agent_B
```

#### ④ Connected App 설정 (외부 API 연동 시)

```
Setup → App Manager → New Connected App
→ OAuth Settings 활성화
→ Enable Client Credentials Flow 체크
→ Manage Consumer Details → Consumer Key / Secret 메모
```

---

## 버전 이력

| 버전 | 릴리즈일 | 주요 변경 사항 |
|------|----------|---------------|
| **1.1.0** | 2026-04-19 | 사용자 프로필 사진 아바타 (SmallPhotoUrl + 폴백), `success` 초록 버블 신규 추가, 챗 제목 → DS Agentic Office Agent, 아이콘 크기 +20%, 퀵 프롬프트 `role` 지원, 버튼 색상 역할별 구분 |
| **1.0.0** | 2026-04-17 | 최초 릴리즈 — `employeeAgentChatCard`, `employeeAgentChatInjector`, 외부 주입 REST API(`AgentforceChatInjectRest`), Platform Event(`AgentforceChatInject__e`), LMS 채널, `closingProgressDashboard`, Quick Action 3종, 레코드 컨텍스트 자동 주입 |

---

## 사전 요구사항

- Salesforce CLI (`sf`) v2 이상
- API version 66.0 이상
- Agentforce Employee Agent가 활성화된 Org
- (외부 API 연동 시) OAuth Connected App — Client Credentials Flow 활성화
