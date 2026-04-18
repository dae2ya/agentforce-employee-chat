@IsTest
private class AgentforceChatInjectRestTest {
    private static RestRequest buildRequest(String body) {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/agentforce/inject';
        req.addHeader('Content-Type', 'application/json');
        if (body != null) {
            req.requestBody = Blob.valueOf(body);
        }
        return req;
    }

    @IsTest
    static void rejectsEmptyBody() {
        RestContext.request = buildRequest(null);
        RestContext.response = new RestResponse();

        Test.startTest();
        AgentforceChatInjectRest.InjectResponse resp =
            AgentforceChatInjectRest.inject();
        Test.stopTest();

        System.assertEquals(false, resp.success);
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void rejectsMissingMessage() {
        RestContext.request = buildRequest('{"targetCardTitle":"X"}');
        RestContext.response = new RestResponse();

        Test.startTest();
        AgentforceChatInjectRest.InjectResponse resp =
            AgentforceChatInjectRest.inject();
        Test.stopTest();

        System.assertEquals(false, resp.success);
        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(resp.error.containsIgnoreCase('message'));
    }

    @IsTest
    static void rejectsInvalidJson() {
        RestContext.request = buildRequest('not json');
        RestContext.response = new RestResponse();

        Test.startTest();
        AgentforceChatInjectRest.InjectResponse resp =
            AgentforceChatInjectRest.inject();
        Test.stopTest();

        System.assertEquals(false, resp.success);
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void publishesEventOnSuccess() {
        String body = JSON.serialize(new Map<String, Object>{
            'message' => 'Hello from legacy',
            'targetCardTitle' => 'Agentforce Employee Agent',
            'sessionId' => null,
            'sourceSystem' => 'UnitTest'
        });
        RestContext.request = buildRequest(body);
        RestContext.response = new RestResponse();

        Test.startTest();
        AgentforceChatInjectRest.InjectResponse resp =
            AgentforceChatInjectRest.inject();
        Test.stopTest();

        System.assertEquals(true, resp.success);
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertNotEquals(null, resp.eventReplayId);
    }

    @IsTest
    static void rejectsInvalidRole() {
        String body = JSON.serialize(new Map<String, Object>{
            'message' => 'hi',
            'role' => 'system'
        });
        RestContext.request = buildRequest(body);
        RestContext.response = new RestResponse();

        Test.startTest();
        AgentforceChatInjectRest.InjectResponse resp =
            AgentforceChatInjectRest.inject();
        Test.stopTest();

        System.assertEquals(false, resp.success);
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void acceptsAgentRole() {
        String body = JSON.serialize(new Map<String, Object>{
            'message' => 'Injected as agent',
            'role' => 'agent'
        });
        RestContext.request = buildRequest(body);
        RestContext.response = new RestResponse();

        Test.startTest();
        AgentforceChatInjectRest.InjectResponse resp =
            AgentforceChatInjectRest.inject();
        Test.stopTest();

        System.assertEquals(true, resp.success);
    }

    @IsTest
    static void defaultsMissingSourceSystem() {
        String body = JSON.serialize(new Map<String, Object>{
            'message' => 'Ping'
        });
        RestContext.request = buildRequest(body);
        RestContext.response = new RestResponse();

        Test.startTest();
        AgentforceChatInjectRest.InjectResponse resp =
            AgentforceChatInjectRest.inject();
        Test.stopTest();

        System.assertEquals(true, resp.success);
    }
}
