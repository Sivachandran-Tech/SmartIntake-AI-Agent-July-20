@IsTest
private class SmartIntakeAgentActionTest {
    private static Date futureArrivalDateValue() {
        return Date.today().addDays(7);
    }

    private static String futureArrivalDate() {
        return String.valueOf(futureArrivalDateValue());
    }

    private static String noMatchEmail() {
        return 'sara.booking@example.test';
    }

    private static String noMatchPhone() {
        return '5550101234';
    }

    private static String completeHotelAnswersJson() {
        String contactJson = contactDetailsAnswersJson();
        return contactJson.substring(0, contactJson.length() - 1) +
            ',"room_type":"Premium","arrival_date":"' +
            futureArrivalDate() + '","booking_note":"Late arrival","booking_attachment":""}';
    }

    private static List<Object> finalReviewItems(SmartIntakeDTO.IntakeResponse response) {
        System.assertNotEquals(null, response.currentQuestion, JSON.serialize(response));
        System.assertEquals('__SMARTINTAKE_FINAL_REVIEW__', response.currentQuestion.dataSourceKey, JSON.serialize(response.currentQuestion));
        Object parsed = JSON.deserializeUntyped(response.currentQuestion.dataSourceJson);
        return (List<Object>) parsed;
    }

    private static String contactDetailsAnswersJson() {
        return '{"guest_name":"Sara Smith","guest_email":"' + noMatchEmail() +
            '","guest_email_match_status":"NO_MATCH","guest_phone":"' + noMatchPhone() +
            '","guest_phone_match_status":"NO_MATCH"}';
    }

    private static SmartIntakeDTO.IntakeResponse answerHotelContactDetails(String sessionId, String answersJson) {
        SmartIntakeDTO.IntakeResponse email = SmartIntakeService.submitAnswer(
            SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'guest_email', noMatchEmail(), answersJson)
        );
        System.assertEquals(true, email.success, JSON.serialize(email));
        System.assertEquals('guest_phone', email.question.questionKey);

