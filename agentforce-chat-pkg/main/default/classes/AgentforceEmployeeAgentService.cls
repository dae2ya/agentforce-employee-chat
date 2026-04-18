/**
 * Facade around the generateAiAgentResponse Invocable Action.
 * Exposes both AuraEnabled (LWC) and InvocableMethod (Flow) entry points.
 * The Agent API Name is sourced from a Custom Label so it can be swapped
 * without code changes once Agentforce_Employee_Agent is activated.
 */
public with sharing class AgentforceEmployeeAgentService {

    public class ChatResult {
        @AuraEnabled @InvocableVariable public String reply;
        @AuraEnabled @InvocableVariable public String sessionId;
        @AuraEnabled @InvocableVariable public Boolean isSuccess;
        @AuraEnabled @InvocableVariable public String errorMessage;
    }

    public class ChatRequest {
        @InvocableVariable(required=true label='User Message')
        public String userMessage;
        @InvocableVariable(label='Session Id')
        public String sessionId;
    }

    @AuraEnabled
    public static ChatResult sendMessage(String userMessage, String sessionId) {
        return invokeAgent(userMessage, sessionId);
    }

    @AuraEnabled
    public static ChatResult sendMessageWithContext(String userMessage, String sessionId, String recordId) {
        String outbound = userMessage;
        if (String.isNotBlank(recordId)) {
            String ctx = buildRecordContext(recordId);
            if (String.isNotBlank(ctx)) {
                outbound =
                    '[Current record context]\n' + ctx +
                    '\n\n[User question]\n' + userMessage;
            }
        }
        return invokeAgent(outbound, sessionId);
    }

    @InvocableMethod(label='Agentforce Employee Agent: Send Message' category='Agentforce')
    public static List<ChatResult> flowSendMessage(List<ChatRequest> requests) {
        List<ChatResult> results = new List<ChatResult>();
        for (ChatRequest req : requests) {
            results.add(invokeAgent(req.userMessage, req.sessionId));
        }
        return results;
    }

    private static final Set<String> CONTEXT_SKIP_FIELDS = new Set<String>{
        'systemmodstamp', 'lastreferenceddate', 'lastvieweddate',
        'lastmodifieddate', 'createddate', 'isdeleted', 'masterrecordid',
        'ownerid', 'recordtypeid', 'lastmodifiedbyid', 'createdbyid',
        'lastactivitydate', 'jigsaw', 'photourl'
    };
    private static final Integer CONTEXT_MAX_FIELDS = 50;

    private static String buildRecordContext(String recordIdStr) {
        try {
            Id rid = (Id) recordIdStr;
            Schema.SObjectType sot = rid.getSObjectType();
            if (sot == null) return null;
            Schema.DescribeSObjectResult dsr = sot.getDescribe();
            if (!dsr.isAccessible()) return null;
            String objName = dsr.getName();
            String objLabel = dsr.getLabel();
            Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();

            List<String> selectFields = new List<String>{ 'Id' };
            Map<String, Schema.DescribeFieldResult> describes =
                new Map<String, Schema.DescribeFieldResult>();
            for (String fname : fieldMap.keySet()) {
                if (selectFields.size() >= CONTEXT_MAX_FIELDS) break;
                if (fname == 'id') continue;
                if (CONTEXT_SKIP_FIELDS.contains(fname)) continue;
                Schema.DescribeFieldResult dfr = fieldMap.get(fname).getDescribe();
                if (!dfr.isAccessible()) continue;
                Schema.DisplayType t = dfr.getType();
                if (t == Schema.DisplayType.BASE64 ||
                    t == Schema.DisplayType.ENCRYPTEDSTRING ||
                    t == Schema.DisplayType.ANYTYPE) continue;
                selectFields.add(dfr.getName());
                describes.put(dfr.getName(), dfr);
            }

            String soql =
                'SELECT ' + String.join(selectFields, ', ') +
                ' FROM ' + objName + ' WHERE Id = :rid LIMIT 1';
            List<SObject> rows = Database.query(soql);
            if (rows.isEmpty()) return null;
            SObject row = rows[0];

            List<String> lines = new List<String>{ '- Object: ' + objLabel };
            for (String fname : selectFields) {
                if (fname == 'Id') continue;
                Schema.DescribeFieldResult dfr = describes.get(fname);
                if (dfr == null) continue;
                Object raw = row.get(fname);
                if (raw == null) continue;
                String s = String.valueOf(raw);
                if (String.isBlank(s)) continue;
                if (s.length() > 240) s = s.substring(0, 240) + '…';
                lines.add('- ' + dfr.getLabel() + ': ' + s);
            }
            return lines.size() > 1 ? String.join(lines, '\n') : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static ChatResult invokeAgent(String userMessage, String sessionId) {
        ChatResult result = new ChatResult();
        try {
            String agentApiName = System.Label.Agentforce_Employee_Agent_ApiName;
            Invocable.Action action = Invocable.Action.createCustomAction(
                'generateAiAgentResponse', agentApiName
            );
            action.setInvocationParameter('userMessage', userMessage);
            if (String.isNotBlank(sessionId)) {
                action.setInvocationParameter('sessionId', sessionId);
            }
            List<Invocable.Action.Result> raw = action.invoke();
            if (raw == null || raw.isEmpty()) {
                result.isSuccess = false;
                result.errorMessage = 'Empty response from agent.';
                return result;
            }
            Invocable.Action.Result r = raw[0];
            if (!r.isSuccess()) {
                result.isSuccess = false;
                result.errorMessage = String.valueOf(r.getErrors());
                return result;
            }
            Map<String, Object> out = r.getOutputParameters();
            result.sessionId = (String) out.get('sessionId');
            String rawResponse = (String) out.get('agentResponse');
            result.reply = parseAgentResponse(rawResponse);
            result.isSuccess = true;
        } catch (Exception e) {
            result.isSuccess = false;
            result.errorMessage = e.getTypeName() + ': ' + e.getMessage();
        }
        return result;
    }

    private static String parseAgentResponse(String raw) {
        if (String.isBlank(raw)) {
            return '';
        }
        try {
            Object parsed = JSON.deserializeUntyped(raw);
            if (parsed instanceof Map<String, Object>) {
                Map<String, Object> m = (Map<String, Object>) parsed;
                Object v = m.get('value');
                if (v != null) return String.valueOf(v);
            }
        } catch (Exception ignore) {
            // Fallthrough to raw string
        }
        return raw;
    }
}
