@IsTest
private class OpportunityUpdateActionTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
    }

    // Positive: 유효한 JSON → 3개 필드 모두 업데이트 성공
    @IsTest
    static void testUpdateAllFieldsSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        String jsonInput = JSON.serialize(new Map<String, Object>{
            'opportunityId' => opp.Id,
            'contractNumber' => 'CNT-2026-001',
            'servicePeriod' => '12개월',
            'engineerGrade' => 'Senior'
        });

        OpportunityUpdateAction.ActionInput input = new OpportunityUpdateAction.ActionInput();
        input.opportunityJson = jsonInput;

        Test.startTest();
        List<OpportunityUpdateAction.ActionOutput> outputs = OpportunityUpdateAction.updateOpportunity(
            new List<OpportunityUpdateAction.ActionInput>{ input }
        );
        Test.stopTest();

        Assert.isTrue(outputs[0].success, '업데이트가 성공해야 합니다.');

        Opportunity updated = [
            SELECT contract_number__c, Service_Period__c, Engineer_Grade__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        Assert.areEqual('CNT-2026-001', updated.contract_number__c, 'contract_number__c가 일치해야 합니다.');
        Assert.areEqual('12개월', updated.Service_Period__c, 'Service_Period__c가 일치해야 합니다.');
        Assert.areEqual('Senior', updated.Engineer_Grade__c, 'Engineer_Grade__c가 일치해야 합니다.');
    }

    // Positive: 일부 필드만 포함한 JSON → 해당 필드만 업데이트
    @IsTest
    static void testUpdatePartialFieldsSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        String jsonInput = JSON.serialize(new Map<String, Object>{
            'opportunityId' => opp.Id,
            'contractNumber' => 'CNT-2026-PARTIAL'
        });

        OpportunityUpdateAction.ActionInput input = new OpportunityUpdateAction.ActionInput();
        input.opportunityJson = jsonInput;

        Test.startTest();
        List<OpportunityUpdateAction.ActionOutput> outputs = OpportunityUpdateAction.updateOpportunity(
            new List<OpportunityUpdateAction.ActionInput>{ input }
        );
        Test.stopTest();

        Assert.isTrue(outputs[0].success, '부분 업데이트도 성공해야 합니다.');

        Opportunity updated = [SELECT contract_number__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('CNT-2026-PARTIAL', updated.contract_number__c);
    }

    // Negative: 존재하지 않는 Opportunity Id
    @IsTest
    static void testInvalidOpportunityId() {
        String jsonInput = JSON.serialize(new Map<String, Object>{
            'opportunityId' => '006000000000000AAA',
            'contractNumber' => 'CNT-INVALID'
        });

        OpportunityUpdateAction.ActionInput input = new OpportunityUpdateAction.ActionInput();
        input.opportunityJson = jsonInput;

        Test.startTest();
        List<OpportunityUpdateAction.ActionOutput> outputs = OpportunityUpdateAction.updateOpportunity(
            new List<OpportunityUpdateAction.ActionInput>{ input }
        );
        Test.stopTest();

        Assert.isFalse(outputs[0].success, '존재하지 않는 Id는 실패해야 합니다.');
        Assert.isTrue(outputs[0].message.contains('찾을 수 없습니다'), '에러 메시지에 "찾을 수 없습니다"가 포함되어야 합니다.');
    }

    // Negative: 잘못된 JSON 형식
    @IsTest
    static void testMalformedJson() {
        OpportunityUpdateAction.ActionInput input = new OpportunityUpdateAction.ActionInput();
        input.opportunityJson = 'not-valid-json{{{';

        Test.startTest();
        List<OpportunityUpdateAction.ActionOutput> outputs = OpportunityUpdateAction.updateOpportunity(
            new List<OpportunityUpdateAction.ActionInput>{ input }
        );
        Test.stopTest();

        Assert.isFalse(outputs[0].success, 'JSON 파싱 오류는 실패해야 합니다.');
        Assert.isTrue(outputs[0].message.contains('JSON 파싱 오류'), '에러 메시지에 "JSON 파싱 오류"가 포함되어야 합니다.');
    }

    // Null: opportunityId 키 없음
    @IsTest
    static void testMissingOpportunityId() {
        String jsonInput = JSON.serialize(new Map<String, Object>{
            'contractNumber' => 'CNT-NO-ID'
        });

        OpportunityUpdateAction.ActionInput input = new OpportunityUpdateAction.ActionInput();
        input.opportunityJson = jsonInput;

        Test.startTest();
        List<OpportunityUpdateAction.ActionOutput> outputs = OpportunityUpdateAction.updateOpportunity(
            new List<OpportunityUpdateAction.ActionInput>{ input }
        );
        Test.stopTest();

        Assert.isFalse(outputs[0].success, 'opportunityId 누락은 실패해야 합니다.');
        Assert.isTrue(outputs[0].message.contains('opportunityId는 필수'), '에러 메시지에 "opportunityId는 필수"가 포함되어야 합니다.');
    }

    // Null: 빈 JSON 문자열 입력
    @IsTest
    static void testBlankJsonInput() {
        OpportunityUpdateAction.ActionInput input = new OpportunityUpdateAction.ActionInput();
        input.opportunityJson = '';

        Test.startTest();
        List<OpportunityUpdateAction.ActionOutput> outputs = OpportunityUpdateAction.updateOpportunity(
            new List<OpportunityUpdateAction.ActionInput>{ input }
        );
        Test.stopTest();

        Assert.isFalse(outputs[0].success, '빈 입력은 실패해야 합니다.');
        Assert.isTrue(outputs[0].message.contains('비어 있습니다'), '에러 메시지에 "비어 있습니다"가 포함되어야 합니다.');
    }
}
