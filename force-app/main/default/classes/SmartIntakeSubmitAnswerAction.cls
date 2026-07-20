global with sharing class SmartIntakeSubmitAnswerAction {
    @InvocableMethod(
        label='SmartIntake - Submit Intake Answer'
        description='Validates and stores the current answer in the SmartIntake answer JSON, then returns the next question.'
    )
    global static List<SmartIntakeDTO.IntakeResponse> invoke(List<SmartIntakeDTO.SubmitAnswerRequest> requests) {
        List<SmartIntakeDTO.IntakeResponse> responses = new List<SmartIntakeDTO.IntakeResponse>();
        for (SmartIntakeDTO.SubmitAnswerRequest request : requests) {
            responses.add(SmartIntakeService.submitAnswer(request));
        }
        return responses;
    }
}