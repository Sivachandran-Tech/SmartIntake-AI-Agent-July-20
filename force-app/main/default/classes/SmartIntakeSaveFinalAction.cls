global with sharing class SmartIntakeSaveFinalAction {
    @InvocableMethod(
        label='SmartIntake - Save Final Intake Record'
        description='Creates the configured SmartIntake target record after confirmation and required-answer validation.'
    )
    global static List<SmartIntakeDTO.IntakeResponse> invoke(List<SmartIntakeDTO.SaveFinalRequest> requests) {
        List<SmartIntakeDTO.IntakeResponse> responses = new List<SmartIntakeDTO.IntakeResponse>();
        for (SmartIntakeDTO.SaveFinalRequest request : requests) {
            responses.add(SmartIntakeService.saveFinal(request));
        }
        return responses;
    }
}