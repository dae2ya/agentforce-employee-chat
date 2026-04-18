/**
 * Agentforce Action: JSON 입력으로 Opportunity 커스텀 필드를 업데이트합니다.
 * 대상 필드: contract_number__c, Service_Period__c, Engineer_Grade__c,
 *           Contract_Period__c, Maker__c
 *
 * JSON 입력 스키마 (마크다운 코드블록 감싸기 허용):
 * {
 *   "opportunityId": "006XXXXXXXXXXXXXXX",  // 필수
 *   "contractNumber": "CNT-2026-001",        // 선택
 *   "servicePeriod": "12개월",               // 선택
 *   "engineerGrade": "Senior",              // 선택
 *   "contractPeriod": "2026-01 ~ 2026-12",  // 선택
 *   "maker": "홍길동"                        // 선택
 * }
 */
public with sharing class OpportunityUpdateAction {

    public class ActionInput {
        @InvocableVariable(
            required=true
            label='Opportunity JSON'
            description='opportunityId(필수), contractNumber, servicePeriod, engineerGrade, contractPeriod, maker를 포함하는 JSON 문자열'
        )
        public String opportunityJson;
    }

    public class ActionOutput {
        @InvocableVariable(label='성공 여부')
        public Boolean success;

        @InvocableVariable(label='결과 메시지')
        public String message;
    }

    @InvocableMethod(
        label='Update Opportunity Fields'
        description='JSON으로 Opportunity의 계약번호(contract_number__c), 서비스기간(Service_Period__c), 엔지니어등급(Engineer_Grade__c), 계약기간(Contract_Period__c), 메이커(Maker__c)를 업데이트합니다. opportunityId는 필수이며 변경할 필드만 포함하면 됩니다.'
        category='Opportunity'
    )
    public static List<ActionOutput> updateOpportunity(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            outputs.add(processInput(input));
        }

        return outputs;
    }

    private static ActionOutput processInput(ActionInput input) {
        ActionOutput output = new ActionOutput();

        if (String.isBlank(input?.opportunityJson)) {
            output.success = false;
            output.message = 'opportunityJson 입력값이 비어 있습니다.';
            return output;
        }

        Map<String, Object> jsonMap;
        try {
            jsonMap = (Map<String, Object>) JSON.deserializeUntyped(stripMarkdown(input.opportunityJson));
        } catch (Exception e) {
            output.success = false;
            output.message = 'JSON 파싱 오류: ' + e.getMessage();
            return output;
        }

        String opportunityId = (String) jsonMap.get('opportunityId');
        if (String.isBlank(opportunityId)) {
            output.success = false;
            output.message = 'opportunityId는 필수 입력값입니다.';
            return output;
        }

        List<Opportunity> opps = [
            SELECT Id, contract_number__c, Service_Period__c, Engineer_Grade__c,
                   Contract_Period__c, Maker__c
            FROM Opportunity
            WHERE Id = :opportunityId
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        if (opps.isEmpty()) {
            output.success = false;
            output.message = 'Opportunity를 찾을 수 없습니다. Id: ' + opportunityId;
            return output;
        }

        Opportunity opp = opps[0];

        if (jsonMap.containsKey('contractNumber')) {
            opp.contract_number__c = (String) jsonMap.get('contractNumber');
        }
        if (jsonMap.containsKey('servicePeriod')) {
            opp.Service_Period__c = (String) jsonMap.get('servicePeriod');
        }
        if (jsonMap.containsKey('engineerGrade')) {
            opp.Engineer_Grade__c = (String) jsonMap.get('engineerGrade');
        }
        if (jsonMap.containsKey('contractPeriod')) {
            opp.Contract_Period__c = (String) jsonMap.get('contractPeriod');
        }
        if (jsonMap.containsKey('maker')) {
            opp.Maker__c = (String) jsonMap.get('maker');
        }

        Database.SaveResult result = Database.update(opp, false, AccessLevel.SYSTEM_MODE);

        if (result.isSuccess()) {
            output.success = true;
            output.message = 'Opportunity가 성공적으로 업데이트되었습니다. Id: ' + opportunityId;
        } else {
            List<String> errors = new List<String>();
            for (Database.Error err : result.getErrors()) {
                errors.add(err.getMessage());
            }
            output.success = false;
            output.message = '업데이트 실패: ' + String.join(errors, ', ');
        }

        return output;
    }

    /**
     * LLM이 JSON을 마크다운 코드블록으로 감싸 반환하는 경우를 처리합니다.
     * 예: ```json\n{...}\n``` 또는 ```\n{...}\n```
     */
    @TestVisible
    private static String stripMarkdown(String raw) {
        String cleaned = raw.trim();

        // 여는 코드펜스(```json 또는 ```) 제거
        if (cleaned.startsWith('```')) {
            Integer newlineIdx = cleaned.indexOf('\n');
            if (newlineIdx != -1) {
                cleaned = cleaned.substring(newlineIdx + 1);
            }
        }

        // 닫는 코드펜스(```) 제거
        if (cleaned.endsWith('```')) {
            cleaned = cleaned.substring(0, cleaned.lastIndexOf('```'));
        }

        return cleaned.trim();
    }
}
