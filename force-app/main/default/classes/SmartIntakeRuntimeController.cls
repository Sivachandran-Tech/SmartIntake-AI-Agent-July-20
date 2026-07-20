public with sharing class SmartIntakeRuntimeController {
    @AuraEnabled
    public static SmartIntakeDTO.IntakeResponse getNextQuestion(
        String intakeSessionId,
        String templateKey,
        String smartIntakeContextKey,
        String currentQuestionKey,
        String answersJson
    ) {
        SmartIntakeDTO.GetNextQuestionRequest request = new SmartIntakeDTO.GetNextQuestionRequest();
        request.intakeSessionId = intakeSessionId;
        request.templateKey = templateKey;
        request.smartIntakeContextKey = smartIntakeContextKey;
        request.currentQuestionKey = currentQuestionKey;
        request.answersJson = answersJson;
        return SmartIntakeService.getNextQuestion(request);
    }

    @AuraEnabled
    public static SmartIntakeDTO.IntakeResponse submitAnswer(
        String intakeSessionId,
        String templateKey,
        String smartIntakeContextKey,
        String questionKey,
        String answerValue,
        String answersJson
    ) {
        SmartIntakeDTO.SubmitAnswerRequest request = new SmartIntakeDTO.SubmitAnswerRequest();
        request.intakeSessionId = intakeSessionId;
        request.templateKey = templateKey;
        request.smartIntakeContextKey = smartIntakeContextKey;
        request.questionKey = questionKey;
        request.answerValue = answerValue;
        request.answersJson = answersJson;
        return SmartIntakeService.submitAnswer(request);
    }

    @AuraEnabled
    public static SmartIntakeDTO.IntakeResponse goBack(
        String intakeSessionId,
        String templateKey,
        String smartIntakeContextKey,
        String questionKey,
        String answersJson
    ) {
        SmartIntakeDTO.NavigateRequest request = new SmartIntakeDTO.NavigateRequest();
        request.intakeSessionId = intakeSessionId;
        request.templateKey = templateKey;
        request.smartIntakeContextKey = smartIntakeContextKey;
        request.questionKey = questionKey;
        request.answersJson = answersJson;
        return SmartIntakeService.goBack(request);
    }

    @AuraEnabled
    public static SmartIntakeDTO.IntakeResponse skipQuestion(
        String intakeSessionId,
        String templateKey,
        String smartIntakeContextKey,
        String questionKey,
        String answersJson
    ) {
        SmartIntakeDTO.NavigateRequest request = new SmartIntakeDTO.NavigateRequest();
        request.intakeSessionId = intakeSessionId;
        request.templateKey = templateKey;
        request.smartIntakeContextKey = smartIntakeContextKey;
        request.questionKey = questionKey;
        request.answersJson = answersJson;
        return SmartIntakeService.skipQuestion(request);
    }

    @AuraEnabled
    public static SmartIntakeDTO.IntakeResponse saveFinal(
        String intakeSessionId,
        String templateKey,
        String smartIntakeContextKey,
        String answersJson,
        Boolean confirmed,
        Boolean consentAccepted
    ) {
        SmartIntakeDTO.SaveFinalRequest request = new SmartIntakeDTO.SaveFinalRequest();
        request.intakeSessionId = intakeSessionId;
        request.templateKey = templateKey;
        request.smartIntakeContextKey = smartIntakeContextKey;
        request.answersJson = answersJson;
        request.confirmed = confirmed;
        request.consentAccepted = consentAccepted;
        return SmartIntakeService.saveFinal(request);
    }

    @AuraEnabled
    public static SmartIntakeDTO.ExistingContextResponse getExistingContext(
        String intakeSessionId,
        String templateKey,
        String questionKey,
        String recordId,
        String answersJson
    ) {
        SmartIntakeDTO.GetExistingContextRequest request = new SmartIntakeDTO.GetExistingContextRequest();
        request.intakeSessionId = intakeSessionId;
        request.templateKey = templateKey;
        request.questionKey = questionKey;
        request.recordId = recordId;
        request.answersJson = answersJson;
        return SmartIntakeService.getExistingContext(request);
    }

    @AuraEnabled
    public static SmartIntakeDTO.HandoffPlanResponse getHandoffPlan(
        String intakeSessionId,
        String templateKey,
        String reason,
        Boolean consentAccepted,
        String contextSummaryJson
    ) {
        SmartIntakeDTO.HandoffPlanRequest request = new SmartIntakeDTO.HandoffPlanRequest();
        request.intakeSessionId = intakeSessionId;
        request.templateKey = templateKey;
        request.reason = reason;
        request.consentAccepted = consentAccepted;
        request.contextSummaryJson = contextSummaryJson;
        return SmartIntakeService.getHandoffPlan(request);
    }
}