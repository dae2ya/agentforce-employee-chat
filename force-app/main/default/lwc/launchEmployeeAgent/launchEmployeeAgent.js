import { api, LightningElement } from 'lwc';
import EmployeeAgentChatModal from 'c/employeeAgentChatModal';

export default class LaunchEmployeeAgent extends LightningElement {
    @api async invoke() {
        await EmployeeAgentChatModal.open({
            size: 'small',
            label: 'Agentforce Employee Agent',
            initialMessage: ''
        });
    }
}
