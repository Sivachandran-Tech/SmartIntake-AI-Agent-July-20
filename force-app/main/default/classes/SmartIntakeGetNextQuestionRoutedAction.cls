global with sharing class SmartIntakeGetNextQuestionRoutedAction {
    @InvocableMethod(
        label='SmartIntake - Get Next Intake Question Routed'
        description='Returns the next metadata-driven SmartIntake question and can resolve the template from page, channel, or deployment context.'
    )
    global static List<SmartIntakeDTO.IntakeResponse> invoke(List<SmartIntakeDTO.GetNextQuestionRequest> requests) {
        List<SmartIntakeDTO.IntakeResponse> responses = new List<SmartIntakeDTO.IntakeResponse>();
        for (SmartIntakeDTO.GetNextQuestionRequest request : requests) {
            responses.add(SmartIntakeService.getNextQuestion(request));
        }
        return responses;
    }
}