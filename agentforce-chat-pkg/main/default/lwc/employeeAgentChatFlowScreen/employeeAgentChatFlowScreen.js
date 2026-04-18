import { api, LightningElement } from 'lwc';
import sendMessage from '@salesforce/apex/AgentforceEmployeeAgentService.sendMessage';

export default class EmployeeAgentChatFlowScreen extends LightningElement {
    @api initialMessage = '';
    @api agentSessionId = '';

    draft = '';
    messages = [];
    loading = false;

    connectedCallback() {
        if (this.initialMessage) {
            this.draft = this.initialMessage;
            this.send();
        }
    }

    get sendDisabled() {
        return this.loading || !(this.draft || '').trim();
    }

    get sendIcon() {
        return this.loading ? 'utility:spinner' : 'utility:send';
    }

    handleInput(event) {
        this.draft = event.target.value;
    }

    handleKeydown(event) {
        if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
            event.preventDefault();
            event.stopPropagation();
            this.send();
        }
    }

    async send() {
        const text = (this.draft || '').trim();
        if (!text || this.loading) return;
        this.appendMessage('user', text);
        this.draft = '';
        const el = this.refs?.input;
        if (el) el.value = '';
        this.loading = true;
        try {
            const res = await sendMessage({
                userMessage: text,
                sessionId: this.agentSessionId
            });
            if (res && res.isSuccess) {
                this.agentSessionId = res.sessionId;
                this.appendMessage('agent', res.reply || '(no content)');
            } else {
                this.appendMessage(
                    'error',
                    (res && res.errorMessage) || 'Agent invocation failed.'
                );
            }
        } catch (e) {
            this.appendMessage('error', e?.body?.message || e?.message || 'Unknown error');
        } finally {
            this.loading = false;
            this.scrollToBottom();
        }
    }

    appendMessage(role, text) {
        this.messages = [
            ...this.messages,
            {
                id: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
                role,
                text,
                isUser: role === 'user',
                isAgent: role === 'agent',
                isError: role === 'error'
            }
        ];
    }

    scrollToBottom() {
        requestAnimationFrame(() => {
            const el = this.template.querySelector('.chat-log');
            if (el) el.scrollTop = el.scrollHeight;
        });
    }
}
