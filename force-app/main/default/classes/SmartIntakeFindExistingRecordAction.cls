global with sharing class SmartIntakeFindExistingRecordAction {
    @InvocableMethod(
        label='SmartIntake - Find Existing Record'
        description='Finds an existing CRM record using SmartIntake matching metadata.'
    )
    global static List<SmartIntakeDTO.FindExistingRecordResponse> invoke(List<SmartIntakeDTO.FindExistingRecordRequest> requests) {
        List<SmartIntakeDTO.FindExistingRecordResponse> responses = new List<SmartIntakeDTO.FindExistingRecordResponse>();
        for (SmartIntakeDTO.FindExistingRecordRequest request : requests) {
            responses.add(SmartIntakeService.findExistingRecord(request));
        }
        return responses;
    }
}