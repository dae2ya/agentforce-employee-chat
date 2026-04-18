import { LightningElement } from 'lwc';

export default class UploadContractButton extends LightningElement {
    showModal = false;

    handleUploadClick() {
        this.showModal = true;
    }

    handleCloseModal() {
        this.showModal = false;
    }

    handleFlowStatusChange(event) {
        const { status } = event.detail || {};
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN' || status === 'ERROR') {
            this.showModal = false;
        }
    }
}
