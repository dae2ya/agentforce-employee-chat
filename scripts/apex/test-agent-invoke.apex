Invocable.Action action = Invocable.Action.createCustomAction('generateAiAgentResponse', 'NotebookAIAgent');
action.setInvocationParameter('userMessage', '안녕하세요, 테스트 메시지입니다.');
List<Invocable.Action.Result> results = action.invoke();
for (Invocable.Action.Result r : results) {
    System.debug('Success: ' + r.isSuccess());
    System.debug('Errors: ' + r.getErrors());
    Map<String, Object> out = r.getOutputParameters();
    System.debug('Output keys: ' + (out == null ? null : out.keySet()));
    System.debug('Output JSON: ' + JSON.serializePretty(out));
}
