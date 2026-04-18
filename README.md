# Agentforce Employee Chat

Salesforce Agentforce Employee Agent 기반 Chat UI 컴포넌트 모음.

## 🚀 원클릭 설치 (Unlocked Package v1.0.0)

| 환경 | 링크 |
|------|------|
| **Production / Developer Org** | [▶ Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tIT000001ONqNYAW) |
| **Sandbox** | [▶ Install (Sandbox)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tIT000001ONqNYAW) |

설치 후 안내: [`agentforce-chat-pkg/README.md`](agentforce-chat-pkg/README.md)

---

## 포함 컴포넌트

| 컴포넌트 | 종류 | 설명 |
|----------|------|------|
| `employeeAgentChatCard` | LWC | 레코드/앱 페이지 임베디드 채팅 |
| `employeeAgentChatModal` | LWC | Quick Action 모달 채팅 |
| `employeeAgentChatFlowScreen` | LWC | Flow Screen 임베디드 채팅 |
| `launchEmployeeAgent` | LWC | Headless Quick Action 런처 |
| `employeeAgentChatInjector` | LWC | 외부 메시지 주입 버튼 팔레트 |
| `agentforceTestConsole` | LWC | QA/데모용 테스트 콘솔 |
| `closingProgressDashboard` | LWC | 결산 마감 태스크 대시보드 |
| `AgentforceEmployeeAgentService` | Apex | Agent 호출 서비스 |
| `AgentforceChatInjectRest` | Apex REST | 외부 시스템 메시지 주입 API |
| `AgentforceChatInject__e` | Platform Event | 실시간 브라우저 푸시 |
| `AgentforceChatInject` | Message Channel | LMS 동일 페이지 통신 |

## 외부 시스템 연동

외부 레거시 시스템에서 현재 열린 Chat Card에 메시지 주입:

```bash
curl -X POST "https://YOUR_DOMAIN.my.salesforce.com/services/apexrest/agentforce/inject" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "요청하신 결산마감 수행이 완료되었습니다.", "role": "agent"}'
```

`role`: `agent`(기본, API 호출 없음) | `user`(Agent 응답 트리거) | `error`(빨간 버블)

자세한 내용: [agentforce-chat-pkg/README.md](agentforce-chat-pkg/README.md)
