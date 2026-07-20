global with sharing class SmartIntakeGetExistingContextAction {
    @InvocableMethod(
        label='SmartIntake - Get Existing Context'
        description='Returns only the existing CRM context configured for the current SmartIntake question.'
    )
    global static List<SmartIntakeDTO.ExistingContextResponse> invoke(List<SmartIntakeDTO.GetExistingContextRequest> requests) {
        List<SmartIntakeDTO.ExistingContextResponse> responses = new List<SmartIntakeDTO.ExistingContextResponse>();
        for (SmartIntakeDTO.GetExistingContextRequest request : requests) {
            responses.add(SmartIntakeService.getExistingContext(request));
        }
        return responses;
    }
}