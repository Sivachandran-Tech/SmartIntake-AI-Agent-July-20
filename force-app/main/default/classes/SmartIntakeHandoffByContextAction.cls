global with sharing class SmartIntakeHandoffByContextAction {
    global class Request {
        @InvocableVariable(label='Intake Session Id' description='Current SmartIntake session id. Pass from the latest SmartIntake action output.')
        global String intakeSessionId;

        @InvocableVariable(label='SmartIntake Context Key' description='Route key for SmartIntake. Set from $Context.Current_Page so Apex can resolve the template from routing metadata.')
        global String smartIntakeContextKey;

        @InvocableVariable(label='Handoff Reason' description='Reason the user or agent is requesting human handoff.')
        global String reason;

        @InvocableVariable(label='Consent Accepted' description='True if the user already accepted consent to share intake context with a human agent.')
        global Boolean consentAccepted;

        @InvocableVariable(label='Context Summary JSON' description='JSON summary of the intake answers and context to share during handoff.')
        global String contextSummaryJson;
    }

    @InvocableMethod(
        label='SmartIntake - Get Handoff Plan By Context'
        description='Returns the metadata-driven handoff plan after resolving the SmartIntake template from context or session.'
    )
    global static List<SmartIntakeDTO.HandoffPlanResponse> invoke(List<Request> requests) {
        List<SmartIntakeDTO.HandoffPlanResponse> responses = new List<SmartIntakeDTO.HandoffPlanResponse>();
        for (Request request : requests) {
            SmartIntakeDTO.HandoffPlanRequest handoffRequest = new SmartIntakeDTO.HandoffPlanRequest();
            if (request != null) {
                handoffRequest.intakeSessionId = request.intakeSessionId;
                handoffRequest.smartIntakeContextKey = request.smartIntakeContextKey;
                handoffRequest.reason = request.reason;
                handoffRequest.consentAccepted = request.consentAccepted;
                handoffRequest.contextSummaryJson = request.contextSummaryJson;
            }
            responses.add(SmartIntakeService.getHandoffPlan(handoffRequest));
        }
        return responses;
    }
}