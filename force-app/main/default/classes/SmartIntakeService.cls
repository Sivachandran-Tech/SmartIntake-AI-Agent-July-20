public with sharing class SmartIntakeService {
    private static final Integer DEFAULT_CONTEXT_LIMIT = 3;
    private static final Integer MAX_CONTEXT_LIMIT = 10;
    private static final Integer DEFAULT_FILE_COUNT = 1;
    private static final Integer MAX_FILE_COUNT = 25;
    private static final String CONTENT_DOCUMENT_PREFIX = '069';
    private static final String CONTENT_VERSION_PREFIX = '068';
    private static final String SESSION_OBJECT_API_NAME = 'SmartIntake_Session__c';
    private static final String SESSION_STATUS_IN_PROGRESS = 'In Progress';
    private static final String SESSION_STATUS_COMPLETE = 'Complete';
    private static final String PENDING_ANSWERS_KEY = '__smartIntakePendingAnswers';
    private static final String PENDING_CONFIRMATION_KEY = '__smartIntakePendingExtractedAnswerConfirmation';
    private static final String FINAL_REVIEW_EDIT_TARGET_KEY = '__smartIntakeFinalReviewEditTarget';
    private static final String ROUTE_CONTEXT_ANSWER_KEY = '__smartIntakeRouteContextKey';
    private static final String ROUTE_TEMPLATE_ANSWER_KEY = '__smartIntakeRouteTemplateKey';
    private static final String FINAL_REVIEW_DATA_SOURCE_KEY = '__SMARTINTAKE_FINAL_REVIEW__';
    private static final String ROUTE_DIAGNOSTIC_CODE = 'SMARTINTAKE_ROUTE_DIAGNOSTIC';
    private static final Integer MESSAGING_CONTEXT_FALLBACK_WINDOW_MINUTES = 15;
    private static final String CONFIRMATION_QUESTION_KEY_FIELD = 'questionKey';
    private static final String CONFIRMATION_ANSWER_VALUE_FIELD = 'answerValue';
    private static final String CONFIRM_USE_PENDING_VALUE = '__SMARTINTAKE_USE_PENDING_ANSWER__';
    private static final String CONFIRM_REENTER_VALUE = '__SMARTINTAKE_ENTER_ANOTHER_ANSWER__';
    private static final String EMAIL_PATTERN = '^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$';
    private static final String BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    @TestVisible
    private static Map<String, String> messagingSessionContextByRoutableIdForTest = new Map<String, String>();
    @TestVisible
    private static String recentMessagingSessionContextKeyForTest;
    private class UploadedFile {
        String name;
        String documentId;
        String contentVersionId;
    }
    private class IntakeSessionState {
        Id recordId;
        String sessionId;
        String templateKey;
        String currentQuestionKey;
        String status;
        Map<String, Object> answers = new Map<String, Object>();
        List<String> questionHistory = new List<String>();
        Set<String> skippedQuestionKeys = new Set<String>();
    }
    private class HydratedHookReplayResult {
        Boolean changed = false;
        String userMessage;
        String nextQuestionKey;
    }
    private static final Set<String> SUPPORTED_VALIDATION_TYPES = new Set<String>{
        'REGEX',
        'MIN_LENGTH',
        'MAX_LENGTH',
        'MIN_VALUE',
        'MAX_VALUE',
        'MIN_DATE',
        'MIN_TODAY',
        'MAX_DATE'
    };
    private static final Set<String> SUPPORTED_CONDITION_ACTIONS = new Set<String>{ 'SHOW_WHEN', 'HIDE_WHEN', 'BLOCK_WHEN' };
    private static final Set<String> SUPPORTED_CONDITION_LOGICS = new Set<String>{ 'ALL', 'ANY', 'CUSTOM' };
    private static final Set<String> SUPPORTED_CONDITION_OPERATORS = new Set<String>{
        'EQUALS',
        'NOT_EQUALS',
        'IN',
        'NOT_IN',
        'IS_BLANK',
        'IS_NOT_BLANK',
        'CONTAINS',
        'NOT_CONTAINS',
        'STARTS_WITH',
        'ENDS_WITH',
        'GREATER_THAN',
        'GREATER_OR_EQUAL',
        'LESS_THAN',
        'LESS_OR_EQUAL',
        'BEFORE',
        'AFTER',
        'ON_OR_BEFORE',
        'ON_OR_AFTER'
    };
    private static final Set<String> SUPPORTED_INPUT_TYPES = new Set<String>{
        'TEXT',
        'LONG_TEXT',
        'EMAIL',
        'PHONE',
        'URL',
        'NUMBER',
        'CURRENCY',
        'DATE',
        'DATETIME',
        'BOOLEAN',
        'PICKLIST',
        'RADIO',
        'MULTI_SELECT',
        'FILE',
        'IMAGE',
        'PDF'
    };
    private static final Set<String> FILE_INPUT_TYPES = new Set<String>{ 'FILE', 'IMAGE', 'PDF' };
    private static final Set<String> SUPPORTED_FILE_SHARE_TYPES = new Set<String>{ 'V', 'C', 'I' };
    private static final Set<String> SUPPORTED_FILE_VISIBILITIES = new Set<String>{ 'AllUsers', 'InternalUsers', 'SharedUsers' };
    private static final Set<String> SUPPORTED_HANDOFF_PROVIDER_TYPES = new Set<String>{ 'ENHANCED_OMNI', 'ENHANCED_CHAT_V2', 'EXTERNAL_URL' };
    private static final Set<String> SUPPORTED_HANDOFF_AVAILABILITY_MODES = new Set<String>{ 'CONFIGURED', 'ALWAYS_AVAILABLE', 'ALWAYS_OFFLINE' };

    public static SmartIntakeDTO.IntakeResponse getNextQuestion(SmartIntakeDTO.GetNextQuestionRequest request) {
        try {
            String effectiveContextKey = effectiveRouteContextKey(
                request == null ? null : request.smartIntakeContextKey,
                request == null ? null : request.answersJson,
                request == null ? null : request.routableId
            );
            String templateKey = resolveTemplateKey(
                request == null ? null : request.templateKey,
                effectiveContextKey,
                request == null ? null : request.routableId,
                request == null ? null : request.intakeSessionId
            );
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            String effectiveSessionId = sessionIdForResolvedTemplate(
                request == null ? null : request.intakeSessionId,
                effectiveContextKey,
                templateKey
            );
            String effectiveAnswersJson = answersJsonForResolvedTemplate(
                request == null ? null : request.answersJson,
                effectiveContextKey,
                templateKey
            );
            IntakeSessionState sessionState = loadSessionState(
                templateKey,
                effectiveSessionId,
                effectiveAnswersJson
            );
            removeUnconfiguredAnswers(metadata, sessionState.answers);
            rememberRouteContext(sessionState.answers, effectiveContextKey, templateKey);
            HydratedHookReplayResult replayResult = replayHydratedAnswerHooks(
                metadata,
                sessionState,
                effectiveContextKey,
                request == null ? null : request.routableId
            );
            String focusedQuestionKey = !String.isBlank(replayResult.nextQuestionKey)
                ? replayResult.nextQuestionKey
                : sessionState.currentQuestionKey;
            SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
                metadata,
                sessionState.sessionId,
                sessionState.answers,
                replayResult.userMessage,
                focusedQuestionKey
            );
            if (replayResult.changed == true || sessionState.recordId == null) {
                persistSessionState(
                    sessionState,
                    templateKey,
                    sessionState.answers,
                    response.question == null ? null : response.question.questionKey,
                    SESSION_STATUS_IN_PROGRESS
                );
            }
            logRouteDiagnostic(
                'getNextQuestion',
                'Question Resolved',
                request == null ? null : request.templateKey,
                request == null ? null : request.smartIntakeContextKey,
                effectiveContextKey,
                request == null ? null : request.routableId,
                request == null ? null : request.intakeSessionId,
                sessionState.sessionId,
                templateKey,
                response == null || response.question == null ? null : response.question.questionKey,
                request == null ? null : request.answersJson
            );
            return response;
        } catch (SmartIntakeException ex) {
            return errorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        } catch (Exception ex) {
            return unexpectedErrorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        }
    }

    public static SmartIntakeDTO.IntakeResponse submitAnswer(SmartIntakeDTO.SubmitAnswerRequest request) {
        try {
            if (request == null) {
                throw validationError('MISSING_REQUEST', 'A submit answer request is required.', 'A submit answer request was null.');
            }
            String effectiveContextKey = effectiveRouteContextKey(request.smartIntakeContextKey, request.answersJson, request.routableId);
            String templateKey = resolveTemplateKey(
                request.templateKey,
                effectiveContextKey,
                request.routableId,
                request.intakeSessionId
            );
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            SmartIntake_Question__mdt question = metadata.questionsByKey.get(request.questionKey);
            if (question == null) {
                throw new SmartIntakeException(
                    'CONFIGURATION',
                    'QUESTION_NOT_FOUND',
                    SmartIntakeMetadataService.message(templateKey, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
                    'Question key ' + request.questionKey + ' was not found for template ' + templateKey + '.'
                );
            }

            Map<String, Object> answers = readAnswers(request.answersJson);
            IntakeSessionState sessionState = loadSessionState(templateKey, request.intakeSessionId, request.answersJson);
            answers = sessionState.answers;
            removeUnconfiguredAnswers(metadata, answers);
            rememberRouteContext(answers, effectiveContextKey, templateKey);
            if (hasPendingExtractedAnswerConfirmation(answers)) {
                SmartIntakeDTO.SubmitCurrentAnswerRequest confirmationRequest = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                confirmationRequest.intakeSessionId = sessionState.sessionId;
                confirmationRequest.agentSessionKey = request.agentSessionKey;
                confirmationRequest.templateKey = templateKey;
                confirmationRequest.smartIntakeContextKey = effectiveContextKey;
                confirmationRequest.answerValue = request.answerValue;
                confirmationRequest.proposedAnswersJson = request.proposedAnswersJson;
                confirmationRequest.answersJson = JSON.serialize(answers);
                confirmationRequest.routableId = request.routableId;
                return handlePendingExtractedAnswerConfirmation(
                    metadata,
                    sessionState,
                    confirmationRequest,
                    request.answerValue,
                    templateKey
                );
            }
            if (!isQuestionVisible(metadata, question, answers)) {
                throw validationError(
                    'QUESTION_NOT_VISIBLE',
                    'That question is not part of the current intake path.',
                    'Question ' + request.questionKey + ' is hidden by condition metadata for the current answers.'
                );
            }
            Map<String, Object> proposedAnswers = readAnswers(request.proposedAnswersJson);
            String submittedAnswerValue = resolveSubmittedAnswerValue(request.answerValue, proposedAnswers, request.questionKey);
            submittedAnswerValue = resolveRenderedPendingControlValue(question, answers, request.questionKey, submittedAnswerValue);
            Boolean answerCameFromRenderedPendingControl = isRenderedPendingControlAnswer(
                question,
                answers,
                proposedAnswers,
                request.questionKey,
                submittedAnswerValue
            );
            Boolean answerCameFromCurrentProposal = !answerCameFromRenderedPendingControl &&
                isCurrentProposedAnswer(request.answerValue, proposedAnswers, request.questionKey);
            if (shouldKeepCurrentQuestionForConversationalText(metadata, question, submittedAnswerValue)) {
                SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
                    metadata,
                    sessionState.sessionId,
                    answers,
                    conversationalHoldMessage(submittedAnswerValue),
                    request.questionKey
                );
                persistSessionState(
                    sessionState,
                    templateKey,
                    answers,
                    response.question == null ? request.questionKey : response.question.questionKey,
                    SESSION_STATUS_IN_PROGRESS
                );
                return response;
            }
            validateAnswer(metadata, question, submittedAnswerValue);
            if (answerCameFromCurrentProposal && requiresExtractedAnswerConfirmation(question)) {
                stageProposedAnswers(metadata, answers, proposedAnswers, request.questionKey);
                setPendingExtractedAnswerConfirmation(answers, request.questionKey, submittedAnswerValue);
                SmartIntakeDTO.IntakeResponse confirmationResponse = buildRuntimeResponse(
                    metadata,
                    sessionState.sessionId,
                    answers,
                    null,
                    request.questionKey
                );
                persistSessionState(
                    sessionState,
                    templateKey,
                    answers,
                    confirmationResponse.question == null ? request.questionKey : confirmationResponse.question.questionKey,
                    SESSION_STATUS_IN_PROGRESS
                );
                return confirmationResponse;
            }

            Object existingAnswer = answers.get(request.questionKey);
            if (answers.containsKey(request.questionKey) && String.valueOf(existingAnswer) != String.valueOf(submittedAnswerValue)) {
                if (!isFinalReviewEditTarget(answers, request.questionKey)) {
                    pruneAnswersAfter(metadata, answers, request.questionKey);
                }
                clearPendingAnswers(answers);
            }
            removePendingAnswer(answers, request.questionKey);
            answers.put(request.questionKey, submittedAnswerValue == null ? '' : submittedAnswerValue);
            clearFinalReviewEditTarget(answers, request.questionKey);
            stageProposedAnswers(metadata, answers, proposedAnswers, request.questionKey);
            applyBlockingConditions(metadata, question, answers);

            Map<String, Object> pendingBeforeHook = pendingAnswers(answers);
            SmartIntakeHookService.HookResult hookResult = SmartIntakeHookService.runAfterAnswer(
                metadata,
                hookContext(
                    templateKey,
                    sessionState.sessionId,
                    request.agentSessionKey,
                    request.questionKey,
                    submittedAnswerValue,
                    externalAnswersJson(answers),
                    request.routableId
                )
            );
            if (hookResult != null && !String.isBlank(hookResult.updatedAnswersJson)) {
                answers = readAnswers(hookResult.updatedAnswersJson);
                mergePendingAnswers(answers, pendingBeforeHook);
                removeUnconfiguredAnswers(metadata, answers);
                rememberRouteContext(answers, effectiveContextKey, templateKey);
            }
            String nextQuestionKey = nextQuestionKeyAfter(metadata, answers, request.questionKey);
            if (hookResult != null && !String.isBlank(hookResult.nextQuestionKey)) {
                nextQuestionKey = hookResult.nextQuestionKey;
                assertHookNextQuestion(metadata, answers, nextQuestionKey);
            }
            if (hookResult != null && hookResult.blockContinue == true && String.isBlank(hookResult.nextQuestionKey)) {
                nextQuestionKey = request.questionKey;
            } else if (hookResult == null || hookResult.blockContinue != true) {
                nextQuestionKey = advanceThroughPendingAnswers(
                    metadata,
                    answers,
                    sessionState.sessionId,
                    request.agentSessionKey,
                    request.routableId,
                    nextQuestionKey
                );
            }
            SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
                metadata,
                sessionState.sessionId,
                answers,
                hookResult == null ? null : hookResult.userMessage,
                nextQuestionKey
            );
            addHistoryKey(sessionState, request.questionKey);
            persistSessionState(sessionState, templateKey, answers, response.question == null ? null : response.question.questionKey, SESSION_STATUS_IN_PROGRESS);
            return response;
        } catch (SmartIntakeException ex) {
            return errorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        } catch (Exception ex) {
            return unexpectedErrorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        }
    }

    public static SmartIntakeDTO.IntakeResponse submitCurrentAnswer(SmartIntakeDTO.SubmitCurrentAnswerRequest request) {
        try {
            if (request == null) {
                throw validationError('MISSING_REQUEST', 'A submit current answer request is required.', 'A submit current answer request was null.');
            }

            String effectiveSessionId = effectiveAgentSessionId(request.intakeSessionId, request.agentSessionKey);
            String effectiveContextKey = effectiveRouteContextKey(request.smartIntakeContextKey, request.answersJson, request.routableId);
            String templateKey = resolveTemplateKey(
                request.templateKey,
                effectiveContextKey,
                request.routableId,
                effectiveSessionId
            );
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            effectiveSessionId = sessionIdForResolvedTemplate(effectiveSessionId, effectiveContextKey, templateKey);
            String effectiveAnswersJson = answersJsonForResolvedTemplate(request.answersJson, effectiveContextKey, templateKey);
            String resolvedAnswerValue = SmartIntakeAgentTypesMapper.resolveAnswerValue(
                request.answerValue,
                request.answerCapture
            );
            IntakeSessionState sessionState = loadSessionState(templateKey, effectiveSessionId, effectiveAnswersJson);
            if (sessionState.recordId == null &&
                shouldAttemptStatelessSubmitRecovery(request, effectiveAnswersJson, resolvedAnswerValue)) {
                IntakeSessionState recoveredSessionState = recentActiveSessionStateForStatelessSubmit(
                    metadata,
                    templateKey,
                    resolvedAnswerValue
                );
                if (recoveredSessionState != null) {
                    sessionState = recoveredSessionState;
                    effectiveSessionId = sessionState.sessionId;
                    effectiveAnswersJson = JSON.serialize(sessionState.answers);
                    logRouteDiagnostic(
                        'submitCurrentAnswer',
                        'Recovered Stateless Session',
                        request.templateKey,
                        request.smartIntakeContextKey,
                        effectiveContextKey,
                        request.routableId,
                        request.intakeSessionId,
                        sessionState.sessionId,
                        templateKey,
                        sessionState.currentQuestionKey,
                        effectiveAnswersJson
                    );
                }
            }
            removeUnconfiguredAnswers(metadata, sessionState.answers);
            rememberRouteContext(sessionState.answers, effectiveContextKey, templateKey);

            if (sessionState.recordId == null && (String.isBlank(request.intakeSessionId) || !String.isBlank(request.agentSessionKey))) {
                SmartIntakeDTO.IntakeResponse startedResponse = buildRuntimeResponse(
                    metadata,
                    sessionState.sessionId,
                    sessionState.answers,
                    null,
                    sessionState.currentQuestionKey
                );
                persistSessionState(
                    sessionState,
                    templateKey,
                    sessionState.answers,
                    startedResponse.question == null ? null : startedResponse.question.questionKey,
                    SESSION_STATUS_IN_PROGRESS
                );
                logRouteDiagnostic(
                    'submitCurrentAnswer',
                    'Started Missing Session',
                    request.templateKey,
                    request.smartIntakeContextKey,
                    effectiveContextKey,
                    request.routableId,
                    request.intakeSessionId,
                    sessionState.sessionId,
                    templateKey,
                    startedResponse == null || startedResponse.question == null ? null : startedResponse.question.questionKey,
                    request.answersJson
                );
                return startedResponse;
            }

            if (hasPendingExtractedAnswerConfirmation(sessionState.answers)) {
                return handlePendingExtractedAnswerConfirmation(
                    metadata,
                    sessionState,
                    request,
                    resolvedAnswerValue,
                    templateKey
                );
            }

            SmartIntakeDTO.Question currentQuestion = String.isBlank(sessionState.currentQuestionKey)
                ? nextUnansweredQuestion(metadata, sessionState.answers)
                : questionByKey(metadata, sessionState.answers, sessionState.currentQuestionKey);

            if (currentQuestion == null) {
                Map<String, Object> proposedAnswers = readAnswers(request.proposedAnswersJson);
                String proposedFinalReviewEditKey = firstFinalReviewProposedAnswerKey(
                    metadata,
                    sessionState.answers,
                    proposedAnswers
                );
                if (!String.isBlank(proposedFinalReviewEditKey)) {
                    SmartIntakeDTO.SubmitAnswerRequest editRequest = new SmartIntakeDTO.SubmitAnswerRequest();
                    editRequest.intakeSessionId = sessionState.sessionId;
                    editRequest.templateKey = templateKey;
                    editRequest.smartIntakeContextKey = effectiveContextKey;
                    editRequest.questionKey = proposedFinalReviewEditKey;
                    editRequest.proposedAnswersJson = request.proposedAnswersJson;
                    editRequest.answersJson = JSON.serialize(sessionState.answers);
                    editRequest.agentSessionKey = request.agentSessionKey;
                    editRequest.routableId = request.routableId;
                    return submitAnswer(editRequest);
                }
                String finalReviewTargetQuestionKey = finalReviewTargetQuestionKeyFromAgent(
                    metadata,
                    sessionState.answers,
                    request.changeQuestionKey
                );
                if (!String.isBlank(finalReviewTargetQuestionKey)) {
                    return reopenFinalReviewQuestion(
                        metadata,
                        sessionState,
                        templateKey,
                        effectiveContextKey,
                        finalReviewTargetQuestionKey
                    );
                }
                if (isAffirmativeFinalConfirmation(resolvedAnswerValue)) {
                    SmartIntakeDTO.SaveFinalRequest saveRequest = new SmartIntakeDTO.SaveFinalRequest();
                    saveRequest.intakeSessionId = sessionState.sessionId;
                    saveRequest.agentSessionKey = request.agentSessionKey;
                    saveRequest.templateKey = templateKey;
                    saveRequest.smartIntakeContextKey = effectiveContextKey;
                    saveRequest.answersJson = JSON.serialize(sessionState.answers);
                    saveRequest.confirmed = true;
                    saveRequest.consentAccepted = true;
                    return saveFinal(saveRequest);
                }
                if (isFinalConfirmationChangeRequest(resolvedAnswerValue)) {
                    return buildFinalReviewChangeResponse(
                        metadata,
                        sessionState.sessionId,
                        sessionState.answers
                    );
                }
                return buildFinalReviewDecisionPromptResponse(
                    metadata,
                    sessionState.sessionId,
                    sessionState.answers
                );
            }

            if (currentQuestion.required != true && isSkipAnswer(resolvedAnswerValue)) {
                SmartIntakeDTO.NavigateRequest skipRequest = new SmartIntakeDTO.NavigateRequest();
                skipRequest.intakeSessionId = sessionState.sessionId;
            skipRequest.templateKey = templateKey;
            skipRequest.smartIntakeContextKey = effectiveContextKey;
            skipRequest.questionKey = currentQuestion.questionKey;
                skipRequest.answersJson = JSON.serialize(sessionState.answers);
                return skipQuestion(skipRequest);
            }

            SmartIntakeDTO.SubmitAnswerRequest submitRequest = new SmartIntakeDTO.SubmitAnswerRequest();
            submitRequest.intakeSessionId = sessionState.sessionId;
            submitRequest.templateKey = templateKey;
            submitRequest.smartIntakeContextKey = effectiveContextKey;
            submitRequest.questionKey = currentQuestion.questionKey;
            submitRequest.answerValue = resolvedAnswerValue;
            submitRequest.proposedAnswersJson = request.proposedAnswersJson;
            submitRequest.answersJson = JSON.serialize(sessionState.answers);
            submitRequest.agentSessionKey = request.agentSessionKey;
            submitRequest.routableId = request.routableId;
            return submitAnswer(submitRequest);
        } catch (SmartIntakeException ex) {
            return errorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        } catch (Exception ex) {
            return unexpectedErrorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        }
    }

    private static Boolean shouldAttemptStatelessSubmitRecovery(
        SmartIntakeDTO.SubmitCurrentAnswerRequest request,
        String effectiveAnswersJson,
        String resolvedAnswerValue
    ) {
        if (request == null ||
            !String.isBlank(request.intakeSessionId) ||
            !String.isBlank(request.agentSessionKey) ||
            !answersJsonIsBlankOrRouteOnly(effectiveAnswersJson)
        ) {
            return false;
        }

        return !String.isBlank(resolvedAnswerValue) || !String.isBlank(request.proposedAnswersJson);
    }

    private static Boolean answersJsonIsBlankOrRouteOnly(String answersJson) {
        if (String.isBlank(answersJson)) {
            return true;
        }

        Map<String, Object> answers = readAnswers(answersJson);
        for (String answerKey : answers.keySet()) {
            if (answerKey != ROUTE_CONTEXT_ANSWER_KEY && answerKey != ROUTE_TEMPLATE_ANSWER_KEY) {
                return false;
            }
        }
        return true;
    }

    private static IntakeSessionState recentActiveSessionStateForStatelessSubmit(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        String templateKey,
        String resolvedAnswerValue
    ) {
        IntakeSessionState candidate = recentActiveSessionStateForTemplate(templateKey);
        if (candidate == null || candidate.recordId == null) {
            return null;
        }

        if (hasPendingExtractedAnswerConfirmation(candidate.answers)) {
            return candidate;
        }

        SmartIntakeDTO.Question currentQuestionDto = String.isBlank(candidate.currentQuestionKey)
            ? nextUnansweredQuestion(metadata, candidate.answers)
            : questionByKey(metadata, candidate.answers, candidate.currentQuestionKey);
        SmartIntake_Question__mdt currentQuestion = currentQuestionDto == null
            ? null
            : metadata.questionsByKey.get(currentQuestionDto.questionKey);

        if (currentQuestion != null &&
            shouldKeepCurrentQuestionForConversationalText(metadata, currentQuestion, resolvedAnswerValue)) {
            return null;
        }

        return candidate;
    }

    private static String effectiveAgentSessionId(String intakeSessionId, String agentSessionKey) {
        if (!String.isBlank(intakeSessionId)) {
            return intakeSessionId;
        }
        if (String.isBlank(agentSessionKey)) {
            return null;
        }

        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(agentSessionKey.trim()));
        return 'SI-' + EncodingUtil.convertToHex(digest).substring(0, 32);
    }

    private static Boolean isSkipAnswer(String answerValue) {
        if (String.isBlank(answerValue)) {
            return true;
        }

        String normalized = answerValue.trim().toLowerCase().replaceAll('\\s+', ' ');
        return new Set<String>{
            'skip',
            'skip this',
            'skip it',
            'none',
            'no',
            'no thanks',
            'no thank you',
            'not now',
            'no attachment',
            'no file',
            'no upload',
            'nothing to upload'
        }.contains(normalized);
    }

    private static Boolean isAffirmativeFinalConfirmation(String answerValue) {
        if (String.isBlank(answerValue)) {
            return false;
        }

        String normalized = answerValue.trim().toLowerCase().replaceAll('\\s+', ' ');
        if (new Set<String>{
            'yes',
            'yes submit',
            'yes, submit',
            'submit',
            'confirm',
            'confirmed',
            'i confirm',
            'i accept',
            'i accept and submit',
            'accept and submit',
            'save',
            'save it',
            'submit it',
            'looks good',
            'go ahead'
        }.contains(normalized)) {
            return true;
        }

        return normalized.contains('accept') && normalized.contains('submit') ||
            normalized.contains('confirm') && normalized.contains('submit') ||
            normalized.contains('yes') && normalized.contains('submit');
    }

    private static Boolean isFinalConfirmationChangeRequest(String answerValue) {
        if (String.isBlank(answerValue)) {
            return false;
        }

        String normalized = answerValue.trim().toLowerCase().replaceAll('[^a-z0-9]+', ' ').replaceAll('\\s+', ' ').trim();
        if (String.isBlank(normalized)) {
            return false;
        }

        if (new Set<String>{
            'change',
            'change it',
            'change answer',
            'change one',
            'edit',
            'edit answer',
            'update',
            'update answer',
            'modify',
            'modify answer',
            'revise',
            'revise answer',
            'correct',
            'correct answer',
            'go back'
        }.contains(normalized)) {
            return true;
        }

        return normalized.contains('want to change') ||
            normalized.contains('need to change') ||
            normalized.contains('would like to change') ||
            normalized.contains('want to edit') ||
            normalized.contains('need to edit') ||
            normalized.contains('change for one') ||
            normalized.contains('change one thing') ||
            normalized.contains('change something') ||
            normalized.contains('fix answer') ||
            normalized.contains('correct answer') ||
            normalized.contains('not correct');
    }

    private static SmartIntakeDTO.IntakeResponse handlePendingExtractedAnswerConfirmation(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        IntakeSessionState sessionState,
        SmartIntakeDTO.SubmitCurrentAnswerRequest request,
        String answerValue,
        String templateKey
    ) {
        Map<String, Object> pendingConfirmation = pendingExtractedAnswerConfirmation(sessionState.answers);
        String questionKey = String.valueOf(pendingConfirmation.get(CONFIRMATION_QUESTION_KEY_FIELD));
        Object extractedValue = pendingConfirmation.get(CONFIRMATION_ANSWER_VALUE_FIELD);
        if (String.isBlank(questionKey) || isBlankValue(extractedValue) || !metadata.questionsByKey.containsKey(questionKey)) {
            clearPendingExtractedAnswerConfirmation(sessionState.answers);
            return buildRuntimeResponse(
                metadata,
                sessionState.sessionId,
                sessionState.answers,
                null,
                sessionState.currentQuestionKey
            );
        }

        SmartIntake_Question__mdt question = metadata.questionsByKey.get(questionKey);
        if (isAffirmativeExtractedAnswerConfirmation(answerValue) ||
            isSameExtractedAnswerValue(question, answerValue, extractedValue)) {
            clearPendingExtractedAnswerConfirmation(sessionState.answers);
            persistSessionState(
                sessionState,
                templateKey,
                sessionState.answers,
                questionKey,
                SESSION_STATUS_IN_PROGRESS
            );
            SmartIntakeDTO.SubmitAnswerRequest submitRequest = new SmartIntakeDTO.SubmitAnswerRequest();
            submitRequest.intakeSessionId = sessionState.sessionId;
            submitRequest.templateKey = templateKey;
            submitRequest.questionKey = questionKey;
            submitRequest.answerValue = String.valueOf(extractedValue).trim();
            submitRequest.proposedAnswersJson = request.proposedAnswersJson;
            submitRequest.answersJson = JSON.serialize(sessionState.answers);
            submitRequest.agentSessionKey = request.agentSessionKey;
            submitRequest.routableId = request.routableId;
            return submitAnswer(submitRequest);
        }

        if (isNegativeExtractedAnswerConfirmation(answerValue)) {
            clearPendingExtractedAnswerConfirmation(sessionState.answers);
            Map<String, Object> pending = pendingAnswers(sessionState.answers);
            pending.remove(questionKey);
            setPendingAnswers(sessionState.answers, pending);

            SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
                metadata,
                sessionState.sessionId,
                sessionState.answers,
                'No problem. Please enter the answer you want to use.',
                questionKey
            );
            persistSessionState(
                sessionState,
                templateKey,
                sessionState.answers,
                response.question == null ? questionKey : response.question.questionKey,
                SESSION_STATUS_IN_PROGRESS
            );
            return response;
        }

        SmartIntakeDTO.IntakeResponse replacementResponse = submitPendingExtractedAnswerReplacementIfValid(
            metadata,
            sessionState,
            request,
            answerValue,
            templateKey,
            questionKey
        );
        if (replacementResponse != null) {
            return replacementResponse;
        }

        SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
            metadata,
            sessionState.sessionId,
            sessionState.answers,
            'Please choose Yes to use the answer I found, or No to enter another answer.',
            questionKey
        );
        persistSessionState(
            sessionState,
            templateKey,
            sessionState.answers,
            response.question == null ? questionKey : response.question.questionKey,
            SESSION_STATUS_IN_PROGRESS
        );
        return response;
    }

    private static SmartIntakeDTO.IntakeResponse submitPendingExtractedAnswerReplacementIfValid(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        IntakeSessionState sessionState,
        SmartIntakeDTO.SubmitCurrentAnswerRequest request,
        String answerValue,
        String templateKey,
        String questionKey
    ) {
        if (String.isBlank(answerValue) || !canAcceptDirectExtractedAnswerReplacement(metadata, questionKey)) {
            return null;
        }

        SmartIntake_Question__mdt question = metadata.questionsByKey.get(questionKey);
        try {
            validateAnswer(metadata, question, answerValue.trim());
        } catch (SmartIntakeException ex) {
            return null;
        }

        clearPendingExtractedAnswerConfirmation(sessionState.answers);
        Map<String, Object> pending = pendingAnswers(sessionState.answers);
        pending.remove(questionKey);
        setPendingAnswers(sessionState.answers, pending);
        persistSessionState(
            sessionState,
            templateKey,
            sessionState.answers,
            questionKey,
            SESSION_STATUS_IN_PROGRESS
        );

        SmartIntakeDTO.SubmitAnswerRequest submitRequest = new SmartIntakeDTO.SubmitAnswerRequest();
        submitRequest.intakeSessionId = sessionState.sessionId;
        submitRequest.templateKey = templateKey;
        submitRequest.questionKey = questionKey;
        submitRequest.answerValue = answerValue.trim();
        submitRequest.proposedAnswersJson = request.proposedAnswersJson;
        submitRequest.answersJson = JSON.serialize(sessionState.answers);
        submitRequest.agentSessionKey = request.agentSessionKey;
        submitRequest.routableId = request.routableId;
        return submitAnswer(submitRequest);
    }

    private static Boolean canAcceptDirectExtractedAnswerReplacement(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        String questionKey
    ) {
        if (metadata == null || String.isBlank(questionKey) || !metadata.questionsByKey.containsKey(questionKey)) {
            return false;
        }

        SmartIntake_Question__mdt question = metadata.questionsByKey.get(questionKey);
        String inputType = normalizeInputType(question.Input_Type__c);
        if (new Set<String>{
            'EMAIL',
            'DATE',
            'DATETIME',
            'NUMBER',
            'CURRENCY',
            'BOOLEAN',
            'PICKLIST',
            'RADIO',
            'MULTI_SELECT'
        }.contains(inputType)) {
            return true;
        }

        List<SmartIntake_Validation_Rule__mdt> rules = metadata.validationRulesByQuestionKey.get(questionKey);
        return rules != null && !rules.isEmpty();
    }

    private static Boolean shouldKeepCurrentQuestionForConversationalText(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        String answerValue
    ) {
        if (question == null || String.isBlank(answerValue)) {
            return false;
        }

        String inputType = normalizeInputType(question.Input_Type__c);
        String trimmedValue = answerValue.trim();
        if (looksLikeExpectedStructuredValue(inputType, trimmedValue)) {
            return false;
        }
        if (looksLikeConfiguredOptionValue(metadata, question, trimmedValue)) {
            return false;
        }
        if (isStructuredCaptureInputType(inputType)) {
            return looksLikeConversationalTurn(trimmedValue);
        }
        return looksLikePureConversationalTurn(trimmedValue);
    }

    private static Boolean isStructuredCaptureInputType(String inputType) {
        return new Set<String>{
            'EMAIL',
            'URL',
            'NUMBER',
            'CURRENCY',
            'DATE',
            'DATETIME',
            'BOOLEAN',
            'PICKLIST',
            'RADIO',
            'MULTI_SELECT'
        }.contains(normalizeInputType(inputType));
    }

    private static Boolean looksLikeExpectedStructuredValue(String inputType, String value) {
        if (String.isBlank(value)) {
            return false;
        }

        String trimmedValue = value.trim();
        String normalizedInputType = normalizeInputType(inputType);
        if (normalizedInputType == 'EMAIL') {
            return trimmedValue.contains('@');
        }
        if (normalizedInputType == 'URL') {
            String lowerValue = trimmedValue.toLowerCase();
            return lowerValue.startsWith('http://') || lowerValue.startsWith('https://') ||
                (!trimmedValue.contains(' ') && trimmedValue.contains('.'));
        }
        if (normalizedInputType == 'NUMBER' || normalizedInputType == 'CURRENCY') {
            return Pattern.matches('^-?\\d+(\\.\\d+)?$', trimmedValue.replace(',', ''));
        }
        if (normalizedInputType == 'DATE' || normalizedInputType == 'DATETIME') {
            return Pattern.matches('.*\\d{1,4}[-/.:T ]\\d{1,2}.*', trimmedValue);
        }
        if (normalizedInputType == 'BOOLEAN') {
            return new Set<String>{ 'true', 'false', 'yes', 'no' }.contains(trimmedValue.toLowerCase());
        }
        return false;
    }

    private static Boolean looksLikeConfiguredOptionValue(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        String value
    ) {
        if (metadata == null || question == null || String.isBlank(value)) {
            return false;
        }
        List<SmartIntake_Option__mdt> optionRecords = metadata.optionsByQuestionKey.get(question.Question_Key__c);
        if (optionRecords == null || optionRecords.isEmpty()) {
            return false;
        }

        String normalizedValue = value.trim().toLowerCase();
        for (SmartIntake_Option__mdt optionRecord : optionRecords) {
            if (optionRecord == null) {
                continue;
            }
            String optionValue = optionRecord.Option_Value__c == null ? null : optionRecord.Option_Value__c.trim().toLowerCase();
            String optionLabel = optionRecord.Option_Label__c == null ? null : optionRecord.Option_Label__c.trim().toLowerCase();
            if (normalizedValue == optionValue || normalizedValue == optionLabel) {
                return true;
            }
        }
        return false;
    }

    private static Boolean looksLikeConversationalTurn(String value) {
        String normalized = normalizedConversationalText(value);
        if (String.isBlank(normalized)) {
            return false;
        }

        if (new Set<String>{
            'hi',
            'hello',
            'hey',
            'thanks',
            'thank you',
            'ok',
            'okay',
            'yes',
            'no',
            'start',
            'begin',
            'continue',
            'proceed',
            'help'
        }.contains(normalized)) {
            return true;
        }

        return normalized.startsWith('yes i ') ||
            normalized.startsWith('no i ') ||
            normalized.startsWith('i want ') ||
            normalized.startsWith('i need ') ||
            normalized.startsWith('can you ') ||
            normalized.startsWith('could you ') ||
            normalized.startsWith('please ') ||
            normalized.contains(' how are you') ||
            normalized == 'how are you';
    }

    private static Boolean looksLikePureConversationalTurn(String value) {
        String normalized = normalizedConversationalText(value);
        if (String.isBlank(normalized)) {
            return false;
        }

        if (new Set<String>{
            'hi',
            'hello',
            'hey',
            'thanks',
            'thank you',
            'ok',
            'okay',
            'help',
            'how are you',
            'what can you do',
            'can you help',
            'could you help'
        }.contains(normalized)) {
            return true;
        }

        return normalized.startsWith('hi ') ||
            normalized.startsWith('hello ') ||
            normalized.startsWith('hey ') ||
            normalized.startsWith('thanks ') ||
            normalized.startsWith('thank you ') ||
            normalized.startsWith('can you help') ||
            normalized.startsWith('could you help') ||
            normalized.contains(' how are you');
    }

    private static String conversationalHoldMessage(String answerValue) {
        String normalized = normalizedConversationalText(answerValue);
        if (normalized == 'thanks' || normalized == 'thank you' ||
            normalized.startsWith('thanks ') || normalized.startsWith('thank you ')) {
            return 'You are welcome. Let us continue with this question.';
        }
        if (normalized == 'how are you' || normalized.contains(' how are you')) {
            return 'I am here and ready to help. Let us continue with this question.';
        }
        return 'Got it. Let us continue with this question.';
    }

    private static String normalizedConversationalText(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        return value.trim().toLowerCase().replaceAll('[^a-z0-9]+', ' ').replaceAll('\\s+', ' ').trim();
    }

    private static Boolean isAffirmativeExtractedAnswerConfirmation(String answerValue) {
        if (String.isBlank(answerValue)) {
            return false;
        }
        String normalized = answerValue.trim().toLowerCase().replaceAll('\\s+', ' ');
        return new Set<String>{
            CONFIRM_USE_PENDING_VALUE.toLowerCase(),
            'yes',
            'yes use this',
            'yes, use this',
            'use this',
            'use it',
            'correct',
            'that is correct'
        }.contains(normalized) || (normalized.contains('yes') && normalized.contains('use'));
    }

    private static Boolean isNegativeExtractedAnswerConfirmation(String answerValue) {
        if (String.isBlank(answerValue)) {
            return false;
        }
        String normalized = answerValue.trim().toLowerCase().replaceAll('\\s+', ' ');
        return new Set<String>{
            CONFIRM_REENTER_VALUE.toLowerCase(),
            'no',
            'no enter another',
            'no, enter another',
            'no, change it',
            'enter another',
            'different answer',
            'change it',
            'not correct'
        }.contains(normalized) || (normalized.contains('no') && (normalized.contains('another') || normalized.contains('different')));
    }

    private static Boolean isSameExtractedAnswerValue(
        SmartIntake_Question__mdt question,
        String answerValue,
        Object extractedValue
    ) {
        if (question == null || String.isBlank(answerValue) || isBlankValue(extractedValue)) {
            return false;
        }
        String submitted = normalizedAnswerValue(question, answerValue);
        String extracted = normalizedAnswerValue(question, String.valueOf(extractedValue));
        return !String.isBlank(submitted) && submitted == extracted;
    }

    public static SmartIntakeDTO.IntakeResponse goBack(SmartIntakeDTO.NavigateRequest request) {
        try {
            if (request == null) {
                throw validationError('MISSING_REQUEST', 'A back navigation request is required.', 'A back navigation request was null.');
            }

            String templateKey = resolveTemplateKey(
                request.templateKey,
                request.smartIntakeContextKey,
                null,
                request.intakeSessionId
            );
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            IntakeSessionState sessionState = loadSessionState(templateKey, request.intakeSessionId, request.answersJson);
            String currentQuestionKey = String.isBlank(request.questionKey) ? sessionState.currentQuestionKey : request.questionKey;
            String previousQuestionKey = previousQuestionKey(metadata, sessionState.answers, currentQuestionKey);
            if (String.isBlank(previousQuestionKey)) {
                throw validationError('BACK_NOT_AVAILABLE', 'There is no earlier question to go back to.', 'Back navigation was requested from the first question.');
            }

            SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
                metadata,
                sessionState.sessionId,
                sessionState.answers,
                'I moved back to the previous question.',
                previousQuestionKey
            );
            persistSessionState(sessionState, templateKey, sessionState.answers, previousQuestionKey, SESSION_STATUS_IN_PROGRESS);
            return response;
        } catch (SmartIntakeException ex) {
            return errorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        } catch (Exception ex) {
            return unexpectedErrorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        }
    }

    public static SmartIntakeDTO.IntakeResponse skipQuestion(SmartIntakeDTO.NavigateRequest request) {
        try {
            if (request == null) {
                throw validationError('MISSING_REQUEST', 'A skip question request is required.', 'A skip question request was null.');
            }
            if (String.isBlank(request.questionKey)) {
                throw validationError('MISSING_QUESTION_KEY', 'I could not determine which question to skip.', 'Question key is required for skip navigation.');
            }

            String effectiveContextKey = effectiveRouteContextKey(request.smartIntakeContextKey, request.answersJson);
            String templateKey = resolveTemplateKey(
                request.templateKey,
                effectiveContextKey,
                null,
                request.intakeSessionId
            );
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            SmartIntake_Question__mdt question = metadata.questionsByKey.get(request.questionKey);
            if (question == null) {
                throw configurationError(templateKey, 'QUESTION_NOT_FOUND', 'Question key ' + request.questionKey + ' was not found for template ' + templateKey + '.');
            }

            IntakeSessionState sessionState = loadSessionState(templateKey, request.intakeSessionId, request.answersJson);
            rememberRouteContext(sessionState.answers, effectiveContextKey, templateKey);
            if (!isQuestionVisible(metadata, question, sessionState.answers)) {
                throw validationError(
                    'QUESTION_NOT_VISIBLE',
                    'That question is not part of the current intake path.',
                    'Question ' + request.questionKey + ' is hidden by condition metadata for the current answers.'
                );
            }
            if (question.Is_Required__c == true) {
                throw validationError(
                    'REQUIRED_QUESTION_CANNOT_BE_SKIPPED',
                    'Please answer this required question before we continue.',
                    'Question ' + request.questionKey + ' is required and cannot be skipped.'
                );
            }

            sessionState.answers.put(request.questionKey, '');
            sessionState.skippedQuestionKeys.add(request.questionKey);
            addHistoryKey(sessionState, request.questionKey);
            String nextQuestionKey = nextQuestionKeyAfter(metadata, sessionState.answers, request.questionKey);
            SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
                metadata,
                sessionState.sessionId,
                sessionState.answers,
                'I skipped that optional question.',
                nextQuestionKey
            );
            persistSessionState(sessionState, templateKey, sessionState.answers, response.question == null ? null : response.question.questionKey, SESSION_STATUS_IN_PROGRESS);
            return response;
        } catch (SmartIntakeException ex) {
            return errorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        } catch (Exception ex) {
            return unexpectedErrorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        }
    }

    public static SmartIntakeDTO.ValidateAnswerResponse validateIntakeAnswer(SmartIntakeDTO.ValidateAnswerRequest request) {
        try {
            if (request == null) {
                throw validationError('MISSING_REQUEST', 'A validate answer request is required.', 'A validate answer request was null.');
            }
            if (String.isBlank(request.questionKey)) {
                throw validationError('MISSING_QUESTION_KEY', 'I could not determine which question to validate.', 'Question key is required for answer validation.');
            }

            String effectiveContextKey = effectiveRouteContextKey(request.smartIntakeContextKey, request.answersJson);
            String templateKey = resolveTemplateKey(
                request.templateKey,
                effectiveContextKey,
                null,
                null
            );
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            SmartIntake_Question__mdt question = metadata.questionsByKey.get(request.questionKey);
            if (question == null) {
                throw configurationError(
                    templateKey,
                    'QUESTION_NOT_FOUND',
                    'Question key ' + request.questionKey + ' was not found for template ' + templateKey + '.'
                );
            }

            Map<String, Object> answers = readAnswers(request.answersJson);
            removeUnconfiguredAnswers(metadata, answers);
            rememberRouteContext(answers, effectiveContextKey, templateKey);
            if (!isQuestionVisible(metadata, question, answers)) {
                throw validationError(
                    'QUESTION_NOT_VISIBLE',
                    'That question is not part of the current intake path.',
                    'Question ' + request.questionKey + ' is hidden by condition metadata for the current answers.'
                );
            }
            validateAnswer(metadata, question, request.answerValue);
            answers.put(request.questionKey, request.answerValue == null ? '' : request.answerValue);
            applyBlockingConditions(metadata, question, answers);

            SmartIntakeDTO.ValidateAnswerResponse response = new SmartIntakeDTO.ValidateAnswerResponse();
            response.success = true;
            response.isValid = true;
            response.normalizedValue = normalizedAnswerValue(question, request.answerValue);
            return response;
        } catch (SmartIntakeException ex) {
            return validateAnswerErrorResponse(ex);
        } catch (Exception ex) {
            SmartIntakeApexDebugLogService.logException(
                'SmartIntakeService',
                'validateAnswerRequest',
                request == null ? null : request.templateKey,
                null,
                ex,
                null
            );
            SmartIntakeDTO.ValidateAnswerResponse response = new SmartIntakeDTO.ValidateAnswerResponse();
            response.success = false;
            response.isValid = false;
            response.errorType = 'TRANSIENT';
            response.errorCode = 'UNEXPECTED_ERROR';
            response.userMessage = 'Something interrupted answer validation. Please try again.';
            response.adminMessage = ex.getTypeName() + ': ' + ex.getMessage();
            return response;
        }
    }

    public static SmartIntakeDTO.IntakeResponse saveFinal(SmartIntakeDTO.SaveFinalRequest request) {
        try {
            if (request == null) {
                throw validationError('MISSING_REQUEST', 'A final save request is required.', 'A final save request was null.');
            }

            String effectiveSessionId = effectiveAgentSessionId(request.intakeSessionId, request.agentSessionKey);
            String effectiveContextKey = effectiveRouteContextKey(
                request.smartIntakeContextKey,
                request.answersJson,
                request.routableId
            );
            String templateKey = resolveTemplateKey(
                request.templateKey,
                effectiveContextKey,
                request.routableId,
                effectiveSessionId
            );
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            if (metadata.template.Requires_Final_Confirmation__c == true && request.confirmed != true) {
                throw validationError('CONFIRMATION_REQUIRED', 'Please confirm before I save this intake.', 'Final save was requested without user confirmation.');
            }
            if (metadata.template.Requires_Consent__c == true && request.consentAccepted != true) {
                throw validationError(
                    'CONSENT_REQUIRED',
                    'Please accept the consent statement before I save this intake.',
                    'Final save was requested without required consent for template ' + templateKey + '.'
                );
            }

            IntakeSessionState sessionState = loadSessionState(templateKey, effectiveSessionId, request.answersJson);
            Map<String, Object> answers = sessionState.answers;
            removeUnconfiguredAnswers(metadata, answers);
            removeInternalAnswerKeys(answers);
            Set<String> visibleQuestionKeys = visibleQuestionKeys(metadata, answers);
            assertRequiredAnswers(metadata, answers, visibleQuestionKeys);
            validateVisibleAnswers(metadata, answers, visibleQuestionKeys);

            if (metadata.bindings.isEmpty()) {
                throw new SmartIntakeException(
                    'CONFIGURATION',
                    'NO_FIELD_BINDINGS',
                    SmartIntakeMetadataService.message(templateKey, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
                    'Template ' + templateKey + ' has no active field bindings.'
                );
            }

            lockSessionForFinalSave(sessionState.recordId);

            List<String> saveObjectApiNames = new List<String>();
            Map<String, SObject> recordsByObjectApiName = new Map<String, SObject>();

            for (SmartIntake_Field_Binding__mdt binding : metadata.bindings) {
                String answerKey = binding.Question_Key__c;
                Boolean isQuestionBinding = metadata.questionsByKey.containsKey(answerKey);
                if (isQuestionBinding && !visibleQuestionKeys.contains(answerKey)) {
                    continue;
                }
                Object answerValue = answers.get(answerKey);
                if (answerValue == null) {
                    continue;
                }
                if (isQuestionBinding) {
                    validateAnswer(metadata, metadata.questionsByKey.get(answerKey), String.valueOf(answerValue));
                }
                if (!recordsByObjectApiName.containsKey(binding.Object_API_Name__c)) {
                    Schema.DescribeSObjectResult objectDescribe = SmartIntakeSecurityService.describeObjectForCreate(binding.Object_API_Name__c);
                    recordsByObjectApiName.put(binding.Object_API_Name__c, objectDescribe.getSObjectType().newSObject());
                    saveObjectApiNames.add(binding.Object_API_Name__c);
                }
                Object coercedValue = SmartIntakeSecurityService.coerceForCreate(
                    binding.Object_API_Name__c,
                    binding.Field_API_Name__c,
                    String.valueOf(answerValue)
                );
                recordsByObjectApiName.get(binding.Object_API_Name__c).put(binding.Field_API_Name__c, coercedValue);
            }

            if (recordsByObjectApiName.isEmpty()) {
                throw new SmartIntakeException(
                    'CONFIGURATION',
                    'NO_FINAL_RECORD_VALUES',
                    SmartIntakeMetadataService.message(templateKey, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
                    'Template ' + templateKey + ' has active field bindings, but none produced a final record value.'
                );
            }

            String answersJson = JSON.serialize(answers);
            String finalSessionId = ensureSessionId(sessionState.sessionId);
            for (String saveObjectApiName : saveObjectApiNames) {
                SObject recordToSave = recordsByObjectApiName.get(saveObjectApiName);
                putIfCreateable(recordToSave, saveObjectApiName, 'Template_Key__c', templateKey);
                putIfCreateable(recordToSave, saveObjectApiName, 'Status__c', 'Complete');
                putIfCreateable(recordToSave, saveObjectApiName, 'Session_Id__c', finalSessionId);
                putIfCreateable(recordToSave, saveObjectApiName, 'Answers_JSON__c', answersJson);
                putIfCreateable(recordToSave, saveObjectApiName, 'External_Key__c', finalRecordExternalKey(templateKey, finalSessionId, saveObjectApiName));
            }

            Id primaryRecordId;
            Map<String, String> savedRecordIdsByObjectApiName = existingFinalRecordIdsByObjectApiName(
                saveObjectApiNames,
                templateKey,
                finalSessionId
            );
            if (!savedRecordIdsByObjectApiName.isEmpty()) {
                if (sessionState.recordId != null) {
                    persistSessionState(sessionState, templateKey, answers, null, SESSION_STATUS_COMPLETE);
                }
                SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(metadata, sessionState.sessionId, answers, metadata.template.Completion_Message__c, null, false);
                response.isComplete = true;
                response.primaryRecordId = savedRecordIdsByObjectApiName.get(saveObjectApiNames[0]);
                response.savedRecordIdsJson = JSON.serialize(savedRecordIdsByObjectApiName);
                applyRuntimeDecision(response, false);
                return response;
            }

            Savepoint savepoint = Database.setSavepoint();
            try {
                // CRUD/FLS is checked above; save in system mode so server-resolved lookup ids are not blocked by private parent sharing.
                for (String saveObjectApiName : saveObjectApiNames) {
                    Database.SaveResult saveResult = Database.insert(recordsByObjectApiName.get(saveObjectApiName), AccessLevel.SYSTEM_MODE);
                    if (!saveResult.isSuccess()) {
                        throw saveError(saveObjectApiName, saveResult);
                    }
                    if (primaryRecordId == null) {
                        primaryRecordId = saveResult.getId();
                    }
                    savedRecordIdsByObjectApiName.put(saveObjectApiName, String.valueOf(saveResult.getId()));
                }
                linkUploadedFiles(metadata, answers, primaryRecordId, visibleQuestionKeys);
                persistSessionState(sessionState, templateKey, answers, null, SESSION_STATUS_COMPLETE);
            } catch (SmartIntakeException ex) {
                Database.rollback(savepoint);
                throw ex;
            } catch (DmlException ex) {
                Database.rollback(savepoint);
                throw dmlSaveError(ex);
            } catch (Exception ex) {
                Database.rollback(savepoint);
                throw ex;
            }

            SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(metadata, sessionState.sessionId, answers, metadata.template.Completion_Message__c, null, false);
            response.isComplete = true;
            response.primaryRecordId = String.valueOf(primaryRecordId);
            response.savedRecordIdsJson = JSON.serialize(savedRecordIdsByObjectApiName);
            applyRuntimeDecision(response, false);
            return response;
        } catch (SmartIntakeException ex) {
            return errorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        } catch (Exception ex) {
            return unexpectedErrorResponse(request == null ? null : request.templateKey, request == null ? null : request.intakeSessionId, ex);
        }
    }

    public static SmartIntakeDTO.FindExistingRecordResponse findExistingRecord(SmartIntakeDTO.FindExistingRecordRequest request) {
        try {
            if (request == null) {
                throw validationError('MISSING_REQUEST', 'A find existing record request is required.', 'A find existing record request was null.');
            }
            if (String.isBlank(request.matchFieldKey) || String.isBlank(request.matchValue)) {
                throw validationError('MISSING_MATCH_INPUT', 'Please provide the value to search for.', 'Match field key and match value are required.');
            }

            String templateKey = resolveTemplateKey(request.templateKey, request.smartIntakeContextKey, null, null);
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            SmartIntake_Matching_Rule__mdt matchingRule = metadata.matchingRulesByKey.get(request.matchFieldKey);
            if (matchingRule == null) {
                matchingRule = metadata.matchingRulesByQuestionKey.get(request.matchFieldKey);
            }
            if (matchingRule == null) {
                throw new SmartIntakeException(
                    'CONFIGURATION',
                    'MATCHING_RULE_NOT_FOUND',
                    SmartIntakeMetadataService.message(templateKey, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
                    'No active matching rule was found for key ' + request.matchFieldKey + ' in template ' + templateKey + '.'
                );
            }
            if (normalizeInputType(matchingRule.Match_Type__c) != 'EXACT') {
                throw new SmartIntakeException(
                    'CONFIGURATION',
                    'UNSUPPORTED_MATCH_TYPE',
                    SmartIntakeMetadataService.message(templateKey, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
                    'Only EXACT matching is supported. Matching rule ' + matchingRule.Matching_Rule_Key__c + ' uses ' + matchingRule.Match_Type__c + '.'
                );
            }

            String objectApiName = matchingRule.Object_API_Name__c;
            String matchFieldApiName = matchingRule.Field_API_Name__c;
            String displayFieldApiName = String.isBlank(matchingRule.Display_Field_API_Name__c)
                ? matchFieldApiName
                : matchingRule.Display_Field_API_Name__c;

            SmartIntakeSecurityService.describeObjectForRead(objectApiName);
            SmartIntakeSecurityService.describeFieldForRead(objectApiName, matchFieldApiName);
            SmartIntakeSecurityService.describeFieldForRead(objectApiName, displayFieldApiName);
            Object matchValue = SmartIntakeSecurityService.coerceForReadFilter(objectApiName, matchFieldApiName, request.matchValue);

            String query = 'SELECT Id, ' + matchFieldApiName;
            if (displayFieldApiName != matchFieldApiName) {
                query += ', ' + displayFieldApiName;
            }
            query += ' FROM ' + objectApiName + ' WHERE ' + matchFieldApiName + ' = :matchValue LIMIT 1';

            List<SObject> records = Database.queryWithBinds(
                query,
                new Map<String, Object>{ 'matchValue' => matchValue },
                AccessLevel.USER_MODE
            );

            SmartIntakeDTO.FindExistingRecordResponse response = new SmartIntakeDTO.FindExistingRecordResponse();
            response.success = true;
            response.recordFound = !records.isEmpty();
            response.objectApiName = objectApiName;
            response.matchedField = matchFieldApiName;
            if (response.recordFound) {
                SObject matchedRecord = records[0];
                response.recordId = String.valueOf(matchedRecord.get('Id'));
                response.displayValue = String.valueOf(matchedRecord.get(displayFieldApiName));
            }
            return response;
        } catch (SmartIntakeException ex) {
            return findExistingErrorResponse(ex);
        } catch (Exception ex) {
            SmartIntakeApexDebugLogService.logException(
                'SmartIntakeService',
                'findExistingRecord',
                request == null ? null : request.templateKey,
                null,
                ex,
                null
            );
            SmartIntakeDTO.FindExistingRecordResponse response = new SmartIntakeDTO.FindExistingRecordResponse();
            response.success = false;
            response.recordFound = false;
            response.errorType = 'TRANSIENT';
            response.errorCode = 'UNEXPECTED_ERROR';
            response.userMessage = 'Something interrupted the existing record search. Please try again.';
            response.adminMessage = ex.getTypeName() + ': ' + ex.getMessage();
            return response;
        }
    }

    private static void lockSessionForFinalSave(Id sessionRecordId) {
        if (sessionRecordId == null) {
            return;
        }
        List<SmartIntake_Session__c> lockedSessions = [
            SELECT Id
            FROM SmartIntake_Session__c
            WHERE Id = :sessionRecordId
            FOR UPDATE
        ];
    }

    private static Map<String, String> existingFinalRecordIdsByObjectApiName(
        List<String> objectApiNames,
        String templateKey,
        String sessionId
    ) {
        Map<String, String> recordIdsByObjectApiName = new Map<String, String>();
        if (objectApiNames == null || objectApiNames.isEmpty() || String.isBlank(templateKey) || String.isBlank(sessionId)) {
            return recordIdsByObjectApiName;
        }

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String objectApiName : objectApiNames) {
            if (String.isBlank(objectApiName) || !globalDescribe.containsKey(objectApiName)) {
                continue;
            }

            Map<String, Schema.SObjectField> fields = globalDescribe.get(objectApiName).getDescribe().fields.getMap();
            Map<String, Object> binds = new Map<String, Object>();
            String query;

            if (fields.containsKey('External_Key__c')) {
                binds.put('externalKey', finalRecordExternalKey(templateKey, sessionId, objectApiName));
                query = 'SELECT Id FROM ' + objectApiName + ' WHERE External_Key__c = :externalKey';
            } else if (fields.containsKey('Session_Id__c') && fields.containsKey('Template_Key__c')) {
                binds.put('sessionId', sessionId);
                binds.put('templateKey', templateKey);
                binds.put('completeStatus', 'Complete');
                query = 'SELECT Id FROM ' + objectApiName +
                    ' WHERE Session_Id__c = :sessionId' +
                    ' AND Template_Key__c = :templateKey';
                if (fields.containsKey('Status__c')) {
                    query += ' AND Status__c = :completeStatus';
                }
            } else {
                continue;
            }
            query += ' ORDER BY CreatedDate ASC LIMIT 1';

            List<SObject> existingRecords = Database.queryWithBinds(query, binds, AccessLevel.SYSTEM_MODE);
            if (!existingRecords.isEmpty()) {
                recordIdsByObjectApiName.put(objectApiName, String.valueOf(existingRecords[0].get('Id')));
            }
        }
        return recordIdsByObjectApiName;
    }

    private static String finalRecordExternalKey(String templateKey, String sessionId, String objectApiName) {
        String source = String.valueOf(templateKey) + '|' + String.valueOf(sessionId) + '|' + String.valueOf(objectApiName);
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(source));
        return 'SI-FINAL-' + EncodingUtil.convertToHex(digest);
    }

    public static SmartIntakeDTO.ExistingContextResponse getExistingContext(SmartIntakeDTO.GetExistingContextRequest request) {
        try {
            if (request == null) {
                throw validationError('MISSING_REQUEST', 'An existing context request is required.', 'An existing context request was null.');
            }
            if (String.isBlank(request.questionKey)) {
                throw validationError('MISSING_QUESTION_KEY', 'I could not determine which question needs context.', 'Question key is required for existing context.');
            }

            String templateKey = resolveTemplateKey(
                request.templateKey,
                request.smartIntakeContextKey,
                null,
                request.intakeSessionId
            );
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            SmartIntake_Context_Config__mdt contextConfig = metadata.contextConfigsByQuestionKey.get(request.questionKey);
            if (contextConfig == null) {
                return emptyExistingContextResponse();
            }

            Map<String, Object> answers = readAnswers(request.answersJson);
            Object sourceAnswer = answers.get(contextConfig.Filter_Source_Question_Key__c);
            if (isBlankValue(sourceAnswer)) {
                return emptyExistingContextResponse();
            }

            String objectApiName = contextConfig.Object_API_Name__c;
            String filterFieldApiName = contextConfig.Filter_Field_API_Name__c;
            String displayFieldApiName = String.isBlank(contextConfig.Display_Field_API_Name__c)
                ? filterFieldApiName
                : contextConfig.Display_Field_API_Name__c;

            SmartIntakeSecurityService.describeObjectForRead(objectApiName);
            SmartIntakeSecurityService.describeFieldForRead(objectApiName, filterFieldApiName);
            SmartIntakeSecurityService.describeFieldForRead(objectApiName, displayFieldApiName);

            Object filterValue = SmartIntakeSecurityService.coerceForReadFilter(
                objectApiName,
                filterFieldApiName,
                String.valueOf(sourceAnswer)
            );
            Integer maxRecords = contextLimit(contextConfig.Max_Records__c);

            String query = 'SELECT Id, ' + displayFieldApiName +
                ' FROM ' + objectApiName +
                ' WHERE ' + filterFieldApiName + ' = :filterValue LIMIT ' + String.valueOf(maxRecords);

            List<SObject> records = Database.queryWithBinds(
                query,
                new Map<String, Object>{ 'filterValue' => filterValue },
                AccessLevel.USER_MODE
            );

            SmartIntakeDTO.ExistingContextResponse response = emptyExistingContextResponse();
            response.success = true;
            response.hasContext = !records.isEmpty();
            response.contextType = String.isBlank(contextConfig.Context_Type__c) ? 'MATCHED_RECORDS' : contextConfig.Context_Type__c;
            response.contextMessage = response.hasContext ? contextConfig.Context_Message__c : null;
            response.contextRecords = new List<SmartIntakeDTO.ExistingContextRecord>();

            String allowedActions = String.isBlank(contextConfig.Allowed_Actions__c)
                ? 'continue'
                : contextConfig.Allowed_Actions__c;
            for (SObject record : records) {
                SmartIntakeDTO.ExistingContextRecord contextRecord = new SmartIntakeDTO.ExistingContextRecord();
                contextRecord.recordId = String.valueOf(record.get('Id'));
                contextRecord.displayValue = String.valueOf(record.get(displayFieldApiName));
                contextRecord.allowedActions = allowedActions;
                response.contextRecords.add(contextRecord);
            }
            response.contextRecordsJson = JSON.serialize(response.contextRecords);
            return response;
        } catch (SmartIntakeException ex) {
            return existingContextErrorResponse(ex);
        } catch (Exception ex) {
            SmartIntakeApexDebugLogService.logException(
                'SmartIntakeService',
                'getExistingContext',
                request == null ? null : request.templateKey,
                null,
                ex,
                null
            );
            SmartIntakeDTO.ExistingContextResponse response = emptyExistingContextResponse();
            response.success = false;
            response.errorType = 'TRANSIENT';
            response.errorCode = 'UNEXPECTED_ERROR';
            response.userMessage = 'Something interrupted the existing context lookup. Please try again.';
            response.adminMessage = ex.getTypeName() + ': ' + ex.getMessage();
            return response;
        }
    }

    public static SmartIntakeDTO.HandoffPlanResponse getHandoffPlan(SmartIntakeDTO.HandoffPlanRequest request) {
        try {
            if (request == null) {
                throw validationError('MISSING_REQUEST', 'A handoff plan request is required.', 'A handoff plan request was null.');
            }

            String templateKey = resolveTemplateKey(
                request.templateKey,
                request.smartIntakeContextKey,
                null,
                request.intakeSessionId
            );
            SmartIntakeMetadataService.RuntimeMetadata metadata = SmartIntakeMetadataService.load(templateKey);
            SmartIntake_Handoff_Config__mdt handoffConfig = metadata.handoffConfig;
            if (handoffConfig == null) {
                SmartIntakeDTO.HandoffPlanResponse disabled = baseHandoffPlanResponse();
                disabled.success = true;
                disabled.handoffEnabled = false;
                disabled.handoffReady = false;
                disabled.availabilityStatus = 'NOT_CONFIGURED';
                disabled.handoffMessage = 'Human handoff is not configured for this intake template.';
                disabled.readinessWarningsJson = JSON.serialize(new List<String>{ 'No active SmartIntake handoff config exists for template ' + templateKey + '.' });
                return disabled;
            }

            String providerType = normalizeInputType(handoffConfig.Provider_Type__c);
            if (!SUPPORTED_HANDOFF_PROVIDER_TYPES.contains(providerType)) {
                throw configurationError(templateKey, 'UNSUPPORTED_HANDOFF_PROVIDER', 'Handoff config ' + handoffConfig.DeveloperName + ' uses unsupported provider type ' + handoffConfig.Provider_Type__c + '.');
            }

            String availabilityMode = normalizeInputType(handoffConfig.Availability_Mode__c);
            if (String.isBlank(availabilityMode)) {
                availabilityMode = 'CONFIGURED';
            }
            if (!SUPPORTED_HANDOFF_AVAILABILITY_MODES.contains(availabilityMode)) {
                throw configurationError(templateKey, 'UNSUPPORTED_HANDOFF_AVAILABILITY_MODE', 'Handoff config ' + handoffConfig.DeveloperName + ' uses unsupported availability mode ' + handoffConfig.Availability_Mode__c + '.');
            }

            SmartIntakeDTO.HandoffPlanResponse response = baseHandoffPlanResponse();
            response.success = true;
            response.handoffEnabled = true;
            response.providerType = providerType;
            response.requiresConsent = handoffConfig.Requires_Consent__c == true;
            response.consentAccepted = request.consentAccepted == true;
            response.triggerMessage = String.isBlank(handoffConfig.Trigger_Message__c)
                ? 'I can help connect you with a human agent.'
                : handoffConfig.Trigger_Message__c;
            response.consentMessage = String.isBlank(handoffConfig.Consent_Message__c)
                ? 'Do you agree to share this intake context with a human agent?'
                : handoffConfig.Consent_Message__c;
            response.declinedMessage = String.isBlank(handoffConfig.Declined_Message__c)
                ? 'No problem. I will continue helping here.'
                : handoffConfig.Declined_Message__c;
            response.offlineMessage = String.isBlank(handoffConfig.Offline_Message__c)
                ? 'A human agent is not available right now.'
                : handoffConfig.Offline_Message__c;
            response.queueDeveloperName = handoffConfig.Queue_Developer_Name__c;
            response.messagingChannelDeveloperName = handoffConfig.Messaging_Channel_Developer_Name__c;
            response.embeddedServiceDeploymentName = handoffConfig.Embedded_Service_Deployment_Name__c;
            response.handoffUrl = handoffConfig.Handoff_URL__c;

            List<String> readinessWarnings = handoffReadinessWarnings(handoffConfig, providerType);
            Boolean providerReady = handoffProviderPrerequisitesReady(handoffConfig, providerType);
            if (response.requiresConsent && !response.consentAccepted) {
                response.handoffReady = false;
                response.availabilityStatus = 'CONSENT_REQUIRED';
                response.handoffMessage = response.consentMessage;
            } else if (availabilityMode == 'ALWAYS_OFFLINE') {
                response.handoffReady = false;
                response.availabilityStatus = 'OFFLINE';
                response.handoffMessage = response.offlineMessage;
            } else if (!providerReady) {
                response.handoffReady = false;
                response.availabilityStatus = 'NOT_READY';
                response.handoffMessage = 'Human handoff is configured, but it needs admin setup before I can connect you.';
            } else {
                response.handoffReady = true;
                response.availabilityStatus = availabilityMode == 'ALWAYS_AVAILABLE' ? 'AVAILABLE' : 'CONFIGURED';
                response.handoffMessage = String.isBlank(handoffConfig.Available_Message__c)
                    ? 'I can connect you with a human agent.'
                    : handoffConfig.Available_Message__c;
            }

            applyHandoffContextPolicy(response, handoffConfig, request.contextSummaryJson);
            response.readinessWarningsJson = JSON.serialize(readinessWarnings);
            return response;
        } catch (SmartIntakeException ex) {
            return handoffPlanErrorResponse(ex);
        } catch (Exception ex) {
            SmartIntakeApexDebugLogService.logException(
                'SmartIntakeService',
                'getHandoffPlan',
                request == null ? null : request.templateKey,
                null,
                ex,
                null
            );
            SmartIntakeDTO.HandoffPlanResponse response = baseHandoffPlanResponse();
            response.success = false;
            response.handoffEnabled = false;
            response.handoffReady = false;
            response.errorType = 'TRANSIENT';
            response.errorCode = 'UNEXPECTED_ERROR';
            response.userMessage = 'Something interrupted the handoff check. Please try again.';
            response.adminMessage = ex.getTypeName() + ': ' + ex.getMessage();
            return response;
        }
    }

    private static SmartIntakeDTO.HandoffPlanResponse baseHandoffPlanResponse() {
        SmartIntakeDTO.HandoffPlanResponse response = new SmartIntakeDTO.HandoffPlanResponse();
        response.success = false;
        response.handoffEnabled = false;
        response.handoffReady = false;
        response.requiresConsent = false;
        response.consentAccepted = false;
        response.contextSharingEnabled = false;
        response.readinessWarningsJson = '[]';
        return response;
    }

    private static SmartIntakeDTO.HandoffPlanResponse handoffPlanErrorResponse(SmartIntakeException ex) {
        SmartIntakeApexDebugLogService.logSmartIntakeException('SmartIntakeService', 'getHandoffPlan', null, null, ex, null);
        SmartIntakeDTO.HandoffPlanResponse response = baseHandoffPlanResponse();
        response.success = false;
        response.errorType = ex.errorType;
        response.errorCode = ex.errorCode;
        response.userMessage = ex.userMessage;
        response.adminMessage = ex.adminMessage;
        return response;
    }

    private static List<String> handoffReadinessWarnings(SmartIntake_Handoff_Config__mdt handoffConfig, String providerType) {
        List<String> warnings = new List<String>();
        if (providerType == 'ENHANCED_OMNI') {
            if (!objectAvailable('PendingServiceRouting') || !objectAvailable('AgentWork')) {
                warnings.add('Enhanced Omni-Channel runtime objects are not available in this org. Enable and configure Enhanced Omni-Channel with the required Service setup before handoff can route work.');
            }
            if (String.isBlank(handoffConfig.Queue_Developer_Name__c)) {
                warnings.add('No Queue Developer Name is configured for the Omni-Channel handoff.');
            }
        } else if (providerType == 'ENHANCED_CHAT_V2') {
            if (!objectAvailable('MessagingChannel')) {
                warnings.add('MessagingChannel is not available in this org. Enable and configure Enhanced Chat v2 or Messaging before chat handoff can be fully verified.');
            }
            if (String.isBlank(handoffConfig.Messaging_Channel_Developer_Name__c) &&
                String.isBlank(handoffConfig.Embedded_Service_Deployment_Name__c)) {
                warnings.add('No Messaging Channel Developer Name or Embedded Service Deployment Name is configured for Enhanced Chat v2 handoff.');
            }
        } else if (providerType == 'EXTERNAL_URL' && String.isBlank(handoffConfig.Handoff_URL__c)) {
            warnings.add('External URL handoff requires Handoff URL.');
        }

        if (handoffConfig.Is_Context_Sharing_Enabled__c == true && String.isBlank(handoffConfig.Context_Fields_To_Share__c)) {
            warnings.add('Context sharing is enabled, but no answer keys are configured in Context Fields To Share.');
        }
        return warnings;
    }

    private static Boolean handoffProviderPrerequisitesReady(SmartIntake_Handoff_Config__mdt handoffConfig, String providerType) {
        if (providerType == 'ENHANCED_OMNI') {
            return objectAvailable('PendingServiceRouting') &&
                objectAvailable('AgentWork') &&
                !String.isBlank(handoffConfig.Queue_Developer_Name__c);
        }
        if (providerType == 'ENHANCED_CHAT_V2') {
            return objectAvailable('MessagingChannel') &&
                (!String.isBlank(handoffConfig.Messaging_Channel_Developer_Name__c) ||
                    !String.isBlank(handoffConfig.Embedded_Service_Deployment_Name__c));
        }
        if (providerType == 'EXTERNAL_URL') {
            return !String.isBlank(handoffConfig.Handoff_URL__c);
        }
        return false;
    }

    private static void applyHandoffContextPolicy(
        SmartIntakeDTO.HandoffPlanResponse response,
        SmartIntake_Handoff_Config__mdt handoffConfig,
        String contextSummaryJson
    ) {
        Boolean canShareContext = handoffConfig.Is_Context_Sharing_Enabled__c == true &&
            response.consentAccepted == true &&
            response.handoffReady == true &&
            !String.isBlank(handoffConfig.Context_Fields_To_Share__c);

        response.contextSharingEnabled = canShareContext;
        response.contextFieldsToShare = canShareContext ? handoffConfig.Context_Fields_To_Share__c : null;
        response.contextSummaryJson = canShareContext
            ? filteredHandoffContextSummary(contextSummaryJson, handoffConfig.Context_Fields_To_Share__c)
            : null;
    }

    @TestVisible
    private static String filteredHandoffContextSummary(String contextSummaryJson, String contextFieldsToShare) {
        if (String.isBlank(contextSummaryJson) || String.isBlank(contextFieldsToShare)) {
            return '{}';
        }

        Object parsed;
        try {
            parsed = JSON.deserializeUntyped(contextSummaryJson);
        } catch (Exception ex) {
            return '{}';
        }

        Map<String, Object> source;
        try {
            source = (Map<String, Object>) parsed;
        } catch (Exception ex) {
            return '{}';
        }

        Map<String, Object> filtered = new Map<String, Object>();
        for (String rawKey : contextFieldsToShare.split(';')) {
            String key = rawKey == null ? null : rawKey.trim();
            if (!String.isBlank(key) && source.containsKey(key)) {
                filtered.put(key, source.get(key));
            }
        }
        return JSON.serialize(filtered);
    }

    private static Boolean objectAvailable(String objectApiName) {
        return Schema.getGlobalDescribe().containsKey(objectApiName);
    }

    private static void validateAnswer(SmartIntakeMetadataService.RuntimeMetadata metadata, SmartIntake_Question__mdt question, String answerValue) {
        String templateKey = metadata.template.Template_Key__c;
        if (question.Is_Required__c && String.isBlank(answerValue)) {
            throw validationError(
                'REQUIRED_ANSWER_MISSING',
                SmartIntakeMetadataService.message(templateKey, 'VALIDATION_REQUIRED', 'Please answer this required question before we continue.'),
                'Question ' + question.Question_Key__c + ' is required.'
            );
        }

        String inputType = normalizeInputType(question.Input_Type__c);
        if (!SUPPORTED_INPUT_TYPES.contains(inputType)) {
            throw new SmartIntakeException(
                'CONFIGURATION',
                'UNSUPPORTED_INPUT_TYPE',
                SmartIntakeMetadataService.message(templateKey, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
                'Question ' + question.Question_Key__c + ' uses unsupported input type ' + question.Input_Type__c + '.'
            );
        }

        if (String.isBlank(answerValue)) {
            return;
        }

        if (FILE_INPUT_TYPES.contains(inputType)) {
            validateFileAnswer(metadata, question, answerValue);
            return;
        }

        if (inputType == 'EMAIL') {
            if (!Pattern.matches(EMAIL_PATTERN, answerValue.trim())) {
                throw validationError('INVALID_EMAIL', 'Please enter a valid email address.', 'Question ' + question.Question_Key__c + ' expected an email address.');
            }
        } else if (inputType == 'DATE') {
            try {
                Date.valueOf(answerValue);
            } catch (Exception ex) {
                throw validationError('INVALID_DATE', 'Please enter a valid date.', 'Question ' + question.Question_Key__c + ' expected an ISO date value.');
            }
        } else if (inputType == 'DATETIME') {
            try {
                DateTime.valueOf(answerValue.replace('T', ' '));
            } catch (Exception ex) {
                throw validationError('INVALID_DATETIME', 'Please enter a valid date and time.', 'Question ' + question.Question_Key__c + ' expected a valid date-time value.');
            }
        } else if (inputType == 'NUMBER' || inputType == 'CURRENCY') {
            try {
                Decimal.valueOf(answerValue);
            } catch (Exception ex) {
                throw validationError('INVALID_NUMBER', 'Please enter a valid number.', 'Question ' + question.Question_Key__c + ' expected a numeric value.');
            }
        } else if (inputType == 'BOOLEAN') {
            String lower = answerValue.toLowerCase();
            if (lower != 'true' && lower != 'false') {
                throw validationError('INVALID_BOOLEAN', 'Please choose yes or no.', 'Question ' + question.Question_Key__c + ' expected true or false.');
            }
        } else if (inputType == 'PICKLIST' || inputType == 'RADIO') {
            assertConfiguredOption(metadata, question, answerValue);
        } else if (inputType == 'MULTI_SELECT') {
            for (String selectedValue : answerValue.split(';')) {
                if (!String.isBlank(selectedValue)) {
                    assertConfiguredOption(metadata, question, selectedValue.trim());
                }
            }
        }

        applyValidationRules(metadata, question, answerValue);
    }

    private static void validateVisibleAnswers(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        Set<String> visibleQuestionKeys
    ) {
        for (SmartIntake_Question__mdt question : metadata.questions) {
            if (!visibleQuestionKeys.contains(question.Question_Key__c) || !answers.containsKey(question.Question_Key__c)) {
                continue;
            }
            Object answerValue = answers.get(question.Question_Key__c);
            validateAnswer(metadata, question, answerValue == null ? null : String.valueOf(answerValue));
            applyBlockingConditions(metadata, question, answers);
        }
    }

    private static void validateFileAnswer(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        String answerValue
    ) {
        List<UploadedFile> uploadedFiles = uploadedFilesFromAnswer(answerValue);
        if (uploadedFiles.isEmpty()) {
            if (question.Is_Required__c) {
                throw validationError(
                    'REQUIRED_ANSWER_MISSING',
                    SmartIntakeMetadataService.message(metadata.template.Template_Key__c, 'VALIDATION_REQUIRED', 'Please answer this required question before we continue.'),
                    'Question ' + question.Question_Key__c + ' requires at least one uploaded file.'
                );
            }
            return;
        }

        SmartIntake_File_Config__mdt fileConfig = metadata.fileConfigsByQuestionKey.get(question.Question_Key__c);
        Integer maxFileCount = fileMaxCount(fileConfig);
        if (uploadedFiles.size() > maxFileCount) {
            throw validationError(
                'FILE_COUNT_EXCEEDED',
                'Please upload no more than ' + String.valueOf(maxFileCount) + ' file' + (maxFileCount == 1 ? '' : 's') + '.',
                'Question ' + question.Question_Key__c + ' received ' + String.valueOf(uploadedFiles.size()) + ' files but allows ' + String.valueOf(maxFileCount) + '.'
            );
        }
        if ((fileConfig == null || fileConfig.Allow_Multiple__c != true) && uploadedFiles.size() > 1) {
            throw validationError(
                'MULTIPLE_FILES_NOT_ALLOWED',
                'Please upload only one file for this question.',
                'Question ' + question.Question_Key__c + ' does not allow multiple files.'
            );
        }

        List<String> acceptedFormats = acceptedFormatsForQuestion(metadata, question);
        for (UploadedFile uploadedFile : uploadedFiles) {
            if (String.isBlank(uploadedFile.documentId) && String.isBlank(uploadedFile.contentVersionId)) {
                throw validationError(
                    'FILE_DOCUMENT_ID_MISSING',
                    'The file upload finished, but I could not read the uploaded file reference. Please try uploading again.',
                    'Question ' + question.Question_Key__c + ' received a file without documentId or contentVersionId.'
                );
            }
            if (!String.isBlank(uploadedFile.documentId)) {
                parseSalesforceId(uploadedFile.documentId, CONTENT_DOCUMENT_PREFIX, 'INVALID_CONTENT_DOCUMENT_ID', 'Uploaded file documentId is not a ContentDocument Id.');
            }
            if (!String.isBlank(uploadedFile.contentVersionId)) {
                parseSalesforceId(uploadedFile.contentVersionId, CONTENT_VERSION_PREFIX, 'INVALID_CONTENT_VERSION_ID', 'Uploaded file contentVersionId is not a ContentVersion Id.');
            }
            assertAcceptedFileName(metadata, question, uploadedFile.name, acceptedFormats);
        }
    }

    private static List<UploadedFile> uploadedFilesFromAnswer(String answerValue) {
        List<UploadedFile> uploadedFiles = new List<UploadedFile>();
        if (String.isBlank(answerValue)) {
            return uploadedFiles;
        }

        Object parsed;
        try {
            parsed = JSON.deserializeUntyped(answerValue);
        } catch (Exception ex) {
            throw validationError(
                'INVALID_FILE_ANSWER_JSON',
                'I could not read the uploaded file answer. Please upload the file again.',
                'File answer JSON could not be parsed: ' + ex.getMessage()
            );
        }
        if (parsed == null) {
            return uploadedFiles;
        }
        if (!(parsed instanceof List<Object>)) {
            throw validationError(
                'INVALID_FILE_ANSWER_FORMAT',
                'I could not read the uploaded file answer. Please upload the file again.',
                'File answer must be a JSON array of uploaded file references.'
            );
        }

        for (Object rawFile : (List<Object>) parsed) {
            if (!(rawFile instanceof Map<String, Object>)) {
                throw validationError(
                    'INVALID_FILE_REFERENCE_FORMAT',
                    'I could not read one uploaded file reference. Please upload the file again.',
                    'Each uploaded file reference must be a JSON object.'
                );
            }
            Map<String, Object> fileValue = (Map<String, Object>) rawFile;
            UploadedFile uploadedFile = new UploadedFile();
            uploadedFile.name = stringValue(fileValue.get('name'));
            uploadedFile.documentId = firstNonBlankString(fileValue.get('documentId'), fileValue.get('contentDocumentId'));
            uploadedFile.contentVersionId = firstNonBlankString(fileValue.get('contentVersionId'), fileValue.get('versionId'));
            uploadedFiles.add(uploadedFile);
        }
        return uploadedFiles;
    }

    private static void assertAcceptedFileName(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        String fileName,
        List<String> acceptedFormats
    ) {
        Set<String> acceptedExtensions = new Set<String>();
        for (String acceptedFormat : acceptedFormats) {
            if (!String.isBlank(acceptedFormat) && acceptedFormat.trim().startsWith('.')) {
                acceptedExtensions.add(acceptedFormat.trim().toLowerCase());
            }
        }
        if (acceptedExtensions.isEmpty() || String.isBlank(fileName)) {
            return;
        }

        String normalizedFileName = fileName.toLowerCase();
        for (String acceptedExtension : acceptedExtensions) {
            if (normalizedFileName.endsWith(acceptedExtension)) {
                return;
            }
        }

        throw validationError(
            'FILE_TYPE_NOT_ALLOWED',
            'Please upload one of the allowed file types.',
            'Question ' + question.Question_Key__c + ' received file ' + fileName +
                ' but accepts ' + String.join(new List<String>(acceptedExtensions), ', ') +
                ' for template ' + metadata.template.Template_Key__c + '.'
        );
    }

    private static Id parseSalesforceId(String value, String expectedPrefix, String errorCode, String adminMessage) {
        if (String.isBlank(value)) {
            return null;
        }
        String trimmedValue = value.trim();
        if (!trimmedValue.startsWith(expectedPrefix)) {
            throw validationError(errorCode, 'I could not read the uploaded file reference. Please upload the file again.', adminMessage);
        }
        try {
            return Id.valueOf(trimmedValue);
        } catch (Exception ex) {
            throw validationError(errorCode, 'I could not read the uploaded file reference. Please upload the file again.', adminMessage);
        }
    }

    private static void applyValidationRules(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        String answerValue
    ) {
        List<SmartIntake_Validation_Rule__mdt> rules = metadata.validationRulesByQuestionKey.get(question.Question_Key__c);
        if (rules == null || rules.isEmpty()) {
            return;
        }

        for (SmartIntake_Validation_Rule__mdt rule : rules) {
            String validationType = normalizeInputType(rule.Validation_Type__c);
            if (!SUPPORTED_VALIDATION_TYPES.contains(validationType)) {
                throw configurationError(
                    metadata.template.Template_Key__c,
                    'UNSUPPORTED_VALIDATION_TYPE',
                    'Validation rule ' + rule.DeveloperName + ' uses unsupported type ' + rule.Validation_Type__c + '.'
                );
            }

            if (validationType == 'REGEX') {
                assertRegexRule(metadata, question, rule, answerValue);
            } else if (validationType == 'MIN_LENGTH') {
                assertMinLengthRule(metadata, question, rule, answerValue);
            } else if (validationType == 'MAX_LENGTH') {
                assertMaxLengthRule(metadata, question, rule, answerValue);
            } else if (validationType == 'MIN_VALUE') {
                assertMinValueRule(metadata, question, rule, answerValue);
            } else if (validationType == 'MAX_VALUE') {
                assertMaxValueRule(metadata, question, rule, answerValue);
            } else if (validationType == 'MIN_DATE') {
                assertMinDateRule(metadata, question, rule, answerValue);
            } else if (validationType == 'MIN_TODAY') {
                assertMinTodayRule(metadata, question, rule, answerValue);
            } else if (validationType == 'MAX_DATE') {
                assertMaxDateRule(metadata, question, rule, answerValue);
            }
        }
    }

    private static void assertRegexRule(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        SmartIntake_Validation_Rule__mdt rule,
        String answerValue
    ) {
        if (String.isBlank(rule.Regex__c)) {
            throw configurationError(metadata.template.Template_Key__c, 'VALIDATION_REGEX_MISSING', 'Validation rule ' + rule.DeveloperName + ' is missing Regex.');
        }

        try {
            if (!Pattern.matches(rule.Regex__c, answerValue)) {
                throw metadataValidationError(metadata, question, rule, 'REGEX_VALIDATION_FAILED');
            }
        } catch (SmartIntakeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw configurationError(metadata.template.Template_Key__c, 'VALIDATION_REGEX_INVALID', 'Validation rule ' + rule.DeveloperName + ' has an invalid regex: ' + ex.getMessage());
        }
    }

    private static void assertMinLengthRule(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        SmartIntake_Validation_Rule__mdt rule,
        String answerValue
    ) {
        if (rule.Min_Length__c == null) {
            throw configurationError(metadata.template.Template_Key__c, 'VALIDATION_MIN_LENGTH_MISSING', 'Validation rule ' + rule.DeveloperName + ' is missing Min Length.');
        }
        if (Decimal.valueOf(String.valueOf(answerValue.length())) < rule.Min_Length__c) {
            throw metadataValidationError(metadata, question, rule, 'MIN_LENGTH_VALIDATION_FAILED');
        }
    }

    private static void assertMaxLengthRule(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        SmartIntake_Validation_Rule__mdt rule,
        String answerValue
    ) {
        if (rule.Max_Length__c == null) {
            throw configurationError(metadata.template.Template_Key__c, 'VALIDATION_MAX_LENGTH_MISSING', 'Validation rule ' + rule.DeveloperName + ' is missing Max Length.');
        }
        if (Decimal.valueOf(String.valueOf(answerValue.length())) > rule.Max_Length__c) {
            throw metadataValidationError(metadata, question, rule, 'MAX_LENGTH_VALIDATION_FAILED');
        }
    }

    private static void assertMinValueRule(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        SmartIntake_Validation_Rule__mdt rule,
        String answerValue
    ) {
        if (rule.Min_Value__c == null) {
            throw configurationError(metadata.template.Template_Key__c, 'VALIDATION_MIN_VALUE_MISSING', 'Validation rule ' + rule.DeveloperName + ' is missing Min Value.');
        }
        if (Decimal.valueOf(answerValue) < rule.Min_Value__c) {
            throw metadataValidationError(metadata, question, rule, 'MIN_VALUE_VALIDATION_FAILED');
        }
    }

    private static void assertMaxValueRule(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        SmartIntake_Validation_Rule__mdt rule,
        String answerValue
    ) {
        if (rule.Max_Value__c == null) {
            throw configurationError(metadata.template.Template_Key__c, 'VALIDATION_MAX_VALUE_MISSING', 'Validation rule ' + rule.DeveloperName + ' is missing Max Value.');
        }
        if (Decimal.valueOf(answerValue) > rule.Max_Value__c) {
            throw metadataValidationError(metadata, question, rule, 'MAX_VALUE_VALIDATION_FAILED');
        }
    }

    private static void assertMinDateRule(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        SmartIntake_Validation_Rule__mdt rule,
        String answerValue
    ) {
        if (rule.Min_Date__c == null) {
            throw configurationError(metadata.template.Template_Key__c, 'VALIDATION_MIN_DATE_MISSING', 'Validation rule ' + rule.DeveloperName + ' is missing Min Date.');
        }
        if (Date.valueOf(answerValue) < rule.Min_Date__c) {
            throw metadataValidationError(metadata, question, rule, 'MIN_DATE_VALIDATION_FAILED');
        }
    }

    private static void assertMinTodayRule(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        SmartIntake_Validation_Rule__mdt rule,
        String answerValue
    ) {
        if (Date.valueOf(answerValue) < Date.today()) {
            throw metadataValidationError(metadata, question, rule, 'MIN_TODAY_VALIDATION_FAILED');
        }
    }

    private static void assertMaxDateRule(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        SmartIntake_Validation_Rule__mdt rule,
        String answerValue
    ) {
        if (rule.Max_Date__c == null) {
            throw configurationError(metadata.template.Template_Key__c, 'VALIDATION_MAX_DATE_MISSING', 'Validation rule ' + rule.DeveloperName + ' is missing Max Date.');
        }
        if (Date.valueOf(answerValue) > rule.Max_Date__c) {
            throw metadataValidationError(metadata, question, rule, 'MAX_DATE_VALIDATION_FAILED');
        }
    }

    private static SmartIntakeException metadataValidationError(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        SmartIntake_Validation_Rule__mdt rule,
        String errorCode
    ) {
        String userMessage = String.isBlank(rule.Error_Message__c)
            ? 'Please check your answer and try again.'
            : rule.Error_Message__c;
        return validationError(
            errorCode,
            userMessage,
            'Question ' + question.Question_Key__c + ' failed validation rule ' + rule.DeveloperName + '.'
        );
    }

    private static void assertConfiguredOption(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        String selectedValue
    ) {
        List<SmartIntake_Option__mdt> options = metadata.optionsByQuestionKey.get(question.Question_Key__c);
        if (options == null || options.isEmpty()) {
            throw new SmartIntakeException(
                'CONFIGURATION',
                'OPTIONS_REQUIRED',
                SmartIntakeMetadataService.message(metadata.template.Template_Key__c, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
                'Question ' + question.Question_Key__c + ' requires active options but none were configured.'
            );
        }

        for (SmartIntake_Option__mdt optionRecord : options) {
            if (optionRecord.Option_Value__c == selectedValue) {
                return;
            }
        }

        throw validationError(
            'INVALID_OPTION',
            'Please choose one of the available options.',
            'Question ' + question.Question_Key__c + ' received value ' + selectedValue + ', which is not an active configured option.'
        );
    }

    private static void assertRequiredAnswers(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        Set<String> visibleQuestionKeys
    ) {
        for (SmartIntake_Question__mdt question : metadata.questions) {
            if (!visibleQuestionKeys.contains(question.Question_Key__c)) {
                continue;
            }
            if (question.Is_Required__c && (!answers.containsKey(question.Question_Key__c) || isBlankValue(answers.get(question.Question_Key__c)))) {
                throw validationError(
                    'REQUIRED_ANSWER_MISSING',
                    SmartIntakeMetadataService.message(metadata.template.Template_Key__c, 'VALIDATION_REQUIRED', 'Please answer this required question before we continue.'),
                    'Required question ' + question.Question_Key__c + ' has not been answered.'
                );
            }
        }
    }

    private static SmartIntakeDTO.IntakeResponse buildRuntimeResponse(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        String requestedSessionId,
        Map<String, Object> answers,
        String userMessage,
        String focusedQuestionKey
    ) {
        return buildRuntimeResponse(metadata, requestedSessionId, answers, userMessage, focusedQuestionKey, true);
    }

    private static SmartIntakeDTO.IntakeResponse buildRuntimeResponse(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        String requestedSessionId,
        Map<String, Object> answers,
        String userMessage,
        String focusedQuestionKey,
        Boolean includeFinalConfirmationCard
    ) {
        SmartIntakeDTO.IntakeResponse response = baseResponse(metadata.template.Template_Key__c, requestedSessionId);
        removeInvisibleAnswers(metadata, answers);
        response.success = true;
        response.answersJson = JSON.serialize(answers);
        response.branding = toBrandingDto(metadata);
        response.brandingJson = JSON.serialize(response.branding);
        response.requiresConsent = metadata.template.Requires_Consent__c;
        response.consentMessage = String.isBlank(metadata.template.Consent_Message__c)
            ? 'I agree that this intake can be saved.'
            : metadata.template.Consent_Message__c;
        response.requiresFinalConfirmation = metadata.template.Requires_Final_Confirmation__c;
        SmartIntakeDTO.Question pendingConfirmationQuestion = pendingExtractedAnswerConfirmationQuestion(metadata, answers);
        response.question = pendingConfirmationQuestion != null
            ? pendingConfirmationQuestion
            : (String.isBlank(focusedQuestionKey)
                ? nextUnansweredQuestion(metadata, answers)
                : questionByKey(metadata, answers, focusedQuestionKey));
        String responseUserMessage = userMessage;
        response.isComplete = response.question == null;
        response.progress = progress(metadata, answers, response.question);
        Boolean isPendingConfirmationQuestion = isPendingExtractedAnswerConfirmationQuestion(
            response.question,
            response.question == null ? null : response.question.questionKey
        );
        response.questionJson = response.question == null || isPendingConfirmationQuestion ? null : JSON.serialize(response.question);
        response.currentQuestion = SmartIntakeAgentTypesMapper.toQuestionContract(response.question);
        response.answerCaptureTemplate = SmartIntakeAgentTypesMapper.toAnswerCapture(response.question);
        removeDisplayText(response.answerCaptureTemplate);
        response.answerCapturePlanJson = isPendingConfirmationQuestion ? null : answerCapturePlanJson(metadata, answers, response.question);
        if (response.question == null &&
            response.requiresFinalConfirmation == true &&
            includeFinalConfirmationCard == true) {
            response.currentQuestion = finalConfirmationQuestionContract(
                metadata,
                answers,
                response.answersJson,
                response.consentMessage,
                response.requiresConsent
            );
            response.answerCaptureTemplate = finalConfirmationAnswerCapture(response.currentQuestion);
            removeDisplayText(response.answerCaptureTemplate);
        }
        applyRuntimeDecision(response, isPendingConfirmationQuestion);
        responseUserMessage = foldUserMessageIntoRenderedQuestion(response, responseUserMessage);
        suppressPlainTextQuestionRenderer(response);
        response.progressJson = JSON.serialize(response.progress);
        response.userMessage = responseUserMessage;
        return response;
    }

    private static SmartIntakeDTO.IntakeResponse buildFinalReviewChangeResponse(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        String requestedSessionId,
        Map<String, Object> answers
    ) {
        SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
            metadata,
            requestedSessionId,
            answers,
            'Sure. Tell me which answer you want to change, or send the corrected answer with the question name.',
            null,
            false
        );
        markWaitingForFinalReviewChange(response);
        return response;
    }

    private static SmartIntakeDTO.IntakeResponse buildFinalReviewDecisionPromptResponse(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        String requestedSessionId,
        Map<String, Object> answers
    ) {
        SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
            metadata,
            requestedSessionId,
            answers,
            'Please reply yes to save this intake, or tell me which answer you want to change.',
            null,
            false
        );
        markWaitingForFinalReviewChange(response);
        return response;
    }

    private static void markWaitingForFinalReviewChange(SmartIntakeDTO.IntakeResponse response) {
        if (response == null) {
            return;
        }
        response.requiresFinalConfirmation = false;
        response.isComplete = false;
        response.hasActiveQuestion = false;
        response.activeQuestionKey = null;
        response.pendingConfirmation = false;
        response.mustRenderCurrentQuestion = false;
        response.rendererMode = 'NONE';
        response.recommendedNextStep = 'WAIT_FOR_CHANGE_DETAILS';
    }

    private static String foldUserMessageIntoRenderedQuestion(
        SmartIntakeDTO.IntakeResponse response,
        String userMessage
    ) {
        if (response == null ||
            response.success != true ||
            response.currentQuestion == null) {
            return userMessage;
        }

        if (response.rendererMode == 'TEXT') {
            return appendTextQuestionToUserMessage(userMessage, response.currentQuestion.questionText);
        }

        if (String.isBlank(userMessage)) {
            return userMessage;
        }

        response.currentQuestion.helpText = prependMessage(userMessage, response.currentQuestion.helpText);
        if (response.question != null) {
            response.question.helpText = prependMessage(userMessage, response.question.helpText);
        }
        if (response.answerCaptureTemplate != null) {
            response.answerCaptureTemplate.helpText = prependMessage(userMessage, response.answerCaptureTemplate.helpText);
        }
        return null;
    }

    private static String appendTextQuestionToUserMessage(String userMessage, String questionText) {
        if (String.isBlank(questionText)) {
            return userMessage;
        }

        String cleanQuestion = questionText.trim();
        if (String.isBlank(userMessage)) {
            return cleanQuestion;
        }

        String cleanMessage = userMessage.trim();
        if (cleanMessage.toLowerCase().contains(cleanQuestion.toLowerCase())) {
            return cleanMessage;
        }
        return cleanMessage + ' ' + cleanQuestion;
    }

    private static void suppressPlainTextQuestionRenderer(SmartIntakeDTO.IntakeResponse response) {
        if (response == null ||
            response.currentQuestion == null ||
            response.rendererMode != 'TEXT' ||
            response.pendingConfirmation == true ||
            response.currentQuestion.questionKey == '__FINAL_CONFIRMATION__' ||
            response.currentQuestion.dataSourceKey == FINAL_REVIEW_DATA_SOURCE_KEY) {
            return;
        }

        response.currentQuestion = null;
        response.mustRenderCurrentQuestion = false;
        response.recommendedNextStep = 'ASK_TEXT_QUESTION';
    }

    private static String prependMessage(String message, String existingText) {
        if (String.isBlank(message)) {
            return existingText;
        }
        String cleanMessage = message.trim();
        if (String.isBlank(existingText)) {
            return cleanMessage;
        }
        String cleanExistingText = existingText.trim();
        if (cleanExistingText.startsWith(cleanMessage)) {
            return cleanExistingText;
        }
        return cleanMessage + '\n\n' + cleanExistingText;
    }

    private static void applyRuntimeDecision(
        SmartIntakeDTO.IntakeResponse response,
        Boolean isPendingConfirmationQuestion
    ) {
        if (response == null) {
            return;
        }
        response.hasActiveQuestion = response.currentQuestion != null;
        response.activeQuestionKey = response.currentQuestion == null ? null : response.currentQuestion.questionKey;
        response.pendingConfirmation = isPendingConfirmationQuestion == true;
        response.mustRenderCurrentQuestion = response.currentQuestion != null;
        response.rendererMode = rendererMode(response.currentQuestion, response.pendingConfirmation);
        if (response.success != true) {
            response.recommendedNextStep = 'ASK_CORRECTION';
        } else if (response.mustRenderCurrentQuestion == true) {
            response.recommendedNextStep = 'RENDER_CURRENT_QUESTION';
        } else if (!String.isBlank(response.primaryRecordId)) {
            response.recommendedNextStep = 'FINAL_RESPONSE';
        } else if (response.isComplete == true) {
            response.recommendedNextStep = 'SAVE_FINAL';
        } else {
            response.recommendedNextStep = 'GET_NEXT';
        }
    }

    private static String rendererMode(SmartIntakeQuestionContract currentQuestion, Boolean pendingConfirmation) {
        if (currentQuestion == null) {
            return 'NONE';
        }
        if (pendingConfirmation == true) {
            return 'PENDING_CONFIRMATION';
        }
        if (!String.isBlank(currentQuestion.uiControl) && currentQuestion.uiControl.trim().toLowerCase().startsWith('c/')) {
            return 'CUSTOM_LWC';
        }
        if (currentQuestion.renderLightningInput == true) {
            return 'LIGHTNING_INPUT';
        }
        if (currentQuestion.options != null && !currentQuestion.options.isEmpty()) {
            return 'OPTIONS';
        }
        return 'TEXT';
    }

    private static Boolean shouldRenderExtractedAnswerWithQuestionControl(SmartIntake_Question__mdt question) {
        return question != null &&
            question.Render_Lightning_Input__c == true &&
            !String.isBlank(question.UI_Control__c) &&
            question.UI_Control__c.trim().toLowerCase().startsWith('c/');
    }

    private static void removeDisplayText(SmartIntakeAnswerCapture capture) {
        if (capture == null) {
            return;
        }
        capture.questionText = null;
        capture.helpText = null;
        capture.placeholderText = null;
    }

    private static SmartIntakeDTO.Question pendingExtractedAnswerConfirmationQuestion(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers
    ) {
        Map<String, Object> pendingConfirmation = pendingExtractedAnswerConfirmation(answers);
        if (pendingConfirmation.isEmpty()) {
            return null;
        }
        String questionKey = String.valueOf(pendingConfirmation.get(CONFIRMATION_QUESTION_KEY_FIELD));
        Object extractedValue = pendingConfirmation.get(CONFIRMATION_ANSWER_VALUE_FIELD);
        SmartIntake_Question__mdt sourceQuestion = metadata.questionsByKey.get(questionKey);
        if (sourceQuestion == null || isBlankValue(extractedValue) || !isQuestionVisible(metadata, sourceQuestion, answers)) {
            return null;
        }

        SmartIntakeDTO.Question confirmationQuestion = new SmartIntakeDTO.Question();
        String answerLabel = extractedAnswerConfirmationLabel(sourceQuestion);
        String answerValue = String.valueOf(extractedValue).trim();
        confirmationQuestion.questionKey = questionKey;
        confirmationQuestion.questionText = 'I found an answer for ' + answerLabel + ' in your message: ' + answerValue + '. Do you want to use it?';
        confirmationQuestion.helpText = null;
        confirmationQuestion.placeholderText = null;
        confirmationQuestion.required = true;
        confirmationQuestion.inputType = 'RADIO';
        confirmationQuestion.uiControl = 'lightning-radio-group';
        confirmationQuestion.renderLightningInput = true;
        confirmationQuestion.answersJson = JSON.serialize(answers);
        confirmationQuestion.options = new List<SmartIntakeDTO.Option>{
            optionDto('Yes', CONFIRM_USE_PENDING_VALUE),
            optionDto('No, change it', CONFIRM_REENTER_VALUE)
        };
        return confirmationQuestion;
    }

    private static String extractedAnswerConfirmationLabel(SmartIntake_Question__mdt sourceQuestion) {
        if (sourceQuestion != null && !String.isBlank(sourceQuestion.Question_Text__c)) {
            String questionText = sourceQuestion.Question_Text__c.trim().replaceAll('\\s+', ' ');
            return '"' + questionText + '"';
        }
        return 'this question';
    }

    private static SmartIntakeDTO.Option optionDto(String label, String value) {
        SmartIntakeDTO.Option option = new SmartIntakeDTO.Option();
        option.label = label;
        option.value = value;
        return option;
    }

    private static SmartIntakeQuestionContract finalConfirmationQuestionContract(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        String answersJson,
        String consentMessage,
        Boolean requiresConsent
    ) {
        SmartIntakeQuestionContract contract = new SmartIntakeQuestionContract();
        contract.questionKey = '__FINAL_CONFIRMATION__';
        contract.questionText = 'All required details have been collected. Please review and confirm to proceed.';
        String confirmationHelpText = requiresConsent == true
            ? consentMessage + ' Type yes to accept and submit this intake.'
            : 'Type yes to submit this intake.';
        String reviewText = finalConfirmationReviewText(metadata, answers);
        contract.helpText = String.isBlank(reviewText)
            ? confirmationHelpText
            : reviewText + '\n\n' + confirmationHelpText;
        contract.placeholderText = requiresConsent == true ? 'Type yes to accept and submit' : 'Type yes to submit';
        contract.required = true;
        contract.inputType = 'TEXT';
        contract.uiControl = 'lightning-input';
        contract.renderLightningInput = false;
        contract.dataSourceKey = FINAL_REVIEW_DATA_SOURCE_KEY;
        contract.dataSourceJson = finalConfirmationReviewJson(metadata, answers);
        contract.answersJson = answersJson;
        return contract;
    }

    private static String finalConfirmationReviewJson(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers
    ) {
        List<Object> reviewItems = new List<Object>();
        if (metadata == null || answers == null) {
            return JSON.serialize(reviewItems);
        }

        for (SmartIntake_Question__mdt question : visibleQuestions(metadata, answers)) {
            if (!hasMeaningfulAnswer(answers, question.Question_Key__c)) {
                continue;
            }

            Map<String, Object> item = new Map<String, Object>();
            item.put('questionKey', question.Question_Key__c);
            item.put('label', reviewLabel(question));
            item.put('value', reviewAnswerValue(answers.get(question.Question_Key__c)));
            reviewItems.add(item);
        }
        return JSON.serialize(reviewItems);
    }

    private static String finalConfirmationReviewText(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers
    ) {
        if (metadata == null || answers == null) {
            return null;
        }

        List<String> lines = new List<String>{ 'Review your answers:' };
        for (SmartIntake_Question__mdt question : visibleQuestions(metadata, answers)) {
            if (!hasMeaningfulAnswer(answers, question.Question_Key__c)) {
                continue;
            }
            lines.add('Q: ' + reviewLabel(question).replaceAll('\\s+', ' ').trim());
            lines.add('A: ' + reviewAnswerValue(answers.get(question.Question_Key__c)).replaceAll('\\s+', ' ').trim());
        }
        return lines.size() > 1 ? String.join(lines, '\n') : null;
    }

    private static String reviewLabel(SmartIntake_Question__mdt question) {
        if (question == null) {
            return 'Question';
        }
        if (!String.isBlank(question.Question_Text__c)) {
            return question.Question_Text__c.trim();
        }
        return String.isBlank(question.Question_Key__c) ? 'Question' : question.Question_Key__c;
    }

    private static String reviewAnswerValue(Object value) {
        if (value == null) {
            return '';
        }
        if (value instanceof List<Object>) {
            List<String> values = new List<String>();
            for (Object item : (List<Object>) value) {
                if (!isBlankValue(item)) {
                    values.add(String.valueOf(item));
                }
            }
            return String.join(values, ', ');
        }
        return String.valueOf(value);
    }

    private static SmartIntakeAnswerCapture finalConfirmationAnswerCapture(SmartIntakeQuestionContract question) {
        SmartIntakeAnswerCapture capture = new SmartIntakeAnswerCapture();
        capture.questionKey = question.questionKey;
        capture.questionText = question.questionText;
        capture.helpText = question.helpText;
        capture.placeholderText = question.placeholderText;
        capture.required = question.required;
        capture.inputType = question.inputType;
        capture.uiControl = question.uiControl;
        capture.renderLightningInput = question.renderLightningInput;
        capture.dataSourceKey = question.dataSourceKey;
        capture.dataSourceJson = question.dataSourceJson;
        capture.answersJson = question.answersJson;
        capture.options = question.options;
        capture.optionsJson = question.optionsJson;
        capture.acceptedFormats = question.acceptedFormats;
        capture.acceptedFormatsJson = question.acceptedFormatsJson;
        capture.allowMultipleFiles = question.allowMultipleFiles;
        capture.maxFileCount = question.maxFileCount;
        return capture;
    }

    private static SmartIntakeHookService.HookContext hookContext(
        String templateKey,
        String intakeSessionId,
        String agentSessionKey,
        String questionKey,
        String answerValue,
        String answersJson,
        String routableId
    ) {
        SmartIntakeHookService.HookContext context = new SmartIntakeHookService.HookContext();
        context.templateKey = templateKey;
        context.intakeSessionId = intakeSessionId;
        context.agentSessionKey = agentSessionKey;
        context.questionKey = questionKey;
        context.answerValue = answerValue;
        context.answersJson = answersJson;
        context.routableId = routableId;
        return context;
    }

    private static void assertHookNextQuestion(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        String nextQuestionKey
    ) {
        if (String.isBlank(nextQuestionKey)) {
            return;
        }
        SmartIntake_Question__mdt nextQuestion = metadata.questionsByKey.get(nextQuestionKey);
        if (nextQuestion == null) {
            throw configurationError(metadata.template.Template_Key__c, 'HOOK_NEXT_QUESTION_NOT_FOUND', 'A SmartIntake hook returned missing question key ' + nextQuestionKey + '.');
        }
        if (!isQuestionVisible(metadata, nextQuestion, answers)) {
            throw configurationError(metadata.template.Template_Key__c, 'HOOK_NEXT_QUESTION_NOT_VISIBLE', 'A SmartIntake hook returned hidden question key ' + nextQuestionKey + '.');
        }
    }

    private static HydratedHookReplayResult replayHydratedAnswerHooks(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        IntakeSessionState sessionState,
        String effectiveContextKey,
        String routableId
    ) {
        HydratedHookReplayResult result = new HydratedHookReplayResult();
        if (metadata == null || sessionState == null || sessionState.answers == null || sessionState.answers.isEmpty()) {
            return result;
        }

        for (SmartIntake_Question__mdt question : metadata.questions) {
            if (question == null ||
                String.isBlank(question.Question_Key__c) ||
                !hasMeaningfulAnswer(sessionState.answers, question.Question_Key__c) ||
                !isQuestionVisible(metadata, question, sessionState.answers)) {
                continue;
            }

            List<SmartIntake_Hook__mdt> hooks = afterAnswerHooks(metadata, question.Question_Key__c);
            Set<String> hookOutputKeys = hookOutputAnswerKeys(hooks);
            if (hooks.isEmpty() || hookOutputKeys.isEmpty() || hasAnyMappedHookOutput(sessionState.answers, hookOutputKeys)) {
                continue;
            }

            Object hydratedAnswer = sessionState.answers.get(question.Question_Key__c);
            String answerValue = hydratedAnswer == null ? null : String.valueOf(hydratedAnswer).trim();
            validateAnswer(metadata, question, answerValue);
            applyBlockingConditions(metadata, question, sessionState.answers);

            Map<String, Object> pendingBeforeHook = pendingAnswers(sessionState.answers);
            SmartIntakeHookService.HookResult hookResult = SmartIntakeHookService.runAfterAnswer(
                metadata,
                hookContext(
                    metadata.template.Template_Key__c,
                    sessionState.sessionId,
                    null,
                    question.Question_Key__c,
                    answerValue,
                    externalAnswersJson(sessionState.answers),
                    routableId
                )
            );
            if (hookResult != null && !String.isBlank(hookResult.updatedAnswersJson)) {
                sessionState.answers.clear();
                sessionState.answers.putAll(readAnswers(hookResult.updatedAnswersJson));
                mergePendingAnswers(sessionState.answers, pendingBeforeHook);
                removeUnconfiguredAnswers(metadata, sessionState.answers);
                rememberRouteContext(sessionState.answers, effectiveContextKey, metadata.template.Template_Key__c);
            }
            addHistoryKey(sessionState, question.Question_Key__c);
            result.changed = true;
            result.userMessage = hookResult == null ? null : hookResult.userMessage;
            if (hookResult != null && !String.isBlank(hookResult.nextQuestionKey)) {
                result.nextQuestionKey = hookResult.nextQuestionKey;
                assertHookNextQuestion(metadata, sessionState.answers, result.nextQuestionKey);
                return result;
            }
            if (hookResult != null && hookResult.blockContinue == true) {
                result.nextQuestionKey = question.Question_Key__c;
                return result;
            }
            result.nextQuestionKey = nextQuestionKeyAfter(metadata, sessionState.answers, question.Question_Key__c);
            return result;
        }
        return result;
    }

    private static List<SmartIntake_Hook__mdt> afterAnswerHooks(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        String questionKey
    ) {
        if (metadata == null || String.isBlank(questionKey)) {
            return new List<SmartIntake_Hook__mdt>();
        }
        List<SmartIntake_Hook__mdt> hooks = metadata.hooksByQuestionAndEvent.get(
            questionKey + ':' + normalizeInputType(SmartIntakeHookService.EVENT_AFTER_ANSWER)
        );
        return hooks == null ? new List<SmartIntake_Hook__mdt>() : hooks;
    }

    private static Boolean hasAnyMappedHookOutput(Map<String, Object> answers, Set<String> hookOutputKeys) {
        if (answers == null || hookOutputKeys == null || hookOutputKeys.isEmpty()) {
            return false;
        }
        for (String answerKey : hookOutputKeys) {
            if (hasMeaningfulAnswer(answers, answerKey)) {
                return true;
            }
        }
        return false;
    }

    private static Set<String> hookOutputAnswerKeys(List<SmartIntake_Hook__mdt> hooks) {
        Set<String> keys = new Set<String>();
        if (hooks == null) {
            return keys;
        }
        for (SmartIntake_Hook__mdt hook : hooks) {
            if (hook != null) {
                addFlowOutputAnswerKeys(keys, hook.Flow_Output_Mappings__c);
            }
        }
        return keys;
    }

    private static SmartIntakeDTO.Question nextUnansweredQuestion(SmartIntakeMetadataService.RuntimeMetadata metadata, Map<String, Object> answers) {
        SmartIntakeDTO.Question configuredStartQuestion = nextConfiguredStartQuestion(metadata, answers);
        if (configuredStartQuestion != null) {
            return configuredStartQuestion;
        }

        for (SmartIntake_Question__mdt question : visibleQuestions(metadata, answers)) {
            if (!answers.containsKey(question.Question_Key__c)) {
                return toQuestionDto(metadata, question, answers);
            }
        }
        return null;
    }

    private static SmartIntakeDTO.Question nextConfiguredStartQuestion(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers
    ) {
        String startQuestionKey = metadata.template == null ? null : metadata.template.Start_Question_Key__c;
        if (String.isBlank(startQuestionKey) || answers.containsKey(startQuestionKey)) {
            return null;
        }

        SmartIntake_Question__mdt question = metadata.questionsByKey.get(startQuestionKey);
        if (question == null || !isQuestionVisible(metadata, question, answers)) {
            return null;
        }
        return toQuestionDto(metadata, question, answers);
    }

    private static String nextQuestionKeyAfter(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        String currentQuestionKey
    ) {
        Boolean afterCurrent = false;
        for (SmartIntake_Question__mdt question : visibleQuestions(metadata, answers)) {
            if (afterCurrent && !answers.containsKey(question.Question_Key__c)) {
                return question.Question_Key__c;
            }
            if (question.Question_Key__c == currentQuestionKey) {
                afterCurrent = true;
            }
        }
        return null;
    }

    private static String firstUnansweredQuestionKeyAtOrAfter(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        String focusedQuestionKey
    ) {
        if (String.isBlank(focusedQuestionKey)) {
            return null;
        }

        Boolean atFocusedQuestion = false;
        for (SmartIntake_Question__mdt question : visibleQuestions(metadata, answers)) {
            if (question.Question_Key__c == focusedQuestionKey) {
                atFocusedQuestion = true;
            }
            if (atFocusedQuestion && !hasMeaningfulAnswer(answers, question.Question_Key__c)) {
                return question.Question_Key__c;
            }
        }
        return null;
    }

    private static String firstFinalReviewProposedAnswerKey(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        Map<String, Object> proposedAnswers
    ) {
        if (metadata == null || proposedAnswers == null || proposedAnswers.isEmpty()) {
            return null;
        }

        for (SmartIntake_Question__mdt question : visibleQuestions(metadata, answers)) {
            if (question == null ||
                String.isBlank(question.Question_Key__c) ||
                !proposedAnswers.containsKey(question.Question_Key__c) ||
                isBlankValue(proposedAnswers.get(question.Question_Key__c))) {
                continue;
            }
            return question.Question_Key__c;
        }
        return null;
    }

    private static String finalReviewTargetQuestionKeyFromAgent(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        String changeQuestionKey
    ) {
        if (metadata == null || answers == null || String.isBlank(changeQuestionKey)) {
            return null;
        }

        String requestedQuestionKey = changeQuestionKey.trim();
        SmartIntake_Question__mdt question = metadata.questionsByKey.get(requestedQuestionKey);
        if (question == null ||
            !isQuestionVisible(metadata, question, answers) ||
            !hasMeaningfulAnswer(answers, requestedQuestionKey)) {
            return null;
        }

        return requestedQuestionKey;
    }

    private static SmartIntakeDTO.IntakeResponse reopenFinalReviewQuestion(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        IntakeSessionState sessionState,
        String templateKey,
        String effectiveContextKey,
        String questionKey
    ) {
        sessionState.answers.remove(questionKey);
        clearPendingAnswers(sessionState.answers);
        setFinalReviewEditTarget(sessionState.answers, questionKey);
        rememberRouteContext(sessionState.answers, effectiveContextKey, templateKey);

        SmartIntakeDTO.IntakeResponse response = buildRuntimeResponse(
            metadata,
            sessionState.sessionId,
            sessionState.answers,
            'Sure. Let us update that answer.',
            questionKey
        );
        persistSessionState(
            sessionState,
            templateKey,
            sessionState.answers,
            response.question == null ? questionKey : response.question.questionKey,
            SESSION_STATUS_IN_PROGRESS
        );
        return response;
    }

    private static void setFinalReviewEditTarget(Map<String, Object> answers, String questionKey) {
        if (answers == null) {
            return;
        }
        if (String.isBlank(questionKey)) {
            clearFinalReviewEditTarget(answers);
            return;
        }
        answers.put(FINAL_REVIEW_EDIT_TARGET_KEY, questionKey.trim());
    }

    private static String finalReviewEditTargetKey(Map<String, Object> answers) {
        if (answers == null || !answers.containsKey(FINAL_REVIEW_EDIT_TARGET_KEY)) {
            return null;
        }
        Object targetQuestionKey = answers.get(FINAL_REVIEW_EDIT_TARGET_KEY);
        return targetQuestionKey == null ? null : String.valueOf(targetQuestionKey).trim();
    }

    private static Boolean isFinalReviewEditTarget(Map<String, Object> answers, String questionKey) {
        return !String.isBlank(questionKey) && questionKey == finalReviewEditTargetKey(answers);
    }

    private static void clearFinalReviewEditTarget(Map<String, Object> answers) {
        if (answers != null) {
            answers.remove(FINAL_REVIEW_EDIT_TARGET_KEY);
        }
    }

    private static void clearFinalReviewEditTarget(Map<String, Object> answers, String questionKey) {
        if (isFinalReviewEditTarget(answers, questionKey)) {
            clearFinalReviewEditTarget(answers);
        }
    }

    private static String resolveSubmittedAnswerValue(
        String rawAnswerValue,
        Map<String, Object> proposedAnswers,
        String questionKey
    ) {
        String answerValue = rawAnswerValue == null ? null : rawAnswerValue.trim();
        if (!String.isBlank(answerValue) || proposedAnswers == null || !proposedAnswers.containsKey(questionKey)) {
            return answerValue;
        }
        Object proposedValue = proposedAnswers.get(questionKey);
        return proposedValue == null ? null : String.valueOf(proposedValue).trim();
    }

    private static String resolveRenderedPendingControlValue(
        SmartIntake_Question__mdt question,
        Map<String, Object> answers,
        String questionKey,
        String submittedAnswerValue
    ) {
        if (!shouldRenderExtractedAnswerWithQuestionControl(question) ||
            String.isBlank(questionKey) ||
            String.isBlank(submittedAnswerValue) ||
            submittedAnswerValue.trim() != CONFIRM_USE_PENDING_VALUE) {
            return submittedAnswerValue;
        }

        String pendingValue = pendingAnswerValue(answers, questionKey);
        return String.isBlank(pendingValue) ? submittedAnswerValue : pendingValue;
    }

    private static Boolean isCurrentProposedAnswer(
        String rawAnswerValue,
        Map<String, Object> proposedAnswers,
        String questionKey
    ) {
        String answerValue = rawAnswerValue == null ? null : rawAnswerValue.trim();
        if (!String.isBlank(answerValue) || proposedAnswers == null || String.isBlank(questionKey) || !proposedAnswers.containsKey(questionKey)) {
            return false;
        }
        return !isBlankValue(proposedAnswers.get(questionKey));
    }

    private static Boolean isRenderedPendingControlAnswer(
        SmartIntake_Question__mdt question,
        Map<String, Object> answers,
        Map<String, Object> proposedAnswers,
        String questionKey,
        String submittedAnswerValue
    ) {
        if (!shouldRenderExtractedAnswerWithQuestionControl(question) ||
            String.isBlank(questionKey) ||
            String.isBlank(submittedAnswerValue) ||
            proposedAnswers == null ||
            !proposedAnswers.containsKey(questionKey)) {
            return false;
        }

        String pendingValue = pendingAnswerValue(answers, questionKey);
        if (String.isBlank(pendingValue)) {
            return false;
        }

        String submitted = normalizedAnswerValue(question, submittedAnswerValue);
        String pending = normalizedAnswerValue(question, pendingValue);
        return !String.isBlank(submitted) && submitted == pending;
    }

    private static Boolean requiresExtractedAnswerConfirmation(SmartIntake_Question__mdt question) {
        return question != null && question.Confirm_AI_Extracted_Answer__c == true;
    }

    private static void stageProposedAnswers(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        Map<String, Object> proposedAnswers,
        String currentQuestionKey
    ) {
        if (proposedAnswers == null || proposedAnswers.isEmpty()) {
            return;
        }

        Map<String, Object> pending = pendingAnswers(answers);
        for (String proposedKey : proposedAnswers.keySet()) {
            if (String.isBlank(proposedKey) ||
                proposedKey == currentQuestionKey ||
                !metadata.questionsByKey.containsKey(proposedKey) ||
                hasMeaningfulAnswer(answers, proposedKey)) {
                continue;
            }

            Object proposedValue = proposedAnswers.get(proposedKey);
            if (isBlankValue(proposedValue)) {
                continue;
            }
            pending.put(proposedKey, String.valueOf(proposedValue).trim());
        }
        setPendingAnswers(answers, pending);
    }

    private static String advanceThroughPendingAnswers(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        String sessionId,
        String agentSessionKey,
        String routableId,
        String focusedQuestionKey
    ) {
        String nextQuestionKey = firstUnansweredQuestionKeyAtOrAfter(metadata, answers, focusedQuestionKey);
        Integer guard = 0;
        while (!String.isBlank(nextQuestionKey) && guard < metadata.questions.size()) {
            guard++;
            Map<String, Object> pending = pendingAnswers(answers);
            if (!pending.containsKey(nextQuestionKey)) {
                return nextQuestionKey;
            }

            Object pendingValue = pending.remove(nextQuestionKey);
            setPendingAnswers(answers, pending);
            SmartIntake_Question__mdt pendingQuestion = metadata.questionsByKey.get(nextQuestionKey);
            if (pendingQuestion == null || isBlankValue(pendingValue)) {
                return nextQuestionKey;
            }

            String answerValue = String.valueOf(pendingValue).trim();
            validateAnswer(metadata, pendingQuestion, answerValue);
            if (requiresExtractedAnswerConfirmation(pendingQuestion)) {
                if (shouldRenderExtractedAnswerWithQuestionControl(pendingQuestion)) {
                    pending.put(nextQuestionKey, answerValue);
                    setPendingAnswers(answers, pending);
                    return nextQuestionKey;
                }
                setPendingExtractedAnswerConfirmation(answers, nextQuestionKey, answerValue);
                return nextQuestionKey;
            }
            answers.put(nextQuestionKey, answerValue);
            applyBlockingConditions(metadata, pendingQuestion, answers);

            Map<String, Object> pendingBeforeHook = pendingAnswers(answers);
            SmartIntakeHookService.HookResult hookResult = SmartIntakeHookService.runAfterAnswer(
                metadata,
                hookContext(
                    metadata.template.Template_Key__c,
                    sessionId,
                    agentSessionKey,
                    nextQuestionKey,
                    answerValue,
                    externalAnswersJson(answers),
                    routableId
                )
            );
            if (hookResult != null && !String.isBlank(hookResult.updatedAnswersJson)) {
                answers.clear();
                answers.putAll(readAnswers(hookResult.updatedAnswersJson));
                mergePendingAnswers(answers, pendingBeforeHook);
                removeUnconfiguredAnswers(metadata, answers);
            }
            if (hookResult != null && hookResult.blockContinue == true && String.isBlank(hookResult.nextQuestionKey)) {
                return nextQuestionKey;
            }
            nextQuestionKey = hookResult != null && !String.isBlank(hookResult.nextQuestionKey)
                ? hookResult.nextQuestionKey
                : nextQuestionKeyAfter(metadata, answers, nextQuestionKey);
            if (!String.isBlank(nextQuestionKey)) {
                assertHookNextQuestion(metadata, answers, nextQuestionKey);
            }
            nextQuestionKey = firstUnansweredQuestionKeyAtOrAfter(metadata, answers, nextQuestionKey);
        }
        return null;
    }

    private static Boolean hasMeaningfulAnswer(Map<String, Object> answers, String questionKey) {
        return answers != null && answers.containsKey(questionKey) && !isBlankValue(answers.get(questionKey));
    }

    private static Map<String, Object> pendingAnswers(Map<String, Object> answers) {
        Map<String, Object> pending = new Map<String, Object>();
        if (answers == null || !answers.containsKey(PENDING_ANSWERS_KEY)) {
            return pending;
        }
        Object pendingValue = answers.get(PENDING_ANSWERS_KEY);
        try {
            pending.putAll((Map<String, Object>) pendingValue);
            return pending;
        } catch (Exception castEx) {
            // Pending values can also be serialized through session persistence.
        }
        try {
            Object parsed = JSON.deserializeUntyped(String.valueOf(pendingValue));
            pending.putAll((Map<String, Object>) parsed);
        } catch (Exception ex) {
            return new Map<String, Object>();
        }
        return pending;
    }

    private static String pendingAnswerValue(Map<String, Object> answers, String questionKey) {
        if (String.isBlank(questionKey)) {
            return null;
        }
        Map<String, Object> pending = pendingAnswers(answers);
        if (!pending.containsKey(questionKey) || isBlankValue(pending.get(questionKey))) {
            return null;
        }
        return String.valueOf(pending.get(questionKey)).trim();
    }

    private static Boolean hasPendingExtractedAnswerConfirmation(Map<String, Object> answers) {
        return !pendingExtractedAnswerConfirmation(answers).isEmpty();
    }

    private static Map<String, Object> pendingExtractedAnswerConfirmation(Map<String, Object> answers) {
        Map<String, Object> confirmation = new Map<String, Object>();
        if (answers == null || !answers.containsKey(PENDING_CONFIRMATION_KEY)) {
            return confirmation;
        }
        Object value = answers.get(PENDING_CONFIRMATION_KEY);
        try {
            confirmation.putAll((Map<String, Object>) value);
            return confirmation;
        } catch (Exception castEx) {
            // Confirmation values can also be serialized through session persistence.
        }
        try {
            Object parsed = JSON.deserializeUntyped(String.valueOf(value));
            confirmation.putAll((Map<String, Object>) parsed);
        } catch (Exception ex) {
            return new Map<String, Object>();
        }
        return confirmation;
    }

    private static void setPendingExtractedAnswerConfirmation(
        Map<String, Object> answers,
        String questionKey,
        Object answerValue
    ) {
        if (answers == null || String.isBlank(questionKey) || isBlankValue(answerValue)) {
            return;
        }
        answers.put(
            PENDING_CONFIRMATION_KEY,
            new Map<String, Object>{
                CONFIRMATION_QUESTION_KEY_FIELD => questionKey,
                CONFIRMATION_ANSWER_VALUE_FIELD => String.valueOf(answerValue).trim()
            }
        );
    }

    private static void clearPendingExtractedAnswerConfirmation(Map<String, Object> answers) {
        if (answers != null) {
            answers.remove(PENDING_CONFIRMATION_KEY);
        }
    }

    private static void setPendingAnswers(Map<String, Object> answers, Map<String, Object> pending) {
        if (answers == null) {
            return;
        }
        if (pending == null || pending.isEmpty()) {
            answers.remove(PENDING_ANSWERS_KEY);
            return;
        }
        answers.put(PENDING_ANSWERS_KEY, pending);
    }

    private static void mergePendingAnswers(Map<String, Object> answers, Map<String, Object> pending) {
        if (answers == null || pending == null || pending.isEmpty()) {
            return;
        }
        Map<String, Object> merged = pendingAnswers(answers);
        for (String key : pending.keySet()) {
            if (!String.isBlank(key) && !merged.containsKey(key)) {
                merged.put(key, pending.get(key));
            }
        }
        setPendingAnswers(answers, merged);
    }

    private static void clearPendingAnswers(Map<String, Object> answers) {
        if (answers != null) {
            answers.remove(PENDING_ANSWERS_KEY);
            answers.remove(PENDING_CONFIRMATION_KEY);
        }
    }

    private static void removePendingAnswer(Map<String, Object> answers, String questionKey) {
        if (answers == null || String.isBlank(questionKey)) {
            return;
        }
        Map<String, Object> pending = pendingAnswers(answers);
        if (!pending.containsKey(questionKey)) {
            return;
        }
        pending.remove(questionKey);
        setPendingAnswers(answers, pending);
    }

    private static void logRouteDiagnostic(
        String methodName,
        String status,
        String requestedTemplateKey,
        String requestedContextKey,
        String effectiveContextKey,
        String routableId,
        String requestedSessionId,
        String resolvedSessionId,
        String resolvedTemplateKey,
        String resolvedQuestionKey,
        String answersJson
    ) {
        try {
            Map<String, Object> context = new Map<String, Object>{
                'status' => valueForLog(status),
                'requestedTemplateKey' => valueForLog(requestedTemplateKey),
                'requestedContextKey' => valueForLog(requestedContextKey),
                'effectiveContextKey' => valueForLog(effectiveContextKey),
                'normalizedRequestedContextKey' => normalizeContextKey(requestedContextKey),
                'normalizedEffectiveContextKey' => normalizeContextKey(effectiveContextKey),
                'routableId' => valueForLog(routableId),
                'recordId' => valueForLog(routableId),
                'requestedSessionId' => valueForLog(requestedSessionId),
                'resolvedSessionId' => valueForLog(resolvedSessionId),
                'resolvedTemplateKey' => valueForLog(resolvedTemplateKey),
                'resolvedQuestionKey' => valueForLog(resolvedQuestionKey),
                'questionKey' => valueForLog(resolvedQuestionKey)
            };
            addAnswersSummaryForLog(context, answersJson);
            SmartIntakeApexDebugLogService.logMessage(
                'INFO',
                'SmartIntakeService',
                methodName,
                resolvedTemplateKey,
                resolvedSessionId,
                null,
                ROUTE_DIAGNOSTIC_CODE,
                'SmartIntake resolved route to template ' + valueForLog(resolvedTemplateKey) +
                    ' and question ' + valueForLog(resolvedQuestionKey) + '.',
                'Compare requestedContextKey, effectiveContextKey, routableId, and answer route keys to identify why the agent selected this template.',
                context
            );
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'SmartIntake route diagnostic log could not be recorded: ' + ex.getMessage());
        }
    }

    private static void addAnswersSummaryForLog(Map<String, Object> context, String answersJson) {
        if (context == null) {
            return;
        }
        context.put('hasAnswersJson', !String.isBlank(answersJson));
        if (String.isBlank(answersJson)) {
            return;
        }
        try {
            Map<String, Object> answers = readAnswers(answersJson);
            List<String> answerKeys = new List<String>();
            answerKeys.addAll(answers.keySet());
            answerKeys.sort();
            context.put('answersJsonReadable', true);
            context.put('answerKeys', answerKeys);
            context.put('storedRouteContextKey', valueForLog(answers.get(ROUTE_CONTEXT_ANSWER_KEY)));
            context.put('storedRouteTemplateKey', valueForLog(answers.get(ROUTE_TEMPLATE_ANSWER_KEY)));
        } catch (Exception ex) {
            context.put('answersJsonReadable', false);
            context.put('answersJsonError', ex.getMessage());
        }
    }

    private static String valueForLog(Object value) {
        return isBlankValue(value) ? null : String.valueOf(value).trim();
    }

    private static String effectiveRouteContextKey(String smartIntakeContextKey, String answersJson) {
        return effectiveRouteContextKey(smartIntakeContextKey, answersJson, null);
    }

    private static String effectiveRouteContextKey(String smartIntakeContextKey, String answersJson, String routableId) {
        String routableContextKey = contextKeyForRoutableId(routableId);
        if (!String.isBlank(routableContextKey)) {
            return routableContextKey;
        }

        if (!String.isBlank(smartIntakeContextKey)) {
            return smartIntakeContextKey.trim();
        }

        Map<String, Object> answers = readAnswers(answersJson);
        if (answers.containsKey(ROUTE_CONTEXT_ANSWER_KEY) && !isBlankValue(answers.get(ROUTE_CONTEXT_ANSWER_KEY))) {
            return String.valueOf(answers.get(ROUTE_CONTEXT_ANSWER_KEY)).trim();
        }
        if (answers.containsKey(ROUTE_TEMPLATE_ANSWER_KEY) && !isBlankValue(answers.get(ROUTE_TEMPLATE_ANSWER_KEY))) {
            return String.valueOf(answers.get(ROUTE_TEMPLATE_ANSWER_KEY)).trim();
        }

        if (String.isBlank(routableId)) {
            String recentMessagingContextKey = recentMessagingSessionContextKey();
            if (!String.isBlank(recentMessagingContextKey)) {
                return recentMessagingContextKey;
            }
        }

        return null;
    }

    private static String sessionIdForResolvedTemplate(String sessionId, String smartIntakeContextKey, String templateKey) {
        if (String.isBlank(sessionId) || String.isBlank(smartIntakeContextKey) || String.isBlank(templateKey)) {
            return sessionId;
        }

        String contextTemplateKey = templateKeyForContext(smartIntakeContextKey);
        if (String.isBlank(contextTemplateKey) || !sameRouteValue(contextTemplateKey, templateKey)) {
            return sessionId;
        }

        String sessionTemplateKey = templateKeyForSession(sessionId);
        return !String.isBlank(sessionTemplateKey) && !sameRouteValue(sessionTemplateKey, templateKey) ? null : sessionId;
    }

    private static String answersJsonForResolvedTemplate(String answersJson, String smartIntakeContextKey, String templateKey) {
        if (String.isBlank(answersJson) || String.isBlank(smartIntakeContextKey) || String.isBlank(templateKey)) {
            return answersJson;
        }

        String contextTemplateKey = templateKeyForContext(smartIntakeContextKey);
        if (String.isBlank(contextTemplateKey) || !sameRouteValue(contextTemplateKey, templateKey)) {
            return answersJson;
        }

        Map<String, Object> answers = readAnswers(answersJson);
        Object routeTemplate = answers.get(ROUTE_TEMPLATE_ANSWER_KEY);
        if (isBlankValue(routeTemplate) || sameRouteValue(String.valueOf(routeTemplate), templateKey)) {
            return answersJson;
        }

        return null;
    }

    private static void rememberRouteContext(Map<String, Object> answers, String smartIntakeContextKey, String templateKey) {
        if (answers == null) {
            return;
        }
        if (!String.isBlank(smartIntakeContextKey)) {
            answers.put(ROUTE_CONTEXT_ANSWER_KEY, smartIntakeContextKey.trim());
        }
        if (!String.isBlank(templateKey)) {
            answers.put(ROUTE_TEMPLATE_ANSWER_KEY, templateKey.trim());
        }
    }

    private static void removeInternalAnswerKeys(Map<String, Object> answers) {
        if (answers != null) {
            answers.remove(PENDING_ANSWERS_KEY);
            answers.remove(PENDING_CONFIRMATION_KEY);
            answers.remove(FINAL_REVIEW_EDIT_TARGET_KEY);
            answers.remove(ROUTE_CONTEXT_ANSWER_KEY);
            answers.remove(ROUTE_TEMPLATE_ANSWER_KEY);
        }
    }

    private static String externalAnswersJson(Map<String, Object> answers) {
        Map<String, Object> externalAnswers = new Map<String, Object>();
        if (answers != null) {
            externalAnswers.putAll(answers);
            removeInternalAnswerKeys(externalAnswers);
        }
        return JSON.serialize(externalAnswers);
    }

    private static String answerCapturePlanJson(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        SmartIntakeDTO.Question currentQuestion
    ) {
        List<Object> capturePlan = new List<Object>();
        String currentQuestionKey = currentQuestion == null ? null : currentQuestion.questionKey;
        Boolean finalReviewCaptureMode = currentQuestion == null &&
            nextUnansweredQuestion(metadata, answers) == null;
        String finalReviewEditTargetKey = finalReviewEditTargetKey(answers);
        for (SmartIntake_Question__mdt question : metadata.questions) {
            if (FILE_INPUT_TYPES.contains(normalizeInputType(question.Input_Type__c))) {
                continue;
            }
            Boolean isCurrentQuestion = question.Question_Key__c == currentQuestionKey;
            Boolean isCurrentConfirmationQuestion = isPendingExtractedAnswerConfirmationQuestion(currentQuestion, question.Question_Key__c);
            Boolean isVisibleNow = isQuestionVisible(metadata, question, answers);
            Boolean isAnswered = hasMeaningfulAnswer(answers, question.Question_Key__c);
            Map<String, Object> entry = new Map<String, Object>();
            entry.put('questionKey', question.Question_Key__c);
            entry.put('questionText', isCurrentQuestion && currentQuestion != null ? currentQuestion.questionText : question.Question_Text__c);
            entry.put('helpText', isCurrentQuestion && currentQuestion != null ? currentQuestion.helpText : question.Help_Text__c);
            entry.put('placeholderText', isCurrentQuestion && currentQuestion != null ? currentQuestion.placeholderText : question.Placeholder_Text__c);
            entry.put('inputType', isCurrentQuestion && currentQuestion != null ? currentQuestion.inputType : normalizeInputType(question.Input_Type__c));
            entry.put('required', question.Is_Required__c);
            entry.put('isCurrent', isCurrentQuestion);
            entry.put('isAnswered', isAnswered);
            entry.put('isVisibleNow', isVisibleNow);
            entry.put('confirmExtractedAnswerBeforeSaving', requiresExtractedAnswerConfirmation(question));
            entry.put('isPendingExtractedAnswerConfirmation', isCurrentConfirmationQuestion);
            if (isCurrentQuestion && currentQuestion != null && currentQuestion.options != null && !currentQuestion.options.isEmpty()) {
                entry.put('options', currentQuestion.options);
            }
            entry.put(
                'captureAllowedFromLatestMessage',
                isCurrentConfirmationQuestion
                    ? false
                    : isVisibleNow && (
                        !isAnswered ||
                        (finalReviewCaptureMode &&
                            !String.isBlank(finalReviewEditTargetKey) &&
                            question.Question_Key__c == finalReviewEditTargetKey)
                    )
            );
            entry.put(
                'captureInstruction',
                isCurrentConfirmationQuestion
                    ? 'This is an active Apex confirmation gate for an answer extracted from the user message. Show the returned currentQuestion/questionText only. On the next user turn, submit answerValue __SMARTINTAKE_USE_PENDING_ANSWER__ for yes/use/confirm/proceed, or __SMARTINTAKE_ENTER_ANOTHER_ANSWER__ for no/change. Do not ask the original metadata question while this confirmation is active.'
                    : 'If the latest user message answers this metadata question, include exactly this questionKey and value in proposedAnswersJson even when isCurrent is false. Never invent alternate semantic keys or template-specific aliases. Apex will validate and apply answers in configured metadata order, and will ask the user to confirm first when confirmExtractedAnswerBeforeSaving is true.'
            );
            capturePlan.add(entry);
        }
        return JSON.serialize(capturePlan);
    }

    private static Boolean isPendingExtractedAnswerConfirmationQuestion(SmartIntakeDTO.Question currentQuestion, String questionKey) {
        if (currentQuestion == null || currentQuestion.questionKey != questionKey || currentQuestion.options == null) {
            return false;
        }
        for (SmartIntakeDTO.Option option : currentQuestion.options) {
            if (option != null &&
                (option.value == CONFIRM_USE_PENDING_VALUE || option.value == CONFIRM_REENTER_VALUE)) {
                return true;
            }
        }
        return false;
    }

    private static String previousQuestionKey(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        String currentQuestionKey
    ) {
        String previousKey;
        for (SmartIntake_Question__mdt question : visibleQuestions(metadata, answers)) {
            if (question.Question_Key__c == currentQuestionKey) {
                return previousKey;
            }
            previousKey = question.Question_Key__c;
        }
        return previousKey;
    }

    private static void pruneAnswersAfter(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        String questionKey
    ) {
        Boolean removeFollowingAnswers = false;
        for (SmartIntake_Question__mdt question : metadata.questions) {
            if (removeFollowingAnswers) {
                answers.remove(question.Question_Key__c);
            }
            if (question.Question_Key__c == questionKey) {
                removeFollowingAnswers = true;
            }
        }
    }

    private static void removeInvisibleAnswers(SmartIntakeMetadataService.RuntimeMetadata metadata, Map<String, Object> answers) {
        Set<String> visibleKeys = visibleQuestionKeys(metadata, answers);
        Set<String> configuredQuestionKeys = metadata.questionsByKey.keySet();
        for (String answerKey : new List<String>(answers.keySet())) {
            if (configuredQuestionKeys.contains(answerKey) && !visibleKeys.contains(answerKey)) {
                answers.remove(answerKey);
            }
        }
    }

    private static void removeUnconfiguredAnswers(SmartIntakeMetadataService.RuntimeMetadata metadata, Map<String, Object> answers) {
        if (metadata == null || answers == null || answers.isEmpty()) {
            return;
        }

        Set<String> configuredKeys = configuredAnswerKeys(metadata);
        for (String answerKey : new List<String>(answers.keySet())) {
            if (answerKey == PENDING_ANSWERS_KEY) {
                removeUnconfiguredPendingAnswers(metadata, answers);
                continue;
            }
            if (answerKey == PENDING_CONFIRMATION_KEY) {
                removeUnconfiguredPendingExtractedAnswerConfirmation(metadata, answers);
                continue;
            }
            if (answerKey == FINAL_REVIEW_EDIT_TARGET_KEY) {
                removeUnconfiguredFinalReviewEditTarget(metadata, answers);
                continue;
            }
            if (!configuredKeys.contains(answerKey)) {
                answers.remove(answerKey);
            }
        }
    }

    private static void removeUnconfiguredFinalReviewEditTarget(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers
    ) {
        String targetQuestionKey = finalReviewEditTargetKey(answers);
        if (String.isBlank(targetQuestionKey) || !metadata.questionsByKey.containsKey(targetQuestionKey)) {
            clearFinalReviewEditTarget(answers);
        }
    }

    private static void removeUnconfiguredPendingAnswers(SmartIntakeMetadataService.RuntimeMetadata metadata, Map<String, Object> answers) {
        Map<String, Object> pending = pendingAnswers(answers);
        for (String pendingKey : new List<String>(pending.keySet())) {
            if (!metadata.questionsByKey.containsKey(pendingKey)) {
                pending.remove(pendingKey);
            }
        }
        setPendingAnswers(answers, pending);
    }

    private static void removeUnconfiguredPendingExtractedAnswerConfirmation(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers
    ) {
        Map<String, Object> pendingConfirmation = pendingExtractedAnswerConfirmation(answers);
        String questionKey = pendingConfirmation.containsKey(CONFIRMATION_QUESTION_KEY_FIELD)
            ? String.valueOf(pendingConfirmation.get(CONFIRMATION_QUESTION_KEY_FIELD))
            : null;
        if (String.isBlank(questionKey) ||
            !metadata.questionsByKey.containsKey(questionKey) ||
            isBlankValue(pendingConfirmation.get(CONFIRMATION_ANSWER_VALUE_FIELD))) {
            clearPendingExtractedAnswerConfirmation(answers);
        }
    }

    private static Set<String> configuredAnswerKeys(SmartIntakeMetadataService.RuntimeMetadata metadata) {
        Set<String> keys = new Set<String>();
        keys.add(ROUTE_CONTEXT_ANSWER_KEY);
        keys.add(ROUTE_TEMPLATE_ANSWER_KEY);
        if (metadata == null) {
            return keys;
        }
        keys.addAll(metadata.questionsByKey.keySet());
        keys.addAll(metadata.bindingsByQuestionKey.keySet());

        for (SmartIntake_Question__mdt question : metadata.questions) {
            addAnswerKey(keys, question.Data_Source_Key__c);
        }
        for (SmartIntake_Condition__mdt condition : metadata.conditions) {
            addAnswerKey(keys, condition.Source_Question_Key__c);
            addAnswerKey(keys, condition.Target_Question_Key__c);
        }
        for (SmartIntake_Hook__mdt hook : metadata.hooks) {
            addAnswerKey(keys, hook.Question_Key__c);
            addFlowOutputAnswerKeys(keys, hook.Flow_Output_Mappings__c);
        }
        for (SmartIntake_Matching_Rule__mdt matchingRule : metadata.matchingRules) {
            addAnswerKey(keys, matchingRule.Question_Key__c);
        }
        for (SmartIntake_Context_Config__mdt contextConfig : metadata.contextConfigs) {
            addAnswerKey(keys, contextConfig.Question_Key__c);
            addAnswerKey(keys, contextConfig.Filter_Source_Question_Key__c);
        }
        for (SmartIntake_File_Config__mdt fileConfig : metadata.fileConfigs) {
            addAnswerKey(keys, fileConfig.Question_Key__c);
        }
        return keys;
    }

    private static void addFlowOutputAnswerKeys(Set<String> keys, String mappingsText) {
        if (String.isBlank(mappingsText)) {
            return;
        }

        String normalized = mappingsText.replace('\r\n', '\n').replace('\r', '\n').replace(';', '\n');
        for (String rawLine : normalized.split('\n')) {
            String line = rawLine == null ? null : rawLine.trim();
            if (String.isBlank(line) || line.startsWith('#')) {
                continue;
            }
            String delimiter = line.contains('->') ? '->' : (line.contains('=') ? '=' : (line.contains(':') ? ':' : null));
            if (String.isBlank(delimiter)) {
                continue;
            }
            Integer delimiterIndex = line.indexOf(delimiter);
            String answerKey = delimiterIndex < 0 ? null : line.substring(delimiterIndex + delimiter.length()).trim();
            addAnswerKey(keys, answerKey);
        }
    }

    private static void addAnswerKey(Set<String> keys, String answerKey) {
        if (keys == null || String.isBlank(answerKey)) {
            return;
        }
        String trimmedKey = answerKey.trim();
        if (trimmedKey.startsWith('$')) {
            trimmedKey = trimmedKey.substring(1);
        }
        if (Pattern.matches('^[A-Za-z][A-Za-z0-9_]*$', trimmedKey)) {
            keys.add(trimmedKey);
        }
    }

    private static SmartIntakeDTO.Question questionByKey(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        String questionKey
    ) {
        SmartIntake_Question__mdt question = metadata.questionsByKey.get(questionKey);
        if (question == null || !isQuestionVisible(metadata, question, answers)) {
            return nextUnansweredQuestion(metadata, answers);
        }
        return toQuestionDto(metadata, question, answers);
    }

    private static SmartIntakeDTO.Question toQuestionDto(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        Map<String, Object> answers
    ) {
        SmartIntakeDTO.Question dto = new SmartIntakeDTO.Question();
        dto.questionKey = question.Question_Key__c;
        dto.questionText = question.Question_Text__c;
        dto.helpText = question.Help_Text__c;
        dto.placeholderText = question.Placeholder_Text__c;
        dto.required = question.Is_Required__c;
        dto.inputType = normalizeInputType(question.Input_Type__c);
        dto.uiControl = question.UI_Control__c;
        dto.renderLightningInput = question.Render_Lightning_Input__c == true;
        dto.value = answers.containsKey(question.Question_Key__c) && answers.get(question.Question_Key__c) != null
            ? String.valueOf(answers.get(question.Question_Key__c))
            : pendingAnswerValue(answers, question.Question_Key__c);
        dto.dataSourceKey = question.Data_Source_Key__c;
        if (!String.isBlank(dto.dataSourceKey) && answers.containsKey(dto.dataSourceKey)) {
            dto.dataSourceJson = JSON.serialize(answers.get(dto.dataSourceKey));
        }
        dto.answersJson = JSON.serialize(answers);
        dto.options = toOptionDtos(metadata, question, answers);
        if (FILE_INPUT_TYPES.contains(dto.inputType)) {
            SmartIntake_File_Config__mdt fileConfig = metadata.fileConfigsByQuestionKey.get(question.Question_Key__c);
            dto.acceptedFormats = acceptedFormatsForQuestion(metadata, question);
            dto.allowMultipleFiles = fileConfig != null && fileConfig.Allow_Multiple__c == true;
            dto.maxFileCount = fileMaxCount(fileConfig);
        }
        return dto;
    }

    private static SmartIntakeDTO.Branding toBrandingDto(SmartIntakeMetadataService.RuntimeMetadata metadata) {
        SmartIntakeDTO.Branding branding = new SmartIntakeDTO.Branding();
        if (metadata.brandingConfig == null) {
            branding.agentDisplayName = 'SmartIntake Agent';
            branding.avatarIconName = 'utility:einstein';
            return branding;
        }

        branding.agentDisplayName = String.isBlank(metadata.brandingConfig.Agent_Display_Name__c)
            ? 'SmartIntake Agent'
            : metadata.brandingConfig.Agent_Display_Name__c;
        branding.avatarIconName = String.isBlank(metadata.brandingConfig.Avatar_Icon_Name__c)
            ? 'utility:einstein'
            : metadata.brandingConfig.Avatar_Icon_Name__c;
        branding.avatarImageUrl = metadata.brandingConfig.Avatar_Image_URL__c;
        branding.welcomeMessage = metadata.brandingConfig.Welcome_Message__c;
        return branding;
    }

    private static List<SmartIntakeDTO.Option> toOptionDtos(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        Map<String, Object> answers
    ) {
        List<SmartIntake_Option__mdt> optionRecords = dependentFilteredOptions(
            metadata,
            question,
            answers,
            metadata.optionsByQuestionKey.get(question.Question_Key__c)
        );
        List<SmartIntakeDTO.Option> options = new List<SmartIntakeDTO.Option>();
        if (optionRecords == null) {
            return options;
        }

        for (SmartIntake_Option__mdt optionRecord : optionRecords) {
            SmartIntakeDTO.Option dto = new SmartIntakeDTO.Option();
            dto.label = optionRecord.Option_Label__c;
            dto.value = optionRecord.Option_Value__c;
            options.add(dto);
        }
        return options;
    }

    private static List<SmartIntake_Option__mdt> dependentFilteredOptions(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        Map<String, Object> answers,
        List<SmartIntake_Option__mdt> optionRecords
    ) {
        if (optionRecords == null || optionRecords.isEmpty()) {
            return optionRecords;
        }
        SmartIntake_Field_Binding__mdt binding = metadata.bindingsByQuestionKey.get(question.Question_Key__c);
        if (binding == null) {
            return optionRecords;
        }
        Schema.DescribeFieldResult fieldDescribe = describeBoundField(binding.Object_API_Name__c, binding.Field_API_Name__c);
        if (!isPicklistField(fieldDescribe) || !fieldDescribe.isDependentPicklist()) {
            return optionRecords;
        }
        String controllerFieldName = controllerFieldApiName(fieldDescribe);
        if (String.isBlank(controllerFieldName)) {
            return optionRecords;
        }
        SmartIntake_Field_Binding__mdt controllerBinding = bindingForField(metadata, binding.Object_API_Name__c, controllerFieldName);
        if (controllerBinding == null || !answers.containsKey(controllerBinding.Question_Key__c)) {
            return optionRecords;
        }
        String controllerValue = String.valueOf(answers.get(controllerBinding.Question_Key__c));
        if (String.isBlank(controllerValue)) {
            return optionRecords;
        }
        Integer controllerIndex = controllerPicklistIndex(binding.Object_API_Name__c, controllerFieldName, controllerValue);
        if (controllerIndex == null) {
            return optionRecords;
        }

        Map<String, Schema.PicklistEntry> entriesByValue = new Map<String, Schema.PicklistEntry>();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            entriesByValue.put(entry.getValue(), entry);
        }

        List<SmartIntake_Option__mdt> filtered = new List<SmartIntake_Option__mdt>();
        Boolean appliedMatrix = false;
        for (SmartIntake_Option__mdt optionRecord : optionRecords) {
            Schema.PicklistEntry entry = entriesByValue.get(optionRecord.Option_Value__c);
            if (entry == null || !entry.isActive()) {
                continue;
            }
            String validFor = picklistValidFor(entry);
            if (String.isBlank(validFor)) {
                filtered.add(optionRecord);
                continue;
            }
            appliedMatrix = true;
            if (isValidForControllerValue(validFor, controllerIndex)) {
                filtered.add(optionRecord);
            }
        }
        return appliedMatrix ? filtered : optionRecords;
    }

    private static Schema.DescribeFieldResult describeBoundField(String objectApiName, String fieldApiName) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            return null;
        }
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType == null) {
            return null;
        }
        Schema.SObjectField fieldToken = objectType.getDescribe().fields.getMap().get(fieldApiName);
        return fieldToken == null ? null : fieldToken.getDescribe();
    }

    private static Boolean isPicklistField(Schema.DescribeFieldResult fieldDescribe) {
        return fieldDescribe != null &&
            (fieldDescribe.getType() == Schema.DisplayType.Picklist ||
                fieldDescribe.getType() == Schema.DisplayType.MultiPicklist);
    }

    private static String controllerFieldApiName(Schema.DescribeFieldResult fieldDescribe) {
        if (!isPicklistField(fieldDescribe) || !fieldDescribe.isDependentPicklist()) {
            return null;
        }
        Schema.SObjectField controller = fieldDescribe.getController();
        return controller == null ? null : controller.getDescribe().getName();
    }

    private static SmartIntake_Field_Binding__mdt bindingForField(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        String objectApiName,
        String fieldApiName
    ) {
        for (SmartIntake_Field_Binding__mdt binding : metadata.bindings) {
            if (binding.Object_API_Name__c == objectApiName && binding.Field_API_Name__c == fieldApiName) {
                return binding;
            }
        }
        return null;
    }

    private static Integer controllerPicklistIndex(String objectApiName, String fieldApiName, String selectedValue) {
        Schema.DescribeFieldResult controllerDescribe = describeBoundField(objectApiName, fieldApiName);
        if (!isPicklistField(controllerDescribe)) {
            return null;
        }
        Integer index = 0;
        for (Schema.PicklistEntry entry : controllerDescribe.getPicklistValues()) {
            if (entry.getValue() == selectedValue) {
                return index;
            }
            index++;
        }
        return null;
    }

    private static String picklistValidFor(Schema.PicklistEntry entry) {
        Map<String, Object> serialized = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry));
        return serialized == null ? null : (String) serialized.get('validFor');
    }

    private static Boolean isValidForControllerValue(String validFor, Integer controllerIndex) {
        if (String.isBlank(validFor) || controllerIndex == null || controllerIndex < 0) {
            return false;
        }
        Integer bitIndex = controllerIndex;
        Integer charIndex = bitIndex / 6;
        if (charIndex >= validFor.length()) {
            return false;
        }
        String encodedChar = validFor.substring(charIndex, charIndex + 1);
        Integer charValue = BASE64_CHARS.indexOf(encodedChar);
        if (charValue < 0) {
            return false;
        }
        Integer bit = 5 - Math.mod(bitIndex, 6);
        Integer mask = 1;
        for (Integer i = 0; i < bit; i++) {
            mask *= 2;
        }
        Integer remainder = Math.mod(charValue, mask * 2);
        return remainder >= mask;
    }

    private static List<String> acceptedFormatsForQuestion(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question
    ) {
        SmartIntake_File_Config__mdt fileConfig = metadata.fileConfigsByQuestionKey.get(question.Question_Key__c);
        String acceptedFormats = fileConfig == null ? null : fileConfig.Accepted_File_Types__c;
        if (String.isBlank(acceptedFormats)) {
            String inputType = normalizeInputType(question.Input_Type__c);
            if (inputType == 'PDF') {
                acceptedFormats = '.pdf';
            } else if (inputType == 'IMAGE') {
                acceptedFormats = '.png,.jpg,.jpeg,.gif,.webp';
            }
        }

        List<String> formats = new List<String>();
        if (String.isBlank(acceptedFormats)) {
            return formats;
        }
        for (String format : acceptedFormats.replace(';', ',').split(',')) {
            if (!String.isBlank(format)) {
                formats.add(format.trim());
            }
        }
        return formats;
    }

    private static Integer fileMaxCount(SmartIntake_File_Config__mdt fileConfig) {
        Integer maxFileCount = fileConfig == null || fileConfig.Max_File_Count__c == null
            ? DEFAULT_FILE_COUNT
            : Integer.valueOf(fileConfig.Max_File_Count__c);
        if (maxFileCount < 1) {
            return DEFAULT_FILE_COUNT;
        }
        if (maxFileCount > MAX_FILE_COUNT) {
            return MAX_FILE_COUNT;
        }
        return maxFileCount;
    }

    private static SmartIntakeDTO.Progress progress(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        SmartIntakeDTO.Question currentQuestion
    ) {
        List<SmartIntake_Question__mdt> visibleQuestions = visibleQuestions(metadata, answers);
        Integer total = visibleQuestions.size();
        Integer completed = 0;
        Integer currentStep = total;
        for (Integer index = 0; index < visibleQuestions.size(); index++) {
            SmartIntake_Question__mdt question = visibleQuestions[index];
            if (currentQuestion != null && question.Question_Key__c == currentQuestion.questionKey) {
                currentStep = index + 1;
            }
            if (answers.containsKey(question.Question_Key__c)) {
                completed++;
            }
        }

        SmartIntakeDTO.Progress progress = new SmartIntakeDTO.Progress();
        progress.totalSteps = total;
        progress.currentStep = currentQuestion == null ? total : currentStep;
        progress.percentageComplete = total == 0 ? 0 : Integer.valueOf(Math.floor((Decimal.valueOf(completed) / Decimal.valueOf(total)) * 100));
        return progress;
    }

    private static List<SmartIntake_Question__mdt> visibleQuestions(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers
    ) {
        List<SmartIntake_Question__mdt> visibleQuestions = new List<SmartIntake_Question__mdt>();
        for (SmartIntake_Question__mdt question : metadata.questions) {
            if (isQuestionVisible(metadata, question, answers)) {
                visibleQuestions.add(question);
            }
        }
        return visibleQuestions;
    }

    private static Set<String> visibleQuestionKeys(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers
    ) {
        Set<String> visibleQuestionKeys = new Set<String>();
        for (SmartIntake_Question__mdt question : visibleQuestions(metadata, answers)) {
            visibleQuestionKeys.add(question.Question_Key__c);
        }
        return visibleQuestionKeys;
    }

    private static Boolean isQuestionVisible(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        Map<String, Object> answers
    ) {
        if (question == null) {
            return false;
        }

        List<SmartIntake_Condition__mdt> conditions = metadata.conditionsByTargetQuestionKey.get(question.Question_Key__c);
        if (conditions == null || conditions.isEmpty()) {
            return true;
        }

        for (ConditionGroup conditionGroup : conditionGroups(metadata, conditions, false)) {
            if (conditionGroup.action == 'SHOW_WHEN' && !conditionGroupMatches(metadata, conditionGroup, answers)) {
                return false;
            }
            if (conditionGroup.action == 'HIDE_WHEN' && conditionGroupMatches(metadata, conditionGroup, answers)) {
                return false;
            }
        }
        return true;
    }

    private static void applyBlockingConditions(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Question__mdt question,
        Map<String, Object> answers
    ) {
        if (question == null) {
            return;
        }

        List<SmartIntake_Condition__mdt> conditions = metadata.conditionsByTargetQuestionKey.get(question.Question_Key__c);
        if (conditions == null || conditions.isEmpty()) {
            return;
        }

        for (ConditionGroup conditionGroup : conditionGroups(metadata, conditions, true)) {
            if (conditionGroup.action == 'BLOCK_WHEN' && conditionGroupMatches(metadata, conditionGroup, answers)) {
                throw validationError(
                    'CONDITION_BLOCKED',
                    String.isBlank(conditionGroup.userMessage) ? 'That answer does not meet the configured intake rules.' : conditionGroup.userMessage,
                    'Question ' + question.Question_Key__c + ' was blocked by condition group ' + conditionGroup.groupKey + '.'
                );
            }
        }
    }

    private static List<ConditionGroup> conditionGroups(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        List<SmartIntake_Condition__mdt> conditions,
        Boolean blockingOnly
    ) {
        Map<String, ConditionGroup> groupsByKey = new Map<String, ConditionGroup>();
        List<ConditionGroup> groups = new List<ConditionGroup>();
        for (SmartIntake_Condition__mdt condition : conditions) {
            String action = normalizeInputType(condition.Action__c);
            String operator = normalizeInputType(condition.Operator__c);
            if (!SUPPORTED_CONDITION_ACTIONS.contains(action)) {
                throw configurationError(
                    metadata.template.Template_Key__c,
                    'UNSUPPORTED_CONDITION_ACTION',
                    'Condition ' + condition.DeveloperName + ' uses unsupported action ' + condition.Action__c + '.'
                );
            }
            if (!SUPPORTED_CONDITION_OPERATORS.contains(operator)) {
                throw configurationError(
                    metadata.template.Template_Key__c,
                    'UNSUPPORTED_CONDITION_OPERATOR',
                    'Condition ' + condition.DeveloperName + ' uses unsupported operator ' + condition.Operator__c + '.'
                );
            }
            if (blockingOnly && action != 'BLOCK_WHEN') {
                continue;
            }
            if (!blockingOnly && action == 'BLOCK_WHEN') {
                continue;
            }

            String logic = String.isBlank(condition.Condition_Logic__c) ? 'ALL' : normalizeInputType(condition.Condition_Logic__c);
            if (!SUPPORTED_CONDITION_LOGICS.contains(logic)) {
                throw configurationError(
                    metadata.template.Template_Key__c,
                    'UNSUPPORTED_CONDITION_LOGIC',
                    'Condition ' + condition.DeveloperName + ' uses unsupported logic ' + condition.Condition_Logic__c + '.'
                );
            }

            String groupKey = String.isBlank(condition.Condition_Group_Key__c)
                ? condition.Condition_Key__c
                : condition.Condition_Group_Key__c;
            if (String.isBlank(groupKey)) {
                groupKey = condition.DeveloperName;
            }
            String mapKey = action + '|' + groupKey;
            ConditionGroup conditionGroup = groupsByKey.get(mapKey);
            if (conditionGroup == null) {
                conditionGroup = new ConditionGroup();
                conditionGroup.action = action;
                conditionGroup.groupKey = groupKey;
                conditionGroup.logic = logic;
                conditionGroup.customLogic = condition.Custom_Logic__c;
                conditionGroup.userMessage = condition.User_Message__c;
                conditionGroup.conditions = new List<SmartIntake_Condition__mdt>();
                groupsByKey.put(mapKey, conditionGroup);
                groups.add(conditionGroup);
            } else if (conditionGroup.logic != logic) {
                throw configurationError(
                    metadata.template.Template_Key__c,
                    'MIXED_CONDITION_GROUP_LOGIC',
                    'Condition group ' + groupKey + ' mixes multiple Condition Logic values.'
                );
            }

            if (String.isBlank(conditionGroup.customLogic) && !String.isBlank(condition.Custom_Logic__c)) {
                conditionGroup.customLogic = condition.Custom_Logic__c;
            }
            if (String.isBlank(conditionGroup.userMessage) && !String.isBlank(condition.User_Message__c)) {
                conditionGroup.userMessage = condition.User_Message__c;
            }
            conditionGroup.conditions.add(condition);
        }
        return groups;
    }

    private static Boolean conditionGroupMatches(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        ConditionGroup conditionGroup,
        Map<String, Object> answers
    ) {
        if (conditionGroup == null || conditionGroup.conditions == null || conditionGroup.conditions.isEmpty()) {
            return true;
        }

        if (conditionGroup.logic == 'CUSTOM') {
            return evaluateCustomConditionLogic(metadata, conditionGroup, answers);
        }

        Boolean anyMatched = false;
        for (SmartIntake_Condition__mdt condition : conditionGroup.conditions) {
            Boolean matches = conditionMatches(metadata, condition, answers);
            if (conditionGroup.logic == 'ANY' && matches) {
                return true;
            }
            if (conditionGroup.logic == 'ALL' && !matches) {
                return false;
            }
            anyMatched = anyMatched || matches;
        }
        return conditionGroup.logic == 'ANY' ? anyMatched : true;
    }

    private static Boolean evaluateCustomConditionLogic(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        ConditionGroup conditionGroup,
        Map<String, Object> answers
    ) {
        if (String.isBlank(conditionGroup.customLogic)) {
            throw configurationError(
                metadata.template.Template_Key__c,
                'CONDITION_CUSTOM_LOGIC_MISSING',
                'Condition group ' + conditionGroup.groupKey + ' uses CUSTOM logic but has no Custom Logic expression.'
            );
        }

        Map<Integer, Boolean> valuesByNumber = new Map<Integer, Boolean>();
        Integer fallbackNumber = 1;
        for (SmartIntake_Condition__mdt condition : conditionGroup.conditions) {
            Integer conditionNumber = condition.Condition_Number__c == null
                ? fallbackNumber
                : condition.Condition_Number__c.intValue();
            valuesByNumber.put(conditionNumber, conditionMatches(metadata, condition, answers));
            fallbackNumber++;
        }

        try {
            return new ConditionLogicParser(conditionGroup.customLogic, valuesByNumber).parse();
        } catch (ConditionLogicException ex) {
            throw configurationError(
                metadata.template.Template_Key__c,
                'CONDITION_CUSTOM_LOGIC_INVALID',
                'Condition group ' + conditionGroup.groupKey + ' has invalid Custom Logic: ' + ex.getMessage()
            );
        }
    }

    private static Boolean conditionMatches(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Condition__mdt condition,
        Map<String, Object> answers
    ) {
        Object sourceAnswer = answers.get(condition.Source_Question_Key__c);
        String operator = normalizeInputType(condition.Operator__c);

        try {
            if (operator == 'IS_BLANK') {
                return isBlankValue(sourceAnswer);
            }
            if (operator == 'IS_NOT_BLANK') {
                return !isBlankValue(sourceAnswer);
            }
            if (operator == 'EQUALS') {
                return conditionValueEquals(metadata, condition, sourceAnswer);
            }
            if (operator == 'NOT_EQUALS') {
                return !conditionValueEquals(metadata, condition, sourceAnswer);
            }
            if (operator == 'IN') {
                return conditionValueIn(sourceAnswer, condition.Compare_Value__c);
            }
            if (operator == 'NOT_IN') {
                return !conditionValueIn(sourceAnswer, condition.Compare_Value__c);
            }
            if (operator == 'CONTAINS') {
                return conditionValueContains(sourceAnswer, condition.Compare_Value__c);
            }
            if (operator == 'NOT_CONTAINS') {
                return !conditionValueContains(sourceAnswer, condition.Compare_Value__c);
            }
            if (operator == 'STARTS_WITH') {
                return conditionValueStartsWith(sourceAnswer, condition.Compare_Value__c);
            }
            if (operator == 'ENDS_WITH') {
                return conditionValueEndsWith(sourceAnswer, condition.Compare_Value__c);
            }

            Integer comparison = conditionValueComparison(metadata, condition, sourceAnswer);
            if (comparison == null) {
                return false;
            }
            if (operator == 'GREATER_THAN' || operator == 'AFTER') {
                return comparison > 0;
            }
            if (operator == 'GREATER_OR_EQUAL' || operator == 'ON_OR_AFTER') {
                return comparison >= 0;
            }
            if (operator == 'LESS_THAN' || operator == 'BEFORE') {
                return comparison < 0;
            }
            if (operator == 'LESS_OR_EQUAL' || operator == 'ON_OR_BEFORE') {
                return comparison <= 0;
            }
        } catch (SmartIntakeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw configurationError(
                metadata.template.Template_Key__c,
                'CONDITION_COMPARE_VALUE_INVALID',
                'Condition ' + condition.DeveloperName + ' has an invalid compare value: ' + ex.getMessage()
            );
        }
        return false;
    }

    private static Boolean conditionValueEquals(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Condition__mdt condition,
        Object sourceAnswer
    ) {
        if (isBlankValue(sourceAnswer)) {
            return String.isBlank(condition.Compare_Value__c);
        }
        if (isComparableCondition(metadata, condition)) {
            Integer comparison = conditionValueComparison(metadata, condition, sourceAnswer);
            return comparison != null && comparison == 0;
        }
        return normalizeConditionValue(String.valueOf(sourceAnswer)) == normalizeConditionValue(condition.Compare_Value__c);
    }

    private static Boolean conditionValueIn(Object sourceAnswer, String compareValues) {
        if (isBlankValue(sourceAnswer) || String.isBlank(compareValues)) {
            return false;
        }

        Set<String> expectedValues = splitConditionValues(compareValues);
        for (String sourceValue : splitConditionValues(String.valueOf(sourceAnswer))) {
            if (expectedValues.contains(sourceValue)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean conditionValueContains(Object sourceAnswer, String compareValue) {
        if (isBlankValue(sourceAnswer) || String.isBlank(compareValue)) {
            return false;
        }
        return normalizeConditionValue(String.valueOf(sourceAnswer)).contains(normalizeConditionValue(compareValue));
    }

    private static Boolean conditionValueStartsWith(Object sourceAnswer, String compareValue) {
        if (isBlankValue(sourceAnswer) || String.isBlank(compareValue)) {
            return false;
        }
        return normalizeConditionValue(String.valueOf(sourceAnswer)).startsWith(normalizeConditionValue(compareValue));
    }

    private static Boolean conditionValueEndsWith(Object sourceAnswer, String compareValue) {
        if (isBlankValue(sourceAnswer) || String.isBlank(compareValue)) {
            return false;
        }
        return normalizeConditionValue(String.valueOf(sourceAnswer)).endsWith(normalizeConditionValue(compareValue));
    }

    private static Integer conditionValueComparison(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Condition__mdt condition,
        Object sourceAnswer
    ) {
        if (isBlankValue(sourceAnswer) || String.isBlank(condition.Compare_Value__c)) {
            return null;
        }

        SmartIntake_Question__mdt sourceQuestion = metadata.questionsByKey.get(condition.Source_Question_Key__c);
        String inputType = sourceQuestion == null ? null : normalizeInputType(sourceQuestion.Input_Type__c);
        if (inputType == 'DATE') {
            return compareDates(Date.valueOf(String.valueOf(sourceAnswer)), conditionDateValue(condition.Compare_Value__c));
        }
        if (inputType == 'DATETIME') {
            return compareDateTimes(conditionDateTimeValue(String.valueOf(sourceAnswer)), conditionDateTimeValue(condition.Compare_Value__c));
        }
        if (inputType == 'NUMBER' || inputType == 'CURRENCY') {
            return compareDecimals(Decimal.valueOf(String.valueOf(sourceAnswer)), Decimal.valueOf(condition.Compare_Value__c));
        }
        return normalizeConditionValue(String.valueOf(sourceAnswer)).compareTo(normalizeConditionValue(condition.Compare_Value__c));
    }

    private static Boolean isComparableCondition(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        SmartIntake_Condition__mdt condition
    ) {
        SmartIntake_Question__mdt sourceQuestion = metadata.questionsByKey.get(condition.Source_Question_Key__c);
        String inputType = sourceQuestion == null ? null : normalizeInputType(sourceQuestion.Input_Type__c);
        return inputType == 'DATE' || inputType == 'DATETIME' || inputType == 'NUMBER' || inputType == 'CURRENCY';
    }

    private static Integer compareDates(Date sourceDate, Date compareDate) {
        if (sourceDate == compareDate) {
            return 0;
        }
        return sourceDate < compareDate ? -1 : 1;
    }

    private static Integer compareDateTimes(DateTime sourceDateTime, DateTime compareDateTime) {
        if (sourceDateTime == compareDateTime) {
            return 0;
        }
        return sourceDateTime < compareDateTime ? -1 : 1;
    }

    private static Integer compareDecimals(Decimal sourceNumber, Decimal compareNumber) {
        if (sourceNumber == compareNumber) {
            return 0;
        }
        return sourceNumber < compareNumber ? -1 : 1;
    }

    private static Date conditionDateValue(String rawValue) {
        String value = rawValue == null ? null : rawValue.trim();
        String upper = String.isBlank(value) ? '' : value.toUpperCase();
        if (upper == 'TODAY') {
            return Date.today();
        }
        if (upper == 'TOMORROW') {
            return Date.today().addDays(1);
        }
        if (upper == 'YESTERDAY') {
            return Date.today().addDays(-1);
        }
        if (upper.startsWith('TODAY+') || upper.startsWith('TODAY-')) {
            return Date.today().addDays(conditionDayOffset(upper.substring(5)));
        }
        if (upper.startsWith('+') || upper.startsWith('-')) {
            return Date.today().addDays(conditionDayOffset(upper));
        }
        return Date.valueOf(value);
    }

    private static DateTime conditionDateTimeValue(String rawValue) {
        String value = rawValue == null ? null : rawValue.trim();
        String upper = String.isBlank(value) ? '' : value.toUpperCase();
        if (upper == 'TODAY' || upper == 'TOMORROW' || upper == 'YESTERDAY' ||
            upper.startsWith('TODAY+') || upper.startsWith('TODAY-') ||
            upper.startsWith('+') || upper.startsWith('-')) {
            return DateTime.newInstance(conditionDateValue(value), Time.newInstance(0, 0, 0, 0));
        }
        return DateTime.valueOf(value.replace('T', ' ').replace('Z', ''));
    }

    private static Integer conditionDayOffset(String rawOffset) {
        String offset = rawOffset == null ? null : rawOffset.trim();
        if (String.isBlank(offset)) {
            return 0;
        }
        if (offset.startsWith('+')) {
            offset = offset.substring(1);
        }
        return Integer.valueOf(offset);
    }

    private static Set<String> splitConditionValues(String values) {
        Set<String> normalizedValues = new Set<String>();
        if (String.isBlank(values)) {
            return normalizedValues;
        }
        for (String value : values.split(';')) {
            if (!String.isBlank(value)) {
                normalizedValues.add(normalizeConditionValue(value));
            }
        }
        return normalizedValues;
    }

    private static String normalizeConditionValue(String value) {
        return String.isBlank(value) ? '' : value.trim().toLowerCase();
    }

    private class ConditionGroup {
        String action;
        String groupKey;
        String logic;
        String customLogic;
        String userMessage;
        List<SmartIntake_Condition__mdt> conditions;
    }

    private class ConditionLogicException extends Exception {}

    private class ConditionLogicParser {
        private List<String> tokens = new List<String>();
        private Integer index = 0;
        private Map<Integer, Boolean> valuesByNumber;

        ConditionLogicParser(String expression, Map<Integer, Boolean> valuesByNumber) {
            this.valuesByNumber = valuesByNumber;
            String prepared = expression == null ? '' : expression.replace('(', ' ( ').replace(')', ' ) ');
            for (String token : prepared.split('\\s+')) {
                if (!String.isBlank(token)) {
                    tokens.add(token.trim().toUpperCase());
                }
            }
        }

        Boolean parse() {
            if (tokens.isEmpty()) {
                throw new ConditionLogicException('Expression is blank.');
            }
            Boolean result = parseOr();
            if (index < tokens.size()) {
                throw new ConditionLogicException('Unexpected token ' + tokens[index] + '.');
            }
            return result;
        }

        private Boolean parseOr() {
            Boolean result = parseAnd();
            while (peek('OR')) {
                consume();
                result = result || parseAnd();
            }
            return result;
        }

        private Boolean parseAnd() {
            Boolean result = parseNot();
            while (peek('AND')) {
                consume();
                result = result && parseNot();
            }
            return result;
        }

        private Boolean parseNot() {
            if (peek('NOT')) {
                consume();
                return !parseNot();
            }
            return parsePrimary();
        }

        private Boolean parsePrimary() {
            if (peek('(')) {
                consume();
                Boolean result = parseOr();
                if (!peek(')')) {
                    throw new ConditionLogicException('Missing closing parenthesis.');
                }
                consume();
                return result;
            }

            if (index >= tokens.size()) {
                throw new ConditionLogicException('Expected condition number.');
            }
            String token = consume();
            Integer conditionNumber;
            try {
                conditionNumber = Integer.valueOf(token);
            } catch (Exception ex) {
                throw new ConditionLogicException('Expected condition number but found ' + token + '.');
            }
            if (!valuesByNumber.containsKey(conditionNumber)) {
                throw new ConditionLogicException('Condition number ' + String.valueOf(conditionNumber) + ' is not defined.');
            }
            return valuesByNumber.get(conditionNumber);
        }

        private Boolean peek(String expectedToken) {
            return index < tokens.size() && tokens[index] == expectedToken;
        }

        private String consume() {
            String token = tokens[index];
            index++;
            return token;
        }
    }

    private static IntakeSessionState loadSessionState(String templateKey, String requestedSessionId, String answersJson) {
        IntakeSessionState state = new IntakeSessionState();
        state.sessionId = ensureSessionId(requestedSessionId);
        state.templateKey = templateKey;
        state.status = SESSION_STATUS_IN_PROGRESS;
        state.answers = readAnswers(answersJson);

        if (String.isBlank(requestedSessionId)) {
            return state;
        }

        assertValidIntakeSessionId(requestedSessionId);
        assertSessionReadAccess();
        List<SmartIntake_Session__c> sessions = [
            SELECT Id, Session_Id__c, Template_Key__c, Answers_JSON__c, Current_Question_Key__c,
                   Question_History_JSON__c, Skipped_Question_Keys_JSON__c, Status__c
            FROM SmartIntake_Session__c
            WHERE Session_Id__c = :requestedSessionId
              AND Template_Key__c = :templateKey
            WITH USER_MODE
            ORDER BY Last_Activity_Date__c DESC NULLS LAST, CreatedDate DESC
            LIMIT 1
        ];

        if (sessions.isEmpty()) {
            return state;
        }

        SmartIntake_Session__c sessionRecord = sessions[0];
        return sessionStateFromRecord(sessionRecord);
    }

    private static IntakeSessionState recentActiveSessionStateForTemplate(String templateKey) {
        if (String.isBlank(templateKey)) {
            return null;
        }

        assertSessionReadAccess();
        DateTime cutoff = System.now().addMinutes(-MESSAGING_CONTEXT_FALLBACK_WINDOW_MINUTES);
        List<SmartIntake_Session__c> sessions = [
            SELECT Id, Session_Id__c, Template_Key__c, Answers_JSON__c, Current_Question_Key__c,
                   Question_History_JSON__c, Skipped_Question_Keys_JSON__c, Status__c
            FROM SmartIntake_Session__c
            WHERE Template_Key__c = :templateKey
              AND Status__c = :SESSION_STATUS_IN_PROGRESS
              AND Current_Question_Key__c != null
              AND Last_Activity_Date__c >= :cutoff
            WITH USER_MODE
            ORDER BY Last_Activity_Date__c DESC NULLS LAST, CreatedDate DESC
            LIMIT 1
        ];

        return sessions.isEmpty() ? null : sessionStateFromRecord(sessions[0]);
    }

    private static IntakeSessionState sessionStateFromRecord(SmartIntake_Session__c sessionRecord) {
        IntakeSessionState state = new IntakeSessionState();
        state.recordId = sessionRecord.Id;
        state.sessionId = sessionRecord.Session_Id__c;
        state.templateKey = sessionRecord.Template_Key__c;
        state.currentQuestionKey = sessionRecord.Current_Question_Key__c;
        state.status = sessionRecord.Status__c;
        state.answers = readAnswers(sessionRecord.Answers_JSON__c);
        state.questionHistory = readStringList(sessionRecord.Question_History_JSON__c);
        state.skippedQuestionKeys = new Set<String>(readStringList(sessionRecord.Skipped_Question_Keys_JSON__c));
        return state;
    }

    private static void assertValidIntakeSessionId(String sessionId) {
        if (String.isBlank(sessionId)) {
            return;
        }
        if (!Pattern.matches('^SI-[A-Fa-f0-9]{32}$', sessionId)) {
            throw validationError(
                'INVALID_SESSION_ID',
                'I could not resume that intake session. Please start again.',
                'The supplied SmartIntake session id did not match the expected opaque id format.'
            );
        }
    }

    private static void persistSessionState(
        IntakeSessionState state,
        String templateKey,
        Map<String, Object> answers,
        String currentQuestionKey,
        String status
    ) {
        if (state == null) {
            state = new IntakeSessionState();
            state.sessionId = ensureSessionId(null);
        }

        SmartIntake_Session__c sessionRecord = new SmartIntake_Session__c();
        sessionRecord.Id = state.recordId;
        sessionRecord.Session_Id__c = state.sessionId;
        sessionRecord.Template_Key__c = templateKey;
        sessionRecord.Answers_JSON__c = JSON.serialize(answers == null ? new Map<String, Object>() : answers);
        sessionRecord.Current_Question_Key__c = currentQuestionKey;
        sessionRecord.Question_History_JSON__c = JSON.serialize(state.questionHistory == null ? new List<String>() : state.questionHistory);
        sessionRecord.Skipped_Question_Keys_JSON__c = JSON.serialize(state.skippedQuestionKeys == null ? new Set<String>() : state.skippedQuestionKeys);
        sessionRecord.Status__c = status;
        sessionRecord.Last_Activity_Date__c = DateTime.now();

        if (state.recordId == null || !canUpdateSessionState()) {
            sessionRecord.Id = null;
            assertSessionCreateAccess();
            Database.SaveResult result = Database.insert(sessionRecord, AccessLevel.USER_MODE);
            if (!result.isSuccess()) {
                throw saveError(result);
            }
            state.recordId = result.getId();
            return;
        }

        assertSessionUpdateAccess();
        Database.SaveResult result = Database.update(sessionRecord, AccessLevel.USER_MODE);
        if (!result.isSuccess()) {
            throw saveError(result);
        }
    }

    private static Boolean canUpdateSessionState() {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(SESSION_OBJECT_API_NAME);
        return objectType != null && objectType.getDescribe().isUpdateable();
    }

    private static void assertSessionReadAccess() {
        SmartIntakeSecurityService.describeObjectForRead(SESSION_OBJECT_API_NAME);
        SmartIntakeSecurityService.describeFieldForRead(SESSION_OBJECT_API_NAME, 'Session_Id__c');
        SmartIntakeSecurityService.describeFieldForRead(SESSION_OBJECT_API_NAME, 'Template_Key__c');
        SmartIntakeSecurityService.describeFieldForRead(SESSION_OBJECT_API_NAME, 'Answers_JSON__c');
        SmartIntakeSecurityService.describeFieldForRead(SESSION_OBJECT_API_NAME, 'Current_Question_Key__c');
        SmartIntakeSecurityService.describeFieldForRead(SESSION_OBJECT_API_NAME, 'Question_History_JSON__c');
        SmartIntakeSecurityService.describeFieldForRead(SESSION_OBJECT_API_NAME, 'Skipped_Question_Keys_JSON__c');
        SmartIntakeSecurityService.describeFieldForRead(SESSION_OBJECT_API_NAME, 'Status__c');
        SmartIntakeSecurityService.describeFieldForRead(SESSION_OBJECT_API_NAME, 'Last_Activity_Date__c');
    }

    private static void assertSessionCreateAccess() {
        SmartIntakeSecurityService.describeObjectForCreate(SESSION_OBJECT_API_NAME);
        SmartIntakeSecurityService.describeFieldForCreate(SESSION_OBJECT_API_NAME, 'Session_Id__c');
        SmartIntakeSecurityService.describeFieldForCreate(SESSION_OBJECT_API_NAME, 'Template_Key__c');
        SmartIntakeSecurityService.describeFieldForCreate(SESSION_OBJECT_API_NAME, 'Answers_JSON__c');
        SmartIntakeSecurityService.describeFieldForCreate(SESSION_OBJECT_API_NAME, 'Current_Question_Key__c');
        SmartIntakeSecurityService.describeFieldForCreate(SESSION_OBJECT_API_NAME, 'Question_History_JSON__c');
        SmartIntakeSecurityService.describeFieldForCreate(SESSION_OBJECT_API_NAME, 'Skipped_Question_Keys_JSON__c');
        SmartIntakeSecurityService.describeFieldForCreate(SESSION_OBJECT_API_NAME, 'Status__c');
        SmartIntakeSecurityService.describeFieldForCreate(SESSION_OBJECT_API_NAME, 'Last_Activity_Date__c');
    }

    private static void assertSessionUpdateAccess() {
        SmartIntakeSecurityService.describeObjectForUpdate(SESSION_OBJECT_API_NAME);
        SmartIntakeSecurityService.describeFieldForUpdate(SESSION_OBJECT_API_NAME, 'Answers_JSON__c');
        SmartIntakeSecurityService.describeFieldForUpdate(SESSION_OBJECT_API_NAME, 'Current_Question_Key__c');
        SmartIntakeSecurityService.describeFieldForUpdate(SESSION_OBJECT_API_NAME, 'Question_History_JSON__c');
        SmartIntakeSecurityService.describeFieldForUpdate(SESSION_OBJECT_API_NAME, 'Skipped_Question_Keys_JSON__c');
        SmartIntakeSecurityService.describeFieldForUpdate(SESSION_OBJECT_API_NAME, 'Status__c');
        SmartIntakeSecurityService.describeFieldForUpdate(SESSION_OBJECT_API_NAME, 'Last_Activity_Date__c');
    }

    private static SmartIntakeDTO.IntakeResponse baseResponse(String templateKey, String requestedSessionId) {
        SmartIntakeDTO.IntakeResponse response = new SmartIntakeDTO.IntakeResponse();
        response.success = false;
        response.templateKey = String.isBlank(templateKey) ? null : templateKey.trim();
        response.intakeSessionId = ensureSessionId(requestedSessionId);
        response.isComplete = false;
        response.hasActiveQuestion = false;
        response.pendingConfirmation = false;
        response.mustRenderCurrentQuestion = false;
        response.rendererMode = 'NONE';
        response.recommendedNextStep = 'GET_NEXT';
        return response;
    }

    private static Map<String, Object> readAnswers(String answersJson) {
        if (String.isBlank(answersJson)) {
            return new Map<String, Object>();
        }
        try {
            Object parsed = JSON.deserializeUntyped(answersJson);
            if (parsed == null) {
                return new Map<String, Object>();
            }
            return (Map<String, Object>) parsed;
        } catch (Exception ex) {
            throw validationError('INVALID_ANSWERS_JSON', 'I could not read the saved answers for this intake.', 'Answers JSON could not be parsed: ' + ex.getMessage());
        }
    }

    private static List<String> readStringList(String jsonValue) {
        List<String> values = new List<String>();
        if (String.isBlank(jsonValue)) {
            return values;
        }
        try {
            Object parsed = JSON.deserializeUntyped(jsonValue);
            List<Object> parsedValues;
            try {
                parsedValues = (List<Object>) parsed;
            } catch (Exception ex) {
                return values;
            }
            for (Object item : parsedValues) {
                if (item != null && !String.isBlank(String.valueOf(item))) {
                    values.add(String.valueOf(item));
                }
            }
        } catch (Exception ex) {
            return values;
        }
        return values;
    }

    private static void addHistoryKey(IntakeSessionState state, String questionKey) {
        if (state.questionHistory == null) {
            state.questionHistory = new List<String>();
        }
        if (!String.isBlank(questionKey) && !state.questionHistory.contains(questionKey)) {
            state.questionHistory.add(questionKey);
        }
    }

    private static void putIfCreateable(SObject recordToSave, String objectApiName, String fieldApiName, Object value) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType == null) {
            return;
        }

        Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();
        if (!fields.containsKey(fieldApiName)) {
            return;
        }

        SmartIntakeSecurityService.describeFieldForCreate(objectApiName, fieldApiName);
        recordToSave.put(fieldApiName, value);
    }

    private static void linkUploadedFiles(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        Map<String, Object> answers,
        Id primaryRecordId,
        Set<String> visibleQuestionKeys
    ) {
        List<UploadedFile> uploadedFilesToLink = new List<UploadedFile>();
        Map<String, SmartIntake_File_Config__mdt> fileConfigByDocumentKey = new Map<String, SmartIntake_File_Config__mdt>();

        for (SmartIntake_Question__mdt question : metadata.questions) {
            String inputType = normalizeInputType(question.Input_Type__c);
            if (!FILE_INPUT_TYPES.contains(inputType) ||
                !visibleQuestionKeys.contains(question.Question_Key__c) ||
                !answers.containsKey(question.Question_Key__c) ||
                isBlankValue(answers.get(question.Question_Key__c))) {
                continue;
            }

            SmartIntake_File_Config__mdt fileConfig = metadata.fileConfigsByQuestionKey.get(question.Question_Key__c);
            if (fileConfig != null && fileConfig.Link_To_Final_Record__c == false) {
                continue;
            }

            for (UploadedFile uploadedFile : uploadedFilesFromAnswer(String.valueOf(answers.get(question.Question_Key__c)))) {
                uploadedFilesToLink.add(uploadedFile);
                fileConfigByDocumentKey.put(uploadedFileKey(uploadedFile), fileConfig);
            }
        }

        if (uploadedFilesToLink.isEmpty()) {
            return;
        }

        Map<String, Id> documentIdsByVersionId = resolveDocumentIdsByVersionId(uploadedFilesToLink);
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        Set<Id> linkedDocumentIds = new Set<Id>();
        for (UploadedFile uploadedFile : uploadedFilesToLink) {
            Id documentId = contentDocumentIdForUploadedFile(uploadedFile, documentIdsByVersionId);
            if (linkedDocumentIds.contains(documentId)) {
                continue;
            }
            linkedDocumentIds.add(documentId);

            SmartIntake_File_Config__mdt fileConfig = fileConfigByDocumentKey.get(uploadedFileKey(uploadedFile));
            links.add(new ContentDocumentLink(
                ContentDocumentId = documentId,
                LinkedEntityId = primaryRecordId,
                ShareType = fileShareType(fileConfig),
                Visibility = fileVisibility(fileConfig)
            ));
        }

        if (links.isEmpty()) {
            return;
        }

        SmartIntakeSecurityService.describeObjectForCreate('ContentDocumentLink');
        SmartIntakeSecurityService.describeFieldForCreate('ContentDocumentLink', 'ContentDocumentId');
        SmartIntakeSecurityService.describeFieldForCreate('ContentDocumentLink', 'LinkedEntityId');
        SmartIntakeSecurityService.describeFieldForCreate('ContentDocumentLink', 'ShareType');
        SmartIntakeSecurityService.describeFieldForCreate('ContentDocumentLink', 'Visibility');

        Database.SaveResult[] linkResults = Database.insert(links, AccessLevel.USER_MODE);
        for (Database.SaveResult linkResult : linkResults) {
            if (!linkResult.isSuccess()) {
                throw fileLinkSaveError(linkResult);
            }
        }
    }

    private static Map<String, Id> resolveDocumentIdsByVersionId(List<UploadedFile> uploadedFiles) {
        Set<Id> contentVersionIds = new Set<Id>();
        for (UploadedFile uploadedFile : uploadedFiles) {
            if (String.isBlank(uploadedFile.documentId) && !String.isBlank(uploadedFile.contentVersionId)) {
                contentVersionIds.add(parseSalesforceId(
                    uploadedFile.contentVersionId,
                    CONTENT_VERSION_PREFIX,
                    'INVALID_CONTENT_VERSION_ID',
                    'Uploaded file contentVersionId is not a ContentVersion Id.'
                ));
            }
        }

        Map<String, Id> documentIdsByVersionId = new Map<String, Id>();
        if (contentVersionIds.isEmpty()) {
            return documentIdsByVersionId;
        }

        for (ContentVersion version : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
            WITH USER_MODE
        ]) {
            documentIdsByVersionId.put(String.valueOf(version.Id), version.ContentDocumentId);
        }
        return documentIdsByVersionId;
    }

    private static Id contentDocumentIdForUploadedFile(UploadedFile uploadedFile, Map<String, Id> documentIdsByVersionId) {
        if (!String.isBlank(uploadedFile.documentId)) {
            return parseSalesforceId(
                uploadedFile.documentId,
                CONTENT_DOCUMENT_PREFIX,
                'INVALID_CONTENT_DOCUMENT_ID',
                'Uploaded file documentId is not a ContentDocument Id.'
            );
        }

        Id documentId = documentIdsByVersionId.get(String.valueOf(parseSalesforceId(
            uploadedFile.contentVersionId,
            CONTENT_VERSION_PREFIX,
            'INVALID_CONTENT_VERSION_ID',
            'Uploaded file contentVersionId is not a ContentVersion Id.'
        )));
        if (documentId == null) {
            throw validationError(
                'CONTENT_VERSION_NOT_ACCESSIBLE',
                'I could not access the uploaded file. Please upload it again or contact support.',
                'Uploaded ContentVersion was not accessible for final file linking.'
            );
        }
        return documentId;
    }

    private static String uploadedFileKey(UploadedFile uploadedFile) {
        if (!String.isBlank(uploadedFile.documentId)) {
            return uploadedFile.documentId;
        }
        return uploadedFile.contentVersionId;
    }

    private static String fileShareType(SmartIntake_File_Config__mdt fileConfig) {
        String shareType = fileConfig == null || String.isBlank(fileConfig.Share_Type__c)
            ? 'V'
            : fileConfig.Share_Type__c.trim();
        if (!SUPPORTED_FILE_SHARE_TYPES.contains(shareType)) {
            throw configurationError(null, 'UNSUPPORTED_FILE_SHARE_TYPE', 'File config uses unsupported Share Type ' + shareType + '.');
        }
        return shareType;
    }

    private static String fileVisibility(SmartIntake_File_Config__mdt fileConfig) {
        String visibility = fileConfig == null || String.isBlank(fileConfig.Visibility__c)
            ? 'AllUsers'
            : fileConfig.Visibility__c.trim();
        if (!SUPPORTED_FILE_VISIBILITIES.contains(visibility)) {
            throw configurationError(null, 'UNSUPPORTED_FILE_VISIBILITY', 'File config uses unsupported Visibility ' + visibility + '.');
        }
        return visibility;
    }

    private static SmartIntakeException saveError(String objectApiName, Database.SaveResult result) {
        String message = saveResultAdminMessage('The final intake record for ' + objectApiName + ' could not be saved.', result);
        return new SmartIntakeException(
            'SAVE',
            'FINAL_SAVE_FAILED',
            saveFailureUserMessage(result),
            message
        );
    }

    private static SmartIntakeException saveError(Database.SaveResult result) {
        String message = saveResultAdminMessage('The final intake record could not be saved.', result);
        return new SmartIntakeException(
            'SAVE',
            'FINAL_SAVE_FAILED',
            saveFailureUserMessage(result),
            message
        );
    }

    private static SmartIntakeException fileLinkSaveError(Database.SaveResult result) {
        String message = saveResultAdminMessage('Uploaded files could not be linked to the final intake record.', result);
        return new SmartIntakeException(
            'SAVE',
            'FILE_LINK_SAVE_FAILED',
            saveFailureUserMessage(result),
            message
        );
    }

    private static SmartIntakeException dmlSaveError(DmlException ex) {
        String message = 'Salesforce rejected the final intake save.';
        if (ex != null && ex.getNumDml() > 0) {
            message += ' Status: ' + String.valueOf(ex.getDmlStatusCode(0)) + '. Message: ' + ex.getDmlMessage(0) + '.';
            if (ex.getDmlFields(0) != null && !ex.getDmlFields(0).isEmpty()) {
                message += ' Fields: ' + String.join(ex.getDmlFields(0), ', ') + '.';
            }
        } else if (ex != null) {
            message += ' ' + ex.getMessage();
        }
        return new SmartIntakeException(
            'SAVE',
            'FINAL_SAVE_FAILED',
            'Salesforce rejected the save because one or more fields need attention. Please review the highlighted answer or contact support.',
            message
        );
    }

    private static String saveResultAdminMessage(String prefix, Database.SaveResult result) {
        String message = prefix;
        if (result != null && result.getErrors() != null && !result.getErrors().isEmpty()) {
            Database.Error firstError = result.getErrors()[0];
            message += ' Status: ' + String.valueOf(firstError.getStatusCode()) + '. Message: ' + firstError.getMessage() + '.';
            if (firstError.getFields() != null && !firstError.getFields().isEmpty()) {
                message += ' Fields: ' + String.join(firstError.getFields(), ', ') + '.';
            }
        }
        return message;
    }

    private static String saveFailureUserMessage(Database.SaveResult result) {
        if (result != null && result.getErrors() != null && !result.getErrors().isEmpty()) {
            Database.Error firstError = result.getErrors()[0];
            if (firstError.getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION ||
                firstError.getStatusCode() == StatusCode.REQUIRED_FIELD_MISSING ||
                firstError.getStatusCode() == StatusCode.INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST) {
                return 'Salesforce rejected the save because one or more fields need attention. Please review your answer or contact support.';
            }
        }
        return 'I couldn’t save the intake yet. Please try again or contact support.';
    }

    private static SmartIntakeException validationError(String code, String userMessage, String adminMessage) {
        return new SmartIntakeException('VALIDATION', code, userMessage, adminMessage);
    }

    private static SmartIntakeException configurationError(String templateKey, String code, String adminMessage) {
        return new SmartIntakeException(
            'CONFIGURATION',
            code,
            SmartIntakeMetadataService.message(templateKey, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
            adminMessage
        );
    }

    private static SmartIntakeDTO.IntakeResponse errorResponse(String templateKey, String sessionId, SmartIntakeException ex) {
        SmartIntakeApexDebugLogService.logSmartIntakeException('SmartIntakeService', 'runtimeResponse', templateKey, sessionId, ex, null);
        SmartIntakeDTO.IntakeResponse response = baseResponse(templateKey, sessionId);
        response.errorType = ex.errorType;
        response.errorCode = ex.errorCode;
        response.userMessage = ex.userMessage;
        response.adminMessage = ex.adminMessage;
        response.answersJson = '{}';
        applyRuntimeDecision(response, false);
        return response;
    }

    private static SmartIntakeDTO.IntakeResponse unexpectedErrorResponse(String templateKey, String sessionId, Exception ex) {
        SmartIntakeApexDebugLogService.logException('SmartIntakeService', 'runtimeResponse', templateKey, sessionId, ex, null);
        SmartIntakeDTO.IntakeResponse response = baseResponse(templateKey, sessionId);
        response.errorType = 'TRANSIENT';
        response.errorCode = 'UNEXPECTED_ERROR';
        response.userMessage = 'Something interrupted the intake. Please try again.';
        response.adminMessage = ex.getTypeName() + ': ' + ex.getMessage();
        response.answersJson = '{}';
        applyRuntimeDecision(response, false);
        return response;
    }

    private static SmartIntakeDTO.FindExistingRecordResponse findExistingErrorResponse(SmartIntakeException ex) {
        SmartIntakeApexDebugLogService.logSmartIntakeException('SmartIntakeService', 'findExistingRecord', null, null, ex, null);
        SmartIntakeDTO.FindExistingRecordResponse response = new SmartIntakeDTO.FindExistingRecordResponse();
        response.success = false;
        response.recordFound = false;
        response.errorType = ex.errorType;
        response.errorCode = ex.errorCode;
        response.userMessage = ex.userMessage;
        response.adminMessage = ex.adminMessage;
        return response;
    }

    private static SmartIntakeDTO.ValidateAnswerResponse validateAnswerErrorResponse(SmartIntakeException ex) {
        SmartIntakeApexDebugLogService.logSmartIntakeException('SmartIntakeService', 'validateAnswerRequest', null, null, ex, null);
        SmartIntakeDTO.ValidateAnswerResponse response = new SmartIntakeDTO.ValidateAnswerResponse();
        response.success = false;
        response.isValid = false;
        response.errorType = ex.errorType;
        response.errorCode = ex.errorCode;
        response.userMessage = ex.userMessage;
        response.adminMessage = ex.adminMessage;
        return response;
    }

    private static SmartIntakeDTO.ExistingContextResponse existingContextErrorResponse(SmartIntakeException ex) {
        SmartIntakeApexDebugLogService.logSmartIntakeException('SmartIntakeService', 'getExistingContext', null, null, ex, null);
        SmartIntakeDTO.ExistingContextResponse response = emptyExistingContextResponse();
        response.success = false;
        response.errorType = ex.errorType;
        response.errorCode = ex.errorCode;
        response.userMessage = ex.userMessage;
        response.adminMessage = ex.adminMessage;
        return response;
    }

    private static SmartIntakeDTO.ExistingContextResponse emptyExistingContextResponse() {
        SmartIntakeDTO.ExistingContextResponse response = new SmartIntakeDTO.ExistingContextResponse();
        response.success = true;
        response.hasContext = false;
        response.contextRecords = new List<SmartIntakeDTO.ExistingContextRecord>();
        response.contextRecordsJson = '[]';
        return response;
    }

    private static Integer contextLimit(Decimal configuredLimit) {
        Integer maxRecords = configuredLimit == null ? DEFAULT_CONTEXT_LIMIT : Integer.valueOf(configuredLimit);
        if (maxRecords < 1) {
            return DEFAULT_CONTEXT_LIMIT;
        }
        if (maxRecords > MAX_CONTEXT_LIMIT) {
            return MAX_CONTEXT_LIMIT;
        }
        return maxRecords;
    }

    private static Boolean isBlankValue(Object value) {
        return value == null || String.isBlank(String.valueOf(value));
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static String firstNonBlankString(Object firstValue, Object secondValue) {
        String firstString = stringValue(firstValue);
        if (!String.isBlank(firstString)) {
            return firstString;
        }
        return stringValue(secondValue);
    }

    private static String normalizedAnswerValue(SmartIntake_Question__mdt question, String answerValue) {
        if (answerValue == null) {
            return null;
        }

        String inputType = normalizeInputType(question.Input_Type__c);
        if (inputType == 'LONG_TEXT') {
            return answerValue;
        }
        if (inputType == 'BOOLEAN') {
            return answerValue.trim().toLowerCase();
        }
        if (inputType == 'MULTI_SELECT') {
            List<String> selectedValues = new List<String>();
            for (String selectedValue : answerValue.split(';')) {
                if (!String.isBlank(selectedValue)) {
                    selectedValues.add(selectedValue.trim());
                }
            }
            return String.join(selectedValues, ';');
        }
        return answerValue.trim();
    }

    private static String normalizeInputType(String inputType) {
        return String.isBlank(inputType) ? '' : inputType.trim().toUpperCase();
    }

    private static String defaultTemplateKey(String templateKey) {
        return resolveTemplateKey(templateKey, null, null, null);
    }

    private static String resolveTemplateKey(String templateKey, String smartIntakeContextKey, String routableId, String sessionId) {
        String routableTemplateKey = templateKeyForRoutableId(routableId);
        if (!String.isBlank(routableTemplateKey)) {
            return routableTemplateKey;
        }

        String contextRouteTemplateKey = templateKeyForConfiguredRoute(smartIntakeContextKey);
        if (!String.isBlank(contextRouteTemplateKey)) {
            return contextRouteTemplateKey;
        }

        if (hasExplicitRouteContext(smartIntakeContextKey)) {
            String contextSessionTemplateKey = templateKeyForPotentialSession(smartIntakeContextKey);
            if (!String.isBlank(contextSessionTemplateKey)) {
                return contextSessionTemplateKey;
            }

            String legacyTemplateKey = templateKeyForActiveTemplate(smartIntakeContextKey);
            if (!String.isBlank(legacyTemplateKey)) {
                return legacyTemplateKey;
            }

            throw configurationError(
                null,
                'ROUTE_NOT_CONFIGURED',
                'No active SmartIntake template route is configured for route key ' + smartIntakeContextKey.trim() + '.'
            );
        }

        if (!String.isBlank(templateKey)) {
            String explicitTemplateKey = templateKey.trim();
            if (templateExists(explicitTemplateKey)) {
                return explicitTemplateKey;
            }

            if (looksLikeIntakeSessionId(explicitTemplateKey)) {
                String sessionTemplateKeyFromTemplateSlot = templateKeyForSession(explicitTemplateKey);
                if (!String.isBlank(sessionTemplateKeyFromTemplateSlot)) {
                    return sessionTemplateKeyFromTemplateSlot;
                }
            } else {
                String legacyContextTemplateKey = templateKeyForContext(explicitTemplateKey);
                if (!String.isBlank(legacyContextTemplateKey)) {
                    return legacyContextTemplateKey;
                }

                return explicitTemplateKey;
            }
        }

        String contextSessionTemplateKey = templateKeyForPotentialSession(smartIntakeContextKey);
        if (!String.isBlank(contextSessionTemplateKey)) {
            return contextSessionTemplateKey;
        }

        String sessionTemplateKey = templateKeyForSession(sessionId);
        if (!String.isBlank(sessionTemplateKey)) {
            return sessionTemplateKey;
        }

        String defaultRouteTemplateKey = templateKeyForDefaultRoute();
        if (!String.isBlank(defaultRouteTemplateKey)) {
            return defaultRouteTemplateKey;
        }

        throw configurationError(null, 'DEFAULT_ROUTE_NOT_CONFIGURED', 'No active default SmartIntake template route is configured.');
    }

    private static String templateKeyForPotentialSession(String potentialSessionId) {
        return looksLikeIntakeSessionId(potentialSessionId) ? templateKeyForSession(potentialSessionId) : null;
    }

    private static Boolean looksLikeIntakeSessionId(String value) {
        return !String.isBlank(value) && value.trim().startsWith('SI-');
    }

    private static String templateKeyForContext(String contextKey) {
        String routeTemplateKey = templateKeyForConfiguredRoute(contextKey);
        if (!String.isBlank(routeTemplateKey)) {
            return routeTemplateKey;
        }

        return templateKeyForActiveTemplate(contextKey);
    }

    private static String templateKeyForConfiguredRoute(String contextKey) {
        String normalizedContext = normalizeContextKey(contextKey);
        if (String.isBlank(normalizedContext)) {
            return null;
        }

        for (SmartIntake_Template_Route__mdt route : [
            SELECT Route_Key__c, Template_Key__c
            FROM SmartIntake_Template_Route__mdt
            WHERE Is_Active__c = true
              AND Is_Default__c = false
            ORDER BY DeveloperName ASC
        ]) {
            if (normalizeContextKey(route.Route_Key__c) == normalizedContext) {
                return route.Template_Key__c;
            }
        }

        return null;
    }

    private static String templateKeyForActiveTemplate(String contextKey) {
        String normalizedContext = normalizeContextKey(contextKey);
        return !String.isBlank(normalizedContext) && templateExists(normalizedContext) ? normalizedContext : null;
    }

    private static Boolean hasExplicitRouteContext(String contextKey) {
        String normalizedContext = normalizeContextKey(contextKey);
        return !String.isBlank(normalizedContext) && normalizedContext != 'ROOT';
    }

    private static String templateKeyForDefaultRoute() {
        List<SmartIntake_Template_Route__mdt> routes = [
            SELECT Template_Key__c
            FROM SmartIntake_Template_Route__mdt
            WHERE Is_Active__c = true
              AND Is_Default__c = true
            ORDER BY DeveloperName ASC
            LIMIT 2
        ];
        if (routes.size() > 1) {
            throw configurationError(null, 'MULTIPLE_DEFAULT_ROUTES', 'Only one active default SmartIntake template route is supported.');
        }
        return routes.isEmpty() ? null : routes[0].Template_Key__c;
    }

    private static String templateKeyForSession(String sessionId) {
        if (String.isBlank(sessionId)) {
            return null;
        }
        assertValidIntakeSessionId(sessionId);
        assertSessionReadAccess();
        List<SmartIntake_Session__c> sessions = [
            SELECT Template_Key__c
            FROM SmartIntake_Session__c
            WHERE Session_Id__c = :sessionId
            WITH USER_MODE
            ORDER BY Last_Activity_Date__c DESC NULLS LAST, CreatedDate DESC
            LIMIT 1
        ];
        return sessions.isEmpty() ? null : sessions[0].Template_Key__c;
    }

    private static String contextKeyForRoutableId(String routableId) {
        if (String.isBlank(routableId) || !String.valueOf(routableId).startsWith('0Mw')) {
            return null;
        }
        if (Test.isRunningTest() && messagingSessionContextByRoutableIdForTest.containsKey(routableId)) {
            String testContextKey = messagingSessionContextByRoutableIdForTest.get(routableId);
            return String.isBlank(testContextKey) ? null : testContextKey.trim();
        }
        if (!Schema.sObjectType.MessagingSession.isAccessible() ||
            !Schema.sObjectType.MessagingSession.fields.Current_Page__c.isAccessible()
        ) {
            return null;
        }
        List<MessagingSession> sessions = [
            SELECT Current_Page__c
            FROM MessagingSession
            WHERE Id = :routableId
            WITH USER_MODE
            LIMIT 1
        ];
        return sessions.isEmpty() || String.isBlank(sessions[0].Current_Page__c)
            ? null
            : sessions[0].Current_Page__c.trim();
    }

    private static String recentMessagingSessionContextKey() {
        if (Test.isRunningTest()) {
            return String.isBlank(recentMessagingSessionContextKeyForTest)
                ? null
                : recentMessagingSessionContextKeyForTest.trim();
        }
        if (!Schema.sObjectType.MessagingSession.isAccessible() ||
            !Schema.sObjectType.MessagingSession.fields.Current_Page__c.isAccessible() ||
            !Schema.sObjectType.MessagingSession.fields.Status.isAccessible() ||
            !Schema.sObjectType.MessagingSession.fields.LastModifiedDate.isAccessible()
        ) {
            return null;
        }
        DateTime cutoff = System.now().addMinutes(-MESSAGING_CONTEXT_FALLBACK_WINDOW_MINUTES);
        List<MessagingSession> sessions = [
            SELECT Current_Page__c
            FROM MessagingSession
            WHERE Status = 'Active'
              AND Current_Page__c != null
              AND LastModifiedDate >= :cutoff
            WITH USER_MODE
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        return sessions.isEmpty() || String.isBlank(sessions[0].Current_Page__c)
            ? null
            : sessions[0].Current_Page__c.trim();
    }

    private static String templateKeyForRoutableId(String routableId) {
        if (String.isBlank(routableId) || !String.valueOf(routableId).startsWith('0Mw')) {
            return null;
        }

        String routableContextKey = contextKeyForRoutableId(routableId);
        String contextTemplateKey = templateKeyForContext(routableContextKey);
        if (!String.isBlank(contextTemplateKey)) {
            return contextTemplateKey;
        }

        if (!Schema.sObjectType.MessagingSession.isAccessible() ||
            !Schema.sObjectType.MessagingSession.fields.MessagingChannelId.isAccessible()
        ) {
            return null;
        }
        List<MessagingSession> sessions = [
            SELECT MessagingChannelId
            FROM MessagingSession
            WHERE Id = :routableId
            WITH USER_MODE
            LIMIT 1
        ];
        return sessions.isEmpty() ? null : templateKeyForMessagingChannelId(sessions[0].MessagingChannelId);
    }

    private static String templateKeyForMessagingSession(MessagingSession session) {
        if (session == null) {
            return null;
        }

        String contextTemplateKey = templateKeyForContext(session.Current_Page__c);
        if (!String.isBlank(contextTemplateKey)) {
            return contextTemplateKey;
        }

        return templateKeyForMessagingChannelId(session.MessagingChannelId);
    }

    private static String templateKeyForMessagingChannelId(Id messagingChannelId) {
        if (messagingChannelId == null ||
            !Schema.sObjectType.MessagingChannel.isAccessible()
        ) {
            return null;
        }

        List<MessagingChannel> channels = [
            SELECT DeveloperName, MasterLabel
            FROM MessagingChannel
            WHERE Id = :messagingChannelId
            WITH USER_MODE
            LIMIT 1
        ];
        if (channels.isEmpty()) {
            return null;
        }

        String channelTemplateKey = templateKeyForContext(channels[0].DeveloperName);
        if (!String.isBlank(channelTemplateKey)) {
            return channelTemplateKey;
        }
        return templateKeyForContext(channels[0].MasterLabel);
    }

    private static String normalizeContextKey(String contextKey) {
        if (String.isBlank(contextKey)) {
            return null;
        }
        String normalized = contextKey.trim().toUpperCase();
        normalized = normalized.replaceAll('^HTTPS?://[^/]+', '');
        normalized = normalized.replaceAll('^/S/', '');
        normalized = normalized.replaceAll('^/+', '');
        normalized = normalized.replaceAll('/+$', '');
        if (String.isBlank(normalized)) {
            return 'ROOT';
        }
        normalized = normalized.replaceAll('[^A-Z0-9]+', '_');
        normalized = normalized.replaceAll('^_+', '').replaceAll('_+$', '');
        return normalized;
    }

    private static Boolean sameRouteValue(String leftValue, String rightValue) {
        if (String.isBlank(leftValue) || String.isBlank(rightValue)) {
            return false;
        }
        return normalizeContextKey(leftValue) == normalizeContextKey(rightValue);
    }

    private static Boolean templateExists(String templateKey) {
        if (String.isBlank(templateKey)) {
            return false;
        }
        return [
            SELECT COUNT()
            FROM SmartIntake_Template__mdt
            WHERE Template_Key__c = :templateKey
              AND Is_Active__c = true
        ] > 0;
    }

    private static String ensureSessionId(String sessionId) {
        if (!String.isBlank(sessionId)) {
            return sessionId;
        }
        return 'SI-' + EncodingUtil.convertToHex(Crypto.generateAesKey(128));
    }
}