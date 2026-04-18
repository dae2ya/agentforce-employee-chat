AgentforceEmployeeAgentService.ChatResult r1 =
    AgentforceEmployeeAgentService.sendMessage('안녕, 오늘 뭐 도와줄 수 있어?', null);
System.debug('TURN1 success=' + r1.isSuccess);
System.debug('TURN1 reply=' + r1.reply);
System.debug('TURN1 sessionId=' + r1.sessionId);
System.debug('TURN1 errorMessage=' + r1.errorMessage);

if (r1.isSuccess && r1.sessionId != null) {
    AgentforceEmployeeAgentService.ChatResult r2 =
        AgentforceEmployeeAgentService.sendMessage('방금 질문을 영어로 번역해줘', r1.sessionId);
    System.debug('TURN2 success=' + r2.isSuccess);
    System.debug('TURN2 reply=' + r2.reply);
    System.debug('TURN2 sessionId=' + r2.sessionId);
}