        SmartIntakeDTO.IntakeResponse phone = SmartIntakeService.submitAnswer(
            SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'guest_phone', noMatchPhone(), email.answersJson)
        );
        System.assertEquals(true, phone.success, JSON.serialize(phone));
        System.assertEquals('room_type', phone.question.questionKey);
        return phone;
    }

    private static SmartIntakeDTO.IntakeResponse answerCurrentContactDetails(String sessionId, String answersJson) {
        SmartIntakeDTO.IntakeResponse email = SmartIntakeSubmitCurrentAnswerAction.invoke(
            new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                SmartIntakeTestDataFactory.submitCurrentRequestWithSession(sessionId, noMatchEmail(), answersJson)
            }
        )[0];
        System.assertEquals(true, email.success, JSON.serialize(email));
        System.assertEquals('guest_phone', email.question.questionKey);

        SmartIntakeDTO.IntakeResponse phone = SmartIntakeSubmitCurrentAnswerAction.invoke(
            new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                SmartIntakeTestDataFactory.submitCurrentRequestWithSession(sessionId, noMatchPhone(), email.answersJson)
            }
        )[0];
        System.assertEquals(true, phone.success, JSON.serialize(phone));
        System.assertEquals('room_type', phone.question.questionKey);
        return phone;
    }

    private static SmartIntakeDTO.IntakeResponse answerAgentContactDetails(String agentSessionKey) {
        SmartIntakeDTO.IntakeResponse email = SmartIntakeSubmitCurrentAnswerAction.invoke(
            new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession(agentSessionKey, noMatchEmail())
            }
        )[0];
        System.assertEquals(true, email.success, JSON.serialize(email));
        System.assertEquals('guest_phone', email.question.questionKey);

        SmartIntakeDTO.IntakeResponse phone = SmartIntakeSubmitCurrentAnswerAction.invoke(
            new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession(agentSessionKey, noMatchPhone())
            }
        )[0];
        System.assertEquals(true, phone.success, JSON.serialize(phone));
        System.assertEquals('room_type', phone.question.questionKey);
        return phone;
    }

    @IsTest
    static void getNextQuestionReturnsFirstMetadataQuestion() {
        SmartIntakeDTO.IntakeResponse response = SmartIntakeService.getNextQuestion(
            SmartIntakeTestDataFactory.getNextRequest()
        );

        System.assertEquals(true, response.success);
        System.assertNotEquals(null, response.intakeSessionId);
        System.assertEquals('guest_name', response.question.questionKey);
        System.assertEquals(false, response.isComplete);
        System.assertEquals(1, response.progress.currentStep);
        System.assertEquals(9, response.progress.totalSteps);
        System.assertEquals('SmartIntake Concierge', response.branding.agentDisplayName);
        System.assert(response.brandingJson.contains('SmartIntake Concierge'), response.brandingJson);
        System.assertEquals(true, response.requiresConsent);
        System.assert(response.consentMessage.contains('hotel booking intake'), response.consentMessage);
        System.assertEquals(true, response.requiresFinalConfirmation);
        System.assertEquals(true, response.hasActiveQuestion);
        System.assertEquals('guest_name', response.activeQuestionKey);
        System.assertEquals(false, response.pendingConfirmation);
        System.assertEquals(true, response.mustRenderCurrentQuestion);
        System.assertEquals('TEXT', response.rendererMode);
        System.assertEquals('RENDER_CURRENT_QUESTION', response.recommendedNextStep);
    }

    @IsTest
    static void questionPayloadCarriesRenderLightningInputFlag() {
        SmartIntakeDTO.GetNextQuestionRequest warrantyRequest =
            new SmartIntakeDTO.GetNextQuestionRequest();
        warrantyRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';

        SmartIntakeDTO.IntakeResponse warrantyResponse =
            SmartIntakeService.getNextQuestion(warrantyRequest);

        System.assertEquals(true, warrantyResponse.success, JSON.serialize(warrantyResponse));
        System.assertEquals('CLAIM_EMAIL', warrantyResponse.question.questionKey);
        System.assertEquals(false, warrantyResponse.question.renderLightningInput, JSON.serialize(warrantyResponse.question));
        System.assertNotEquals(null, warrantyResponse.currentQuestion, JSON.serialize(warrantyResponse));
        System.assertEquals(false, warrantyResponse.currentQuestion.renderLightningInput, JSON.serialize(warrantyResponse.currentQuestion));
        System.assertNotEquals(null, warrantyResponse.answerCaptureTemplate, JSON.serialize(warrantyResponse));
        System.assertEquals(false, warrantyResponse.answerCaptureTemplate.renderLightningInput, JSON.serialize(warrantyResponse.answerCaptureTemplate));

        SmartIntakeDTO.SubmitAnswerRequest proposedEmailRequest =
            new SmartIntakeDTO.SubmitAnswerRequest();
        proposedEmailRequest.intakeSessionId = warrantyResponse.intakeSessionId;
        proposedEmailRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
        proposedEmailRequest.questionKey = 'CLAIM_EMAIL';
        proposedEmailRequest.answersJson = warrantyResponse.answersJson;
        proposedEmailRequest.proposedAnswersJson = JSON.serialize(new Map<String, Object>{
            'CLAIM_EMAIL' => 'sivachandran2256@gmail.com'
        });

        SmartIntakeDTO.IntakeResponse extractedEmailConfirmation =
            SmartIntakeService.submitAnswer(proposedEmailRequest);

        System.assertEquals(true, extractedEmailConfirmation.success, JSON.serialize(extractedEmailConfirmation));
        System.assertEquals('CLAIM_EMAIL', extractedEmailConfirmation.question.questionKey);
        System.assertEquals('RADIO', extractedEmailConfirmation.question.inputType);
        System.assertEquals(true, extractedEmailConfirmation.question.renderLightningInput, JSON.serialize(extractedEmailConfirmation.question));
        System.assertEquals(true, extractedEmailConfirmation.hasActiveQuestion, JSON.serialize(extractedEmailConfirmation));
        System.assertEquals('CLAIM_EMAIL', extractedEmailConfirmation.activeQuestionKey, JSON.serialize(extractedEmailConfirmation));
        System.assertEquals(true, extractedEmailConfirmation.pendingConfirmation, JSON.serialize(extractedEmailConfirmation));
        System.assertEquals(true, extractedEmailConfirmation.mustRenderCurrentQuestion, JSON.serialize(extractedEmailConfirmation));
        System.assertEquals('PENDING_CONFIRMATION', extractedEmailConfirmation.rendererMode, JSON.serialize(extractedEmailConfirmation));
        System.assertEquals('RENDER_CURRENT_QUESTION', extractedEmailConfirmation.recommendedNextStep, JSON.serialize(extractedEmailConfirmation));
        System.assertNotEquals(null, extractedEmailConfirmation.currentQuestion, JSON.serialize(extractedEmailConfirmation));
        System.assertEquals(extractedEmailConfirmation.question.questionText, extractedEmailConfirmation.currentQuestion.questionText, JSON.serialize(extractedEmailConfirmation));
        System.assertEquals('RADIO', extractedEmailConfirmation.currentQuestion.inputType, JSON.serialize(extractedEmailConfirmation.currentQuestion));
        System.assertNotEquals(null, extractedEmailConfirmation.answerCaptureTemplate, JSON.serialize(extractedEmailConfirmation));
        System.assertEquals(null, extractedEmailConfirmation.userMessage, JSON.serialize(extractedEmailConfirmation));

        SmartIntakeGetNextByContextAction.Request feedbackRequest =
            new SmartIntakeGetNextByContextAction.Request();
        feedbackRequest.smartIntakeContextKey = 'feedback';
        feedbackRequest.answersJson = '{}';

        SmartIntakeDTO.IntakeResponse feedbackResponse =
            SmartIntakeGetNextByContextAction.invoke(
                new List<SmartIntakeGetNextByContextAction.Request>{ feedbackRequest }
            )[0];

        System.assertEquals(true, feedbackResponse.success, JSON.serialize(feedbackResponse));
        System.assertEquals('EVENT_FEEDBACK_FORM', feedbackResponse.templateKey);
        System.assertEquals('RATING', feedbackResponse.question.questionKey);
        System.assertEquals(true, feedbackResponse.question.renderLightningInput, JSON.serialize(feedbackResponse.question));
        System.assertEquals(true, feedbackResponse.mustRenderCurrentQuestion, JSON.serialize(feedbackResponse));
        System.assertEquals('CUSTOM_LWC', feedbackResponse.rendererMode, JSON.serialize(feedbackResponse));
        System.assertEquals('RENDER_CURRENT_QUESTION', feedbackResponse.recommendedNextStep, JSON.serialize(feedbackResponse));
        System.assertNotEquals(null, feedbackResponse.currentQuestion, JSON.serialize(feedbackResponse));
        System.assertEquals(true, feedbackResponse.currentQuestion.renderLightningInput, JSON.serialize(feedbackResponse.currentQuestion));
        System.assertNotEquals(null, feedbackResponse.answerCaptureTemplate, JSON.serialize(feedbackResponse));
        System.assertEquals(true, feedbackResponse.answerCaptureTemplate.renderLightningInput, JSON.serialize(feedbackResponse.answerCaptureTemplate));
    }

    @IsTest
    static void requiredAnswerValidationReturnsControlledError() {
        SmartIntakeDTO.SubmitAnswerRequest request = SmartIntakeTestDataFactory.submitRequest(
            'guest_name',
            '',
            '{}'
        );

        SmartIntakeDTO.IntakeResponse response = SmartIntakeService.submitAnswer(request);

        System.assertEquals(false, response.success);
        System.assertEquals('VALIDATION', response.errorType);
        System.assertEquals('REQUIRED_ANSWER_MISSING', response.errorCode);
        System.assert(response.userMessage.contains('required'), response.userMessage);
    }

    @IsTest
    static void validateAnswerActionUsesValidationMetadata() {
        SmartIntakeDTO.ValidateAnswerResponse validResponse = SmartIntakeService.validateIntakeAnswer(
            SmartIntakeTestDataFactory.validateRequest('guest_name', 'Sara Smith')
        );
        System.assertEquals(true, validResponse.success);
        System.assertEquals(true, validResponse.isValid);
        System.assertEquals('Sara Smith', validResponse.normalizedValue);

        SmartIntakeDTO.ValidateAnswerResponse shortNameResponse = SmartIntakeValidateAnswerAction.invoke(
            new List<SmartIntakeDTO.ValidateAnswerRequest>{
                SmartIntakeTestDataFactory.validateRequest('guest_name', 'S')
            }
        )[0];
        System.assertEquals(false, shortNameResponse.success);
        System.assertEquals(false, shortNameResponse.isValid);
        System.assertEquals('VALIDATION', shortNameResponse.errorType);
        System.assertEquals('MIN_LENGTH_VALIDATION_FAILED', shortNameResponse.errorCode);
        System.assert(shortNameResponse.userMessage.contains('2 characters'), shortNameResponse.userMessage);

        SmartIntakeMetadataService.conditionsForTests = new List<SmartIntake_Condition__mdt>();
        try {
            SmartIntakeDTO.ValidateAnswerResponse earlyDateResponse = SmartIntakeService.validateIntakeAnswer(
                SmartIntakeTestDataFactory.validateRequest('arrival_date', String.valueOf(Date.today().addDays(-1)))
            );
            System.assertEquals(false, earlyDateResponse.success);
            System.assertEquals('MIN_TODAY_VALIDATION_FAILED', earlyDateResponse.errorCode);
            System.assert(earlyDateResponse.userMessage.contains('today or a future date'), earlyDateResponse.userMessage);

            SmartIntakeDTO.ValidateAnswerResponse todayDateResponse = SmartIntakeService.validateIntakeAnswer(
                SmartIntakeTestDataFactory.validateRequest('arrival_date', String.valueOf(Date.today()))
            );
            System.assertEquals(true, todayDateResponse.success);
            System.assertEquals(true, todayDateResponse.isValid);
        } finally {
            SmartIntakeMetadataService.conditionsForTests = null;
        }

        String longNote = '';
        for (Integer index = 0; index < 260; index++) {
            longNote += 'x';
        }
        SmartIntakeDTO.ValidateAnswerResponse longNoteResponse = SmartIntakeService.validateIntakeAnswer(
            SmartIntakeTestDataFactory.validateRequest('booking_note', longNote)
        );
        System.assertEquals(false, longNoteResponse.success);
        System.assertEquals('MAX_LENGTH_VALIDATION_FAILED', longNoteResponse.errorCode);
    }

    @IsTest
    static void submitAnswersAdvancesAndFinalSaveCreatesSubmission() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeDTO.IntakeResponse saved;
        String sessionId;
        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse first = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequest('guest_name', 'Sara Smith', '{}')
            );
            System.assertEquals(true, first.success);
            sessionId = first.intakeSessionId;
            System.assertEquals('guest_email', first.question.questionKey);

            SmartIntakeDTO.IntakeResponse contactDetails = answerHotelContactDetails(sessionId, first.answersJson);
            System.assertEquals(3, contactDetails.question.options.size());

            SmartIntakeDTO.IntakeResponse second = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'room_type', 'Premium', contactDetails.answersJson)
            );
            System.assertEquals(true, second.success);
            System.assertEquals('arrival_date', second.question.questionKey);

            SmartIntakeDTO.IntakeResponse third = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'arrival_date', futureArrivalDate(), second.answersJson)
            );
            System.assertEquals(true, third.success);
            System.assertEquals('booking_note', third.question.questionKey);

            SmartIntakeDTO.IntakeResponse fourth = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'booking_note', 'Late arrival', third.answersJson)
            );
            System.assertEquals(true, fourth.success);
            System.assertEquals('booking_attachment', fourth.question.questionKey);
            System.assertEquals('FILE', fourth.question.inputType);
            System.assertEquals(true, fourth.question.allowMultipleFiles);
            System.assertEquals(2, fourth.question.maxFileCount);
            System.assert(fourth.question.acceptedFormats.contains('.pdf'), JSON.serialize(fourth.question.acceptedFormats));

            SmartIntakeDTO.IntakeResponse complete = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'booking_attachment', '', fourth.answersJson)
            );
            System.assertEquals(true, complete.success);
            System.assertEquals(true, complete.isComplete);

            saved = SmartIntakeService.saveFinal(
                SmartIntakeTestDataFactory.finalSaveRequestWithSession(sessionId, complete.answersJson)
            );
        }

        System.assertEquals(true, saved.success);
        System.assertNotEquals(null, saved.primaryRecordId);
        System.assertEquals(false, saved.hasActiveQuestion, JSON.serialize(saved));
        System.assertEquals(false, saved.mustRenderCurrentQuestion, JSON.serialize(saved));
        System.assertEquals('NONE', saved.rendererMode, JSON.serialize(saved));
        System.assertEquals('FINAL_RESPONSE', saved.recommendedNextStep, JSON.serialize(saved));

        SmartIntake_Submission__c submission = [
            SELECT Template_Key__c, Status__c, Primary_Text__c, Guest_Email__c, Guest_Phone__c, Room_Type__c,
                   Arrival_Date__c, Secondary_Text__c, Answers_JSON__c
            FROM SmartIntake_Submission__c
            WHERE Id = :saved.primaryRecordId
            LIMIT 1
        ];
        System.assertEquals(SmartIntakeTestDataFactory.TEMPLATE_KEY, submission.Template_Key__c);
        System.assertEquals('Complete', submission.Status__c);
        System.assertEquals('Sara Smith', submission.Primary_Text__c);
        System.assertEquals(noMatchEmail(), submission.Guest_Email__c);
        System.assertEquals(noMatchPhone(), submission.Guest_Phone__c);
        System.assertEquals('Premium', submission.Room_Type__c);
        System.assertEquals(futureArrivalDateValue(), submission.Arrival_Date__c);
        System.assertEquals('Late arrival', submission.Secondary_Text__c);
        System.assert(submission.Answers_JSON__c.contains('booking_attachment'), submission.Answers_JSON__c);

        SmartIntake_Session__c session = [
            SELECT Status__c, Current_Question_Key__c, Answers_JSON__c
            FROM SmartIntake_Session__c
            WHERE Session_Id__c = :sessionId
            LIMIT 1
        ];
        System.assertEquals('Complete', session.Status__c);
        System.assertEquals(null, session.Current_Question_Key__c);
        System.assert(session.Answers_JSON__c.contains('Sara Smith'), session.Answers_JSON__c);
    }

    @IsTest
    static void afterAnswerHookCanPauseCurrentQuestionWithFlowMessage() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        SmartIntake_Hook__mdt hook = new SmartIntake_Hook__mdt();
        hook.Template_Key__c = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        hook.Hook_Key__c = 'Room_Availability_Hook';
        hook.Question_Key__c = 'room_type';
        hook.Event__c = 'AFTER_ANSWER';
        hook.Handler_Type__c = 'FLOW';
        hook.Flow_API_Name__c = 'Check_Room_Availability';
        hook.Is_Active__c = true;
        hook.Sort_Order__c = 10;

        SmartIntakeMetadataService.setHooksForTest(new List<SmartIntake_Hook__mdt>{ hook });
        SmartIntakeHookService.setExecutorForTest(new FakeAvailabilityHookExecutor());

        try {
            User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
            System.runAs(currentUser) {
                SmartIntakeDTO.IntakeResponse first = SmartIntakeService.submitAnswer(
                    SmartIntakeTestDataFactory.submitRequest('guest_name', 'Sara Smith', '{}')
                );
                System.assertEquals(true, first.success, JSON.serialize(first));
                System.assertEquals('guest_email', first.question.questionKey);

                SmartIntakeDTO.IntakeResponse paused = SmartIntakeService.submitAnswer(
                    SmartIntakeTestDataFactory.submitRequestWithSession(first.intakeSessionId, 'room_type', 'Suite', contactDetailsAnswersJson())
                );
                System.assertEquals(true, paused.success, JSON.serialize(paused));
                System.assertEquals('room_type', paused.question.questionKey);
                System.assertEquals(null, paused.userMessage, JSON.serialize(paused));
                System.assert(paused.question.questionText.contains('Suite rooms are unavailable for those dates. Please choose another room type.'), JSON.serialize(paused));
                System.assertEquals('Suite', paused.question.value);

                SmartIntake_Session__c session = [
                    SELECT Current_Question_Key__c, Answers_JSON__c
                    FROM SmartIntake_Session__c
                    WHERE Session_Id__c = :first.intakeSessionId
                    LIMIT 1
                ];
                System.assertEquals('room_type', session.Current_Question_Key__c);
                System.assert(session.Answers_JSON__c.contains('Suite'), session.Answers_JSON__c);
            }
        } finally {
            SmartIntakeMetadataService.setHooksForTest(null);
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void afterAnswerHookCanUpdateAnswersAndRouteNextQuestion() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        SmartIntake_Hook__mdt hook = new SmartIntake_Hook__mdt();
        hook.Template_Key__c = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        hook.Hook_Key__c = 'Room_Routing_Hook';
        hook.Question_Key__c = 'room_type';
        hook.Event__c = 'AFTER_ANSWER';
        hook.Handler_Type__c = 'FLOW';
        hook.Flow_API_Name__c = 'Route_After_Room_Choice';
        hook.Is_Active__c = true;
        hook.Sort_Order__c = 10;

        SmartIntakeMetadataService.setHooksForTest(new List<SmartIntake_Hook__mdt>{ hook });
        SmartIntakeHookService.setExecutorForTest(new FakeRoutingHookExecutor());

        try {
            User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
            System.runAs(currentUser) {
                SmartIntakeDTO.IntakeResponse first = SmartIntakeService.submitAnswer(
                    SmartIntakeTestDataFactory.submitRequest('guest_name', 'Sara Smith', '{}')
                );
                System.assertEquals(true, first.success, JSON.serialize(first));

                SmartIntakeDTO.IntakeResponse routed = SmartIntakeService.submitAnswer(
                    SmartIntakeTestDataFactory.submitRequestWithSession(first.intakeSessionId, 'room_type', 'Premium', contactDetailsAnswersJson())
                );

                System.assertEquals(true, routed.success, JSON.serialize(routed));
                System.assertEquals('booking_note', routed.question.questionKey);
                System.assertEquals(null, routed.userMessage, JSON.serialize(routed));
                System.assert(routed.question.questionText.contains('Room choice checked. I can skip to notes.'), JSON.serialize(routed));
                System.assert(routed.answersJson.contains(futureArrivalDate()), routed.answersJson);

                SmartIntake_Session__c session = [
                    SELECT Current_Question_Key__c, Answers_JSON__c
                    FROM SmartIntake_Session__c
                    WHERE Session_Id__c = :first.intakeSessionId
                    LIMIT 1
                ];
                System.assertEquals('booking_note', session.Current_Question_Key__c);
                System.assert(session.Answers_JSON__c.contains(futureArrivalDate()), session.Answers_JSON__c);
            }
        } finally {
            SmartIntakeMetadataService.setHooksForTest(null);
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void afterAnswerHookInvalidNextQuestionReturnsConfigurationError() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        SmartIntake_Hook__mdt hook = new SmartIntake_Hook__mdt();
        hook.Template_Key__c = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        hook.Hook_Key__c = 'Invalid_Next_Question_Hook';
        hook.Question_Key__c = 'room_type';
        hook.Event__c = 'AFTER_ANSWER';
        hook.Handler_Type__c = 'FLOW';
        hook.Flow_API_Name__c = 'Route_After_Room_Choice';
        hook.Is_Active__c = true;
        hook.Sort_Order__c = 10;

        SmartIntakeMetadataService.setHooksForTest(new List<SmartIntake_Hook__mdt>{ hook });
        SmartIntakeHookService.setExecutorForTest(new FakeInvalidNextQuestionHookExecutor());

        try {
            User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
            System.runAs(currentUser) {
                SmartIntakeDTO.IntakeResponse first = SmartIntakeService.submitAnswer(
                    SmartIntakeTestDataFactory.submitRequest('guest_name', 'Sara Smith', '{}')
                );
                System.assertEquals(true, first.success, JSON.serialize(first));

                SmartIntakeDTO.IntakeResponse failed = SmartIntakeService.submitAnswer(
                    SmartIntakeTestDataFactory.submitRequestWithSession(first.intakeSessionId, 'room_type', 'Premium', contactDetailsAnswersJson())
                );

                System.assertEquals(false, failed.success, JSON.serialize(failed));
                System.assertEquals('CONFIGURATION', failed.errorType);
                System.assertEquals('HOOK_NEXT_QUESTION_NOT_FOUND', failed.errorCode);
                System.assert(failed.adminMessage.contains('missing question key'), failed.adminMessage);
            }
        } finally {
            SmartIntakeMetadataService.setHooksForTest(null);
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void changingEarlierAnswerPrunesDownstreamAnswers() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse guest = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequest('guest_name', 'Sara Smith', '{}')
            );
            SmartIntakeDTO.IntakeResponse contactDetails = answerHotelContactDetails(
                guest.intakeSessionId,
                guest.answersJson
            );
            SmartIntakeDTO.IntakeResponse room = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(guest.intakeSessionId, 'room_type', 'Premium', contactDetails.answersJson)
            );
            SmartIntakeDTO.IntakeResponse arrival = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(guest.intakeSessionId, 'arrival_date', futureArrivalDate(), room.answersJson)
            );
            SmartIntakeDTO.IntakeResponse note = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(guest.intakeSessionId, 'booking_note', 'Late arrival', arrival.answersJson)
            );
            System.assert(note.answersJson.contains('Late arrival'), note.answersJson);

            SmartIntakeDTO.IntakeResponse changedRoom = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(guest.intakeSessionId, 'room_type', 'Suite', note.answersJson)
            );

            System.assertEquals(true, changedRoom.success, JSON.serialize(changedRoom));
            System.assert(changedRoom.answersJson.contains('Suite'), changedRoom.answersJson);
            System.assert(!changedRoom.answersJson.contains(futureArrivalDate()), changedRoom.answersJson);
            System.assert(!changedRoom.answersJson.contains('Late arrival'), changedRoom.answersJson);
            System.assertNotEquals(null, changedRoom.question, JSON.serialize(changedRoom));
        }
    }

    @IsTest
    static void submitCurrentAnswerWithCompleteAnswersPromptsForConfirmation() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.SubmitCurrentAnswerRequest request = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
            request.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
            request.intakeSessionId = 'SI-1234567890abcdef1234567890abcdef';
            request.answerValue = 'later';
            request.answersJson = completeHotelAnswersJson();

            SmartIntakeDTO.IntakeResponse response = SmartIntakeService.submitCurrentAnswer(request);

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals(null, response.question);
            System.assertEquals(true, response.isComplete);
            System.assertEquals(null, response.userMessage, JSON.serialize(response));
            System.assertNotEquals(null, response.currentQuestion, JSON.serialize(response));
            System.assert(response.currentQuestion.questionText.contains('review and confirm'), JSON.serialize(response));
            List<Object> reviewItems = finalReviewItems(response);
            System.assert(response.currentQuestion.dataSourceJson.contains('Sara Smith'), response.currentQuestion.dataSourceJson);
            System.assert(response.currentQuestion.dataSourceJson.contains('Late arrival'), response.currentQuestion.dataSourceJson);
            System.assert(response.currentQuestion.helpText.contains('Review your answers:'), JSON.serialize(response.currentQuestion));
            System.assertNotEquals(null, response.answerCaptureTemplate, JSON.serialize(response));
            System.assertEquals('__SMARTINTAKE_FINAL_REVIEW__', response.answerCaptureTemplate.dataSourceKey, JSON.serialize(response.answerCaptureTemplate));
            System.assert(response.answerCaptureTemplate.dataSourceJson.contains('Sara Smith'), response.answerCaptureTemplate.dataSourceJson);
            System.assert(reviewItems.size() > 0, JSON.serialize(response.currentQuestion));
            System.assert(response.answersJson.contains('Late arrival'), response.answersJson);
        }
    }

    @IsTest
    static void finalReviewChangeIntentDoesNotRepeatConfirmationCard() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.SubmitCurrentAnswerRequest request = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
            request.templateKey = 'EVENT_FEEDBACK_FORM';
            request.intakeSessionId = 'SI-2234567890abcdef1234567890abcdef';
            request.answerValue = 'i want to change for one thing';
            request.answersJson = '{"RATING":"5","SATISFACTION_RATING":"5","OPINION_SNAPSHOT":"Great session"}';

            SmartIntakeDTO.IntakeResponse response = SmartIntakeService.submitCurrentAnswer(request);

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals(false, response.isComplete, JSON.serialize(response));
            System.assertEquals(null, response.question, JSON.serialize(response));
            System.assertEquals(null, response.currentQuestion, JSON.serialize(response));
            System.assertEquals(false, response.requiresFinalConfirmation, JSON.serialize(response));
            System.assertEquals(false, response.mustRenderCurrentQuestion, JSON.serialize(response));
            System.assertEquals('NONE', response.rendererMode, JSON.serialize(response));
            System.assertEquals('WAIT_FOR_CHANGE_DETAILS', response.recommendedNextStep, JSON.serialize(response));
            System.assert(response.userMessage.contains('which answer'), JSON.serialize(response));
            System.assert(response.answerCapturePlanJson.contains('"captureAllowedFromLatestMessage":true'), response.answerCapturePlanJson);
        }
    }

    @IsTest
    static void finalReviewQuestionNameReopensConfiguredQuestion() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            Map<String, Object> completeAnswers = new Map<String, Object>{
                'CLAIM_EMAIL' => 'sivachandran2256@gmail.com',
                'VERIFY_EMAIL_OTP' => '000000',
                'CLAIM_SERIAL_NUMBER' => 'LT-PRO15-1001',
                'CLAIM_ISSUE_CATEGORY' => 'Battery'
            };

            SmartIntakeDTO.SubmitCurrentAnswerRequest request = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
            request.templateKey = 'LAPTOP_WARRANTY_CLAIM';
            request.intakeSessionId = 'SI-3334567890abcdef1234567890abcdef';
            request.answerValue = 'issue category';
            request.changeQuestionKey = 'CLAIM_ISSUE_CATEGORY';
            request.answersJson = JSON.serialize(completeAnswers);

            SmartIntakeDTO.IntakeResponse response = SmartIntakeService.submitCurrentAnswer(request);

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals(false, response.isComplete, JSON.serialize(response));
            System.assertNotEquals(null, response.question, JSON.serialize(response));
            System.assertEquals('CLAIM_ISSUE_CATEGORY', response.question.questionKey, JSON.serialize(response));
            System.assertEquals('CLAIM_ISSUE_CATEGORY', response.currentQuestion.questionKey, JSON.serialize(response));
            Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(response.answersJson);
            System.assertEquals(false, answers.containsKey('CLAIM_ISSUE_CATEGORY'), response.answersJson);
        }
    }

    @IsTest
    static void finalReviewGenericAliasReopensConfiguredQuestion() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            Map<String, Object> completeAnswers = new Map<String, Object>{
                'CLAIM_EMAIL' => 'sivachandran2256@gmail.com',
                'VERIFY_EMAIL_OTP' => '000000',
                'CLAIM_SERIAL_NUMBER' => 'LT-PRO15-1001',
                'CLAIM_ISSUE_CATEGORY' => 'Battery'
            };

            SmartIntakeDTO.SubmitCurrentAnswerRequest request = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
            request.templateKey = 'LAPTOP_WARRANTY_CLAIM';
            request.intakeSessionId = 'SI-4334567890abcdef1234567890abcdef';
            request.answerValue = 'i want to change the issue type';
            request.changeQuestionKey = 'CLAIM_ISSUE_CATEGORY';
            request.answersJson = JSON.serialize(completeAnswers);

            SmartIntakeDTO.IntakeResponse response = SmartIntakeService.submitCurrentAnswer(request);

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals(false, response.isComplete, JSON.serialize(response));
            System.assertNotEquals(null, response.question, JSON.serialize(response));
            System.assertEquals('CLAIM_ISSUE_CATEGORY', response.question.questionKey, JSON.serialize(response));
            Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(response.answersJson);
            System.assertEquals(false, answers.containsKey('CLAIM_ISSUE_CATEGORY'), response.answersJson);
        }
    }

    @IsTest
    static void finalReviewProposedCorrectionReopensMetadataFlow() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.SubmitCurrentAnswerRequest request = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
            request.templateKey = 'EVENT_FEEDBACK_FORM';
            request.intakeSessionId = 'SI-3234567890abcdef1234567890abcdef';
            request.answerValue = 'change the event energy';
            request.proposedAnswersJson = JSON.serialize(new Map<String, Object>{
                'SATISFACTION_RATING' => '4'
            });
            request.answersJson = '{"RATING":"5","SATISFACTION_RATING":"5","OPINION_SNAPSHOT":"Great session"}';

            SmartIntakeDTO.IntakeResponse response = SmartIntakeService.submitCurrentAnswer(request);

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals(false, response.isComplete, JSON.serialize(response));
            System.assertNotEquals(null, response.question, JSON.serialize(response));
            System.assertEquals('OPINION_SNAPSHOT', response.question.questionKey, JSON.serialize(response));
            Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(response.answersJson);
            System.assertEquals('4', String.valueOf(answers.get('SATISFACTION_RATING')), response.answersJson);
            System.assertEquals(false, answers.containsKey('OPINION_SNAPSHOT'), response.answersJson);
        }
    }

    @IsTest
    static void submitCurrentBlankOptionalAnswerSkipsAndBlankConfirmationPrompts() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            String answersBeforeAttachment = '{"guest_name":"Sara Smith","guest_email":"' + noMatchEmail() +
                '","guest_email_match_status":"NO_MATCH","guest_phone":"' + noMatchPhone() +
                '","guest_phone_match_status":"NO_MATCH","room_type":"Premium","arrival_date":"' +
                futureArrivalDate() + '","booking_note":"Late arrival"}';

            SmartIntakeDTO.SubmitCurrentAnswerRequest blankAttachment =
                new SmartIntakeDTO.SubmitCurrentAnswerRequest();
            blankAttachment.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
            blankAttachment.intakeSessionId = 'SI-00000000000000000000000000000001';
            blankAttachment.answerValue = '';
            blankAttachment.answersJson = answersBeforeAttachment;

            SmartIntakeDTO.IntakeResponse skipped = SmartIntakeService.submitCurrentAnswer(blankAttachment);
            System.assertEquals(true, skipped.success, JSON.serialize(skipped));
            System.assertEquals(true, skipped.isComplete, JSON.serialize(skipped));
            System.assertEquals(null, skipped.question, JSON.serialize(skipped));
            System.assertEquals(null, skipped.userMessage, JSON.serialize(skipped));
            System.assertNotEquals(null, skipped.currentQuestion, JSON.serialize(skipped));
            System.assert(skipped.currentQuestion.questionText.contains('skipped'), JSON.serialize(skipped));

            SmartIntakeDTO.SubmitCurrentAnswerRequest blankConfirmation =
                new SmartIntakeDTO.SubmitCurrentAnswerRequest();
            blankConfirmation.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
            blankConfirmation.intakeSessionId = 'SI-00000000000000000000000000000002';
            blankConfirmation.answerValue = '';
            blankConfirmation.answersJson = completeHotelAnswersJson();

            SmartIntakeDTO.IntakeResponse confirmationPrompt =
                SmartIntakeService.submitCurrentAnswer(blankConfirmation);
            System.assertEquals(true, confirmationPrompt.success, JSON.serialize(confirmationPrompt));
            System.assertEquals(false, confirmationPrompt.isComplete, JSON.serialize(confirmationPrompt));
            System.assertEquals(null, confirmationPrompt.question, JSON.serialize(confirmationPrompt));
            System.assertEquals(null, confirmationPrompt.currentQuestion, JSON.serialize(confirmationPrompt));
            System.assertEquals(false, confirmationPrompt.requiresFinalConfirmation, JSON.serialize(confirmationPrompt));
            System.assertEquals(false, confirmationPrompt.mustRenderCurrentQuestion, JSON.serialize(confirmationPrompt));
            System.assertEquals('NONE', confirmationPrompt.rendererMode, JSON.serialize(confirmationPrompt));
            System.assertEquals('WAIT_FOR_CHANGE_DETAILS', confirmationPrompt.recommendedNextStep, JSON.serialize(confirmationPrompt));
            System.assert(confirmationPrompt.userMessage.contains('reply yes'), JSON.serialize(confirmationPrompt));
            System.assert(confirmationPrompt.userMessage.contains('which answer'), JSON.serialize(confirmationPrompt));
        }
    }

    @IsTest
    static void sessionStateSupportsResumeBackSkipAndCompletion() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse first = SmartIntakeService.getNextQuestion(
                SmartIntakeTestDataFactory.getNextRequest()
            );
            System.assertEquals(true, first.success);
            System.assert(first.intakeSessionId.startsWith('SI-'), first.intakeSessionId);

            String sessionId = first.intakeSessionId;
            SmartIntakeDTO.IntakeResponse second = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'guest_name', 'Sara Smith', first.answersJson)
            );
            System.assertEquals(true, second.success, JSON.serialize(second));
            System.assertEquals('guest_email', second.question.questionKey);

            SmartIntake_Session__c inProgressSession = [
                SELECT Status__c, Current_Question_Key__c, Answers_JSON__c
                FROM SmartIntake_Session__c
                WHERE Session_Id__c = :sessionId
                LIMIT 1
            ];
            System.assertEquals('In Progress', inProgressSession.Status__c);
            System.assertEquals('guest_email', inProgressSession.Current_Question_Key__c);
            System.assert(inProgressSession.Answers_JSON__c.contains('Sara Smith'), inProgressSession.Answers_JSON__c);

            SmartIntakeDTO.IntakeResponse resumed = SmartIntakeService.getNextQuestion(
                SmartIntakeTestDataFactory.getNextRequestWithSession(sessionId)
            );
            System.assertEquals(true, resumed.success, JSON.serialize(resumed));
            System.assertEquals('guest_email', resumed.question.questionKey);
            System.assert(resumed.answersJson.contains('Sara Smith'), resumed.answersJson);

            SmartIntakeDTO.IntakeResponse back = SmartIntakeService.goBack(
                SmartIntakeTestDataFactory.navigateRequest(sessionId, 'guest_email', resumed.answersJson)
            );
            System.assertEquals(true, back.success, JSON.serialize(back));
            System.assertEquals('guest_name', back.question.questionKey);
            System.assertEquals('Sara Smith', back.question.value);

            SmartIntakeDTO.IntakeResponse requiredSkip = SmartIntakeService.skipQuestion(
                SmartIntakeTestDataFactory.navigateRequest(sessionId, 'guest_name', back.answersJson)
            );
            System.assertEquals(false, requiredSkip.success);
            System.assertEquals('REQUIRED_QUESTION_CANNOT_BE_SKIPPED', requiredSkip.errorCode);

            SmartIntakeDTO.IntakeResponse room = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'guest_name', 'Sara Smith', back.answersJson)
            );
            System.assertEquals(true, room.success, JSON.serialize(room));
            System.assertEquals('guest_email', room.question.questionKey);

            SmartIntakeDTO.IntakeResponse contactDetails = answerHotelContactDetails(sessionId, room.answersJson);

            SmartIntakeDTO.IntakeResponse arrival = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'room_type', 'Premium', contactDetails.answersJson)
            );
            System.assertEquals(true, arrival.success, JSON.serialize(arrival));
            System.assertEquals('arrival_date', arrival.question.questionKey);

            SmartIntakeDTO.IntakeResponse note = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'arrival_date', futureArrivalDate(), arrival.answersJson)
            );
            System.assertEquals(true, note.success, JSON.serialize(note));
            System.assertEquals('booking_note', note.question.questionKey);

            SmartIntakeDTO.IntakeResponse skipped = SmartIntakeService.skipQuestion(
                SmartIntakeTestDataFactory.navigateRequest(sessionId, 'booking_note', note.answersJson)
            );
            System.assertEquals(true, skipped.success, JSON.serialize(skipped));
            System.assertEquals('booking_attachment', skipped.question.questionKey);
            System.assertEquals(null, skipped.userMessage, JSON.serialize(skipped));
            System.assert(skipped.question.questionText.contains('skipped'), JSON.serialize(skipped));

            SmartIntakeDTO.IntakeResponse complete = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(sessionId, 'booking_attachment', '', skipped.answersJson)
            );
            System.assertEquals(true, complete.success, JSON.serialize(complete));
            System.assertEquals(true, complete.isComplete);

            SmartIntakeDTO.IntakeResponse saved = SmartIntakeService.saveFinal(
                SmartIntakeTestDataFactory.finalSaveRequestWithSession(sessionId, complete.answersJson)
            );
            System.assertEquals(true, saved.success, JSON.serialize(saved));

            SmartIntake_Session__c completedSession = [
                SELECT Status__c, Current_Question_Key__c, Skipped_Question_Keys_JSON__c
                FROM SmartIntake_Session__c
                WHERE Session_Id__c = :sessionId
                LIMIT 1
            ];
            System.assertEquals('Complete', completedSession.Status__c);
            System.assertEquals(null, completedSession.Current_Question_Key__c);
            System.assert(completedSession.Skipped_Question_Keys_JSON__c.contains('booking_note'), completedSession.Skipped_Question_Keys_JSON__c);
        }
    }

    @IsTest
    static void invalidTemplateReturnsConfigurationError() {
        SmartIntakeDTO.GetNextQuestionRequest request = new SmartIntakeDTO.GetNextQuestionRequest();
        request.templateKey = 'MISSING_TEMPLATE';

        SmartIntakeDTO.IntakeResponse response = SmartIntakeService.getNextQuestion(request);

        System.assertEquals(false, response.success);
        System.assertEquals('CONFIGURATION', response.errorType);
        System.assertEquals('TEMPLATE_NOT_FOUND', response.errorCode);
    }

    @IsTest
    static void invocableActionsCoverAgentforceEntryPoints() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse first = SmartIntakeGetNextQuestionAction.invoke(
                new List<SmartIntakeDTO.GetNextQuestionRequest>{
                    SmartIntakeTestDataFactory.getNextRequest()
                }
            )[0];
            System.assertEquals(true, first.success);
            System.assertEquals('guest_name', first.question.questionKey);
            String sessionId = first.intakeSessionId;

            SmartIntakeDTO.IntakeResponse second = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithSession(sessionId, 'Sara Smith', first.answersJson)
                }
            )[0];
            System.assertEquals(true, second.success);
            System.assertEquals('guest_email', second.question.questionKey);

            SmartIntakeDTO.IntakeResponse contactDetails = answerCurrentContactDetails(sessionId, second.answersJson);

            SmartIntakeDTO.IntakeResponse third = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithSession(sessionId, 'Deluxe', contactDetails.answersJson)
                }
            )[0];
            System.assertEquals(true, third.success);
            System.assertEquals('arrival_date', third.question.questionKey);

            SmartIntakeDTO.IntakeResponse fourth = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithSession(sessionId, futureArrivalDate(), third.answersJson)
                }
            )[0];
            System.assertEquals(true, fourth.success);
            System.assertEquals('booking_note', fourth.question.questionKey);

            SmartIntakeDTO.IntakeResponse complete = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithSession(sessionId, 'Late arrival', fourth.answersJson)
                }
            )[0];
            System.assertEquals(false, complete.isComplete);
            System.assertEquals('booking_attachment', complete.question.questionKey);

            complete = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithSession(sessionId, 'skip', complete.answersJson)
                }
            )[0];
            System.assertEquals(true, complete.isComplete);
            System.assert(complete.answersJson.contains('booking_attachment'), complete.answersJson);

            SmartIntakeDTO.IntakeResponse saved = SmartIntakeSaveFinalAction.invoke(
                new List<SmartIntakeDTO.SaveFinalRequest>{
                    SmartIntakeTestDataFactory.finalSaveRequestWithSession(sessionId, complete.answersJson)
                }
            )[0];
            System.assertEquals(true, saved.success);
            System.assertNotEquals(null, saved.primaryRecordId);
        }

        SmartIntakeDTO.HandoffPlanRequest handoffRequest = new SmartIntakeDTO.HandoffPlanRequest();
        handoffRequest.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        handoffRequest.consentAccepted = true;
        SmartIntakeDTO.HandoffPlanResponse handoffResponse = SmartIntakeGetHandoffPlanAction.invoke(
            new List<SmartIntakeDTO.HandoffPlanRequest>{ handoffRequest }
        )[0];
        System.assertEquals(true, handoffResponse.success);
        System.assertEquals('ENHANCED_CHAT_V2', handoffResponse.providerType);
    }

    @IsTest
    static void submitCurrentAnswerCanStartFromAgentSessionKey() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse started = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession('agent-preview-session-1', 'I want to start an intake.')
                }
            )[0];
            System.assertEquals(true, started.success, JSON.serialize(started));
            System.assertEquals('guest_name', started.question.questionKey);
            System.assert(started.intakeSessionId.startsWith('SI-'), started.intakeSessionId);

            SmartIntakeDTO.IntakeResponse answered = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession('agent-preview-session-1', 'Sara Smith')
                }
            )[0];
            System.assertEquals(true, answered.success, JSON.serialize(answered));
            System.assertEquals('guest_email', answered.question.questionKey);
            System.assert(answered.answersJson.contains('Sara Smith'), answered.answersJson);
        }
    }

    @IsTest
    static void submitCurrentConfirmationSavesCompleteAgentSession() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            String agentSessionKey = 'agent-preview-final-save-session';
            SmartIntakeDTO.IntakeResponse response = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession(agentSessionKey, 'Start hotel booking')
                }
            )[0];
            System.assertEquals('guest_name', response.question.questionKey);

            response = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession(agentSessionKey, 'Sara Smith')
                }
            )[0];
            System.assertEquals('guest_email', response.question.questionKey);

            response = answerAgentContactDetails(agentSessionKey);

            response = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession(agentSessionKey, 'Deluxe')
                }
            )[0];
            System.assertEquals('arrival_date', response.question.questionKey);

            response = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession(agentSessionKey, futureArrivalDate())
                }
            )[0];
            System.assertEquals('booking_note', response.question.questionKey);

            response = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession(agentSessionKey, 'Late arrival around 10 PM.')
                }
            )[0];
            System.assertEquals('booking_attachment', response.question.questionKey);

            response = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession(agentSessionKey, 'skip')
                }
            )[0];
            System.assertEquals(true, response.isComplete, JSON.serialize(response));
            System.assertEquals(null, response.question);

            SmartIntakeDTO.IntakeResponse saved = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession(agentSessionKey, 'I accept and submit')
                }
            )[0];
            System.assertEquals(true, saved.success, JSON.serialize(saved));
            System.assertNotEquals(null, saved.primaryRecordId);
            System.assert(saved.userMessage.contains('saved'), saved.userMessage);

            SmartIntake_Session__c completedSession = [
                SELECT Status__c, Current_Question_Key__c
                FROM SmartIntake_Session__c
                WHERE Session_Id__c = :saved.intakeSessionId
                LIMIT 1
            ];
            System.assertEquals('Complete', completedSession.Status__c);
            System.assertEquals(null, completedSession.Current_Question_Key__c);
        }
    }

    @IsTest
    static void getHandoffPlanUsesMetadataAndConsent() {
        SmartIntakeDTO.HandoffPlanResponse missingRequest = SmartIntakeService.getHandoffPlan(null);
        System.assertEquals(false, missingRequest.success);
        System.assertEquals('VALIDATION', missingRequest.errorType);
        System.assertEquals('MISSING_REQUEST', missingRequest.errorCode);

        SmartIntakeDTO.HandoffPlanRequest request = new SmartIntakeDTO.HandoffPlanRequest();
        request.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        request.reason = 'guest asked for human help';
        request.consentAccepted = false;

        SmartIntakeDTO.HandoffPlanResponse consentResponse = SmartIntakeService.getHandoffPlan(request);
        System.assertEquals(true, consentResponse.success);
        System.assertEquals(true, consentResponse.handoffEnabled);
        System.assertEquals(false, consentResponse.handoffReady);
        System.assertEquals('ENHANCED_CHAT_V2', consentResponse.providerType);
        System.assertEquals('CONSENT_REQUIRED', consentResponse.availabilityStatus);
        System.assertEquals(true, consentResponse.requiresConsent);
        System.assertEquals(false, consentResponse.consentAccepted);
        System.assertEquals(false, consentResponse.contextSharingEnabled);
        System.assertEquals(null, consentResponse.contextFieldsToShare);
        System.assertEquals(null, consentResponse.contextSummaryJson);
        System.assert(consentResponse.handoffMessage.contains('Before I connect'), consentResponse.handoffMessage);
        System.assert(consentResponse.triggerMessage.contains('booking team'), consentResponse.triggerMessage);
        System.assert(consentResponse.readinessWarningsJson.contains('Enhanced Chat v2'), consentResponse.readinessWarningsJson);

        SmartIntakeDTO.HandoffPlanResponse acceptedResponse = SmartIntakeRuntimeController.getHandoffPlan(
            null,
            SmartIntakeTestDataFactory.TEMPLATE_KEY,
            'guest asked for human help',
            true,
            '{"guest_name":"Sara Smith","unconfigured_secret":"Do not share"}'
        );
        System.assertEquals(true, acceptedResponse.success);
        System.assertEquals(true, acceptedResponse.handoffEnabled);
        System.assertEquals(true, acceptedResponse.requiresConsent);
        System.assertEquals(true, acceptedResponse.consentAccepted);
        System.assertEquals('NOT_READY', acceptedResponse.availabilityStatus);
        System.assertEquals(false, acceptedResponse.contextSharingEnabled);
        System.assertEquals(null, acceptedResponse.contextFieldsToShare);
        System.assertEquals(null, acceptedResponse.contextSummaryJson);

        String filteredContext = SmartIntakeService.filteredHandoffContextSummary(
            '{"guest_name":"Sara Smith","unconfigured_secret":"Do not share"}',
            'guest_name;room_type'
        );
        System.assert(filteredContext.contains('Sara Smith'), filteredContext);
        System.assert(!filteredContext.contains('unconfigured_secret'), filteredContext);
        System.assertEquals('{}', SmartIntakeService.filteredHandoffContextSummary('', 'guest_name'));
        System.assertEquals('{}', SmartIntakeService.filteredHandoffContextSummary('{', 'guest_name'));
        System.assertEquals('{}', SmartIntakeService.filteredHandoffContextSummary('["guest_name"]', 'guest_name'));
    }

    @IsTest
    static void getHandoffPlanReturnsDisabledWhenTemplateHasNoConfig() {
        SmartIntakeDTO.HandoffPlanRequest request = new SmartIntakeDTO.HandoffPlanRequest();
        request.templateKey = 'EVENT_FEEDBACK_FORM';
        request.consentAccepted = true;

        SmartIntakeDTO.HandoffPlanResponse response = SmartIntakeService.getHandoffPlan(request);

        System.assertEquals(true, response.success, JSON.serialize(response));
        System.assertEquals(false, response.handoffEnabled, JSON.serialize(response));
        System.assertEquals(false, response.handoffReady, JSON.serialize(response));
        System.assertEquals('NOT_CONFIGURED', response.availabilityStatus, JSON.serialize(response));
        System.assert(response.readinessWarningsJson.contains('EVENT_FEEDBACK_FORM'), response.readinessWarningsJson);
    }

    @IsTest
    static void findExistingRecordUsesMatchingMetadata() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeDTO.FindExistingRecordResponse serviceResponse;
        SmartIntakeDTO.FindExistingRecordResponse actionResponse;
        System.runAs(currentUser) {
            insert new SmartIntake_Submission__c(
                Primary_Text__c = 'Sara Smith',
                Template_Key__c = SmartIntakeTestDataFactory.TEMPLATE_KEY,
                Status__c = 'Complete',
                Session_Id__c = 'test-match'
            );

            serviceResponse = SmartIntakeService.findExistingRecord(
                SmartIntakeTestDataFactory.findExistingRequest('guest_name_exact', 'Sara Smith')
            );
            actionResponse = SmartIntakeFindExistingRecordAction.invoke(
                new List<SmartIntakeDTO.FindExistingRecordRequest>{
                    SmartIntakeTestDataFactory.findExistingRequest('guest_name', 'Sara Smith')
                }
            )[0];
        }

        System.assertEquals(true, serviceResponse.success);
        System.assertEquals(true, serviceResponse.recordFound);
        System.assertNotEquals(null, serviceResponse.recordId);
        System.assertEquals('SmartIntake_Submission__c', serviceResponse.objectApiName);
        System.assertEquals('Primary_Text__c', serviceResponse.matchedField);
        System.assertNotEquals(null, serviceResponse.displayValue);

        System.assertEquals(true, actionResponse.success);
        System.assertEquals(true, actionResponse.recordFound);
        System.assertEquals(serviceResponse.recordId, actionResponse.recordId);
    }

    @IsTest
    static void findExistingRecordReturnsControlledErrors() {
        SmartIntakeDTO.FindExistingRecordResponse missingRequest = SmartIntakeService.findExistingRecord(null);
        System.assertEquals(false, missingRequest.success);
        System.assertEquals('VALIDATION', missingRequest.errorType);
        System.assertEquals('MISSING_REQUEST', missingRequest.errorCode);

        SmartIntakeDTO.FindExistingRecordResponse missingRule = SmartIntakeService.findExistingRecord(
            SmartIntakeTestDataFactory.findExistingRequest('not_real', 'Sara Smith')
        );
        System.assertEquals(false, missingRule.success);
        System.assertEquals('CONFIGURATION', missingRule.errorType);
        System.assertEquals('MATCHING_RULE_NOT_FOUND', missingRule.errorCode);
    }

    @IsTest
    static void getExistingContextUsesMetadata() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String answersJson = '{"guest_name":"Sara Smith","room_type":"Premium","arrival_date":"' + futureArrivalDate() + '"}';

        SmartIntakeDTO.ExistingContextResponse serviceResponse;
        SmartIntakeDTO.ExistingContextResponse actionResponse;
        SmartIntakeDTO.ExistingContextResponse controllerResponse;
        System.runAs(currentUser) {
            insert new SmartIntake_Submission__c(
                Primary_Text__c = 'Sara Smith',
                Template_Key__c = SmartIntakeTestDataFactory.TEMPLATE_KEY,
                Status__c = 'Complete',
                Session_Id__c = 'test-context'
            );

            serviceResponse = SmartIntakeService.getExistingContext(
                SmartIntakeTestDataFactory.existingContextRequest('booking_note', answersJson)
            );
            actionResponse = SmartIntakeGetExistingContextAction.invoke(
                new List<SmartIntakeDTO.GetExistingContextRequest>{
                    SmartIntakeTestDataFactory.existingContextRequest('booking_note', answersJson)
                }
            )[0];
            controllerResponse = SmartIntakeRuntimeController.getExistingContext(
                null,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                'booking_note',
                null,
                answersJson
            );
        }

        System.assertEquals(true, serviceResponse.success);
        System.assertEquals(true, serviceResponse.hasContext);
        System.assertEquals('MATCHED_RECORDS', serviceResponse.contextType);
        System.assertEquals(1, serviceResponse.contextRecords.size());
        System.assert(serviceResponse.contextMessage.contains('earlier bookings'), serviceResponse.contextMessage);
        System.assert(serviceResponse.contextRecords[0].allowedActions.contains('select'), serviceResponse.contextRecords[0].allowedActions);
        System.assert(serviceResponse.contextRecordsJson.contains(serviceResponse.contextRecords[0].recordId), serviceResponse.contextRecordsJson);

        System.assertEquals(true, actionResponse.hasContext);
        System.assertEquals(true, controllerResponse.hasContext);
    }

    @IsTest
    static void getExistingContextReturnsControlledNoContextResponses() {
        SmartIntakeDTO.ExistingContextResponse missingRequest = SmartIntakeService.getExistingContext(null);
        System.assertEquals(false, missingRequest.success);
        System.assertEquals('VALIDATION', missingRequest.errorType);
        System.assertEquals('MISSING_REQUEST', missingRequest.errorCode);

        SmartIntakeDTO.ExistingContextResponse noConfig = SmartIntakeService.getExistingContext(
            SmartIntakeTestDataFactory.existingContextRequest('guest_name', '{"guest_name":"Sara Smith"}')
        );
        System.assertEquals(true, noConfig.success);
        System.assertEquals(false, noConfig.hasContext);
        System.assertEquals('[]', noConfig.contextRecordsJson);

        SmartIntakeDTO.ExistingContextResponse missingSourceAnswer = SmartIntakeService.getExistingContext(
            SmartIntakeTestDataFactory.existingContextRequest('booking_note', '{}')
        );
        System.assertEquals(true, missingSourceAnswer.success);
        System.assertEquals(false, missingSourceAnswer.hasContext);
    }

    @IsTest
    static void runtimeControllerCoversLwcEntryPoints() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse first = SmartIntakeRuntimeController.getNextQuestion(
                null,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                null,
                '{}'
            );
            System.assertEquals(true, first.success);

            SmartIntakeDTO.IntakeResponse second = SmartIntakeRuntimeController.submitAnswer(
                first.intakeSessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'guest_name',
                'Sara Smith',
                first.answersJson
            );
            System.assertEquals(true, second.success);

            SmartIntakeDTO.IntakeResponse third = SmartIntakeRuntimeController.submitAnswer(
                second.intakeSessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'guest_email',
                noMatchEmail(),
                second.answersJson
            );
            System.assertEquals(true, third.success);
            System.assertEquals('guest_phone', third.question.questionKey);

            SmartIntakeDTO.IntakeResponse fourth = SmartIntakeRuntimeController.submitAnswer(
                third.intakeSessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'guest_phone',
                noMatchPhone(),
                third.answersJson
            );
            System.assertEquals(true, fourth.success);
            System.assertEquals('room_type', fourth.question.questionKey);

            SmartIntakeDTO.IntakeResponse fifth = SmartIntakeRuntimeController.submitAnswer(
                fourth.intakeSessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'room_type',
                'Suite',
                fourth.answersJson
            );
            System.assertEquals(true, fifth.success);
            System.assertEquals('suite_preference', fifth.question.questionKey);

            SmartIntakeDTO.IntakeResponse sixth = SmartIntakeRuntimeController.submitAnswer(
                fifth.intakeSessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'suite_preference',
                'High floor',
                fifth.answersJson
            );
            System.assertEquals(true, sixth.success);
            System.assertEquals('arrival_date', sixth.question.questionKey);

            SmartIntakeDTO.IntakeResponse seventh = SmartIntakeRuntimeController.submitAnswer(
                sixth.intakeSessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'arrival_date',
                futureArrivalDate(),
                sixth.answersJson
            );
            System.assertEquals(true, seventh.success);

            SmartIntakeDTO.IntakeResponse complete = SmartIntakeRuntimeController.submitAnswer(
                seventh.intakeSessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'booking_note',
                'Late arrival',
                seventh.answersJson
            );
            System.assertEquals(false, complete.isComplete);
            System.assertEquals('booking_attachment', complete.question.questionKey);

            complete = SmartIntakeRuntimeController.submitAnswer(
                complete.intakeSessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'booking_attachment',
                '',
                complete.answersJson
            );
            System.assertEquals(true, complete.isComplete);

            SmartIntakeDTO.IntakeResponse saved = SmartIntakeRuntimeController.saveFinal(
                complete.intakeSessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                complete.answersJson,
                true,
                true
            );
            System.assertEquals(true, saved.success);
        }
    }

    @IsTest
    static void conditionalQuestionIsControlledByMetadata() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse first = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequest('guest_name', 'Sara Smith', '{}')
            );
            System.assertEquals(true, first.success);
            SmartIntakeDTO.IntakeResponse contactDetails = answerHotelContactDetails(
                first.intakeSessionId,
                first.answersJson
            );

            SmartIntakeDTO.IntakeResponse deluxePath = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(first.intakeSessionId, 'room_type', 'Deluxe', contactDetails.answersJson)
            );
            System.assertEquals(true, deluxePath.success);
            System.assertEquals('arrival_date', deluxePath.question.questionKey);
            System.assertEquals(9, deluxePath.progress.totalSteps);

            SmartIntakeDTO.IntakeResponse suitePath = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(first.intakeSessionId, 'room_type', 'Suite', contactDetails.answersJson)
            );
            System.assertEquals(true, suitePath.success);
            System.assertEquals('suite_preference', suitePath.question.questionKey);
            System.assertEquals(10, suitePath.progress.totalSteps);

            SmartIntakeDTO.IntakeResponse hiddenAnswer = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequest('suite_preference', 'High floor', deluxePath.answersJson)
            );
            System.assertEquals(false, hiddenAnswer.success);
            System.assertEquals('QUESTION_NOT_VISIBLE', hiddenAnswer.errorCode);
        }
    }

    @IsTest
    static void customGroupedConditionsControlQuestionVisibility() {
        SmartIntakeMetadataService.conditionsForTests = new List<SmartIntake_Condition__mdt>{
            runtimeCondition('suite_by_room', 'room_type', 'suite_preference', 'SHOW_WHEN', 'EQUALS', 'Suite', 'suite_gate', 'CUSTOM', 1, '1 OR 2', null),
            runtimeCondition('suite_by_guest', 'guest_name', 'suite_preference', 'SHOW_WHEN', 'EQUALS', 'VIP Guest', 'suite_gate', 'CUSTOM', 2, '1 OR 2', null)
        };
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse regularGuest = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequest('guest_name', 'Sara Smith', '{}')
            );
            SmartIntakeDTO.IntakeResponse regularContactDetails = answerHotelContactDetails(
                regularGuest.intakeSessionId,
                regularGuest.answersJson
            );
            SmartIntakeDTO.IntakeResponse regularPath = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(regularGuest.intakeSessionId, 'room_type', 'Deluxe', regularContactDetails.answersJson)
            );
            System.assertEquals(true, regularPath.success);
            System.assertEquals('arrival_date', regularPath.question.questionKey);

            SmartIntakeDTO.IntakeResponse vipGuest = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequest('guest_name', 'VIP Guest', '{}')
            );
            SmartIntakeDTO.IntakeResponse vipContactDetails = answerHotelContactDetails(
                vipGuest.intakeSessionId,
                vipGuest.answersJson
            );
            SmartIntakeDTO.IntakeResponse vipPath = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(vipGuest.intakeSessionId, 'room_type', 'Deluxe', vipContactDetails.answersJson)
            );
            System.assertEquals(true, vipPath.success);
            System.assertEquals('suite_preference', vipPath.question.questionKey);
        }
        SmartIntakeMetadataService.conditionsForTests = null;
    }

    @IsTest
    static void invalidCustomConditionLogicReturnsConfigurationError() {
        SmartIntakeMetadataService.conditionsForTests = new List<SmartIntake_Condition__mdt>{
            runtimeCondition(
                'invalid_guest_name_rule',
                'guest_name',
                'guest_name',
                'BLOCK_WHEN',
                'EQUALS',
                'Sara Smith',
                'invalid_logic_gate',
                'CUSTOM',
                1,
                '1 AND (',
                null
            )
        };
        try {
            SmartIntakeDTO.ValidateAnswerResponse response = SmartIntakeService.validateIntakeAnswer(
                SmartIntakeTestDataFactory.validateRequest('guest_name', 'Sara Smith')
            );

            System.assertEquals(false, response.success, JSON.serialize(response));
            System.assertEquals(false, response.isValid, JSON.serialize(response));
            System.assertEquals('CONFIGURATION', response.errorType, JSON.serialize(response));
            System.assertEquals('CONDITION_CUSTOM_LOGIC_INVALID', response.errorCode, JSON.serialize(response));
            System.assert(response.adminMessage.contains('Expected condition number'), response.adminMessage);
        } finally {
            SmartIntakeMetadataService.conditionsForTests = null;
        }
    }

    @IsTest
    static void blockWhenConditionRejectsAnswerWithConfiguredMessage() {
        SmartIntakeMetadataService.conditionsForTests = new List<SmartIntake_Condition__mdt>{
            runtimeCondition(
                'arrival_not_after_today',
                'arrival_date',
                'arrival_date',
                'BLOCK_WHEN',
                'AFTER',
                'TODAY',
                'arrival_date_rules',
                'ALL',
                1,
                null,
                'Arrival date must not be after today in this test rule.'
            )
        };

        SmartIntakeDTO.ValidateAnswerResponse response = SmartIntakeService.validateIntakeAnswer(
            SmartIntakeTestDataFactory.validateRequest('arrival_date', String.valueOf(Date.today().addDays(1)))
        );

        System.assertEquals(false, response.success);
        System.assertEquals(false, response.isValid);
        System.assertEquals('CONDITION_BLOCKED', response.errorCode);
        System.assert(response.userMessage.contains('must not be after today'), response.userMessage);

        SmartIntakeMetadataService.conditionsForTests = new List<SmartIntake_Condition__mdt>{
            runtimeCondition(
                'arrival_not_on_or_after_tomorrow',
                'arrival_date',
                'arrival_date',
                'BLOCK_WHEN',
                'ON_OR_AFTER',
                'TODAY+1',
                'arrival_date_rules',
                'ALL',
                1,
                null,
                'Arrival date matched the dynamic tomorrow rule.'
            )
        };
        SmartIntakeDTO.ValidateAnswerResponse offsetResponse = SmartIntakeService.validateIntakeAnswer(
            SmartIntakeTestDataFactory.validateRequest('arrival_date', String.valueOf(Date.today().addDays(1)))
        );
        System.assertEquals(false, offsetResponse.success);
        System.assertEquals('CONDITION_BLOCKED', offsetResponse.errorCode);
        System.assert(offsetResponse.userMessage.contains('dynamic tomorrow'), offsetResponse.userMessage);
        SmartIntakeMetadataService.conditionsForTests = null;
    }

    @IsTest
    static void textAndListConditionOperatorsCanBeCombinedWithAllLogic() {
        SmartIntakeMetadataService.conditionsForTests = new List<SmartIntake_Condition__mdt>{
            runtimeCondition('name_contains', 'guest_name', 'suite_preference', 'SHOW_WHEN', 'CONTAINS', 'Guest', 'text_gate', 'ALL', 1, null, null),
            runtimeCondition('name_not_contains', 'guest_name', 'suite_preference', 'SHOW_WHEN', 'NOT_CONTAINS', 'Blocked', 'text_gate', 'ALL', 2, null, null),
            runtimeCondition('name_starts', 'guest_name', 'suite_preference', 'SHOW_WHEN', 'STARTS_WITH', 'VIP', 'text_gate', 'ALL', 3, null, null),
            runtimeCondition('name_ends', 'guest_name', 'suite_preference', 'SHOW_WHEN', 'ENDS_WITH', 'Guest', 'text_gate', 'ALL', 4, null, null),
            runtimeCondition('room_in', 'room_type', 'suite_preference', 'SHOW_WHEN', 'IN', 'Deluxe;Premium', 'text_gate', 'ALL', 5, null, null),
            runtimeCondition('room_not_in', 'room_type', 'suite_preference', 'SHOW_WHEN', 'NOT_IN', 'Suite', 'text_gate', 'ALL', 6, null, null)
        };
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse guest = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequest('guest_name', 'VIP Guest', '{}')
            );
            SmartIntakeDTO.IntakeResponse contactDetails = answerHotelContactDetails(
                guest.intakeSessionId,
                guest.answersJson
            );
            SmartIntakeDTO.IntakeResponse room = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(guest.intakeSessionId, 'room_type', 'Deluxe', contactDetails.answersJson)
            );

            System.assertEquals(true, room.success);
            System.assertEquals('suite_preference', room.question.questionKey);
        }
        SmartIntakeMetadataService.conditionsForTests = null;
    }

    @IsTest
    static void hideWhenAnyLogicAndBlankOperatorsCanSkipTargetQuestion() {
        SmartIntakeMetadataService.conditionsForTests = new List<SmartIntake_Condition__mdt>{
            runtimeCondition('hide_for_deluxe', 'room_type', 'suite_preference', 'HIDE_WHEN', 'EQUALS', 'Deluxe', 'hide_suite', 'ANY', 1, null, null),
            runtimeCondition('hide_when_note_blank', 'booking_note', 'suite_preference', 'HIDE_WHEN', 'IS_BLANK', null, 'hide_suite', 'ANY', 2, null, null)
        };
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse guest = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequest('guest_name', 'Sara Smith', '{}')
            );
            SmartIntakeDTO.IntakeResponse contactDetails = answerHotelContactDetails(
                guest.intakeSessionId,
                guest.answersJson
            );
            SmartIntakeDTO.IntakeResponse room = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(guest.intakeSessionId, 'room_type', 'Suite', contactDetails.answersJson)
            );

            System.assertEquals(true, room.success);
            System.assertEquals('arrival_date', room.question.questionKey);
        }
        SmartIntakeMetadataService.conditionsForTests = null;

        SmartIntakeMetadataService.conditionsForTests = new List<SmartIntake_Condition__mdt>{
            runtimeCondition('block_when_note_present', 'booking_note', 'booking_note', 'BLOCK_WHEN', 'IS_NOT_BLANK', null, 'note_rule', 'ALL', 1, null, null)
        };
        SmartIntakeDTO.ValidateAnswerResponse response = SmartIntakeService.validateIntakeAnswer(
            SmartIntakeTestDataFactory.validateRequest('booking_note', 'Do not continue')
        );
        System.assertEquals(false, response.success);
        System.assertEquals('CONDITION_BLOCKED', response.errorCode);
        System.assert(response.userMessage.contains('configured intake rules'), response.userMessage);
        SmartIntakeMetadataService.conditionsForTests = null;
    }

    @IsTest
    static void finalSaveRequiresConfirmation() {
        SmartIntakeDTO.SaveFinalRequest request = SmartIntakeTestDataFactory.finalSaveRequest(
            '{"guest_name":"Sara Smith","booking_note":"Late arrival"}'
        );
        request.confirmed = false;

        SmartIntakeDTO.IntakeResponse response = SmartIntakeService.saveFinal(request);

        System.assertEquals(false, response.success);
        System.assertEquals('VALIDATION', response.errorType);
        System.assertEquals('CONFIRMATION_REQUIRED', response.errorCode);
    }

    @IsTest
    static void finalSaveRequiresConsentWhenTemplateRequiresIt() {
        SmartIntakeDTO.SaveFinalRequest request = SmartIntakeTestDataFactory.finalSaveRequest(
            completeHotelAnswersJson()
        );
        request.consentAccepted = false;

        SmartIntakeDTO.IntakeResponse response = SmartIntakeService.saveFinal(request);

        System.assertEquals(false, response.success);
        System.assertEquals('VALIDATION', response.errorType);
        System.assertEquals('CONSENT_REQUIRED', response.errorCode);
    }

    @IsTest
    static void finalSaveIsIdempotentForSameSession() {
        String sessionId = 'SI-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        SmartIntakeDTO.SaveFinalRequest request = SmartIntakeTestDataFactory.finalSaveRequestWithSession(
            sessionId,
            completeHotelAnswersJson()
        );

        SmartIntakeDTO.IntakeResponse first = SmartIntakeService.saveFinal(request);
        SmartIntakeDTO.IntakeResponse second = SmartIntakeService.saveFinal(request);

        System.assertEquals(true, first.success, JSON.serialize(first));
        System.assertEquals(true, second.success, JSON.serialize(second));
        System.assertEquals(first.primaryRecordId, second.primaryRecordId);
        System.assertEquals(1, [
            SELECT COUNT()
            FROM SmartIntake_Submission__c
            WHERE Session_Id__c = :sessionId
              AND Template_Key__c = :SmartIntakeTestDataFactory.TEMPLATE_KEY
        ]);
    }

    @IsTest
    static void finalSavePersistsFlowOutputDataKeys() {
        Account account = new Account(Name = 'Warranty Customer');
        insert account;

        Contact contact = new Contact(
            LastName = 'Customer',
            Email = 'claim@example.com',
            AccountId = account.Id
        );
        insert contact;

        Product2 product = new Product2(Name = 'Laptop Pro 15', IsActive = true);
        insert product;

        Asset asset = new Asset(
            Name = 'Laptop Pro 15',
            AccountId = account.Id,
            ContactId = contact.Id,
            Product2Id = product.Id,
            SerialNumber = 'LT-PRO15-TEST'
        );
        insert asset;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Asset__c = asset.Id,
            Status__c = 'Active',
            Start_Date__c = Date.today().addMonths(-1),
            End_Date__c = Date.today().addYears(1)
        );
        insert warranty;

        Map<String, Object> answers = new Map<String, Object>{
            'CLAIM_EMAIL' => contact.Email,
            'VERIFY_EMAIL_OTP' => '123456',
            'CLAIM_SERIAL_NUMBER' => asset.SerialNumber,
            'CLAIM_ISSUE_CATEGORY' => 'Battery',
            'CONTACT_ID' => String.valueOf(contact.Id),
            'ASSET_ID' => String.valueOf(asset.Id),
            'PRODUCT_ID' => String.valueOf(product.Id),
            'ASSET_WARRANTY_ID' => String.valueOf(warranty.Id)
        };

        SmartIntakeDTO.SaveFinalRequest request = new SmartIntakeDTO.SaveFinalRequest();
        request.intakeSessionId = 'SI-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
        request.templateKey = 'LAPTOP_WARRANTY_CLAIM';
        request.answersJson = JSON.serialize(answers);
        request.confirmed = true;
        request.consentAccepted = true;

        SmartIntakeDTO.IntakeResponse response = SmartIntakeService.saveFinal(request);
        SmartIntakeDTO.IntakeResponse repeatResponse = SmartIntakeService.saveFinal(request);

        System.assertEquals(true, response.success, JSON.serialize(response));
        System.assertEquals(true, repeatResponse.success, JSON.serialize(repeatResponse));
        System.assertNotEquals(null, response.primaryRecordId);
        System.assertEquals(response.primaryRecordId, repeatResponse.primaryRecordId);

        Warranty_Claim__c savedClaim = [
            SELECT Contact__c, Asset__c, Product__c, Asset_Warranty__c, External_Key__c
            FROM Warranty_Claim__c
            WHERE Id = :response.primaryRecordId
            LIMIT 1
        ];
        System.assertEquals(contact.Id, savedClaim.Contact__c);
        System.assertEquals(asset.Id, savedClaim.Asset__c);
        System.assertEquals(product.Id, savedClaim.Product__c);
        System.assertEquals(warranty.Id, savedClaim.Asset_Warranty__c);
        System.assertNotEquals(null, savedClaim.External_Key__c);
        System.assertEquals(1, [
            SELECT COUNT()
            FROM Warranty_Claim__c
            WHERE External_Key__c = :savedClaim.External_Key__c
        ]);
    }

    @IsTest
    static void finalSaveReturnsControlledErrorForInvalidMappedLookup() {
        Account account = new Account(Name = 'Warranty Customer');
        insert account;

        Contact contact = new Contact(
            LastName = 'Customer',
            Email = 'claim@example.com',
            AccountId = account.Id
        );
        insert contact;

        Product2 product = new Product2(Name = 'Laptop Pro 15', IsActive = true);
        insert product;

        Asset asset = new Asset(
            Name = 'Laptop Pro 15',
            AccountId = account.Id,
            ContactId = contact.Id,
            Product2Id = product.Id,
            SerialNumber = 'LT-PRO15-TEST'
        );
        insert asset;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Asset__c = asset.Id,
            Status__c = 'Active',
            Start_Date__c = Date.today().addMonths(-1),
            End_Date__c = Date.today().addYears(1)
        );
        insert warranty;

        Map<String, Object> answers = new Map<String, Object>{
            'CLAIM_EMAIL' => contact.Email,
            'VERIFY_EMAIL_OTP' => '123456',
            'CLAIM_SERIAL_NUMBER' => asset.SerialNumber,
            'CONTACT_ID' => String.valueOf(account.Id),
            'ASSET_ID' => String.valueOf(asset.Id),
            'PRODUCT_ID' => String.valueOf(product.Id),
            'ASSET_WARRANTY_ID' => String.valueOf(warranty.Id)
        };

        SmartIntakeDTO.SaveFinalRequest request = new SmartIntakeDTO.SaveFinalRequest();
        request.templateKey = 'LAPTOP_WARRANTY_CLAIM';
        request.answersJson = JSON.serialize(answers);
        request.confirmed = true;
        request.consentAccepted = true;

        SmartIntakeDTO.IntakeResponse response = SmartIntakeService.saveFinal(request);

        System.assertEquals(false, response.success, JSON.serialize(response));
        System.assertEquals('SAVE', response.errorType, JSON.serialize(response));
        System.assertEquals('FINAL_SAVE_FAILED', response.errorCode, JSON.serialize(response));
        System.assertEquals(null, response.primaryRecordId, JSON.serialize(response));
    }

    @IsTest
    static void finalSaveLinksUploadedFilesFromMetadata() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeDTO.IntakeResponse saved;
        Id contentDocumentId;
        System.runAs(currentUser) {
            ContentVersion version = new ContentVersion(
                Title = 'Preference',
                PathOnClient = 'Preference.pdf',
                VersionData = Blob.valueOf('test file')
            );
            insert version;
            version = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :version.Id
                LIMIT 1
            ];
            contentDocumentId = version.ContentDocumentId;

            String fileAnswer = JSON.serialize(new List<Object>{
                new Map<String, Object>{
                    'name' => 'Preference.pdf',
                    'documentId' => String.valueOf(contentDocumentId)
                }
            });
            Map<String, Object> answers = new Map<String, Object>{
                'guest_name' => 'Sara Smith',
                'guest_email' => noMatchEmail(),
                'guest_email_match_status' => 'NO_MATCH',
                'guest_phone' => noMatchPhone(),
                'guest_phone_match_status' => 'NO_MATCH',
                'room_type' => 'Premium',
                'arrival_date' => futureArrivalDate(),
                'booking_note' => 'Late arrival',
                'booking_attachment' => fileAnswer
            };

            saved = SmartIntakeService.saveFinal(
                SmartIntakeTestDataFactory.finalSaveRequest(JSON.serialize(answers))
            );
        }

        System.assertEquals(true, saved.success, JSON.serialize(saved));
        System.assertNotEquals(null, saved.primaryRecordId);

        List<ContentDocumentLink> links = [
            SELECT Id, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
              AND LinkedEntityId = :saved.primaryRecordId
        ];
        System.assertEquals(1, links.size());
        System.assertEquals('V', links[0].ShareType);
        System.assertEquals('AllUsers', links[0].Visibility);
    }

    @IsTest
    static void additionalControlledErrorPathsAreCovered() {
        SmartIntakeDTO.IntakeResponse defaultTemplateResponse = SmartIntakeService.getNextQuestion(null);
        System.assertEquals(true, defaultTemplateResponse.success);
        System.assertNotEquals(null, defaultTemplateResponse.question.questionKey);

        SmartIntakeDTO.IntakeResponse nullSubmit = SmartIntakeService.submitAnswer(null);
        System.assertEquals(false, nullSubmit.success);
        System.assertEquals('MISSING_REQUEST', nullSubmit.errorCode);

        SmartIntakeDTO.IntakeResponse nullCurrentSubmit = SmartIntakeService.submitCurrentAnswer(null);
        System.assertEquals(false, nullCurrentSubmit.success);
        System.assertEquals('MISSING_REQUEST', nullCurrentSubmit.errorCode);

        SmartIntakeDTO.IntakeResponse nullBack = SmartIntakeService.goBack(null);
        System.assertEquals(false, nullBack.success);
        System.assertEquals('MISSING_REQUEST', nullBack.errorCode);

        SmartIntakeDTO.IntakeResponse nullSkip = SmartIntakeService.skipQuestion(null);
        System.assertEquals(false, nullSkip.success);
        System.assertEquals('MISSING_REQUEST', nullSkip.errorCode);

        SmartIntakeDTO.ValidateAnswerResponse nullValidate = SmartIntakeService.validateIntakeAnswer(null);
        System.assertEquals(false, nullValidate.success);
        System.assertEquals('MISSING_REQUEST', nullValidate.errorCode);

        SmartIntakeDTO.SubmitAnswerRequest badQuestion = SmartIntakeTestDataFactory.submitRequest(
            'not_real',
            'value',
            '{}'
        );
        SmartIntakeDTO.IntakeResponse badQuestionResponse = SmartIntakeService.submitAnswer(badQuestion);
        System.assertEquals(false, badQuestionResponse.success);
        System.assertEquals('QUESTION_NOT_FOUND', badQuestionResponse.errorCode);

        SmartIntakeDTO.SubmitAnswerRequest invalidJson = SmartIntakeTestDataFactory.submitRequest(
            'guest_name',
            'Sara Smith',
            '{not valid json'
        );
        SmartIntakeDTO.IntakeResponse invalidJsonResponse = SmartIntakeService.submitAnswer(invalidJson);
        System.assertEquals(false, invalidJsonResponse.success);
        System.assertEquals('INVALID_ANSWERS_JSON', invalidJsonResponse.errorCode);

        SmartIntakeDTO.IntakeResponse invalidOption = SmartIntakeService.submitAnswer(
            SmartIntakeTestDataFactory.submitRequest('room_type', 'Not a Room', '{"guest_name":"Sara Smith"}')
        );
        System.assertEquals(false, invalidOption.success);
        System.assertEquals('INVALID_OPTION', invalidOption.errorCode);

        SmartIntakeDTO.IntakeResponse invalidDate = SmartIntakeService.submitAnswer(
            SmartIntakeTestDataFactory.submitRequest(
                'arrival_date',
                'not-a-date',
                '{"guest_name":"Sara Smith","guest_email":"' + noMatchEmail() +
                    '","guest_email_match_status":"NO_MATCH","guest_phone":"' + noMatchPhone() +
                    '","guest_phone_match_status":"NO_MATCH","room_type":"Premium"}'
            )
        );
        System.assertEquals(false, invalidDate.success);
        System.assertEquals('INVALID_DATE', invalidDate.errorCode);

        SmartIntakeDTO.ValidateAnswerRequest invalidNumberRequest = new SmartIntakeDTO.ValidateAnswerRequest();
        invalidNumberRequest.templateKey = 'EVENT_FEEDBACK_FORM';
        invalidNumberRequest.questionKey = 'RATING';
        invalidNumberRequest.answerValue = 'not-a-number';
        invalidNumberRequest.answersJson = '{}';
        SmartIntakeDTO.ValidateAnswerResponse invalidNumber =
            SmartIntakeService.validateIntakeAnswer(invalidNumberRequest);
        System.assertEquals(false, invalidNumber.success, JSON.serialize(invalidNumber));
        System.assertEquals('INVALID_NUMBER', invalidNumber.errorCode, JSON.serialize(invalidNumber));

        SmartIntakeDTO.IntakeResponse invalidFileJson = SmartIntakeService.submitAnswer(
            SmartIntakeTestDataFactory.submitRequest(
                'booking_attachment',
                '{not valid json',
                '{"guest_name":"Sara Smith","guest_email":"' + noMatchEmail() +
                    '","guest_email_match_status":"NO_MATCH","guest_phone":"' + noMatchPhone() +
                    '","guest_phone_match_status":"NO_MATCH","room_type":"Premium","arrival_date":"' +
                    futureArrivalDate() + '","booking_note":"Late arrival"}'
            )
        );
        System.assertEquals(false, invalidFileJson.success);
        System.assertEquals('INVALID_FILE_ANSWER_JSON', invalidFileJson.errorCode);

        SmartIntakeDTO.GetNextQuestionRequest invalidSessionRequest = SmartIntakeTestDataFactory.getNextRequestWithSession('not-a-session-id');
        SmartIntakeDTO.IntakeResponse invalidSession = SmartIntakeService.getNextQuestion(invalidSessionRequest);
        System.assertEquals(false, invalidSession.success);
        System.assertEquals('INVALID_SESSION_ID', invalidSession.errorCode);

        SmartIntakeDTO.FindExistingRecordResponse nullFindExisting = SmartIntakeService.findExistingRecord(null);
        System.assertEquals(false, nullFindExisting.success);
        System.assertEquals('MISSING_REQUEST', nullFindExisting.errorCode);

        SmartIntakeDTO.ExistingContextResponse nullExistingContext = SmartIntakeService.getExistingContext(null);
        System.assertEquals(false, nullExistingContext.success);
        System.assertEquals('MISSING_REQUEST', nullExistingContext.errorCode);

        SmartIntakeDTO.IntakeResponse nullSave = SmartIntakeService.saveFinal(null);
        System.assertEquals(false, nullSave.success);
        System.assertEquals('MISSING_REQUEST', nullSave.errorCode);

        SmartIntakeDTO.SaveFinalRequest missingRequired = SmartIntakeTestDataFactory.finalSaveRequest(
            '{"booking_note":"Late arrival"}'
        );
        SmartIntakeDTO.IntakeResponse missingRequiredResponse = SmartIntakeService.saveFinal(missingRequired);
        System.assertEquals(false, missingRequiredResponse.success);
        System.assertEquals('REQUIRED_ANSWER_MISSING', missingRequiredResponse.errorCode);

        SmartIntakeMetadataService.conditionsForTests = new List<SmartIntake_Condition__mdt>{
            runtimeCondition('hide_validation_suite', 'room_type', 'suite_preference', 'HIDE_WHEN', 'EQUALS', 'Deluxe', 'hide_validation_suite', 'ALL', 1, null, null)
        };
        try {
            SmartIntakeDTO.ValidateAnswerRequest hiddenValidationRequest =
                SmartIntakeTestDataFactory.validateRequest('suite_preference', 'Quiet floor');
            hiddenValidationRequest.answersJson = '{"guest_name":"Sara Smith","guest_email":"' + noMatchEmail() +
                '","guest_email_match_status":"NO_MATCH","guest_phone":"' + noMatchPhone() +
                '","guest_phone_match_status":"NO_MATCH","room_type":"Deluxe"}';
            SmartIntakeDTO.ValidateAnswerResponse hiddenValidation =
                SmartIntakeService.validateIntakeAnswer(hiddenValidationRequest);
            System.assertEquals(false, hiddenValidation.success, JSON.serialize(hiddenValidation));
            System.assertEquals('QUESTION_NOT_VISIBLE', hiddenValidation.errorCode, JSON.serialize(hiddenValidation));
        } finally {
            SmartIntakeMetadataService.conditionsForTests = null;
        }

        System.assertEquals(
            'fallback',
            SmartIntakeMetadataService.message(SmartIntakeTestDataFactory.TEMPLATE_KEY, null, 'fallback')
        );
    }

    @IsTest
    static void securityServiceControlledBranchesAreCovered() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            try {
                SmartIntakeSecurityService.describeFieldForCreate('SmartIntake_Submission__c', 'Not_Real__c');
                System.assert(false, 'Expected field-not-found SmartIntakeException.');
            } catch (SmartIntakeException ex) {
                System.assertEquals('CONFIGURATION', ex.errorType);
                System.assertEquals('FIELD_NOT_FOUND', ex.errorCode);
            }

            Object nullValue = SmartIntakeSecurityService.coerceForCreate(
                'SmartIntake_Submission__c',
                'Primary_Text__c',
                null
            );
            System.assertEquals(null, nullValue);
        }
    }

    @IsTest
    static void invalidObjectIsControlledConfigurationError() {
        try {
            SmartIntakeSecurityService.describeObjectForCreate('Definitely_Not_Real__c');
            System.assert(false, 'Expected SmartIntakeException.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('CONFIGURATION', ex.errorType);
            System.assertEquals('OBJECT_NOT_FOUND', ex.errorCode);
        }
    }

    @IsTest
    static void runtimeResponseIncludesAgentforceContracts() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.GetNextQuestionRequest request = SmartIntakeTestDataFactory.getNextRequest();
            SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextQuestionAction.invoke(
                new List<SmartIntakeDTO.GetNextQuestionRequest>{
                    request
                }
            )[0];

            System.assertEquals(true, response.success);
            System.assertNotEquals(null, response.currentQuestion);
            System.assertEquals('guest_name', response.currentQuestion.questionKey);
            System.assertEquals('TEXT', response.currentQuestion.inputType);
            System.assertNotEquals(null, response.answerCaptureTemplate);
            System.assertEquals('guest_name', response.answerCaptureTemplate.questionKey);
        }
    }

    @IsTest
    static void answerCapturePlanMarksFutureVisibleQuestionsForAiExtraction() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextQuestionAction.invoke(
                new List<SmartIntakeDTO.GetNextQuestionRequest>{
                    SmartIntakeTestDataFactory.getNextRequest()
                }
            )[0];

            List<Object> plan = (List<Object>) JSON.deserializeUntyped(response.answerCapturePlanJson);
            Map<String, Object> entriesByKey = new Map<String, Object>();
            for (Object rawEntry : plan) {
                Map<String, Object> entry = (Map<String, Object>) rawEntry;
                entriesByKey.put(String.valueOf(entry.get('questionKey')), entry);
            }

            Map<String, Object> currentEntry = (Map<String, Object>) entriesByKey.get('guest_name');
            Map<String, Object> futureEntry = (Map<String, Object>) entriesByKey.get('guest_email');
            System.assertEquals(true, currentEntry.get('isCurrent'));
            System.assertEquals(true, currentEntry.get('captureAllowedFromLatestMessage'));
            System.assertEquals(false, futureEntry.get('isCurrent'));
            System.assertEquals(true, futureEntry.get('captureAllowedFromLatestMessage'));
            System.assert(String.valueOf(futureEntry.get('captureInstruction')).contains('proposedAnswersJson'));

            SmartIntakeDTO.IntakeResponse answered = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{
                    SmartIntakeTestDataFactory.submitCurrentRequestWithSession(
                        response.intakeSessionId,
                        'Sara Smith',
                        response.answersJson
                    )
                }
            )[0];
            List<Object> answeredPlan = (List<Object>) JSON.deserializeUntyped(answered.answerCapturePlanJson);
            for (Object rawEntry : answeredPlan) {
                Map<String, Object> entry = (Map<String, Object>) rawEntry;
                if (String.valueOf(entry.get('questionKey')) == 'guest_name') {
                    System.assertEquals(true, entry.get('isAnswered'));
                    System.assertEquals(false, entry.get('captureAllowedFromLatestMessage'));
                }
            }
        }
    }

    @IsTest
    static void contextResolutionSupportsUrlsSessionsAndInvalidJsonErrors() {
        SmartIntakeGetNextByContextAction.Request urlContextRequest =
            new SmartIntakeGetNextByContextAction.Request();
        urlContextRequest.smartIntakeContextKey = 'https://example.test/s/feedback/';
        urlContextRequest.answersJson = '{}';

        SmartIntakeDTO.IntakeResponse urlContextResponse = SmartIntakeGetNextByContextAction.invoke(
            new List<SmartIntakeGetNextByContextAction.Request>{ urlContextRequest }
        )[0];
        System.assertEquals(true, urlContextResponse.success, JSON.serialize(urlContextResponse));
        System.assertEquals('EVENT_FEEDBACK_FORM', urlContextResponse.templateKey);

        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            SmartIntakeDTO.GetNextQuestionRequest invalidSessionRequest = SmartIntakeTestDataFactory.getNextRequest();
            invalidSessionRequest.intakeSessionId = 'not-a-smartintake-session';
            SmartIntakeDTO.IntakeResponse invalidSession = SmartIntakeService.getNextQuestion(invalidSessionRequest);
            System.assertEquals(false, invalidSession.success);
            System.assertEquals('INVALID_SESSION_ID', invalidSession.errorCode);

            SmartIntakeDTO.SubmitAnswerRequest invalidJsonRequest =
                SmartIntakeTestDataFactory.submitRequest('guest_name', 'Sara Smith', '{bad json');
            SmartIntakeDTO.IntakeResponse invalidJson = SmartIntakeService.submitAnswer(invalidJsonRequest);
            System.assertEquals(false, invalidJson.success);
            System.assertEquals('INVALID_ANSWERS_JSON', invalidJson.errorCode);
        }
    }

    @IsTest
    static void controlledErrorBranchesReturnSpecificMessages() {
        SmartIntakeDTO.SubmitAnswerRequest missingSubmitRequest = new SmartIntakeDTO.SubmitAnswerRequest();
        missingSubmitRequest.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        missingSubmitRequest.questionKey = 'missing_question';
        missingSubmitRequest.answerValue = 'value';
        missingSubmitRequest.answersJson = '{}';
        SmartIntakeDTO.IntakeResponse missingQuestion = SmartIntakeService.submitAnswer(missingSubmitRequest);
        System.assertEquals(false, missingQuestion.success);
        System.assertEquals('QUESTION_NOT_FOUND', missingQuestion.errorCode);

        SmartIntakeDTO.NavigateRequest missingSkipKey = new SmartIntakeDTO.NavigateRequest();
        missingSkipKey.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        SmartIntakeDTO.IntakeResponse missingSkipKeyResponse = SmartIntakeService.skipQuestion(missingSkipKey);
        System.assertEquals(false, missingSkipKeyResponse.success);
        System.assertEquals('MISSING_QUESTION_KEY', missingSkipKeyResponse.errorCode);

        SmartIntakeDTO.NavigateRequest missingSkipQuestion = SmartIntakeTestDataFactory.navigateRequest(
            'SI-abcdefabcdefabcdefabcdefabcdefab',
            'missing_question',
            '{}'
        );
        SmartIntakeDTO.IntakeResponse missingSkipQuestionResponse = SmartIntakeService.skipQuestion(missingSkipQuestion);
        System.assertEquals(false, missingSkipQuestionResponse.success);
        System.assertEquals('QUESTION_NOT_FOUND', missingSkipQuestionResponse.errorCode);

        SmartIntakeDTO.NavigateRequest firstQuestionBack = SmartIntakeTestDataFactory.navigateRequest(
            'SI-abcdefabcdefabcdefabcdefabcdefac',
            'guest_name',
            '{}'
        );
        SmartIntakeDTO.IntakeResponse backUnavailable = SmartIntakeService.goBack(firstQuestionBack);
        System.assertEquals(false, backUnavailable.success);
        System.assertEquals('BACK_NOT_AVAILABLE', backUnavailable.errorCode);

        SmartIntakeDTO.ValidateAnswerRequest missingValidationKey = new SmartIntakeDTO.ValidateAnswerRequest();
        missingValidationKey.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        missingValidationKey.answerValue = 'value';
        SmartIntakeDTO.ValidateAnswerResponse missingValidationKeyResponse =
            SmartIntakeService.validateIntakeAnswer(missingValidationKey);
        System.assertEquals(false, missingValidationKeyResponse.success);
        System.assertEquals('MISSING_QUESTION_KEY', missingValidationKeyResponse.errorCode);

        SmartIntakeDTO.ValidateAnswerRequest missingValidationQuestion =
            SmartIntakeTestDataFactory.validateRequest('missing_question', 'value');
        SmartIntakeDTO.ValidateAnswerResponse missingValidationQuestionResponse =
            SmartIntakeService.validateIntakeAnswer(missingValidationQuestion);
        System.assertEquals(false, missingValidationQuestionResponse.success);
        System.assertEquals('QUESTION_NOT_FOUND', missingValidationQuestionResponse.errorCode);

        SmartIntakeDTO.FindExistingRecordResponse missingMatchInput =
            SmartIntakeService.findExistingRecord(SmartIntakeTestDataFactory.findExistingRequest('', ''));
        System.assertEquals(false, missingMatchInput.success);
        System.assertEquals('MISSING_MATCH_INPUT', missingMatchInput.errorCode);

        SmartIntakeDTO.GetExistingContextRequest missingContextQuestion =
            new SmartIntakeDTO.GetExistingContextRequest();
        missingContextQuestion.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        SmartIntakeDTO.ExistingContextResponse missingContextQuestionResponse =
            SmartIntakeService.getExistingContext(missingContextQuestion);
        System.assertEquals(false, missingContextQuestionResponse.success);
        System.assertEquals('MISSING_QUESTION_KEY', missingContextQuestionResponse.errorCode);
    }

    @IsTest
    static void contextOnlyGetNextActionResolvesFeedbackWithoutTemplateInput() {
        SmartIntakeGetNextByContextAction.Request request =
            new SmartIntakeGetNextByContextAction.Request();
        request.smartIntakeContextKey = 'feedback';
        request.answersJson = '{}';

        SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextByContextAction.invoke(
            new List<SmartIntakeGetNextByContextAction.Request>{ request }
        )[0];

        System.assertEquals(true, response.success, JSON.serialize(response));
        System.assertEquals('EVENT_FEEDBACK_FORM', response.templateKey);
        System.assertEquals('RATING', response.question.questionKey);

        Apex_Debug_Log__c routeLog = [
            SELECT Severity__c, Error_Code__c, Template_Key__c, Question_Key__c, Context_JSON__c
            FROM Apex_Debug_Log__c
            WHERE Error_Code__c = 'SMARTINTAKE_ROUTE_DIAGNOSTIC'
              AND Template_Key__c = 'EVENT_FEEDBACK_FORM'
              AND Question_Key__c = 'RATING'
            LIMIT 1
        ];
        System.assertEquals('INFO', routeLog.Severity__c);
        System.assert(routeLog.Context_JSON__c.contains('"requestedContextKey":"feedback"'), routeLog.Context_JSON__c);
        System.assert(routeLog.Context_JSON__c.contains('"effectiveContextKey":"feedback"'), routeLog.Context_JSON__c);
    }

    @IsTest
    static void contextRouteOverridesStaleTemplateKey() {
        SmartIntakeGetNextByContextAction.Request request =
            new SmartIntakeGetNextByContextAction.Request();
        request.smartIntakeContextKey = 'feedback';
        request.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        request.answersJson = '{"guest_name":"Sara Smith","__smartIntakeRouteTemplateKey":"' +
            SmartIntakeTestDataFactory.TEMPLATE_KEY + '"}';

        SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextByContextAction.invoke(
            new List<SmartIntakeGetNextByContextAction.Request>{ request }
        )[0];

        System.assertEquals(true, response.success, JSON.serialize(response));
        System.assertEquals('EVENT_FEEDBACK_FORM', response.templateKey);
        System.assertEquals('RATING', response.question.questionKey);
        System.assert(!response.answersJson.contains('guest_name'), response.answersJson);
    }

    @IsTest
    static void routablePageRouteOverridesStaleBookingContext() {
        String routableId = '0Mw000000000001AAA';
        SmartIntakeService.messagingSessionContextByRoutableIdForTest.put(routableId, 'feedback');

        try {
            SmartIntakeGetNextByContextAction.Request request =
                new SmartIntakeGetNextByContextAction.Request();
            request.routableId = routableId;
            request.smartIntakeContextKey = 'HOTEL_BOOKING_PAGE';
            request.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
            request.answersJson = '{"guest_name":"Sara Smith","__smartIntakeRouteContextKey":"HOTEL_BOOKING_PAGE","__smartIntakeRouteTemplateKey":"' +
                SmartIntakeTestDataFactory.TEMPLATE_KEY + '"}';

            SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextByContextAction.invoke(
                new List<SmartIntakeGetNextByContextAction.Request>{ request }
            )[0];

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals('EVENT_FEEDBACK_FORM', response.templateKey);
            System.assertEquals('RATING', response.question.questionKey);
            System.assert(!response.answersJson.contains('guest_name'), response.answersJson);
        } finally {
            SmartIntakeService.messagingSessionContextByRoutableIdForTest.clear();
        }
    }

    @IsTest
    static void blankLiveSiteInputsUseRecentMessagingSessionContextFallback() {
        SmartIntakeService.recentMessagingSessionContextKeyForTest = 'feedback';

        try {
            SmartIntakeGetNextByContextAction.Request request =
                new SmartIntakeGetNextByContextAction.Request();
            request.answersJson = '{}';

            SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextByContextAction.invoke(
                new List<SmartIntakeGetNextByContextAction.Request>{ request }
            )[0];

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals('EVENT_FEEDBACK_FORM', response.templateKey);
            System.assertEquals('RATING', response.question.questionKey);

            Apex_Debug_Log__c routeLog = [
                SELECT Template_Key__c, Question_Key__c, Context_JSON__c
                FROM Apex_Debug_Log__c
                WHERE Error_Code__c = 'SMARTINTAKE_ROUTE_DIAGNOSTIC'
                  AND Template_Key__c = 'EVENT_FEEDBACK_FORM'
                  AND Question_Key__c = 'RATING'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            System.assert(routeLog.Context_JSON__c.contains('"requestedContextKey":null'), routeLog.Context_JSON__c);
            System.assert(routeLog.Context_JSON__c.contains('"effectiveContextKey":"feedback"'), routeLog.Context_JSON__c);
        } finally {
            SmartIntakeService.recentMessagingSessionContextKeyForTest = null;
        }
    }

    @IsTest
    static void savedRouteContextWinsBeforeGlobalRecentMessagingFallback() {
        SmartIntakeService.recentMessagingSessionContextKeyForTest = 'feedback';

        try {
            SmartIntakeGetNextByContextAction.Request request =
                new SmartIntakeGetNextByContextAction.Request();
            request.answersJson = '{"guest_name":"Sara Smith","__smartIntakeRouteContextKey":"HOTEL_BOOKING_PAGE","__smartIntakeRouteTemplateKey":"' +
                SmartIntakeTestDataFactory.TEMPLATE_KEY + '"}';

            SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextByContextAction.invoke(
                new List<SmartIntakeGetNextByContextAction.Request>{ request }
            )[0];

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals(SmartIntakeTestDataFactory.TEMPLATE_KEY, response.templateKey);
        } finally {
            SmartIntakeService.recentMessagingSessionContextKeyForTest = null;
        }
    }

    @IsTest
    static void blankRoutableContextDoesNotUseRecentMessagingFallback() {
        String routableId = '0Mw000000000003AAA';
        SmartIntakeService.messagingSessionContextByRoutableIdForTest.put(routableId, '');
        SmartIntakeService.recentMessagingSessionContextKeyForTest = 'feedback';

        try {
            SmartIntakeGetNextByContextAction.Request request =
                new SmartIntakeGetNextByContextAction.Request();
            request.routableId = routableId;
            request.answersJson = '{}';

            SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextByContextAction.invoke(
                new List<SmartIntakeGetNextByContextAction.Request>{ request }
            )[0];

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals(SmartIntakeTestDataFactory.TEMPLATE_KEY, response.templateKey);
        } finally {
            SmartIntakeService.messagingSessionContextByRoutableIdForTest.clear();
            SmartIntakeService.recentMessagingSessionContextKeyForTest = null;
        }
    }

    @IsTest
    static void submitByRoutableRouteOverridesStaleBookingContext() {
        String routableId = '0Mw000000000002AAA';
        SmartIntakeService.messagingSessionContextByRoutableIdForTest.put(routableId, 'feedback');

        try {
            SmartIntakeSubmitByContextAction.Request request =
                new SmartIntakeSubmitByContextAction.Request();
            request.routableId = routableId;
            request.smartIntakeContextKey = 'HOTEL_BOOKING_PAGE';
            request.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
            request.answerValue = 'start feedback';
            request.answersJson = '{"guest_name":"Sara Smith","__smartIntakeRouteContextKey":"HOTEL_BOOKING_PAGE","__smartIntakeRouteTemplateKey":"' +
                SmartIntakeTestDataFactory.TEMPLATE_KEY + '"}';

            SmartIntakeDTO.IntakeResponse response = SmartIntakeSubmitByContextAction.invoke(
                new List<SmartIntakeSubmitByContextAction.Request>{ request }
            )[0];

            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assertEquals('EVENT_FEEDBACK_FORM', response.templateKey);
            System.assertEquals('RATING', response.question.questionKey);
            System.assert(!response.answersJson.contains('guest_name'), response.answersJson);
        } finally {
            SmartIntakeService.messagingSessionContextByRoutableIdForTest.clear();
        }
    }

    @IsTest
    static void getNextUsesDefaultRouteWhenNoContextIsProvided() {
        SmartIntakeDTO.IntakeResponse response = SmartIntakeService.getNextQuestion(null);

        System.assertEquals(true, response.success, JSON.serialize(response));
        System.assertEquals(SmartIntakeTestDataFactory.TEMPLATE_KEY, response.templateKey);
        System.assertEquals('guest_name', response.question.questionKey);
    }

    @IsTest
    static void unknownRouteKeyDoesNotFallBackToDefaultRoute() {
        SmartIntakeGetNextByContextAction.Request request =
            new SmartIntakeGetNextByContextAction.Request();
        request.smartIntakeContextKey = 'missing-feedback-route';
        request.answersJson = '{}';

        SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextByContextAction.invoke(
            new List<SmartIntakeGetNextByContextAction.Request>{ request }
        )[0];

        System.assertEquals(false, response.success, JSON.serialize(response));
        System.assertEquals('CONFIGURATION', response.errorType);
        System.assertEquals('ROUTE_NOT_CONFIGURED', response.errorCode);
        System.assertNotEquals(SmartIntakeTestDataFactory.TEMPLATE_KEY, response.templateKey);
    }

    @IsTest
    static void contextOnlyGetNextActionResolvesWhatsappChannelRoute() {
        SmartIntakeGetNextByContextAction.Request request =
            new SmartIntakeGetNextByContextAction.Request();
        request.smartIntakeContextKey = 'WHATSAPP_US_1211546385366494';
        request.answersJson = '{}';

        SmartIntakeDTO.IntakeResponse response = SmartIntakeGetNextByContextAction.invoke(
            new List<SmartIntakeGetNextByContextAction.Request>{ request }
        )[0];

        System.assertEquals(true, response.success, JSON.serialize(response));
        System.assertEquals('EVENT_FEEDBACK_FORM', response.templateKey);
        System.assertEquals('RATING', response.question.questionKey);
    }

    @IsTest
    static void contextOnlyFeedbackSaveDoesNotNeedTemplateKeyInput() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeSaveByContextAction.Request saveRequest = new SmartIntakeSaveByContextAction.Request();
            saveRequest.smartIntakeContextKey = 'feedback';
            saveRequest.answersJson = '{"RATING":"4","SATISFACTION_RATING":"4","OPINION_SNAPSHOT":"Great event"}';
            saveRequest.confirmed = true;
            saveRequest.consentAccepted = true;

            SmartIntakeDTO.IntakeResponse saved = SmartIntakeSaveByContextAction.invoke(
                new List<SmartIntakeSaveByContextAction.Request>{ saveRequest }
            )[0];

            System.assertEquals(true, saved.success, JSON.serialize(saved));
            System.assertEquals('EVENT_FEEDBACK_FORM', saved.templateKey);
            System.assertNotEquals(null, saved.primaryRecordId);
        }
    }

    @IsTest
    static void saveByRoutableRouteOverridesStaleBookingContext() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String routableId = '0Mw000000000003AAA';
        SmartIntakeService.messagingSessionContextByRoutableIdForTest.put(routableId, 'feedback');

        try {
            System.runAs(currentUser) {
                SmartIntakeSaveByContextAction.Request saveRequest =
                    new SmartIntakeSaveByContextAction.Request();
                saveRequest.routableId = routableId;
                saveRequest.smartIntakeContextKey = 'HOTEL_BOOKING_PAGE';
                saveRequest.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
                saveRequest.answersJson = '{"RATING":"4","SATISFACTION_RATING":"4","OPINION_SNAPSHOT":"Routed feedback"}';
                saveRequest.confirmed = true;
                saveRequest.consentAccepted = true;

                SmartIntakeDTO.IntakeResponse saved = SmartIntakeSaveByContextAction.invoke(
                    new List<SmartIntakeSaveByContextAction.Request>{ saveRequest }
                )[0];

                System.assertEquals(true, saved.success, JSON.serialize(saved));
                System.assertEquals('EVENT_FEEDBACK_FORM', saved.templateKey);
                System.assertNotEquals(null, saved.primaryRecordId);
            }
        } finally {
            SmartIntakeService.messagingSessionContextByRoutableIdForTest.clear();
        }
    }

    @IsTest
    static void legacyFeedbackRouteInTemplateSlotStillSaves() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeSaveByContextAction.Request saveRequest = new SmartIntakeSaveByContextAction.Request();
            saveRequest.templateKey = 'feedback';
            saveRequest.answersJson = '{"RATING":"4","SATISFACTION_RATING":"4","OPINION_SNAPSHOT":"Great event"}';
            saveRequest.confirmed = true;
            saveRequest.consentAccepted = true;

            SmartIntakeDTO.IntakeResponse saved = SmartIntakeSaveByContextAction.invoke(
                new List<SmartIntakeSaveByContextAction.Request>{ saveRequest }
            )[0];

            System.assertEquals(true, saved.success, JSON.serialize(saved));
            System.assertEquals('EVENT_FEEDBACK_FORM', saved.templateKey);
            System.assertNotEquals(null, saved.primaryRecordId);
        }
    }

    @IsTest
    static void saveByContextResolvesSessionIdWhenAgentPutsItInTemplateSlot() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            String sessionId = 'SI-0123456789abcdef0123456789abcdef';
            insert new SmartIntake_Session__c(
                Session_Id__c = sessionId,
                Template_Key__c = 'EVENT_FEEDBACK_FORM',
                Answers_JSON__c = '{"RATING":"5","SATISFACTION_RATING":"5","OPINION_SNAPSHOT":"Helpful"}',
                Current_Question_Key__c = null,
                Question_History_JSON__c = '[]',
                Skipped_Question_Keys_JSON__c = '[]',
                Status__c = 'In Progress',
                Last_Activity_Date__c = System.now()
            );

            SmartIntakeSaveByContextAction.Request saveRequest =
                new SmartIntakeSaveByContextAction.Request();
            saveRequest.intakeSessionId = sessionId;
            saveRequest.templateKey = sessionId;
            saveRequest.answersJson = '{}';
            saveRequest.confirmed = true;
            saveRequest.consentAccepted = true;

            SmartIntakeDTO.IntakeResponse saved = SmartIntakeSaveByContextAction.invoke(
                new List<SmartIntakeSaveByContextAction.Request>{ saveRequest }
            )[0];

            System.assertEquals(true, saved.success, JSON.serialize(saved));
            System.assertEquals('EVENT_FEEDBACK_FORM', saved.templateKey);
            System.assertNotEquals(null, saved.primaryRecordId);
        }
    }

    @IsTest
    static void contextOnlyAgentActionsDoNotNeedTemplateKeyInput() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeSubmitByContextAction.Request submitRequest = new SmartIntakeSubmitByContextAction.Request();
            submitRequest.smartIntakeContextKey = 'HOTEL_BOOKING_PAGE';
            submitRequest.answerValue = 'Start';

            SmartIntakeDTO.IntakeResponse started = SmartIntakeSubmitByContextAction.invoke(
                new List<SmartIntakeSubmitByContextAction.Request>{ submitRequest }
            )[0];
            System.assertEquals(true, started.success, JSON.serialize(started));

            SmartIntakeSaveByContextAction.Request saveRequest = new SmartIntakeSaveByContextAction.Request();
            saveRequest.smartIntakeContextKey = 'HOTEL_BOOKING_PAGE';
            saveRequest.answersJson = completeHotelAnswersJson();
            saveRequest.confirmed = true;
            saveRequest.consentAccepted = true;

            SmartIntakeDTO.IntakeResponse saved = SmartIntakeSaveByContextAction.invoke(
                new List<SmartIntakeSaveByContextAction.Request>{ saveRequest }
            )[0];
            System.assertEquals(true, saved.success, JSON.serialize(saved));
            System.assertNotEquals(null, saved.primaryRecordId);

            SmartIntakeHandoffByContextAction.Request handoffRequest = new SmartIntakeHandoffByContextAction.Request();
            handoffRequest.smartIntakeContextKey = 'HOTEL_BOOKING_PAGE';
            handoffRequest.consentAccepted = true;

            SmartIntakeDTO.HandoffPlanResponse handoff = SmartIntakeHandoffByContextAction.invoke(
                new List<SmartIntakeHandoffByContextAction.Request>{ handoffRequest }
            )[0];
            System.assertEquals(true, handoff.success, JSON.serialize(handoff));
        }
    }

    @IsTest
    static void submitCurrentAnswerPrefersAnswerCaptureValue() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.SubmitCurrentAnswerRequest startRequest =
                SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession('clt-session-1', 'Start intake');
            SmartIntakeDTO.IntakeResponse started = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{ startRequest }
            )[0];
            System.assertEquals('guest_name', started.question.questionKey);

            SmartIntakeDTO.SubmitCurrentAnswerRequest answerRequest =
                SmartIntakeTestDataFactory.submitCurrentRequestWithAgentSession('clt-session-1', 'ignored chat text');
            answerRequest.intakeSessionId = started.intakeSessionId;
            answerRequest.answerCapture = started.answerCaptureTemplate;
            answerRequest.answerCapture.answerValue = 'Jordan Lee';

            SmartIntakeDTO.IntakeResponse answered = SmartIntakeSubmitCurrentAnswerAction.invoke(
                new List<SmartIntakeDTO.SubmitCurrentAnswerRequest>{ answerRequest }
            )[0];

            System.assertEquals(true, answered.success);
            System.assertEquals('guest_email', answered.question.questionKey);
            System.assert(answered.answersJson.contains('Jordan Lee'), answered.answersJson);
            System.assert(!answered.answersJson.contains('ignored chat text'), answered.answersJson);
        }
    }

    @IsTest
    static void warrantySubmitCurrentAcceptsAiProposedAnswerMapInOrder() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeHookService.setExecutorForTest(new FakeWarrantyHookExecutor());
        try {
            System.runAs(currentUser) {
                String agentSessionKey = 'warranty-prefill-session-1';

                SmartIntakeDTO.SubmitCurrentAnswerRequest startRequest = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                startRequest.agentSessionKey = agentSessionKey;
                startRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                startRequest.answerValue = 'I want to claim warranty';

                SmartIntakeDTO.IntakeResponse started = SmartIntakeService.submitCurrentAnswer(startRequest);
                System.assertEquals(true, started.success, JSON.serialize(started));
                System.assertEquals('CLAIM_EMAIL', started.question.questionKey);

                SmartIntakeDTO.SubmitCurrentAnswerRequest emailRequest = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                emailRequest.agentSessionKey = agentSessionKey;
                emailRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                emailRequest.proposedAnswersJson = JSON.serialize(new Map<String, Object>{
                    'CLAIM_EMAIL' => 'sivachandran2256@gmail.com',
                    'CLAIM_SERIAL_NUMBER' => 'LT-PRO15-1001',
                    'email' => 'sivachandran2256@gmail.com',
                    'product_id' => 'LT-PRO15-1001'
                });

                SmartIntakeDTO.IntakeResponse emailConfirmation = SmartIntakeService.submitCurrentAnswer(emailRequest);
                System.assertEquals(true, emailConfirmation.success, JSON.serialize(emailConfirmation));
                System.assertEquals('CLAIM_EMAIL', emailConfirmation.question.questionKey, JSON.serialize(emailConfirmation));
                System.assertEquals('RADIO', emailConfirmation.question.inputType, JSON.serialize(emailConfirmation));
                System.assertEquals(2, emailConfirmation.question.options.size(), JSON.serialize(emailConfirmation));
                System.assertEquals(
                    'I found an answer for "Please enter the email address used to register your product." in your message: sivachandran2256@gmail.com. Do you want to use it?',
                    emailConfirmation.question.questionText,
                    JSON.serialize(emailConfirmation)
                );
                System.assertEquals(null, emailConfirmation.question.helpText, JSON.serialize(emailConfirmation));
                System.assertEquals(null, emailConfirmation.question.placeholderText, JSON.serialize(emailConfirmation));
                System.assertNotEquals(null, emailConfirmation.question, JSON.serialize(emailConfirmation));
                System.assertNotEquals(null, emailConfirmation.currentQuestion, JSON.serialize(emailConfirmation));
                System.assertEquals(emailConfirmation.question.questionText, emailConfirmation.currentQuestion.questionText, JSON.serialize(emailConfirmation));
                System.assertNotEquals(null, emailConfirmation.answerCaptureTemplate, JSON.serialize(emailConfirmation));
                System.assertEquals(null, emailConfirmation.userMessage, JSON.serialize(emailConfirmation));
                System.assertEquals('Yes', emailConfirmation.question.options[0].label, JSON.serialize(emailConfirmation));
                System.assertEquals('No, change it', emailConfirmation.question.options[1].label, JSON.serialize(emailConfirmation));

                Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(emailConfirmation.answersJson);
                System.assertEquals(null, answers.get('CLAIM_EMAIL'), 'Email should wait for user confirmation.');
                System.assertEquals(null, answers.get('CLAIM_SERIAL_NUMBER'), 'Serial should wait until metadata reaches that question.');
                System.assertEquals(null, answers.get('email'), 'Only configured metadata keys should be stored.');
                System.assertEquals(null, answers.get('product_id'), 'Only configured metadata keys should be stored.');
                System.assert(emailConfirmation.answersJson.contains('__smartIntakePendingAnswers'), emailConfirmation.answersJson);
                System.assert(emailConfirmation.answersJson.contains('__smartIntakePendingExtractedAnswerConfirmation'), emailConfirmation.answersJson);
                Map<String, Object> stagedAnswers = (Map<String, Object>) answers.get('__smartIntakePendingAnswers');
                System.assertEquals('LT-PRO15-1001', String.valueOf(stagedAnswers.get('CLAIM_SERIAL_NUMBER')));

                SmartIntakeDTO.SubmitCurrentAnswerRequest useEmailRequest = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                useEmailRequest.agentSessionKey = agentSessionKey;
                useEmailRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                useEmailRequest.answerValue = 'yes';

                SmartIntakeDTO.IntakeResponse otpQuestion = SmartIntakeService.submitCurrentAnswer(useEmailRequest);
                System.assertEquals(true, otpQuestion.success, JSON.serialize(otpQuestion));
                System.assertEquals('VERIFY_EMAIL_OTP', otpQuestion.question.questionKey, JSON.serialize(otpQuestion));
                Map<String, Object> emailConfirmedAnswers = (Map<String, Object>) JSON.deserializeUntyped(otpQuestion.answersJson);
                System.assertEquals('sivachandran2256@gmail.com', String.valueOf(emailConfirmedAnswers.get('CLAIM_EMAIL')));

                SmartIntakeDTO.SubmitCurrentAnswerRequest otpRequest = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                otpRequest.agentSessionKey = agentSessionKey;
                otpRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                otpRequest.proposedAnswersJson = JSON.serialize(new Map<String, Object>{
                    'VERIFY_EMAIL_OTP' => '478424'
                });

                SmartIntakeDTO.IntakeResponse serialConfirmation = SmartIntakeService.submitCurrentAnswer(otpRequest);
                System.assertEquals(true, serialConfirmation.success, JSON.serialize(serialConfirmation));
                System.assertEquals('CLAIM_SERIAL_NUMBER', serialConfirmation.question.questionKey, JSON.serialize(serialConfirmation));
                System.assertEquals(null, serialConfirmation.userMessage, JSON.serialize(serialConfirmation));
                System.assert(!serialConfirmation.question.questionText.contains('Email verified.'), JSON.serialize(serialConfirmation));
                System.assert(serialConfirmation.question.helpText.contains('Email verified.'), JSON.serialize(serialConfirmation));
                System.assertEquals('CUSTOM_LWC', serialConfirmation.rendererMode, JSON.serialize(serialConfirmation));
                System.assertEquals(true, serialConfirmation.question.renderLightningInput, JSON.serialize(serialConfirmation));
                System.assertEquals('c/smartIntakeProductSelector', serialConfirmation.question.uiControl, JSON.serialize(serialConfirmation));
                System.assertEquals('LT-PRO15-1001', serialConfirmation.question.value, JSON.serialize(serialConfirmation));
                System.assertNotEquals(null, serialConfirmation.currentQuestion, JSON.serialize(serialConfirmation));
                System.assert(serialConfirmation.currentQuestion.helpText.contains('Email verified.'), JSON.serialize(serialConfirmation.currentQuestion));
                System.assertNotEquals(null, serialConfirmation.currentQuestion.options, JSON.serialize(serialConfirmation.currentQuestion));
                System.assertEquals('[]', serialConfirmation.currentQuestion.optionsJson, JSON.serialize(serialConfirmation.currentQuestion));
                System.assertNotEquals(null, serialConfirmation.currentQuestion.acceptedFormats, JSON.serialize(serialConfirmation.currentQuestion));
                System.assertEquals('[]', serialConfirmation.currentQuestion.acceptedFormatsJson, JSON.serialize(serialConfirmation.currentQuestion));
                System.assertNotEquals(null, serialConfirmation.questionJson, JSON.serialize(serialConfirmation));
                System.assertEquals(serialConfirmation.question.questionText, serialConfirmation.currentQuestion.questionText, JSON.serialize(serialConfirmation));
                System.assertEquals('c/smartIntakeProductSelector', serialConfirmation.currentQuestion.uiControl, JSON.serialize(serialConfirmation));
                System.assertNotEquals(null, serialConfirmation.answerCaptureTemplate, JSON.serialize(serialConfirmation));
                System.assertEquals(null, serialConfirmation.answerCaptureTemplate.questionText, JSON.serialize(serialConfirmation));
                System.assertEquals('[]', serialConfirmation.answerCaptureTemplate.optionsJson, JSON.serialize(serialConfirmation.answerCaptureTemplate));
                System.assertEquals('[]', serialConfirmation.answerCaptureTemplate.acceptedFormatsJson, JSON.serialize(serialConfirmation.answerCaptureTemplate));
                System.assertNotEquals(null, serialConfirmation.answerCapturePlanJson, JSON.serialize(serialConfirmation));
                Map<String, Object> serialPendingAnswers = (Map<String, Object>) JSON.deserializeUntyped(serialConfirmation.answersJson);
                System.assertEquals(null, serialPendingAnswers.get('CLAIM_SERIAL_NUMBER'), 'Serial should wait for confirmation.');
                Map<String, Object> stagedSerialAfterOtp =
                    (Map<String, Object>) serialPendingAnswers.get('__smartIntakePendingAnswers');
                System.assertEquals('LT-PRO15-1001', String.valueOf(stagedSerialAfterOtp.get('CLAIM_SERIAL_NUMBER')));

                SmartIntakeDTO.SubmitCurrentAnswerRequest useSerialRequest = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                useSerialRequest.agentSessionKey = agentSessionKey;
                useSerialRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                useSerialRequest.answerValue = '__SMARTINTAKE_USE_PENDING_ANSWER__';
                useSerialRequest.proposedAnswersJson = JSON.serialize(new Map<String, Object>{
                    'CLAIM_SERIAL_NUMBER' => 'LT-PRO15-1001'
                });

                SmartIntakeDTO.IntakeResponse confirmation = SmartIntakeService.submitCurrentAnswer(useSerialRequest);
                System.assertEquals(true, confirmation.success, JSON.serialize(confirmation));
                System.assertEquals(true, confirmation.isComplete, JSON.serialize(confirmation));
                System.assertEquals(null, confirmation.question, JSON.serialize(confirmation));
                System.assertNotEquals(null, confirmation.currentQuestion, JSON.serialize(confirmation));
                System.assertEquals('__FINAL_CONFIRMATION__', confirmation.currentQuestion.questionKey);
                Map<String, Object> confirmedAnswers = (Map<String, Object>) JSON.deserializeUntyped(confirmation.answersJson);
                System.assertEquals('LT-PRO15-1001', String.valueOf(confirmedAnswers.get('CLAIM_SERIAL_NUMBER')));
                System.assertEquals(null, confirmedAnswers.get('__smartIntakePendingExtractedAnswerConfirmation'));
                System.assertEquals(null, confirmedAnswers.get('__smartIntakePendingAnswers'));
                System.assertEquals(null, confirmedAnswers.get('email'), 'Only configured metadata keys should be stored.');
                System.assertEquals(null, confirmedAnswers.get('product_id'), 'Only configured metadata keys should be stored.');
            }
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void warrantyExtractedAnswerConfirmationWorksWithDirectSubmit() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeHookService.setExecutorForTest(new FakeWarrantyHookExecutor());
        try {
            System.runAs(currentUser) {
                SmartIntakeDTO.GetNextQuestionRequest startRequest = new SmartIntakeDTO.GetNextQuestionRequest();
                startRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                SmartIntakeDTO.IntakeResponse started = SmartIntakeService.getNextQuestion(startRequest);
                System.assertEquals(true, started.success, JSON.serialize(started));
                System.assertEquals('CLAIM_EMAIL', started.question.questionKey, JSON.serialize(started));

                SmartIntakeDTO.SubmitAnswerRequest proposeEmail = new SmartIntakeDTO.SubmitAnswerRequest();
                proposeEmail.intakeSessionId = started.intakeSessionId;
                proposeEmail.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                proposeEmail.questionKey = 'CLAIM_EMAIL';
                proposeEmail.proposedAnswersJson = JSON.serialize(new Map<String, Object>{
                    'CLAIM_EMAIL' => 'sivachandran2256@gmail.com'
                });
                proposeEmail.answersJson = started.answersJson;

                SmartIntakeDTO.IntakeResponse confirmation = SmartIntakeService.submitAnswer(proposeEmail);
                System.assertEquals(true, confirmation.success, JSON.serialize(confirmation));
                System.assertEquals('CLAIM_EMAIL', confirmation.question.questionKey, JSON.serialize(confirmation));
                System.assertEquals('RADIO', confirmation.question.inputType, JSON.serialize(confirmation));

                SmartIntakeDTO.SubmitAnswerRequest useEmail = new SmartIntakeDTO.SubmitAnswerRequest();
                useEmail.intakeSessionId = started.intakeSessionId;
                useEmail.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                useEmail.questionKey = 'CLAIM_EMAIL';
                useEmail.answerValue = 'yes';
                useEmail.answersJson = confirmation.answersJson;

                SmartIntakeDTO.IntakeResponse otp = SmartIntakeService.submitAnswer(useEmail);
                System.assertEquals(true, otp.success, JSON.serialize(otp));
                System.assertEquals('VERIFY_EMAIL_OTP', otp.question.questionKey, JSON.serialize(otp));
                Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(otp.answersJson);
                System.assertEquals('sivachandran2256@gmail.com', String.valueOf(answers.get('CLAIM_EMAIL')));
                System.assertEquals(null, answers.get('__smartIntakePendingExtractedAnswerConfirmation'));
            }
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void warrantyConversationalStartDoesNotSkipEmailOtp() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeHookService.setExecutorForTest(new FakeWarrantyHookExecutor());
        try {
            System.runAs(currentUser) {
                String agentSessionKey = 'warranty-conversation-start-session';

                SmartIntakeDTO.SubmitCurrentAnswerRequest startRequest = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                startRequest.agentSessionKey = agentSessionKey;
                startRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                startRequest.answerValue = 'yes i want to claim';

                SmartIntakeDTO.IntakeResponse started = SmartIntakeService.submitCurrentAnswer(startRequest);
                System.assertEquals(true, started.success, JSON.serialize(started));
                System.assertEquals('CLAIM_EMAIL', started.question.questionKey, JSON.serialize(started));

                SmartIntakeDTO.SubmitCurrentAnswerRequest conversationalReply = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                conversationalReply.agentSessionKey = agentSessionKey;
                conversationalReply.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                conversationalReply.answerValue = 'yes i want to claim';

                SmartIntakeDTO.IntakeResponse stillOnEmail = SmartIntakeService.submitCurrentAnswer(conversationalReply);
                System.assertEquals(true, stillOnEmail.success, JSON.serialize(stillOnEmail));
                System.assertEquals('CLAIM_EMAIL', stillOnEmail.question.questionKey, JSON.serialize(stillOnEmail));
                System.assert(stillOnEmail.userMessage.contains('Got it. Let us continue with this question.'), JSON.serialize(stillOnEmail));
                System.assert(stillOnEmail.userMessage.contains(stillOnEmail.question.questionText), JSON.serialize(stillOnEmail));
                System.assert(!stillOnEmail.question.questionText.contains('Got it. Let us continue with this question.'), JSON.serialize(stillOnEmail));

                Map<String, Object> conversationalAnswers =
                    (Map<String, Object>) JSON.deserializeUntyped(stillOnEmail.answersJson);
                System.assertEquals(null, conversationalAnswers.get('CLAIM_EMAIL'), 'Conversational text must not be saved as the email answer.');
                System.assertEquals(null, conversationalAnswers.get('OTP_SENT'), 'OTP must not be skipped or marked from conversational text.');
                System.assertEquals(null, conversationalAnswers.get('OTP_VERIFICATION_ID'));

                SmartIntakeDTO.SubmitCurrentAnswerRequest invalidEmail = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                invalidEmail.agentSessionKey = agentSessionKey;
                invalidEmail.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                invalidEmail.answerValue = 'not-an-email';

                SmartIntakeDTO.IntakeResponse invalidEmailResponse = SmartIntakeService.submitCurrentAnswer(invalidEmail);
                System.assertEquals(false, invalidEmailResponse.success, JSON.serialize(invalidEmailResponse));
                System.assertEquals('INVALID_EMAIL', invalidEmailResponse.errorCode, JSON.serialize(invalidEmailResponse));

                SmartIntakeDTO.SubmitCurrentAnswerRequest emailAnswer = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                emailAnswer.agentSessionKey = agentSessionKey;
                emailAnswer.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                emailAnswer.answerValue = 'sivachandran2256@gmail.com';

                SmartIntakeDTO.IntakeResponse otpQuestion = SmartIntakeService.submitCurrentAnswer(emailAnswer);
                System.assertEquals(true, otpQuestion.success, JSON.serialize(otpQuestion));
                System.assertEquals('VERIFY_EMAIL_OTP', otpQuestion.question.questionKey, JSON.serialize(otpQuestion));

                Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(otpQuestion.answersJson);
                System.assertEquals('sivachandran2256@gmail.com', String.valueOf(answers.get('CLAIM_EMAIL')));
                System.assertEquals(true, answers.get('OTP_SENT'), JSON.serialize(answers));
            }
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void warrantyStatelessSubmitRecoversRecentActiveSession() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeHookService.setExecutorForTest(new FakeWarrantyHookExecutor());
        try {
            System.runAs(currentUser) {
                SmartIntakeDTO.GetNextQuestionRequest startRequest = new SmartIntakeDTO.GetNextQuestionRequest();
                startRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                SmartIntakeDTO.IntakeResponse started = SmartIntakeService.getNextQuestion(startRequest);
                System.assertEquals(true, started.success, JSON.serialize(started));
                System.assertEquals('CLAIM_EMAIL', started.question.questionKey, JSON.serialize(started));

                SmartIntakeDTO.SubmitCurrentAnswerRequest statelessEmail = new SmartIntakeDTO.SubmitCurrentAnswerRequest();
                statelessEmail.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                statelessEmail.answerValue = 'sivachandran2256@gmail.com';

                SmartIntakeDTO.IntakeResponse otpQuestion = SmartIntakeService.submitCurrentAnswer(statelessEmail);
                System.assertEquals(true, otpQuestion.success, JSON.serialize(otpQuestion));
                System.assertEquals(started.intakeSessionId, otpQuestion.intakeSessionId, 'Stateless submit should resume the active persisted session.');
                System.assertEquals('VERIFY_EMAIL_OTP', otpQuestion.question.questionKey, JSON.serialize(otpQuestion));

                Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(otpQuestion.answersJson);
                System.assertEquals('sivachandran2256@gmail.com', String.valueOf(answers.get('CLAIM_EMAIL')));
                System.assertEquals(true, answers.get('OTP_SENT'), JSON.serialize(answers));
            }
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void submitCurrentAnswerKeepsTextQuestionForPureSideChat() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.GetNextQuestionRequest startRequest = SmartIntakeTestDataFactory.getNextRequest();
            SmartIntakeDTO.IntakeResponse first = SmartIntakeService.getNextQuestion(startRequest);
            System.assertEquals(true, first.success, JSON.serialize(first));
            System.assertEquals('guest_name', first.question.questionKey, JSON.serialize(first));

            SmartIntakeDTO.SubmitCurrentAnswerRequest sideChatRequest =
                SmartIntakeTestDataFactory.submitCurrentRequestWithSession(
                    first.intakeSessionId,
                    'how are you?',
                    first.answersJson
                );
            SmartIntakeDTO.IntakeResponse stillOnName = SmartIntakeService.submitCurrentAnswer(sideChatRequest);

            System.assertEquals(true, stillOnName.success, JSON.serialize(stillOnName));
            System.assertEquals('guest_name', stillOnName.question.questionKey, JSON.serialize(stillOnName));
            System.assert(stillOnName.userMessage.contains('I am here and ready to help. Let us continue with this question.'), JSON.serialize(stillOnName));
            System.assert(stillOnName.userMessage.contains(stillOnName.question.questionText), JSON.serialize(stillOnName));
            Map<String, Object> sideChatAnswers =
                (Map<String, Object>) JSON.deserializeUntyped(stillOnName.answersJson);
            System.assertEquals(null, sideChatAnswers.get('guest_name'), 'Pure side-chat must not be saved as a text answer.');

            SmartIntakeDTO.SubmitCurrentAnswerRequest answerRequest =
                SmartIntakeTestDataFactory.submitCurrentRequestWithSession(
                    first.intakeSessionId,
                    'Sara Smith',
                    stillOnName.answersJson
                );
            SmartIntakeDTO.IntakeResponse answered = SmartIntakeService.submitCurrentAnswer(answerRequest);

            System.assertEquals(true, answered.success, JSON.serialize(answered));
            System.assertEquals('guest_email', answered.question.questionKey, JSON.serialize(answered));
            Map<String, Object> answers =
                (Map<String, Object>) JSON.deserializeUntyped(answered.answersJson);
            System.assertEquals('Sara Smith', answers.get('guest_name'), 'Real text answers must still be saved normally.');
        }
    }

    @IsTest
    static void warrantyExtractedAnswerConfirmationAcceptsTypedEmailReplacement() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeHookService.setExecutorForTest(new FakeWarrantyHookExecutor());
        try {
            System.runAs(currentUser) {
                SmartIntakeDTO.GetNextQuestionRequest startRequest = new SmartIntakeDTO.GetNextQuestionRequest();
                startRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                SmartIntakeDTO.IntakeResponse started = SmartIntakeService.getNextQuestion(startRequest);
                System.assertEquals(true, started.success, JSON.serialize(started));
                System.assertEquals('CLAIM_EMAIL', started.question.questionKey, JSON.serialize(started));

                SmartIntakeDTO.SubmitAnswerRequest proposeEmail = new SmartIntakeDTO.SubmitAnswerRequest();
                proposeEmail.intakeSessionId = started.intakeSessionId;
                proposeEmail.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                proposeEmail.questionKey = 'CLAIM_EMAIL';
                proposeEmail.proposedAnswersJson = JSON.serialize(new Map<String, Object>{
                    'CLAIM_EMAIL' => 'wrong@example.test'
                });
                proposeEmail.answersJson = started.answersJson;

                SmartIntakeDTO.IntakeResponse confirmation = SmartIntakeService.submitAnswer(proposeEmail);
                System.assertEquals(true, confirmation.success, JSON.serialize(confirmation));
                System.assertEquals('CLAIM_EMAIL', confirmation.question.questionKey, JSON.serialize(confirmation));
                System.assertEquals('RADIO', confirmation.question.inputType, JSON.serialize(confirmation));

                SmartIntakeDTO.SubmitAnswerRequest typoConfirmation = new SmartIntakeDTO.SubmitAnswerRequest();
                typoConfirmation.intakeSessionId = started.intakeSessionId;
                typoConfirmation.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                typoConfirmation.questionKey = 'CLAIM_EMAIL';
                typoConfirmation.answerValue = 'yes corrrect';
                typoConfirmation.answersJson = confirmation.answersJson;

                SmartIntakeDTO.IntakeResponse stillConfirming = SmartIntakeService.submitAnswer(typoConfirmation);
                System.assertEquals(true, stillConfirming.success, JSON.serialize(stillConfirming));
                System.assertEquals('CLAIM_EMAIL', stillConfirming.question.questionKey, JSON.serialize(stillConfirming));
                System.assertEquals('RADIO', stillConfirming.question.inputType, JSON.serialize(stillConfirming));
                System.assert(
                    stillConfirming.question.questionText.contains('Please choose Yes'),
                    JSON.serialize(stillConfirming)
                );
                Map<String, Object> stillPendingAnswers = (Map<String, Object>) JSON.deserializeUntyped(stillConfirming.answersJson);
                System.assertEquals(null, stillPendingAnswers.get('CLAIM_EMAIL'));
                System.assertNotEquals(null, stillPendingAnswers.get('__smartIntakePendingExtractedAnswerConfirmation'));

                SmartIntakeDTO.SubmitAnswerRequest typedReplacement = new SmartIntakeDTO.SubmitAnswerRequest();
                typedReplacement.intakeSessionId = started.intakeSessionId;
                typedReplacement.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                typedReplacement.questionKey = 'CLAIM_EMAIL';
                typedReplacement.answerValue = 'sivachandran2256@gmail.com';
                typedReplacement.answersJson = stillConfirming.answersJson;

                SmartIntakeDTO.IntakeResponse otp = SmartIntakeService.submitAnswer(typedReplacement);
                System.assertEquals(true, otp.success, JSON.serialize(otp));
                System.assertEquals('VERIFY_EMAIL_OTP', otp.question.questionKey, JSON.serialize(otp));
                Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(otp.answersJson);
                System.assertEquals('sivachandran2256@gmail.com', String.valueOf(answers.get('CLAIM_EMAIL')));
                System.assertEquals(null, answers.get('__smartIntakePendingExtractedAnswerConfirmation'));
                System.assertEquals(true, answers.get('EMAIL_REGISTERED'), JSON.serialize(answers));
            }
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void warrantyGetNextReplaysHydratedEmailHook() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeHookService.setExecutorForTest(new FakeWarrantyHookExecutor());
        try {
            System.runAs(currentUser) {
                SmartIntakeDTO.GetNextQuestionRequest request = new SmartIntakeDTO.GetNextQuestionRequest();
                request.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                request.answersJson = JSON.serialize(new Map<String, Object>{
                    'CLAIM_EMAIL' => 'sivachandran2256@gmail.com'
                });

                SmartIntakeDTO.IntakeResponse response = SmartIntakeService.getNextQuestion(request);

                System.assertEquals(true, response.success, JSON.serialize(response));
                System.assertEquals('VERIFY_EMAIL_OTP', response.question.questionKey, JSON.serialize(response));
                System.assertEquals(null, response.userMessage, JSON.serialize(response));
                System.assert(response.question.questionText.contains('We sent a verification code.'), JSON.serialize(response));
                Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(response.answersJson);
                System.assertEquals('sivachandran2256@gmail.com', String.valueOf(answers.get('CLAIM_EMAIL')));
                System.assertEquals(true, answers.get('OTP_SENT'), JSON.serialize(answers));
                System.assertEquals(true, answers.get('EMAIL_REGISTERED'), JSON.serialize(answers));
            }
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void warrantyExtractedAnswerConfirmationCanBeRejected() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        SmartIntakeHookService.setExecutorForTest(new FakeWarrantyHookExecutor());
        try {
            System.runAs(currentUser) {
                SmartIntakeDTO.GetNextQuestionRequest startRequest = new SmartIntakeDTO.GetNextQuestionRequest();
                startRequest.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                SmartIntakeDTO.IntakeResponse started = SmartIntakeService.getNextQuestion(startRequest);
                System.assertEquals(true, started.success, JSON.serialize(started));
                System.assertEquals('CLAIM_EMAIL', started.question.questionKey, JSON.serialize(started));

                SmartIntakeDTO.SubmitAnswerRequest proposeEmail = new SmartIntakeDTO.SubmitAnswerRequest();
                proposeEmail.intakeSessionId = started.intakeSessionId;
                proposeEmail.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                proposeEmail.questionKey = 'CLAIM_EMAIL';
                proposeEmail.proposedAnswersJson = JSON.serialize(new Map<String, Object>{
                    'CLAIM_EMAIL' => 'wrong@example.test'
                });
                proposeEmail.answersJson = started.answersJson;

                SmartIntakeDTO.IntakeResponse confirmation = SmartIntakeService.submitAnswer(proposeEmail);
                System.assertEquals(true, confirmation.success, JSON.serialize(confirmation));
                System.assertEquals('CLAIM_EMAIL', confirmation.question.questionKey, JSON.serialize(confirmation));
                System.assertEquals('RADIO', confirmation.question.inputType, JSON.serialize(confirmation));

                SmartIntakeDTO.SubmitAnswerRequest rejectEmail = new SmartIntakeDTO.SubmitAnswerRequest();
                rejectEmail.intakeSessionId = started.intakeSessionId;
                rejectEmail.templateKey = 'LAPTOP_WARRANTY_CLAIM';
                rejectEmail.questionKey = 'CLAIM_EMAIL';
                rejectEmail.answerValue = 'No, change it';
                rejectEmail.answersJson = confirmation.answersJson;

                SmartIntakeDTO.IntakeResponse reenter = SmartIntakeService.submitAnswer(rejectEmail);
                System.assertEquals(true, reenter.success, JSON.serialize(reenter));
                System.assertEquals('CLAIM_EMAIL', reenter.question.questionKey, JSON.serialize(reenter));
                System.assertEquals(null, reenter.userMessage, JSON.serialize(reenter));
                System.assert(reenter.question.questionText.contains('Please enter the answer'), JSON.serialize(reenter));
                Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(reenter.answersJson);
                System.assertEquals(null, answers.get('CLAIM_EMAIL'));
                System.assertEquals(null, answers.get('__smartIntakePendingExtractedAnswerConfirmation'));
            }
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    private static SmartIntake_Condition__mdt runtimeCondition(
        String conditionKey,
        String sourceQuestionKey,
        String targetQuestionKey,
        String action,
        String operator,
        String compareValue,
        String groupKey,
        String logic,
        Integer conditionNumber,
        String customLogic,
        String userMessage
    ) {
        SmartIntake_Condition__mdt condition = new SmartIntake_Condition__mdt();
        condition.Template_Key__c = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        condition.Condition_Key__c = conditionKey;
        condition.Source_Question_Key__c = sourceQuestionKey;
        condition.Target_Question_Key__c = targetQuestionKey;
        condition.Action__c = action;
        condition.Operator__c = operator;
        condition.Compare_Value__c = compareValue;
        condition.Condition_Group_Key__c = groupKey;
        condition.Condition_Logic__c = logic;
        condition.Condition_Number__c = conditionNumber;
        condition.Custom_Logic__c = customLogic;
        condition.User_Message__c = userMessage;
        condition.Sort_Order__c = conditionNumber;
        condition.Is_Active__c = true;
        return condition;
    }

    private class FakeAvailabilityHookExecutor implements SmartIntakeHookService.HookExecutor {
        public SmartIntakeHookService.HookResult executeFlow(
            SmartIntake_Hook__mdt hook,
            SmartIntakeHookService.HookContext context
        ) {
            System.assertEquals('Room_Availability_Hook', hook.Hook_Key__c);
            System.assertEquals(SmartIntakeTestDataFactory.TEMPLATE_KEY, context.templateKey);
            System.assertEquals('room_type', context.questionKey);
            System.assertEquals('Suite', context.answerValue);

            SmartIntakeHookService.HookResult result = new SmartIntakeHookService.HookResult();
            result.userMessage = 'Suite rooms are unavailable for those dates. Please choose another room type.';
            result.blockContinue = true;
            return result;
        }
    }

    private class FakeRoutingHookExecutor implements SmartIntakeHookService.HookExecutor {
        public SmartIntakeHookService.HookResult executeFlow(
            SmartIntake_Hook__mdt hook,
            SmartIntakeHookService.HookContext context
        ) {
            System.assertEquals('Room_Routing_Hook', hook.Hook_Key__c);
            System.assertEquals('room_type', context.questionKey);
            System.assertEquals('Premium', context.answerValue);

            SmartIntakeHookService.HookResult result = new SmartIntakeHookService.HookResult();
            result.updatedAnswersJson = '{"guest_name":"Sara Smith","room_type":"Premium","arrival_date":"' + futureArrivalDate() + '"}';
            result.nextQuestionKey = 'booking_note';
            result.userMessage = 'Room choice checked. I can skip to notes.';
            return result;
        }
    }

    private class FakeInvalidNextQuestionHookExecutor implements SmartIntakeHookService.HookExecutor {
        public SmartIntakeHookService.HookResult executeFlow(
            SmartIntake_Hook__mdt hook,
            SmartIntakeHookService.HookContext context
        ) {
            SmartIntakeHookService.HookResult result = new SmartIntakeHookService.HookResult();
            result.nextQuestionKey = 'missing_question_key';
            return result;
        }
    }

    private class FakeWarrantyHookExecutor implements SmartIntakeHookService.HookExecutor {
        public SmartIntakeHookService.HookResult executeFlow(
            SmartIntake_Hook__mdt hook,
            SmartIntakeHookService.HookContext context
        ) {
            SmartIntakeHookService.HookResult result = new SmartIntakeHookService.HookResult();
            if (context.questionKey == 'CLAIM_EMAIL') {
                System.assertEquals('sivachandran2256@gmail.com', context.answerValue);
                result.nextQuestionKey = 'VERIFY_EMAIL_OTP';
                result.userMessage = 'We sent a verification code.';
                result.mappedAnswers.put('EMAIL_REGISTERED', true);
                result.mappedAnswers.put('OTP_SENT', true);
                return result;
            }
            if (context.questionKey == 'VERIFY_EMAIL_OTP') {
                System.assertEquals('478424', context.answerValue);
                result.nextQuestionKey = 'CLAIM_SERIAL_NUMBER';
                result.userMessage = 'Email verified.';
                result.mappedAnswers.put('OTP_VERIFIED', true);
                return result;
            }
            return result;
        }
    }
}