# Agentforce Employee Chat

> **Salesforce Agentforce Employee Agent** 기반의 커스텀 Chat UI 컴포넌트 모음입니다.  
> 레코드 페이지에 채팅 카드를 임베디드하고, 외부 시스템(레거시 CRM 등)에서 실시간으로 메시지를 주입할 수 있는 통합 솔루션입니다.

---

## 📦 원클릭 설치 (Unlocked Package)

### ✅ v1.1.0 — UX Enhancement _(최신)_

| 환경 | 설치 링크 |
|------|-----------|
| **Production / Developer Org** | [▶ Install v1.1.0](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tIT000001ONqSYAW) |
| **Sandbox** | [▶ Install v1.1.0 (Sandbox)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tIT000001ONqSYAW) |

<details>
<summary>v1.0.0 — Initial Release</summary>

| 환경 | 설치 링크 |
|------|-----------|
| **Production / Developer Org** | [▶ Install v1.0.0](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tIT000001ONqNYAW) |
| **Sandbox** | [▶ Install v1.0.0 (Sandbox)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tIT000001ONqNYAW) |

</details>

---

## 🏗️ 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Salesforce Lightning Page                                                  │
│                                                                             │
│  ┌────────────────────────┐   LMS Publish   ┌──────────────────────────┐  │
│  │  employeeAgentChat     │ ──────────────▶ │  AgentforceChatInject    │  │
│  │  Injector (LWC)        │                 │  (Lightning Msg Channel) │  │
│  │  [버튼 팔레트]          │                 └──────────┬───────────────┘  │
│  └────────────────────────┘                            │ subscribe        │
│                                                        ▼                  │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │  employeeAgentChatCard (LWC)  ← 채팅 UI 본체                       │   │
│  │                                                                    │   │
│  │  [사용자 입력] ──Apex──▶ Agentforce Agent API ──▶ [Agent 응답 버블] │   │
│  │  [주입된 메시지]                              ──▶ [역할별 버블]     │   │
│  └─────────────────────────────────┬──────────────────────────────────┘   │
│                                    │ empApi / CometD subscribe            │
└────────────────────────────────────┼────────────────────────────────────── ┘
                                     │
                          ┌──────────┴──────────────────┐
                          │  AgentforceChatInject__e     │
                          │  (Platform Event)            │
                          └──────────┬───────────────────┘
                                     │ EventBus.publish
                          ┌──────────┴───────────────────┐
                          │  AgentforceChatInjectRest     │
                          │  (Apex REST — @RestResource)  │
                          └──────────┬───────────────────┘
                                     │ HTTP POST
                          ┌──────────┴───────────────────┐
                          │  외부 레거시 시스템             │
                          │  (ERP, CRM, 결산 시스템 등)    │
                          └──────────────────────────────┘
```

---

## 💬 Chat Injector 동작 원리

이 패키지의 핵심 기능인 **메시지 주입(Inject)** 은 두 가지 경로를 지원합니다.

### 경로 1 — 동일 페이지 LWC 간 통신 (Lightning Message Service)

```
employeeAgentChatInjector   →   AgentforceChatInject   →   employeeAgentChatCard
      (버튼 클릭)               (MessageChannel LMS)          (메시지 표시)
```

- 같은 Lightning Page에 두 컴포넌트가 함께 배치된 경우 사용
- 네트워크 왕복 없이 브라우저 내에서 즉시 전달
- `employeeAgentChatInjector`의 **Quick Prompts** 속성으로 버튼 라벨/메시지/역할 커스터마이징 가능

### 경로 2 — 외부 시스템 → 브라우저 실시간 주입 (Platform Event + empApi)

```
외부 시스템  →  REST POST  →  AgentforceChatInjectRest  →  AgentforceChatInject__e  →  employeeAgentChatCard
                              (Apex @RestResource)          (Platform Event)            (CometD 구독)
