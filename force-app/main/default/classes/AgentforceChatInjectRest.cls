/**
 * External REST endpoint for injecting messages into running employeeAgentChatCard instances.
 *
 * URL: /services/apexrest/agentforce/inject
 * Method: POST
 * Body:
 * {
 *   "message": "required text to inject as user message",
 *   "targetCardTitle": "optional - match cardTitle on Chat Card",
 *   "sessionId": "optional - match current Agentforce session id",
 *   "sourceSystem": "optional - source identifier for audit"
 * }
 *
 * Publishes an AgentforceChatInject__e Platform Event which the LWC Chat Card
 * subscribes to via lightning/empApi.
 */
@RestResource(urlMapping='/agentforce/inject/*')
global with sharing class AgentforceChatInjectRest {
    private static final Set<String> VALID_ROLES = new Set<String>{
        'agent', 'user', 'error'
    };
    private static final String DEFAULT_ROLE = 'agent';

    global class InjectRequest {
        global String message;
        global String targetCardTitle;
        global String sessionId;
        global String sourceSystem;
        // agent (default) | user | error
        global String role;
    }

    global class InjectResponse {
        global Boolean success;
        global String eventReplayId;
        global String error;
    }

    @HttpPost
    global static InjectResponse inject() {
        InjectResponse resp = new InjectResponse();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            if (req == null || req.requestBody == null) {
                return fail(resp, res, 400, 'Missing request body');
            }
            String body = req.requestBody.toString();
            if (String.isBlank(body)) {
                return fail(resp, res, 400, 'Empty request body');
            }
            InjectRequest ir;
            try {
                ir = (InjectRequest) JSON.deserialize(body, InjectRequest.class);
            } catch (Exception e) {
                return fail(resp, res, 400, 'Invalid JSON body: ' + e.getMessage());
            }
            if (ir == null || String.isBlank(ir.message)) {
                return fail(resp, res, 400, 'Field "message" is required');
            }

            String role = String.isBlank(ir.role)
                ? DEFAULT_ROLE
                : ir.role.toLowerCase();
            if (!VALID_ROLES.contains(role)) {
                return fail(
                    resp,
                    res,
                    400,
                    'Invalid "role" value. Must be one of: agent, user, error'
                );
            }

            AgentforceChatInject__e evt = new AgentforceChatInject__e(
                Message__c = ir.message,
                TargetCardTitle__c = ir.targetCardTitle,
                SessionId__c = ir.sessionId,
                SourceSystem__c = String.isBlank(ir.sourceSystem)
                    ? 'unknown'
                    : ir.sourceSystem,
                Role__c = role
            );

            Database.SaveResult sr = EventBus.publish(evt);
            if (sr.isSuccess()) {
                resp.success = true;
                resp.eventReplayId = sr.getId();
                if (res != null) res.statusCode = 200;
            } else {
                List<String> errs = new List<String>();
                for (Database.Error e : sr.getErrors()) {
                    errs.add(e.getStatusCode() + ': ' + e.getMessage());
                }
                return fail(resp, res, 500, String.join(errs, '; '));
            }
        } catch (Exception e) {
            return fail(resp, res, 500, e.getMessage());
        }
        return resp;
    }

    private static InjectResponse fail(
        InjectResponse resp,
        RestResponse res,
        Integer status,
        String message
    ) {
        resp.success = false;
        resp.error = message;
        if (res != null) res.statusCode = status;
        return resp;
    }
}
