@IsTest
public class SmartIntakeTestDataFactory {
    public static final String TEMPLATE_KEY = 'HOTEL_BOOKING_BASIC_V1';

    public static void assignRuntimePermissionSet() {
        PermissionSet runtimePermissionSet = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'SmartIntake_Runtime'
            LIMIT 1
        ];
        Integer existingAssignments = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
              AND PermissionSetId = :runtimePermissionSet.Id
        ];
        if (existingAssignments > 0) {
            return;
        }
        insert new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = runtimePermissionSet.Id
        );
    }

    public static SmartIntakeDTO.GetNextQuestionRequest getNextRequest() {
        SmartIntakeDTO.GetNextQuestionRequest request = new SmartIntakeDTO.GetNextQuestionRequest();
        request.templateKey = TEMPLATE_KEY;
        request.answersJson = '{}';
        return request;
    }

    public static SmartIntakeDTO.GetNextQuestionRequest getNextRequestWithSession(String sessionId) {
        SmartIntakeDTO.GetNextQuestionRequest request = getNextRequest();
        request.intakeSessionId = sessionId;
        return request;
    }

    public static SmartIntakeDTO.SubmitAnswerRequest submitRequest(String questionKey, String answerValue, String answersJson) {
        SmartIntakeDTO.SubmitAnswerRequest request = new SmartIntakeDTO.SubmitAnswerRequest();
        request.templateKey = TEMPLATE_KEY;
        request.questionKey = questionKey;
        request.answerValue = answerValue;
        request.answersJson = answersJson;
        return request;
    }

    public static SmartIntakeDTO.SubmitAnswerRequest submitRequestWithSession(
        String sessionId,
        String questionKey,
        String answerValue,
        String answersJson
    ) {
        SmartIntakeDTO.SubmitAnswerRequest request = submitRequest(questionKey, answerValue, answersJson);
        request.intakeSessionId = sessionId;
        return request;
    }

    public static SmartIntakeDTO.SubmitCurrentAnswerRequest submitCurrentRequestWithSession(
        String sessionId,
        String answerValue,
        String answersJson
    ) {
        SmartIntakeDTO.SubmitCurrentAnswerRequest request = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
        request.intakeSessionId = sessionId;
        request.templateKey = TEMPLATE_KEY;
        request.answerValue = answerValue;
        request.answersJson = answersJson;
        return request;
    }

    public static SmartIntakeDTO.SubmitCurrentAnswerRequest submitCurrentRequestWithAgentSession(
        String agentSessionKey,
        String answerValue
    ) {
        SmartIntakeDTO.SubmitCurrentAnswerRequest request = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
        request.agentSessionKey = agentSessionKey;
        request.templateKey = TEMPLATE_KEY;
        request.answerValue = answerValue;
        return request;
    }

    public static SmartIntakeDTO.ValidateAnswerRequest validateRequest(String questionKey, String answerValue) {
        SmartIntakeDTO.ValidateAnswerRequest request = new SmartIntakeDTO.ValidateAnswerRequest();
        request.templateKey = TEMPLATE_KEY;
        request.questionKey = questionKey;
        request.answerValue = answerValue;
        request.answersJson = '{}';
        return request;
    }

    public static SmartIntakeDTO.SaveFinalRequest finalSaveRequest(String answersJson) {
        SmartIntakeDTO.SaveFinalRequest request = new SmartIntakeDTO.SaveFinalRequest();
        request.templateKey = TEMPLATE_KEY;
        request.answersJson = answersJson;
        request.confirmed = true;
        request.consentAccepted = true;
        return request;
    }

    public static SmartIntakeDTO.SaveFinalRequest finalSaveRequestWithSession(String sessionId, String answersJson) {
        SmartIntakeDTO.SaveFinalRequest request = finalSaveRequest(answersJson);
        request.intakeSessionId = sessionId;
        return request;
    }

    public static SmartIntakeDTO.NavigateRequest navigateRequest(String sessionId, String questionKey, String answersJson) {
        SmartIntakeDTO.NavigateRequest request = new SmartIntakeDTO.NavigateRequest();
        request.intakeSessionId = sessionId;
        request.templateKey = TEMPLATE_KEY;
        request.questionKey = questionKey;
        request.answersJson = answersJson;
        return request;
    }

    public static SmartIntakeDTO.FindExistingRecordRequest findExistingRequest(String matchFieldKey, String matchValue) {
        SmartIntakeDTO.FindExistingRecordRequest request = new SmartIntakeDTO.FindExistingRecordRequest();
        request.templateKey = TEMPLATE_KEY;
        request.matchFieldKey = matchFieldKey;
        request.matchValue = matchValue;
        request.answersJson = '{}';
        return request;
    }

    public static SmartIntakeDTO.GetExistingContextRequest existingContextRequest(String questionKey, String answersJson) {
        SmartIntakeDTO.GetExistingContextRequest request = new SmartIntakeDTO.GetExistingContextRequest();
        request.templateKey = TEMPLATE_KEY;
        request.questionKey = questionKey;
        request.answersJson = answersJson;
        return request;
    }
}