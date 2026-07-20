global with sharing class SmartIntakeTurnInterpreterAction {
    private static final String PROMPT_TEMPLATE_API_NAME = 'SmartIntake_Turn_Interpreter';

    @TestVisible
    private static String testInterpretationJson;

    @TestVisible
    private static String testResolvedPrompt;

    @TestVisible
    private static String testErrorMessage;

    global class Request {
        @InvocableVariable(label='Latest User Message' description='Latest customer message to interpret.')
        global String latestUserMessage;

        @InvocableVariable(label='Current Question JSON' description='JSON for the currently active SmartIntake question.')
        global String currentQuestionJson;

        @InvocableVariable(label='Answer Capture Plan JSON' description='JSON list of configured answer slots and semantic hints.')
        global String answerCapturePlanJson;

        @InvocableVariable(label='Conversation State JSON' description='Current SmartIntake flow state JSON, including pending confirmation and final review state when present.')
        global String conversationStateJson;

        @InvocableVariable(label='Answers JSON' description='Current accumulated SmartIntake answers JSON.')
        global String answersJson;

        @InvocableVariable(label='Pending Confirmation' description='True when the latest SmartIntake state is waiting for a confirmation answer.')
        global Boolean pendingConfirmation;

        @InvocableVariable(label='Renderer Mode' description='Renderer mode returned by SmartIntake, such as TEXT, CUSTOM_LWC, LIGHTNING_INPUT, OPTIONS, or PENDING_CONFIRMATION.')
        global String rendererMode;

        @InvocableVariable(label='Recommended Next Step' description='Recommended next SmartIntake step returned by Apex.')
        global String recommendedNextStep;

        @InvocableVariable(label='Requires Final Confirmation' description='True when SmartIntake is waiting on final review confirmation.')
        global Boolean requiresFinalConfirmation;

        @InvocableVariable(label='Recent Messages JSON' description='Recent chat history needed for context.')
        global String recentMessagesJson;
    }

    global class Response {
        @InvocableVariable(label='Interpretation JSON' description='Strict JSON returned by the SmartIntake Turn Interpreter prompt template.')
        global String interpretationJson;

        @InvocableVariable(label='Resolved Prompt' description='Resolved prompt text used by Prompt Builder. For debug only.')
        global String resolvedPrompt;

        @InvocableVariable(label='Error Message' description='Prompt Builder or generation error, if the interpreter could not run.')
        global String errorMessage;

        @InvocableVariable(label='Success' description='True when Prompt Builder returned a generated interpretation.')
        global Boolean success;
    }

    @InvocableMethod(
        label='SmartIntake - Interpret Turn With Prompt Template'
        description='Calls the generic SmartIntake_Turn_Interpreter Prompt Builder template to classify the latest user turn. Does not perform SmartIntake business logic.'
    )
    global static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            requests = new List<Request>{ new Request() };
        }

        for (Request request : requests) {
            responses.add(runInterpreter(request));
        }
        return responses;
    }

    @TestVisible
    private static Response runInterpreter(Request request) {
        Response response = new Response();
        response.success = false;

        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.isPreview = false;
            input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName = 'SmartIntake';
            input.inputParams = buildInputParams(request);

            if (Test.isRunningTest() && testInterpretationJson != null) {
                response.resolvedPrompt = testResolvedPrompt;
                response.interpretationJson = testInterpretationJson;
                response.errorMessage = testErrorMessage;
            } else {
                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
                    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(PROMPT_TEMPLATE_API_NAME, input);

                response.resolvedPrompt = output == null ? null : output.prompt;
                response.interpretationJson = firstGeneratedText(output);
                response.errorMessage = firstGenerationError(output);
            }
            response.success = String.isNotBlank(response.interpretationJson);
        } catch (Exception ex) {
            response.errorMessage = ex.getMessage();
        }

        return response;
    }

    @TestVisible
    private static Map<String, ConnectApi.WrappedValue> buildInputParams(Request request) {
        Map<String, ConnectApi.WrappedValue> values = new Map<String, ConnectApi.WrappedValue>();
        values.put('Input:LatestUserMessage', wrap(request == null ? null : request.latestUserMessage));
        values.put('Input:CurrentQuestionJson', wrap(request == null ? null : request.currentQuestionJson));
        values.put('Input:AnswerCapturePlanJson', wrap(request == null ? null : request.answerCapturePlanJson));
        values.put('Input:ConversationStateJson', wrap(conversationStateJson(request)));
        values.put('Input:RecentMessagesJson', wrap(request == null ? null : request.recentMessagesJson));
        return values;
    }

    private static String conversationStateJson(Request request) {
        if (request == null) {
            return null;
        }
        Map<String, Object> state = new Map<String, Object>();
        putIfPresent(state, 'conversationStateJson', request.conversationStateJson);
        putIfPresent(state, 'answersJson', request.answersJson);
        putIfPresent(state, 'pendingConfirmation', request.pendingConfirmation);
        putIfPresent(state, 'rendererMode', request.rendererMode);
        putIfPresent(state, 'recommendedNextStep', request.recommendedNextStep);
        putIfPresent(state, 'requiresFinalConfirmation', request.requiresFinalConfirmation);
        return JSON.serialize(state);
    }

    private static void putIfPresent(Map<String, Object> values, String key, Object value) {
        if (value != null) {
            values.put(key, value);
        }
    }

    @TestVisible
    private static ConnectApi.WrappedValue wrap(String value) {
        ConnectApi.WrappedValue wrappedValue = new ConnectApi.WrappedValue();
        wrappedValue.value = String.isBlank(value) ? '' : value;
        return wrappedValue;
    }

    @TestVisible
    private static String firstGeneratedText(ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output) {
        if (output == null || output.generations == null || output.generations.isEmpty()) {
            return null;
        }
        ConnectApi.EinsteinLLMGenerationItemOutput firstGeneration = output.generations[0];
        return firstGeneration == null ? null : firstGeneration.text;
    }

    @TestVisible
    private static String firstGenerationError(ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output) {
        if (output == null || output.generationErrors == null || output.generationErrors.isEmpty()) {
            return null;
        }
        ConnectApi.EinsteinPromptTemplateGenerationsError firstError = output.generationErrors[0];
        if (firstError == null) {
            return null;
        }
        if (String.isNotBlank(firstError.localizedErrorMessage)) {
            return firstError.localizedErrorMessage;
        }
        return firstError.errorMessage;
    }
}