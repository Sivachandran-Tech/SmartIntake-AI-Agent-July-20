global with sharing class SmartIntakeGetNextByContextAction {
    global class Request {
        @InvocableVariable(label='Intake Session Id' description='Unique session identifier. Pass from previous action output to resume the same intake session.')
        global String intakeSessionId;

        @InvocableVariable(label='Template Key' description='Legacy builder compatibility field. Leave blank when SmartIntake resolves the template from context.')
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or routing context key used to resolve the metadata template. Map this from $Context.Current_Page or Current Page. Do not ask the user.')
        global String smartIntakeContextKey;

        @InvocableVariable(label='Current Question Key' description='Key of the current question being presented. Pass from previous response when available.')
        global String currentQuestionKey;

        @InvocableVariable(label='Answers JSON' description='Carries collected answers across turns. Pass from previous action output when available.')
        global String answersJson;

        @InvocableVariable(label='Routable Id' description='The MessagingSession Id or voice call Id. Pass when available.')
        global String routableId;
    }

    @InvocableMethod(
        label='SmartIntake - Get Next Intake Question By Context'
        description='Returns the next metadata-driven SmartIntake question and resolves the template only from page, channel, session, routable, or default context.'
    )
    global static List<SmartIntakeDTO.IntakeResponse> invoke(List<Request> requests) {
        List<SmartIntakeDTO.IntakeResponse> responses = new List<SmartIntakeDTO.IntakeResponse>();
        if (requests == null || requests.isEmpty()) {
            requests = new List<Request>{ new Request() };
        }
        for (Request request : requests) {
            SmartIntakeDTO.GetNextQuestionRequest routedRequest = new SmartIntakeDTO.GetNextQuestionRequest();
            if (request != null) {
                routedRequest.intakeSessionId = request.intakeSessionId;
                routedRequest.templateKey = request.templateKey;
                routedRequest.smartIntakeContextKey = request.smartIntakeContextKey;
                routedRequest.currentQuestionKey = request.currentQuestionKey;
                routedRequest.answersJson = request.answersJson;
                routedRequest.routableId = request.routableId;
            }
            responses.add(SmartIntakeService.getNextQuestion(routedRequest));
        }
        return responses;
    }
}