```

- 외부 서버(레거시 CRM, ERP, 배치 프로세스 등)에서 HTTP POST 한 번으로 브라우저 Chat Card에 메시지를 직접 표시
- Agentforce Agent를 추가로 호출하지 않으므로 API 비용 없음
- `role` 파라미터로 메시지 버블 종류 제어

### 메시지 역할(role)과 버블 스타일

| role | 버블 색상 | 동작 |
|------|-----------|------|
| `agent` (기본) | 흰색 (Agent 스타일) | Agent가 답변하는 것처럼 표시. Agentforce API 호출 없음 |
| `user` | 파란색 (사용자 스타일) | 사용자가 입력한 것처럼 표시 후 **Agent 응답 트리거** |
| `error` | 빨간색 | 에러 메시지 강조 표시 |
| `success` | 초록색 | 성공/완료 메시지 강조 표시 |

---

## 📦 포함 컴포넌트

### Lightning Web Components

| 컴포넌트 | 배치 위치 | 설명 |
|----------|-----------|------|
| `employeeAgentChatCard` | 레코드/앱 페이지 | 핵심 채팅 UI. 사용자 프로필 사진 아바타, 역할별 버블, 레코드 컨텍스트 자동 주입 |
| `employeeAgentChatInjector` | 같은 페이지 | 퀵 프롬프트 버튼 팔레트. LMS로 ChatCard에 메시지 주입 |
| `employeeAgentChatModal` | Quick Action | 모달 팝업 형태 채팅 |
| `employeeAgentChatFlowScreen` | Flow Screen | Flow 내 임베디드 채팅 |
| `launchEmployeeAgent` | Quick Action | Headless Quick Action 런처 |
| `agentforceTestConsole` | 앱/탭 페이지 | QA/데모용 테스트 콘솔 |
| `closingProgressDashboard` | 앱 페이지 | 결산 마감 태스크 진행 현황 대시보드 |

### Apex Classes

| 클래스 | 설명 |
|--------|------|
| `AgentforceEmployeeAgentService` | Agentforce Agent 호출 서비스. 레코드 컨텍스트 자동 빌드 포함 |
| `AgentforceChatInjectRest` | 외부 → Chat 메시지 주입 REST API (`/agentforce/inject`) |
| `ClosingTaskProgressController` | 결산 진행 현황 조회 컨트롤러 |

### 인프라 메타데이터

| 메타데이터 | 종류 | 설명 |
|------------|------|------|
| `AgentforceChatInject__e` | Platform Event | 외부→브라우저 실시간 메시지 전달 채널 |
| `AgentforceChatInject` | Lightning Message Channel | 동일 페이지 LWC 간 통신 채널 |
| `Agentforce_Employee_Agent_ApiName` | Custom Label | Agent API Name 설정값 |

---

## ⚙️ 설치 후 설정

### 1. Agent API 이름 지정 (필수)

```
Setup → Custom Labels → Agentforce_Employee_Agent_ApiName
→ Value를 실제 활성화된 Agent의 API Name으로 변경
   예: AEA_for_SEC_DS_Full_Service
```

### 2. 페이지에 컴포넌트 배치

Lightning App Builder에서 원하는 레코드/앱 페이지에 드래그:

```
[DS Agentic Office Agent]  ← employeeAgentChatCard
[📌 결산 마감 수행완료]     ← employeeAgentChatInjector (선택)
[🚨 마감 수행중 에러 발생]
```

### 3. Quick Actions 등록 (선택)

```
Setup → Object Manager → Account → Buttons, Links, and Actions
→ Page Layouts에 추가:
   • Ask Employee Agent (Flow)        — A옵션: Flow 기반
   • Launch Employee Agent (Headless) — B옵션: Headless LWC Modal
```

---

## 🌐 외부 시스템 REST API

### 인증 (OAuth 2.0 Client Credentials)

```bash
curl -X POST "https://YOUR_DOMAIN.my.salesforce.com/services/oauth2/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=CONSUMER_KEY" \
  -d "client_secret=CONSUMER_SECRET"
```

### 메시지 주입 예시

```bash
# ✅ 결산 완료 (초록 버블)
curl -X POST "https://YOUR_DOMAIN.my.salesforce.com/services/apexrest/agentforce/inject" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "요청하신 결산마감 수행이 완료되었습니다.", "role": "success", "sourceSystem": "ClosingSystem"}'

# 🚨 에러 알림 (빨간 버블)
curl -X POST "https://YOUR_DOMAIN.my.salesforce.com/services/apexrest/agentforce/inject" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "마감 수행중 에러가 발생하였습니다. 에러 코드는 ERR-1234 입니다.", "role": "error", "sourceSystem": "ClosingSystem"}'
```

| 파라미터 | 필수 | 기본값 | 설명 |
|----------|------|--------|------|
| `message` | ✅ | — | 주입할 메시지 텍스트 |
| `role` | ❌ | `agent` | `agent` / `user` / `error` / `success` |
| `targetCardTitle` | ❌ | (전체 broadcast) | 특정 Chat Card 타겟팅 |
| `sessionId` | ❌ | (전체) | 특정 Agentforce 세션 타겟팅 |
| `sourceSystem` | ❌ | `unknown` | 발신 시스템 식별자 (로그/감사용) |

---

## 📋 버전 이력

| 버전 | 날짜 | 주요 변경 사항 |
|------|------|---------------|
| **1.1.0** | 2026-04-19 | 사용자 프로필 사진 아바타, `success` 초록 버블, 챗 제목 변경(DS Agentic Office Agent), 아이콘 크기 +20%, 퀵 프롬프트 역할 지원 |
| **1.0.0** | 2026-04-17 | 최초 릴리즈 — 채팅 카드, 메시지 주입 API, 결산 대시보드 |

---

자세한 설치/설정 가이드: [agentforce-chat-pkg/README.md](agentforce-chat-pkg/README.md)
