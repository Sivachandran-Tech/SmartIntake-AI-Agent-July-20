global with sharing class SmartIntakeValidateAnswerAction {
    @InvocableMethod(
        label='SmartIntake - Validate Answer'
        description='Validates one SmartIntake answer using metadata-driven validation rules.'
    )
    global static List<SmartIntakeDTO.ValidateAnswerResponse> invoke(List<SmartIntakeDTO.ValidateAnswerRequest> requests) {
        List<SmartIntakeDTO.ValidateAnswerResponse> responses = new List<SmartIntakeDTO.ValidateAnswerResponse>();
        for (SmartIntakeDTO.ValidateAnswerRequest request : requests) {
            responses.add(SmartIntakeService.validateIntakeAnswer(request));
        }
        return responses;
    }
}