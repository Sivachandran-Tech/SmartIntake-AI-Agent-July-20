global with sharing class SmartIntakeSubmitCurrentAnswerAction {
    @InvocableMethod(
        label='SmartIntake - Submit Current Intake Answer'
        description='Stores the answer for the current metadata-driven SmartIntake session question without letting the agent choose the question key.'
    )
    global static List<SmartIntakeDTO.IntakeResponse> invoke(List<SmartIntakeDTO.SubmitCurrentAnswerRequest> requests) {
        List<SmartIntakeDTO.IntakeResponse> responses = new List<SmartIntakeDTO.IntakeResponse>();
        for (SmartIntakeDTO.SubmitCurrentAnswerRequest request : requests) {
            responses.add(SmartIntakeService.submitCurrentAnswer(request));
        }
        return responses;
    }
}