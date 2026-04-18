import { api, LightningElement } from 'lwc';
import sendMessage from '@salesforce/apex/AgentforceEmployeeAgentService.sendMessage';
import sendMessageWithContext from '@salesforce/apex/AgentforceEmployeeAgentService.sendMessageWithContext';

const DEFAULT_PROMPTS = [
    '📄 내 계약 조회 | 현재 활성 상태인 보험 계약 목록을 요약해줘',
    '⚠️ 리스크 분석 | 보유 계약에서 가장 큰 리스크 요인을 알려줘',
    '💡 상품 추천 | 이 고객에게 적합한 추가 보험 상품을 3개 추천해줘',
    '📊 이번 달 실적 | 이번 달 영업 실적을 간략히 요약해줘'
].join('\n');

/**
 * Agentforce Test Console
 * - 관리자/QA가 미리 정의한 프롬프트 버튼을 눌러 대화를 빠르게 주입
 * - 현재 세션을 유지하며 multi-turn 테스트 가능
 * - 수동 입력도 여전히 지원
 */
export default class AgentforceTestConsole extends LightningElement {
    @api cardTitle = 'Agentforce Test Console';
    @api recordId;
    @api includeRecordContext = false;

    /**
     * 버튼 정의 (design property).
     * 각 줄 = "라벨 | 메시지"
     * 예: "계약 조회 | 내 계약 목록을 보여줘"
     */
    @api prompts = DEFAULT_PROMPTS;

    sessionId = null;
    loading = false;
    draft = '';
    messages = [];
    _msgSeq = 0;

    get quickActions() {
        const lines = (this.prompts || '').split(/\r?\n/);
        const out = [];
        for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed) continue;
            const sep = trimmed.indexOf('|');
            let label;
            let message;
            if (sep === -1) {
                label = trimmed;
                message = trimmed;
            } else {
                label = trimmed.slice(0, sep).trim();
                message = trimmed.slice(sep + 1).trim();
            }
            if (!message) continue;
            out.push({
                id: `qa-${out.length}`,
                label,
                message
            });
        }
        return out;
    }

    get hasQuickActions() {
        return this.quickActions.length > 0;
    }

    get showPlaceholder() {
        return !this.loading && this.messages.length === 0;
    }

    get sendDisabled() {
        return this.loading || !(this.draft || '').trim();
    }

    get sendIcon() {
        return this.loading ? 'utility:spinner' : 'utility:send';
    }

    get sessionBadgeLabel() {
        return this.sessionId
            ? `session: ${String(this.sessionId).slice(0, 8)}…`
            : 'session: none';
    }

    get sessionBadgeClass() {
        return this.sessionId
            ? 'session-badge session-badge--active'
            : 'session-badge session-badge--idle';
    }

    get turnCount() {
        return this.messages.length;
    }

    get contextBadgeVisible() {
        return this.includeRecordContext && !!this.recordId;
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
        if (!message || this.loading) return;
        this.sendAsUser(message);
    }

    sendDraft() {
        const text = (this.draft || '').trim();
        if (!text || this.loading) return;
        this.draft = '';
        const el = this.refs?.input;
        if (el) el.value = '';
        this.sendAsUser(text);
    }

    async sendAsUser(text) {
        this.appendMessage('user', text);
        this.loading = true;
        try {
            const useContext = this.includeRecordContext && this.recordId;
            const res = useContext
                ? await sendMessageWithContext({
                      userMessage: text,
                      sessionId: this.sessionId,
                      recordId: this.recordId
                  })
                : await sendMessage({
                      userMessage: text,
                      sessionId: this.sessionId
                  });
            if (res && res.isSuccess) {
                this.sessionId = res.sessionId;
                this.appendMessage('agent', res.reply || '(no content)');
            } else {
                this.appendMessage(
                    'error',
                    (res && res.errorMessage) || 'Agent invocation failed.'
                );
            }
        } catch (e) {
            this.appendMessage(
                'error',
                e?.body?.message || e?.message || 'Unknown error'
            );
        } finally {
            this.loading = false;
            this.scrollToBottom();
        }
    }

    appendMessage(role, text) {
        this._msgSeq += 1;
        this.messages = [
            ...this.messages,
            {
                id: `${role}-${this._msgSeq}`,
                role,
                text,
                isUser: role === 'user',
                isAgent: role === 'agent',
                isError: role === 'error'
            }
        ];
        Promise.resolve().then(() => this.scrollToBottom());
    }

    scrollToBottom() {
        const el = this.template.querySelector('.chat-log');
        if (el) el.scrollTop = el.scrollHeight;
    }

    resetSession() {
        this.sessionId = null;
        this.messages = [];
        this.draft = '';
        const el = this.refs?.input;
        if (el) el.value = '';
    }

    copySessionId() {
        if (!this.sessionId || !navigator?.clipboard) return;
        navigator.clipboard.writeText(this.sessionId).catch(() => {});
    }
}
