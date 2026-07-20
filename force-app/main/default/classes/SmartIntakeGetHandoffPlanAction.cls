global with sharing class SmartIntakeGetHandoffPlanAction {
    @InvocableMethod(
        label='SmartIntake - Get Handoff Plan'
        description='Returns the metadata-driven human handoff plan and readiness state for the current SmartIntake template.'
    )
    global static List<SmartIntakeDTO.HandoffPlanResponse> invoke(List<SmartIntakeDTO.HandoffPlanRequest> requests) {
        List<SmartIntakeDTO.HandoffPlanResponse> responses = new List<SmartIntakeDTO.HandoffPlanResponse>();
        for (SmartIntakeDTO.HandoffPlanRequest request : requests) {
            responses.add(SmartIntakeService.getHandoffPlan(request));
        }
        return responses;
    }
}