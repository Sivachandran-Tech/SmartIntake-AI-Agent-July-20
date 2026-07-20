global with sharing class SmartIntakeSubmitByContextAction {
    global class Request {
        @InvocableVariable(label='Intake Session Id' description='Current SmartIntake session id. Pass from the latest SmartIntake action output.')
        global String intakeSessionId;

        @InvocableVariable(label='Agent Session Key' description='Stable agent session key if available. Pass automatically from session context.')
        global String agentSessionKey;

        @InvocableVariable(label='Template Key' description='Legacy builder compatibility field. Leave blank when SmartIntake resolves the template from context.')
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Route key for SmartIntake. Set from $Context.Current_Page so Apex can resolve the template from routing metadata.')
        global String smartIntakeContextKey;

        @InvocableVariable(label='Answer Value' description='The user answer to the currently displayed SmartIntake question. Optional when Proposed Answers JSON contains the current question key.')
        global String answerValue;

        @InvocableVariable(label='Change Question Key' description='Exact SmartIntake questionKey selected by Agentforce when the user wants to revise a final-review answer but has not provided a replacement value. Use only keys from the latest final-review currentQuestion or answerCapturePlanJson.')
        global String changeQuestionKey;

        @InvocableVariable(label='Proposed Answers JSON' description='AI-extracted answer map keyed only by exact SmartIntake questionKey values from answerCapturePlanJson. Do not invent semantic keys such as email, phone, product_id, or serial. Include all configured answers found in the latest user message, including future questions. Apex accepts only metadata-valid keys, stores future answers as pending, and applies them in configured order.')
        global String proposedAnswersJson;

        @InvocableVariable(label='Answer Capture' description='Structured answer capture returned by the previous SmartIntake action.')
        global SmartIntakeAnswerCapture answerCapture;

        @InvocableVariable(label='Answers JSON' description='Current accumulated answers JSON. Pass from the latest SmartIntake action output.')
        global String answersJson;

        @InvocableVariable(label='Routable Id' description='Messaging session or voice call record id. Pass from system context when available.')
        global String routableId;
    }

    @InvocableMethod(
        label='SmartIntake - Submit Current Intake Answer By Context'
        description='Stores the current answer and optional AI-extracted answers for future configured questions. Resolves the SmartIntake template from context, session, routable record, or default route.'
    )
    global static List<SmartIntakeDTO.IntakeResponse> invoke(List<Request> requests) {
        List<SmartIntakeDTO.IntakeResponse> responses = new List<SmartIntakeDTO.IntakeResponse>();
        for (Request request : requests) {
            SmartIntakeDTO.SubmitCurrentAnswerRequest submitRequest = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
            if (request != null) {
                submitRequest.intakeSessionId = request.intakeSessionId;
                submitRequest.agentSessionKey = request.agentSessionKey;
                submitRequest.templateKey = request.templateKey;
                submitRequest.smartIntakeContextKey = request.smartIntakeContextKey;
                submitRequest.answerValue = request.answerValue;
                submitRequest.changeQuestionKey = request.changeQuestionKey;
                submitRequest.proposedAnswersJson = request.proposedAnswersJson;
                submitRequest.answerCapture = request.answerCapture;
                submitRequest.answersJson = request.answersJson;
                submitRequest.routableId = request.routableId;
            }
            responses.add(SmartIntakeService.submitCurrentAnswer(submitRequest));
        }
        return responses;
    }
}