/**
 * 마감 태스크 진행 현황을 조회하는 Apex 컨트롤러.
 * 향후 커스텀 오브젝트(ClosingPhase__c, ClosingTask__c) 또는 외부 시스템 연동으로 확장 가능.
 */
public with sharing class ClosingTaskProgressController {
    private static final Map<String, String> PHASE_LABELS = new Map<String, String>{
        '1' => '결산 사전준비',
        '2' => '데이터 수집 및 집계',
        '3' => '결산 조정 및 검증',
        '4' => '재무제표 생성',
        '5' => '결산 마감 및 배포'
    };

    @AuraEnabled(cacheable=true)
    public static ClosingProgressResult getClosingProgress() {
        ClosingProgressResult result = new ClosingProgressResult();
        result.phases = new List<PhaseWrapper>();

        for (String phaseId : new List<String>{ '1', '2', '3', '4', '5' }) {
            PhaseWrapper phase = new PhaseWrapper();
            phase.id = phaseId;
            phase.label = PHASE_LABELS.get(phaseId);
            phase.tasks = buildTasksForPhase(phaseId);
            result.phases.add(phase);
        }

        return result;
    }

    private static List<TaskWrapper> buildTasksForPhase(String phaseId) {
        List<TaskWrapper> tasks = new List<TaskWrapper>();
        List<String> labels = getTaskLabels(phaseId);

        for (Integer i = 1; i <= labels.size(); i++) {
            TaskWrapper task = new TaskWrapper();
            task.id = phaseId + '-' + String.valueOf(100 + i).substring(1);
            task.label = labels[i - 1];
            task.status = resolveTaskStatus(phaseId, i);
            task.errorMessage = task.status == 'error'
                ? '데이터 추출 스크립트 실행 중 NULL 참조 오류가 발생했습니다. 스크립트 설정 및 소스 데이터를 확인해 주세요.'
                : null;
            tasks.add(task);
        }

        return tasks;
    }

    private static String resolveTaskStatus(String phaseId, Integer index) {
        if (index <= 13) {
            return 'completed';
        }
        if (index == 14) {
            return 'in-progress';
        }
        if (index == 16 && phaseId == '1') {
            return 'error';
        }
        return 'pending';
    }

    private static List<String> getTaskLabels(String phaseId) {
        if (phaseId != '1') {
            List<String> generic = new List<String>();
            for (Integer i = 1; i <= 20; i++) {
                generic.add('태스크 ' + i);
            }
            return generic;
        }

        return new List<String>{
            '결산 기간/회계연도 확인',
            '결산 일정 확인',
            '담당자 역할 확인',
            '결산 체크리스트 검토',
            '전월 결산 이력 확인',
            '시스템 가용성 점검',
            '백업 및 복구 계획 확인',
            '권한 설정 검토',
            '마감 절차 문서화 확인',
            '교육 이수 현황 확인',
            '외부 감사 일정 확인',
            '회계 정책 변경 검토',
            'IFRS/GAAP 적용 확인',
            '데이터 무결성 사전 점검',
            '결산 소프트웨어 업데이트',
            '데이터 추출 스크립트 오류',
            '차대조표 검증 준비',
            '재고 실사 일정 조율',
            '외화 환산률 확정',
            '결산 킥오프 회의'
        };
    }

    // Wrapper classes for JSON serialization
    public class ClosingProgressResult {
        @AuraEnabled public List<PhaseWrapper> phases;
    }

    public class PhaseWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String label;
        @AuraEnabled public List<TaskWrapper> tasks;
    }

    public class TaskWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String label;
        @AuraEnabled public String status;
        @AuraEnabled public String errorMessage;
    }
}
