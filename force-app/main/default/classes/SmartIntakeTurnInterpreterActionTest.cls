@IsTest
private class SmartIntakeTurnInterpreterActionTest {
    @IsTest
    static void invokeHandlesPromptBuilderErrorsWithoutThrowing() {
        SmartIntakeTurnInterpreterAction.Request request = new SmartIntakeTurnInterpreterAction.Request();
        request.latestUserMessage = 'hello';
        request.currentQuestionJson = '{"questionKey":"Q1","questionText":"What is your name?"}';
        request.answerCapturePlanJson = '[{"questionKey":"Q1","questionText":"What is your name?"}]';
        request.conversationStateJson = '{"phase":"question"}';
        request.recentMessagesJson = '[]';

        Test.startTest();
        List<SmartIntakeTurnInterpreterAction.Response> responses =
            SmartIntakeTurnInterpreterAction.invoke(new List<SmartIntakeTurnInterpreterAction.Request>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'The invocable action must return one response per request.');
        System.assertNotEquals(null, responses[0].success, 'Success flag should always be populated.');
    }

    @IsTest
    static void invokeReturnsInjectedPromptInterpretationInTests() {
        SmartIntakeTurnInterpreterAction.testInterpretationJson =
            '{"intent":"SIDE_CHAT","shouldSubmit":false,"assistantMessage":"Hi. I can help with that."}';
        SmartIntakeTurnInterpreterAction.testResolvedPrompt = 'resolved prompt';
        SmartIntakeTurnInterpreterAction.testErrorMessage = null;

        SmartIntakeTurnInterpreterAction.Request request = new SmartIntakeTurnInterpreterAction.Request();
        request.latestUserMessage = 'how are you?';
        request.currentQuestionJson = '{"questionKey":"EMAIL","questionText":"Email?","inputType":"EMAIL"}';
        request.answerCapturePlanJson = '[{"questionKey":"EMAIL"}]';
        request.answersJson = '{"EMAIL":"existing@example.com"}';
        request.pendingConfirmation = true;
        request.rendererMode = 'PENDING_CONFIRMATION';
        request.recommendedNextStep = 'RENDER_CURRENT_QUESTION';
        request.requiresFinalConfirmation = false;
        request.recentMessagesJson = '[]';

        List<SmartIntakeTurnInterpreterAction.Response> responses =
            SmartIntakeTurnInterpreterAction.invoke(new List<SmartIntakeTurnInterpreterAction.Request>{ request });

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
        System.assertEquals(SmartIntakeTurnInterpreterAction.testInterpretationJson, responses[0].interpretationJson);
        System.assertEquals('resolved prompt', responses[0].resolvedPrompt);

        Map<String, ConnectApi.WrappedValue> params = SmartIntakeTurnInterpreterAction.buildInputParams(request);
        System.assertEquals('how are you?', params.get('Input:LatestUserMessage').value);
        System.assert(String.valueOf(params.get('Input:CurrentQuestionJson').value).contains('"questionKey":"EMAIL"'));
        System.assert(String.valueOf(params.get('Input:ConversationStateJson').value).contains('"pendingConfirmation":true'));
        System.assertEquals('', SmartIntakeTurnInterpreterAction.wrap(null).value);
        System.assertEquals(null, SmartIntakeTurnInterpreterAction.firstGeneratedText(null));
        System.assertEquals(null, SmartIntakeTurnInterpreterAction.firstGenerationError(null));
    }

    @IsTest
    static void invokeCreatesDefaultRequestForEmptyInput() {
        SmartIntakeTurnInterpreterAction.testInterpretationJson =
            '{"intent":"START_OR_ACK","shouldSubmit":false,"assistantMessage":"Let us continue."}';

        List<SmartIntakeTurnInterpreterAction.Response> responses =
            SmartIntakeTurnInterpreterAction.invoke(new List<SmartIntakeTurnInterpreterAction.Request>());

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
    }
}