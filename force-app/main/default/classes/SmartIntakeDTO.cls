global class SmartIntakeDTO {
    global class GetNextQuestionRequest {
        @InvocableVariable(label='Intake Session Id')
        @AuraEnabled
        global String intakeSessionId;

        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or routing context key used to resolve the metadata template. ALWAYS map and pass the value of the "$Conversation.Current_Page" or "Current Page" conversation variable into this parameter. Do not ask the user.')
        @AuraEnabled
        global String smartIntakeContextKey;

        @InvocableVariable(label='Current Question Key')
        @AuraEnabled
        global String currentQuestionKey;

        @InvocableVariable(label='Answers JSON')
        @AuraEnabled
        global String answersJson;

        @InvocableVariable(label='Routable Id' description='The MessagingSession Id or voice call Id.')
        @AuraEnabled
        global String routableId;
    }

    global class SubmitAnswerRequest {
        @InvocableVariable(label='Intake Session Id')
        @AuraEnabled
        global String intakeSessionId;

        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or routing context key used to resolve the metadata template. ALWAYS map and pass the value of the "$Conversation.Current_Page" or "Current Page" conversation variable into this parameter. Do not ask the user.')
        @AuraEnabled
        global String smartIntakeContextKey;

        @InvocableVariable(label='Question Key' required=true)
        @AuraEnabled
        global String questionKey;

        @InvocableVariable(label='Answer Value')
        @AuraEnabled
        global String answerValue;

        @InvocableVariable(label='Proposed Answers JSON' description='AI-extracted answer map keyed by SmartIntake question key. Apex accepts only metadata-valid keys and applies them in configured order.')
        @AuraEnabled
        global String proposedAnswersJson;

        @InvocableVariable(label='Answers JSON')
        @AuraEnabled
        global String answersJson;

        @InvocableVariable(label='Agent Session Key')
        @AuraEnabled
        global String agentSessionKey;

        @InvocableVariable(label='Routable Id' description='The MessagingSession Id or voice call Id.')
        @AuraEnabled
        global String routableId;
    }

    global class SubmitCurrentAnswerRequest {
        @InvocableVariable(label='Intake Session Id')
        @AuraEnabled
        global String intakeSessionId;

        @InvocableVariable(label='Agent Session Key')
        @AuraEnabled
        global String agentSessionKey;

        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or routing context key used to resolve the metadata template. ALWAYS map and pass the value of the "$Conversation.Current_Page" or "Current Page" conversation variable into this parameter. Do not ask the user.')
        @AuraEnabled
        global String smartIntakeContextKey;

        @InvocableVariable(label='Answer Value')
        @AuraEnabled
        global String answerValue;

        @InvocableVariable(label='Change Question Key' description='Exact SmartIntake questionKey selected by Agentforce when the user wants to revise a final-review answer but has not provided a replacement value. Use only keys from the latest currentQuestion final-review items or answerCapturePlanJson; do not infer or invent keys in Apex.')
        @AuraEnabled
        global String changeQuestionKey;

        @InvocableVariable(label='Proposed Answers JSON' description='AI-extracted answer map keyed by SmartIntake question key. Apex accepts only metadata-valid keys and applies them in configured order.')
        @AuraEnabled
        global String proposedAnswersJson;

        @InvocableVariable(label='Answer Capture')
        @AuraEnabled
        global SmartIntakeAnswerCapture answerCapture;

        @InvocableVariable(label='Answers JSON')
        @AuraEnabled
        global String answersJson;

        @InvocableVariable(label='Routable Id' description='The MessagingSession Id or voice call Id.')
        @AuraEnabled
        global String routableId;
    }

    global class NavigateRequest {
        @InvocableVariable(label='Intake Session Id')
        @AuraEnabled
        global String intakeSessionId;

        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or deployment context key used to resolve the SmartIntake template. Do not ask the user.')
        @AuraEnabled
        global String smartIntakeContextKey;

        @InvocableVariable(label='Question Key')
        @AuraEnabled
        global String questionKey;

        @InvocableVariable(label='Answers JSON')
        @AuraEnabled
        global String answersJson;
    }

    global class ValidateAnswerRequest {
        @InvocableVariable(label='Intake Session Id')
        @AuraEnabled
        global String intakeSessionId;

        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or deployment context key used to resolve the SmartIntake template. Do not ask the user.')
        @AuraEnabled
        global String smartIntakeContextKey;

        @InvocableVariable(label='Question Key' required=true)
        @AuraEnabled
        global String questionKey;

        @InvocableVariable(label='Answer Value')
        @AuraEnabled
        global String answerValue;

        @InvocableVariable(label='Answers JSON')
        @AuraEnabled
        global String answersJson;
    }

    global class SaveFinalRequest {
        @InvocableVariable(label='Intake Session Id')
        @AuraEnabled
        global String intakeSessionId;

        @InvocableVariable(label='Agent Session Key')
        @AuraEnabled
        global String agentSessionKey;

        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or deployment context key used to resolve the SmartIntake template. Do not ask the user.')
        @AuraEnabled
        global String smartIntakeContextKey;

        @InvocableVariable(label='Routable Id' description='Messaging session or voice call record id. Pass from system context when available.')
        @AuraEnabled
        global String routableId;

        @InvocableVariable(label='Answers JSON')
        @AuraEnabled
        global String answersJson;

        @InvocableVariable(label='Confirmed')
        @AuraEnabled
        global Boolean confirmed;

        @InvocableVariable(label='Consent Accepted')
        @AuraEnabled
        global Boolean consentAccepted;
    }

    global class FindExistingRecordRequest {
        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or deployment context key used to resolve the SmartIntake template. Do not ask the user.')
        @AuraEnabled
        global String smartIntakeContextKey;

        @InvocableVariable(label='Match Field Key' required=true)
        @AuraEnabled
        global String matchFieldKey;

        @InvocableVariable(label='Match Value' required=true)
        @AuraEnabled
        global String matchValue;

        @InvocableVariable(label='Answers JSON')
        @AuraEnabled
        global String answersJson;
    }

    global class GetExistingContextRequest {
        @InvocableVariable(label='Intake Session Id')
        @AuraEnabled
        global String intakeSessionId;

        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or deployment context key used to resolve the SmartIntake template. Do not ask the user.')
        @AuraEnabled
        global String smartIntakeContextKey;

        @InvocableVariable(label='Question Key' required=true)
        @AuraEnabled
        global String questionKey;

        @InvocableVariable(label='Record Id')
        @AuraEnabled
        global String recordId;

        @InvocableVariable(label='Answers JSON')
        @AuraEnabled
        global String answersJson;
    }

    global class HandoffPlanRequest {
        @InvocableVariable(label='Intake Session Id')
        @AuraEnabled
        global String intakeSessionId;

        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='SmartIntake Context Key' description='Page, channel, or deployment context key used to resolve the SmartIntake template. Do not ask the user.')
        @AuraEnabled
        global String smartIntakeContextKey;

        @InvocableVariable(label='Handoff Reason')
        @AuraEnabled
        global String reason;

        @InvocableVariable(label='Consent Accepted')
        @AuraEnabled
        global Boolean consentAccepted;

        @InvocableVariable(label='Context Summary JSON')
        @AuraEnabled
        global String contextSummaryJson;
    }

    global class HandoffPlanResponse {
        @InvocableVariable(label='Success')
        @AuraEnabled
        global Boolean success;

        @InvocableVariable(label='Handoff Enabled')
        @AuraEnabled
        global Boolean handoffEnabled;

        @InvocableVariable(label='Handoff Ready')
        @AuraEnabled
        global Boolean handoffReady;

        @InvocableVariable(label='Provider Type')
        @AuraEnabled
        global String providerType;

        @InvocableVariable(label='Availability Status')
        @AuraEnabled
        global String availabilityStatus;

        @InvocableVariable(label='Requires Consent')
        @AuraEnabled
        global Boolean requiresConsent;

        @InvocableVariable(label='Consent Accepted')
        @AuraEnabled
        global Boolean consentAccepted;

        @InvocableVariable(label='Handoff Message')
        @AuraEnabled
        global String handoffMessage;

        @InvocableVariable(label='Trigger Message')
        @AuraEnabled
        global String triggerMessage;

        @InvocableVariable(label='Consent Message')
        @AuraEnabled
        global String consentMessage;

        @InvocableVariable(label='Declined Message')
        @AuraEnabled
        global String declinedMessage;

        @InvocableVariable(label='Offline Message')
        @AuraEnabled
        global String offlineMessage;

        @InvocableVariable(label='Queue Developer Name')
        @AuraEnabled
        global String queueDeveloperName;

        @InvocableVariable(label='Messaging Channel Developer Name')
        @AuraEnabled
        global String messagingChannelDeveloperName;

        @InvocableVariable(label='Embedded Service Deployment Name')
        @AuraEnabled
        global String embeddedServiceDeploymentName;

        @InvocableVariable(label='Handoff URL')
        @AuraEnabled
        global String handoffUrl;

        @InvocableVariable(label='Context Sharing Enabled')
        @AuraEnabled
        global Boolean contextSharingEnabled;

        @InvocableVariable(label='Context Fields To Share')
        @AuraEnabled
        global String contextFieldsToShare;

        @InvocableVariable(label='Context Summary JSON')
        @AuraEnabled
        global String contextSummaryJson;

        @InvocableVariable(label='Readiness Warnings JSON')
        @AuraEnabled
        global String readinessWarningsJson;

        @InvocableVariable(label='Error Type')
        @AuraEnabled
        global String errorType;

        @InvocableVariable(label='Error Code')
        @AuraEnabled
        global String errorCode;

        @InvocableVariable(label='User Message')
        @AuraEnabled
        global String userMessage;

        @InvocableVariable(label='Admin Message')
        @AuraEnabled
        global String adminMessage;
    }

    global class IntakeResponse {
        @InvocableVariable(label='Success')
        @AuraEnabled
        global Boolean success;

        @InvocableVariable(label='Intake Session Id')
        @AuraEnabled
        global String intakeSessionId;

        @InvocableVariable(label='Template Key')
        @AuraEnabled
        global String templateKey;

        @InvocableVariable(label='Question JSON')
        @AuraEnabled
        global String questionJson;

        @InvocableVariable(label='Progress JSON')
        @AuraEnabled
        global String progressJson;

        @InvocableVariable(label='Answers JSON')
        @AuraEnabled
        global String answersJson;

        @InvocableVariable(label='Branding JSON')
        @AuraEnabled
        global String brandingJson;

        @InvocableVariable(label='Requires Consent')
        @AuraEnabled
        global Boolean requiresConsent;

        @InvocableVariable(label='Consent Message')
        @AuraEnabled
        global String consentMessage;

        @InvocableVariable(label='Requires Final Confirmation')
        @AuraEnabled
        global Boolean requiresFinalConfirmation;

        @InvocableVariable(label='Is Complete')
        @AuraEnabled
        global Boolean isComplete;

        @InvocableVariable(label='Has Active Question')
        @AuraEnabled
        global Boolean hasActiveQuestion;

        @InvocableVariable(label='Active Question Key')
        @AuraEnabled
        global String activeQuestionKey;

        @InvocableVariable(label='Pending Confirmation')
        @AuraEnabled
        global Boolean pendingConfirmation;

        @InvocableVariable(label='Must Render Current Question')
        @AuraEnabled
        global Boolean mustRenderCurrentQuestion;

        @InvocableVariable(label='Renderer Mode')
        @AuraEnabled
        global String rendererMode;

        @InvocableVariable(label='Recommended Next Step')
        @AuraEnabled
        global String recommendedNextStep;

        @InvocableVariable(label='Error Type')
        @AuraEnabled
        global String errorType;

        @InvocableVariable(label='Error Code')
        @AuraEnabled
        global String errorCode;

        @InvocableVariable(label='User Message')
        @AuraEnabled
        global String userMessage;

        @InvocableVariable(label='Admin Message')
        @AuraEnabled
        global String adminMessage;

        @InvocableVariable(label='Primary Record Id')
        @AuraEnabled
        global String primaryRecordId;

        @InvocableVariable(label='Saved Record Ids JSON')
        @AuraEnabled
        global String savedRecordIdsJson;

        global Question question;

        @InvocableVariable(label='Current Question Contract')
        @AuraEnabled
        global SmartIntakeQuestionContract currentQuestion;

        @InvocableVariable(label='Answer Capture Template')
        @AuraEnabled
        global SmartIntakeAnswerCapture answerCaptureTemplate;

        @InvocableVariable(label='Answer Capture Plan JSON')
        @AuraEnabled
        global String answerCapturePlanJson;

        global Progress progress;

        global Branding branding;
    }

    global class Question {
        @AuraEnabled
        global String questionKey;

        @AuraEnabled
        global String questionText;

        @AuraEnabled
        global String helpText;

        @AuraEnabled
        global String placeholderText;

        @AuraEnabled
        global Boolean required;

        @AuraEnabled
        global String inputType;

        @AuraEnabled
        global String uiControl;

        @AuraEnabled
        global Boolean renderLightningInput;

        @AuraEnabled
        global String value;

        @AuraEnabled
        global String dataSourceKey;

        @AuraEnabled
        global String dataSourceJson;

        @AuraEnabled
        global String answersJson;

        @AuraEnabled
        global List<Option> options;

        @AuraEnabled
        global List<String> acceptedFormats;

        @AuraEnabled
        global Boolean allowMultipleFiles;

        @AuraEnabled
        global Integer maxFileCount;
    }

    global class Option {
        @AuraEnabled
        global String label;

        @AuraEnabled
        global String value;
    }

    global class Progress {
        @AuraEnabled
        global Integer currentStep;

        @AuraEnabled
        global Integer totalSteps;

        @AuraEnabled
        global Integer percentageComplete;
    }

    global class Branding {
        @AuraEnabled
        global String agentDisplayName;

        @AuraEnabled
        global String avatarIconName;

        @AuraEnabled
        global String avatarImageUrl;

        @AuraEnabled
        global String welcomeMessage;
    }

    global class FindExistingRecordResponse {
        @InvocableVariable(label='Success')
        @AuraEnabled
        global Boolean success;

        @InvocableVariable(label='Record Found')
        @AuraEnabled
        global Boolean recordFound;

        @InvocableVariable(label='Record Id')
        @AuraEnabled
        global String recordId;

        @InvocableVariable(label='Object API Name')
        @AuraEnabled
        global String objectApiName;

        @InvocableVariable(label='Matched Field')
        @AuraEnabled
        global String matchedField;

        @InvocableVariable(label='Display Value')
        @AuraEnabled
        global String displayValue;

        @InvocableVariable(label='Error Type')
        @AuraEnabled
        global String errorType;

        @InvocableVariable(label='Error Code')
        @AuraEnabled
        global String errorCode;

        @InvocableVariable(label='User Message')
        @AuraEnabled
        global String userMessage;

        @InvocableVariable(label='Admin Message')
        @AuraEnabled
        global String adminMessage;
    }

    global class ExistingContextRecord {
        @AuraEnabled
        global String recordId;

        @AuraEnabled
        global String displayValue;

        @AuraEnabled
        global String allowedActions;
    }

    global class ExistingContextResponse {
        @InvocableVariable(label='Success')
        @AuraEnabled
        global Boolean success;

        @InvocableVariable(label='Has Context')
        @AuraEnabled
        global Boolean hasContext;

        @InvocableVariable(label='Context Type')
        @AuraEnabled
        global String contextType;

        @InvocableVariable(label='Context Message')
        @AuraEnabled
        global String contextMessage;

        @InvocableVariable(label='Context Records JSON')
        @AuraEnabled
        global String contextRecordsJson;

        @InvocableVariable(label='Error Type')
        @AuraEnabled
        global String errorType;

        @InvocableVariable(label='Error Code')
        @AuraEnabled
        global String errorCode;

        @InvocableVariable(label='User Message')
        @AuraEnabled
        global String userMessage;

        @InvocableVariable(label='Admin Message')
        @AuraEnabled
        global String adminMessage;

        @AuraEnabled
        global List<ExistingContextRecord> contextRecords;
    }

    global class ValidateAnswerResponse {
        @InvocableVariable(label='Success')
        @AuraEnabled
        global Boolean success;

        @InvocableVariable(label='Is Valid')
        @AuraEnabled
        global Boolean isValid;

        @InvocableVariable(label='Normalized Value')
        @AuraEnabled
        global String normalizedValue;

        @InvocableVariable(label='Error Type')
        @AuraEnabled
        global String errorType;

        @InvocableVariable(label='Error Code')
        @AuraEnabled
        global String errorCode;

        @InvocableVariable(label='User Message')
        @AuraEnabled
        global String userMessage;

        @InvocableVariable(label='Admin Message')
        @AuraEnabled
        global String adminMessage;
    }
}