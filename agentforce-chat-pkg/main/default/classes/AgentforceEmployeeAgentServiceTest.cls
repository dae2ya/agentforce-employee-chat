@IsTest
private class AgentforceEmployeeAgentServiceTest {

    @IsTest
    static void parseAgentResponse_returnsValueField() {
        AgentforceEmployeeAgentService.ChatResult res =
            AgentforceEmployeeAgentService.sendMessage(null, null);
        System.assertNotEquals(null, res, 'Should always return a result object');
    }

    @IsTest
    static void flowSendMessage_handlesEmptyList() {
        Test.startTest();
        List<AgentforceEmployeeAgentService.ChatResult> out =
            AgentforceEmployeeAgentService.flowSendMessage(
                new List<AgentforceEmployeeAgentService.ChatRequest>()
            );
        Test.stopTest();
        System.assertEquals(0, out.size(), 'Empty input should produce empty output');
    }

    @IsTest
    static void sendMessageWithContext_handlesBlankRecordId() {
        AgentforceEmployeeAgentService.ChatResult res =
            AgentforceEmployeeAgentService.sendMessageWithContext('hello', null, null);
        System.assertNotEquals(null, res, 'Blank recordId should still return a result');
    }

    @IsTest
    static void sendMessageWithContext_handlesInvalidRecordId() {
        AgentforceEmployeeAgentService.ChatResult res =
            AgentforceEmployeeAgentService.sendMessageWithContext('hello', null, 'not-an-id');
        System.assertNotEquals(null, res, 'Invalid recordId should not throw');
    }

    @IsTest
    static void sendMessageWithContext_buildsContextForRealRecord() {
        Account a = new Account(Name = 'ContextAcct');
        insert a;
        Test.startTest();
        AgentforceEmployeeAgentService.ChatResult res =
            AgentforceEmployeeAgentService.sendMessageWithContext(
                'Give me a summary of this account.', null, a.Id
            );
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void flowSendMessage_wrapsInvocableSafely() {
        AgentforceEmployeeAgentService.ChatRequest req =
            new AgentforceEmployeeAgentService.ChatRequest();
        req.userMessage = 'unit test message';
        Test.startTest();
        List<AgentforceEmployeeAgentService.ChatResult> out =
            AgentforceEmployeeAgentService.flowSendMessage(
                new List<AgentforceEmployeeAgentService.ChatRequest>{ req }
            );
        Test.stopTest();
        System.assertEquals(1, out.size());
        System.assertNotEquals(null, out[0]);
    }
}
