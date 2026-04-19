import { api, wire, LightningElement } from 'lwc';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import {
    subscribe as empSubscribe,
    unsubscribe as empUnsubscribe,
    onError as empOnError
} from 'lightning/empApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_PHOTO from '@salesforce/schema/User.SmallPhotoUrl';
import USER_NAME from '@salesforce/schema/User.Name';
import AGENTFORCE_CHAT_INJECT from '@salesforce/messageChannel/AgentforceChatInject__c';
import sendMessage from '@salesforce/apex/AgentforceEmployeeAgentService.sendMessage';
import sendMessageWithContext from '@salesforce/apex/AgentforceEmployeeAgentService.sendMessageWithContext';

const PLATFORM_EVENT_CHANNEL = '/event/AgentforceChatInject__e';
const VALID_ROLES = new Set(['agent', 'user', 'error', 'success']);

function normalizeRole(raw) {
    if (!raw) return 'agent';
    const r = String(raw).trim().toLowerCase();
    return VALID_ROLES.has(r) ? r : 'agent';
}

export default class EmployeeAgentChatCard extends LightningElement {
    @api recordId;
    @api cardTitle = 'DS Agentic Office Agent';
    @api iconName = 'utility:einstein';
    @api initialMessage = '';
    @api maxHeight = 480;
    @api autoStart = false;
    @api includeRecordContext = false;

    sessionId = null;
    draft = '';
    messages = [];
    loading = false;
    _bootstrapped = false;
    _lmsSubscription;
    _empSubscription;
    _injectQueue = [];

    userId = USER_ID;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$userId', fields: [USER_PHOTO, USER_NAME] })
    currentUser;

    get userPhotoUrl() {
        const url = getFieldValue(this.currentUser?.data, USER_PHOTO);
        if (!url) return null;
        // SmallPhotoUrl이 상대경로일 경우 절대경로로 보정
        if (url.startsWith('http')) return url;
        return url;
    }

    get userHasPhoto() {
        return !!this.userPhotoUrl;
    }

    connectedCallback() {
        this.subscribeToInjectChannel();
        this.subscribeToPlatformEvent();
        if (this._bootstrapped) return;
        this._bootstrapped = true;
        if (this.autoStart && this.initialMessage) {
            this.draft = this.initialMessage;
            this.send();
        }
    }

    disconnectedCallback() {
        if (this._lmsSubscription) {
            unsubscribe(this._lmsSubscription);
            this._lmsSubscription = null;
        }
        if (this._empSubscription) {
            empUnsubscribe(this._empSubscription, () => {});
            this._empSubscription = null;
        }
    }

    subscribeToInjectChannel() {
        if (this._lmsSubscription) return;
        this._lmsSubscription = subscribe(
            this.messageContext,
            AGENTFORCE_CHAT_INJECT,
            (payload) => this.handleInject(payload)
        );
    }

    async subscribeToPlatformEvent() {
        if (this._empSubscription) return;
        try {
            empOnError((err) => {
                console.warn('[employeeAgentChatCard] empApi error', err);
            });
            this._empSubscription = await empSubscribe(
                PLATFORM_EVENT_CHANNEL,
                -1,
                (event) => this.handlePlatformEvent(event)
            );
        } catch (e) {
            console.warn(
                '[employeeAgentChatCard] Platform Event subscribe failed',
                e
            );
        }
    }

    handlePlatformEvent(event) {
        const payload = event?.data?.payload;
        if (!payload) return;
        const msg = (payload.Message__c || '').trim();
        const target = payload.TargetCardTitle__c;
        const sessId = payload.SessionId__c;
        const role = normalizeRole(payload.Role__c);
        if (!msg) return;
        if (target && target !== this.cardTitle) return;
        if (sessId && sessId !== this.sessionId) return;
        this.dispatchInjected(role, msg);
    }

    handleInject(payload) {
        if (!payload) return;
        const msg = (payload.message || '').trim();
        if (!msg) return;
        if (
            payload.targetCardTitle &&
            payload.targetCardTitle !== this.cardTitle
        ) {
            return;
        }
        const role = normalizeRole(payload.role);
        this.dispatchInjected(role, msg);
    }

    /**
     * role에 따라 분기:
     * - agent / error: API 호출 없이 버블만 추가 (기본 동작)
     * - user: 기존처럼 user 턴으로 보내고 Agent 호출
     */
    dispatchInjected(role, msg) {
        if (role === 'user') {
            this.enqueueUserInject(msg);
            return;
        }
        const bubbleRole = (role === 'error' || role === 'success') ? role : 'agent';
        this.appendMessage(bubbleRole, msg);
        this.scrollToBottom();
    }

    enqueueUserInject(msg) {
        if (this.loading) {
            this._injectQueue.push(msg);
            return;
        }
        this.runInjected(msg);
    }

    async runInjected(text) {
        this.draft = text;
        this.clearInput();
        await this.send();
        if (this._injectQueue.length > 0) {
            const next = this._injectQueue.shift();
            this.runInjected(next);
        }
    }

    get logStyle() {
        const h = Number(this.maxHeight) || 480;
        return `max-height: ${h}px; min-height: ${Math.min(h, 260)}px;`;
    }

    get showPlaceholder() {
        return this.messages.length === 0 && !this.loading;
    }

    get canSend() {
        return !this.loading && (this.draft || '').trim().length > 0;
    }

    get sendDisabled() {
        return !this.canSend;
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
        this.clearInput();
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
            this.appendMessage('error', e?.body?.message || e?.message || 'Unknown error');
        } finally {
            this.loading = false;
            this.scrollToBottom();
        }
    }

    resetSession() {
        this.sessionId = null;
        this.messages = [];
        this.draft = '';
        this.clearInput();
    }

    clearInput() {
        const el = this.refs?.input;
        if (el) el.value = '';
    }

    appendMessage(role, text) {
        this.messages = [
            ...this.messages,
            {
                id: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
                role,
                rowClass: `msg-row msg-row--${role}`,
                text,
                isUser: role === 'user',
                isAgent: role === 'agent',
                isError: role === 'error',
                isSuccess: role === 'success'
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
