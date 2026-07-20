global with sharing class SmartIntakeSaveByContextAction {
    global class Request {
        @InvocableVariable(label='Intake Session Id' description='Current SmartIntake session id. Pass from the latest SmartIntake action output.')
        global String intakeSessionId;

        @InvocableVariable(label='Agent Session Key' description='Stable agent session key if available. Pass automatically from session context.')
        global String agentSessionKey;

        @InvocableVariable(label='Template Key' description='Legacy builder compatibility field. Leave blank when SmartIntake resolves the template from context.')
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Route key for SmartIntake. Set from $Context.Current_Page so Apex can resolve the template from routing metadata.')
        global String smartIntakeContextKey;

        @InvocableVariable(label='Routable Id' description='Messaging session or voice call record id. Pass from system context when available.')
        global String routableId;

        @InvocableVariable(label='Answers JSON' description='Current accumulated answers JSON. Pass from the latest SmartIntake action output.')
        global String answersJson;

        @InvocableVariable(label='Confirmed' description='True only after the user has confirmed the final answers.')
        global Boolean confirmed;

        @InvocableVariable(label='Consent Accepted' description='True only after the user has accepted required consent.')
        global Boolean consentAccepted;
    }

    @InvocableMethod(
        label='SmartIntake - Save Final Intake Record By Context'
        description='Creates the configured Salesforce record after resolving the SmartIntake template from context or session.'
    )
    global static List<SmartIntakeDTO.IntakeResponse> invoke(List<Request> requests) {
        List<SmartIntakeDTO.IntakeResponse> responses = new List<SmartIntakeDTO.IntakeResponse>();
        for (Request request : requests) {
            SmartIntakeDTO.SaveFinalRequest saveRequest = new SmartIntakeDTO.SaveFinalRequest();
            if (request != null) {
                saveRequest.intakeSessionId = request.intakeSessionId;
                saveRequest.agentSessionKey = request.agentSessionKey;
                saveRequest.templateKey = request.templateKey;
                saveRequest.smartIntakeContextKey = request.smartIntakeContextKey;
                saveRequest.routableId = request.routableId;
                saveRequest.answersJson = request.answersJson;
                saveRequest.confirmed = request.confirmed;
                saveRequest.consentAccepted = request.consentAccepted;
            }
            responses.add(SmartIntakeService.saveFinal(saveRequest));
        }
        return responses;
    }
}