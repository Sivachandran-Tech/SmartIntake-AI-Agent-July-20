global with sharing class SmartIntakeGetNextQuestionAction {
    @InvocableMethod(
        label='SmartIntake - Get Next Intake Question'
        description='Returns the next metadata-driven SmartIntake question for the current session.'
    )
    global static List<SmartIntakeDTO.IntakeResponse> invoke(List<SmartIntakeDTO.GetNextQuestionRequest> requests) {
        List<SmartIntakeDTO.IntakeResponse> responses = new List<SmartIntakeDTO.IntakeResponse>();
        for (SmartIntakeDTO.GetNextQuestionRequest request : requests) {
            responses.add(SmartIntakeService.getNextQuestion(request));
        }
        return responses;
    }
}