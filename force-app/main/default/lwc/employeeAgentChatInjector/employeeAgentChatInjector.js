import { api, wire, LightningElement } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import AGENTFORCE_CHAT_INJECT from '@salesforce/messageChannel/AgentforceChatInject__c';

/**
 * 프롬프트 형식: "라벨 | 메시지 | role(optional)"
 * role 생략 시 → 글로벌 라디오 선택값 사용
 * role 명시 시 → 해당 버튼은 항상 지정된 role로 동작
 */
const DEFAULT_PROMPTS = [
    '✅ 결산 마감 수행완료 | 요청하신 결산마감 수행이 완료되었습니다. | agent',
    '🚨 마감 수행중 에러 발생 | 마감 수행중 에러가 발생하였습니다. 에러 코드는 OOOOO 입니다. | error'
].join('\n');

/**
 * Employee Agent Chat Injector
 * - 같은 Lightning 페이지의 employeeAgentChatCard에 메시지를 밀어넣는다.
 * - Lightning Message Service (AgentforceChatInject__c) publish.
 * - targetCardTitle 로 필터링 가능 (같은 페이지에 Chat Card가 여러 개일 때).
 */
export default class EmployeeAgentChatInjector extends LightningElement {
    @api cardTitle = 'Chat Message Injector';
    @api targetCardTitle = '';
    @api prompts = DEFAULT_PROMPTS;

    draft = '';
    lastSent = '';
    role = 'agent';

    @wire(MessageContext)
    messageContext;

    roleOptions = [
        { label: 'Agent 버블 (API 호출 없음)', value: 'agent' },
        { label: 'User 턴 (Agent API 호출)', value: 'user' },
        { label: 'Error 버블', value: 'error' }
    ];

    get roleHint() {
        if (this.role === 'user') {
            return 'User 턴으로 주입되며 Agent API 호출이 실행됩니다.';
        }
        if (this.role === 'error') {
            return 'Error 버블로 표시됩니다 (빨간색).';
        }
        return 'Agent가 말한 것처럼 표시됩니다 (API 호출 없음).';
    }

    handleRoleChange(event) {
        this.role = event.detail.value;
    }

    get quickActions() {
        const lines = (this.prompts || '').split(/\r?\n/);
        const VALID = new Set(['agent', 'user', 'error']);
        const out = [];
        for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed) continue;
            const parts = trimmed.split('|').map((s) => s.trim());
            const label = parts[0] || '';
            const message = parts[1] || parts[0] || '';
            const roleRaw = (parts[2] || '').toLowerCase();
            const role = VALID.has(roleRaw) ? roleRaw : null;
            if (!message) continue;
            out.push({
                id: `qa-${out.length}`,
                label,
                message,
                role,
                btnClass: this.btnClass(role)
            });
        }
        return out;
    }

    btnClass(role) {
        if (role === 'error') return 'quick-action-btn quick-action-btn--error';
        if (role === 'user') return 'quick-action-btn quick-action-btn--user';
        return 'quick-action-btn';
    }

    get hasQuickActions() {
        return this.quickActions.length > 0;
    }

    get sendDisabled() {
        return !(this.draft || '').trim();
    }

    get targetBadgeLabel() {
        return this.targetCardTitle
            ? `→ ${this.targetCardTitle}`
            : '→ broadcast (모든 Chat Card)';
    }

    handleInput(event) {
        this.draft = event.target.value;
    }

    handleKeydown(event) {
        if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
            event.preventDefault();
            event.stopPropagation();
            this.sendDraft();
        }
    }

    handleQuickAction(event) {
        const message = event.currentTarget.dataset.message;
        // role이 버튼에 명시되어 있으면 우선 사용, 없으면 글로벌 라디오 값
        const promptRole = event.currentTarget.dataset.role;
        if (!message) return;
        this.inject(message, promptRole || this.role);
    }

    sendDraft() {
        const text = (this.draft || '').trim();
        if (!text) return;
        this.inject(text);
        this.draft = '';
        const el = this.refs?.input;
        if (el) el.value = '';
    }

    inject(message, role) {
        publish(this.messageContext, AGENTFORCE_CHAT_INJECT, {
            message,
            targetCardTitle: this.targetCardTitle || null,
            sourceId: 'employeeAgentChatInjector',
            role: role || this.role
        });
        this.lastSent = message;
    }
}
