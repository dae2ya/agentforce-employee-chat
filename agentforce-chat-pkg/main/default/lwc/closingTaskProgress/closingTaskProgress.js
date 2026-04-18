import { LightningElement, track, wire } from 'lwc';
import getClosingProgress from '@salesforce/apex/ClosingTaskProgressController.getClosingProgress';

const STATUS_LABELS = {
    completed: '완료',
    'in-progress': '진행중',
    pending: '대기중',
    error: '에러'
};

function enrichTask(task) {
    const statusLabel = STATUS_LABELS[task.status] || task.status;
    return {
        ...task,
        statusLabel,
        showBadge: task.status !== 'pending',
        badgeRole: task.status === 'error' ? 'button' : 'presentation',
        badgeTabindex: task.status === 'error' ? 0 : -1,
        badgeAriaLabel:
            task.status === 'error'
                ? `${task.label} - 에러, 클릭하여 상세 보기`
                : `${task.label} - ${statusLabel}`
    };
}

export default class ClosingTaskProgress extends LightningElement {
    @track selectedPhaseId = '1';
    @track expandedErrorTaskId = null;
    @track phasesWithTasksRaw = [];
    @track dataError = null;

    @wire(getClosingProgress)
    wiredClosingProgress({ data, error }) {
        if (data) {
            this.phasesWithTasksRaw = data.phases || [];
            this.dataError = null;
        }
        if (error) {
            this.phasesWithTasksRaw = [];
            this.dataError = error;
        }
    }

    get phases() {
        return (this.phasesWithTasksRaw || []).map((p) => ({
            ...p,
            isSelected: p.id === this.selectedPhaseId,
            ariaLabel: `${p.label} 선택`
        }));
    }

    get phasesWithTasks() {
        return (this.phasesWithTasksRaw || []).map((phase) => ({
            ...phase,
            tasks: (phase.tasks || []).map((t) => ({
                ...enrichTask(t),
                isErrorPanelVisible: this.expandedErrorTaskId === t.id
            }))
        }));
    }

    get selectedPhase() {
        const phase = this.phasesWithTasks.find((p) => p.id === this.selectedPhaseId);
        return (
            phase ||
            this.phasesWithTasks[0] || { id: '1', label: '결산 사전준비', tasks: [] }
        );
    }

    get overallProgress() {
        const allTasks = this.phasesWithTasks.flatMap((p) => p.tasks);
        const completed = allTasks.filter((t) => t.status === 'completed').length;
        const total = allTasks.length;
        return {
            percent: total ? Math.round((completed / total) * 100) : 0,
            completed,
            total,
            inProgress: allTasks.filter((t) => t.status === 'in-progress').length,
            pending: allTasks.filter((t) => t.status === 'pending').length,
            error: allTasks.filter((t) => t.status === 'error').length
        };
    }

    get isLoading() {
        return !this.phasesWithTasksRaw?.length && !this.dataError;
    }

    get hasDataError() {
        return !!this.dataError;
    }

    handlePhaseSelect(event) {
        this.selectedPhaseId = event.currentTarget.dataset.phaseId;
        this.expandedErrorTaskId = null;
    }

    handlePhaseKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handlePhaseSelect(event);
        }
    }

    handleTaskBadgeClick(event) {
        const taskId = event.currentTarget.dataset.taskId;
        const task = this.selectedPhase?.tasks?.find((t) => t.id === taskId);
        if (task?.status === 'error') {
            this.toggleErrorPanel(taskId);
        }
    }

    handleTaskBadgeKeydown(event) {
        const taskId = event.currentTarget.dataset.taskId;
        const task = this.selectedPhase?.tasks?.find((t) => t.id === taskId);
        if (task?.status === 'error' && (event.key === 'Enter' || event.key === ' ')) {
            event.preventDefault();
            this.toggleErrorPanel(taskId);
        }
    }

    toggleErrorPanel(taskId) {
        this.expandedErrorTaskId =
            this.expandedErrorTaskId === taskId ? null : taskId;
    }
}
