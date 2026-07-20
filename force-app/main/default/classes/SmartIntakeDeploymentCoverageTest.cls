@IsTest
private class SmartIntakeDeploymentCoverageTest {
    @IsTest
    static void coversInvocableAndRuntimeWrappers() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            List<SmartIntakeDTO.IntakeResponse> routedResponses =
                SmartIntakeGetNextQuestionRoutedAction.invoke(new List<SmartIntakeDTO.GetNextQuestionRequest>{
                    SmartIntakeTestDataFactory.getNextRequest()
                });
            System.assertEquals(1, routedResponses.size());
            System.assertEquals(true, routedResponses[0].success, JSON.serialize(routedResponses[0]));
            String sessionId = routedResponses[0].intakeSessionId;

            List<SmartIntakeDTO.IntakeResponse> submitResponses =
                SmartIntakeSubmitAnswerAction.invoke(new List<SmartIntakeDTO.SubmitAnswerRequest>{
                    SmartIntakeTestDataFactory.submitRequest('guest_name', 'Coverage Guest', '{}')
                });
            System.assertEquals(1, submitResponses.size());
            System.assertEquals(true, submitResponses[0].success, JSON.serialize(submitResponses[0]));

            SmartIntakeDTO.IntakeResponse backResponse = SmartIntakeRuntimeController.goBack(
                sessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'guest_name',
                '{}'
            );
            System.assertEquals(false, backResponse.success);
            System.assertEquals('BACK_NOT_AVAILABLE', backResponse.errorCode);

            SmartIntakeDTO.IntakeResponse skipResponse = SmartIntakeRuntimeController.skipQuestion(
                sessionId,
                SmartIntakeTestDataFactory.TEMPLATE_KEY,
                null,
                'missing_question',
                '{}'
            );
            System.assertEquals(false, skipResponse.success);
            System.assertEquals('QUESTION_NOT_FOUND', skipResponse.errorCode);
        }
    }

    @IsTest
    static void coversAdminDescribeEndpoints() {
        System.assertNotEquals(null, SmartIntakeAdminController.listCustomRenderers());
        System.assertNotEquals(null, SmartIntakeAdminController.listInvocableFlows());
        System.assertEquals(0, SmartIntakeAdminController.listFlowVariables(null).size());
        System.assertEquals(0, SmartIntakeAdminController.listFlowVariables('Bad Name!').size());
        System.assertNotEquals(null, SmartIntakeAdminController.listFlowVariables('Get_Agent_User'));
        System.assertNotEquals(null, SmartIntakeAdminController.listBindableObjects());
        System.assertNotEquals(null, SmartIntakeAdminController.listBindableFields('Warranty_Claim__c', 'TEXT'));
        System.assertNotEquals(null, SmartIntakeAdminController.listBindableFields('Warranty_Claim__c', 'BOOLEAN'));
        System.assertEquals(0, SmartIntakeAdminController.listBindableFields('NoSuch__c', 'TEXT').size());
        System.assertNotEquals(null, SmartIntakeAdminController.listActivePicklistValues('Warranty_Claim__c', 'Claim_Type__c'));
        System.assertEquals(0, SmartIntakeAdminController.listActivePicklistValues('Warranty_Claim__c', 'Asset__c').size());
        System.assertEquals(0, SmartIntakeAdminController.listActivePicklistValues('NoSuch__c', 'Claim_Type__c').size());
    }

    @IsTest
    static void coversDynamicFlowHookMappings() {
        User currentUser = [SELECT Name FROM User WHERE Id = :UserInfo.getUserId()];
        SmartIntake_Hook__mdt flowHook = hook('Coverage_Flow_Hook', 'guest_name');
        flowHook.Output_Mode__c = SmartIntakeHookService.OUTPUT_MODE_BASIC_MAPPING;
        flowHook.Flow_Input_Mappings__c = 'userName <- "' + currentUser.Name + '"';
        flowHook.Flow_Output_Mappings__c = 'userId -> AGENT_USER_ID';

        SmartIntakeHookService.HookResult result = SmartIntakeHookService.runAfterAnswer(
            metadataWith(new List<SmartIntake_Hook__mdt>{ flowHook }),
            context('guest_name', 'Coverage Guest', '{}')
        );

        System.assertEquals(true, result.success, JSON.serialize(result));
        System.assertEquals(false, result.blockContinue);
        System.assertNotEquals(null, result.updatedAnswersJson);
        Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(result.updatedAnswersJson);
        System.assertEquals(true, answers.containsKey('AGENT_USER_ID'), result.updatedAnswersJson);
    }

    @IsTest
    static void coversHookMappingValidationErrors() {
        SmartIntake_Hook__mdt badInput = hook('Bad_Input_Hook', 'guest_name');
        badInput.Flow_Input_Mappings__c = 'not valid';

        try {
            SmartIntakeHookService.runAfterAnswer(
                metadataWith(new List<SmartIntake_Hook__mdt>{ badInput }),
                context('guest_name', 'Coverage Guest', '{}')
            );
            System.assert(false, 'Expected invalid input mapping.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('HOOK_INPUT_MAPPING_INVALID', ex.errorCode);
        }

        SmartIntake_Hook__mdt badOutput = hook('Bad_Output_Hook', 'guest_name');
        badOutput.Output_Mode__c = SmartIntakeHookService.OUTPUT_MODE_BASIC_MAPPING;
        badOutput.Flow_Output_Mappings__c = 'not valid';

        try {
            SmartIntakeHookService.runAfterAnswer(
                metadataWith(new List<SmartIntake_Hook__mdt>{ badOutput }),
                context('guest_name', 'Coverage Guest', '{}')
            );
            System.assert(false, 'Expected invalid output mapping.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('HOOK_OUTPUT_MAPPING_INVALID', ex.errorCode);
        }
    }

    @IsTest
    static void coversNavigationContextAndHandoffBranches() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.IntakeResponse started = SmartIntakeService.getNextQuestion(
                SmartIntakeTestDataFactory.getNextRequest()
            );
            System.assertEquals(true, started.success, JSON.serialize(started));

            SmartIntakeDTO.IntakeResponse answered = SmartIntakeService.submitAnswer(
                SmartIntakeTestDataFactory.submitRequestWithSession(
                    started.intakeSessionId,
                    'guest_name',
                    'Coverage Guest',
                    '{}'
                )
            );
            System.assertEquals(true, answered.success, JSON.serialize(answered));

            SmartIntakeDTO.IntakeResponse backResponse = SmartIntakeService.goBack(
                SmartIntakeTestDataFactory.navigateRequest(
                    answered.intakeSessionId,
                    answered.question.questionKey,
                    answered.answersJson
                )
            );
            System.assertEquals(true, backResponse.success, JSON.serialize(backResponse));
            System.assertEquals('guest_name', backResponse.question.questionKey);

            String completeVisibleAnswersJson =
                '{"guest_name":"Coverage Guest",' +
                '"guest_email":"coverage@example.test",' +
                '"guest_email_match_status":"NO_MATCH",' +
                '"guest_phone":"5550109999",' +
                '"guest_phone_match_status":"NO_MATCH",' +
                '"room_type":"Premium",' +
                '"arrival_date":"' + String.valueOf(Date.today().addDays(2)) + '"}';

            SmartIntakeDTO.IntakeResponse skipResponse = SmartIntakeService.skipQuestion(
                SmartIntakeTestDataFactory.navigateRequest(
                    answered.intakeSessionId,
                    'booking_note',
                    completeVisibleAnswersJson
                )
            );
            System.assertEquals(true, skipResponse.success, JSON.serialize(skipResponse));

            SmartIntakeDTO.ExistingContextResponse contextResponse = SmartIntakeService.getExistingContext(
                SmartIntakeTestDataFactory.existingContextRequest(
                    'booking_note',
                    '{"guest_name":"No Existing Coverage Guest"}'
                )
            );
            System.assertEquals(true, contextResponse.success, JSON.serialize(contextResponse));
            System.assertEquals(false, contextResponse.hasContext, JSON.serialize(contextResponse));
            System.assertEquals(0, contextResponse.contextRecords.size(), JSON.serialize(contextResponse));

            SmartIntakeDTO.HandoffPlanRequest consentRequired = handoffRequest(false);
            SmartIntakeDTO.HandoffPlanResponse consentResponse = SmartIntakeService.getHandoffPlan(consentRequired);
            System.assertEquals(true, consentResponse.success, JSON.serialize(consentResponse));
            System.assertEquals('CONSENT_REQUIRED', consentResponse.availabilityStatus, JSON.serialize(consentResponse));

            SmartIntakeDTO.HandoffPlanRequest providerNotReady = handoffRequest(true);
            SmartIntakeDTO.HandoffPlanResponse handoffResponse = SmartIntakeService.getHandoffPlan(providerNotReady);
            System.assertEquals(true, handoffResponse.success, JSON.serialize(handoffResponse));
            System.assertEquals('NOT_READY', handoffResponse.availabilityStatus, JSON.serialize(handoffResponse));
        }
    }

    @IsTest
    static void coversPendingExtractedAnswerConfirmationBranches() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            String pendingGuestNameJson =
                '{"__smartIntakePendingExtractedAnswerConfirmation":' +
                '{"questionKey":"guest_name","answerValue":"Extracted Guest"}}';

            SmartIntakeDTO.SubmitCurrentAnswerRequest affirmative =
                SmartIntakeTestDataFactory.submitCurrentRequestWithSession(
                    validSessionId('pending-affirmative'),
                    'yes',
                    pendingGuestNameJson
                );
            SmartIntakeDTO.IntakeResponse accepted = SmartIntakeService.submitCurrentAnswer(affirmative);
            System.assertEquals(true, accepted.success, JSON.serialize(accepted));
            System.assert(accepted.answersJson.contains('Extracted Guest'), accepted.answersJson);

            SmartIntakeDTO.SubmitCurrentAnswerRequest negative =
                SmartIntakeTestDataFactory.submitCurrentRequestWithSession(
                    validSessionId('pending-negative'),
                    'no',
                    pendingGuestNameJson
                );
            SmartIntakeDTO.IntakeResponse rejected = SmartIntakeService.submitCurrentAnswer(negative);
            System.assertEquals(true, rejected.success, JSON.serialize(rejected));
            System.assertEquals('guest_name', rejected.question.questionKey, JSON.serialize(rejected));
            System.assert(rejected.userMessage.contains('enter the answer'), rejected.userMessage);

            SmartIntakeDTO.SubmitCurrentAnswerRequest unclear =
                SmartIntakeTestDataFactory.submitCurrentRequestWithSession(
                    validSessionId('pending-unclear'),
                    'maybe later',
                    pendingGuestNameJson
                );
            SmartIntakeDTO.IntakeResponse clarification = SmartIntakeService.submitCurrentAnswer(unclear);
            System.assertEquals(true, clarification.success, JSON.serialize(clarification));
            System.assertEquals('guest_name', clarification.question.questionKey, JSON.serialize(clarification));
            System.assert(clarification.userMessage.contains('Please choose Yes'), clarification.userMessage);

            SmartIntakeDTO.SubmitCurrentAnswerRequest invalidPending =
                SmartIntakeTestDataFactory.submitCurrentRequestWithSession(
                    validSessionId('pending-invalid'),
                    'yes',
                    '{"__smartIntakePendingExtractedAnswerConfirmation":{"questionKey":"missing","answerValue":"x"}}'
                );
            SmartIntakeDTO.IntakeResponse ignored = SmartIntakeService.submitCurrentAnswer(invalidPending);
            System.assertEquals(true, ignored.success, JSON.serialize(ignored));
        }
    }

    @IsTest
    static void coversSubmitCurrentOptionalSkipBranch() {
        SmartIntakeTestDataFactory.assignRuntimePermissionSet();
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            SmartIntakeDTO.SubmitCurrentAnswerRequest request =
                SmartIntakeTestDataFactory.submitCurrentRequestWithSession(
                    validSessionId('optional-skip'),
                    'skip',
                    completeHotelAnswersBeforeOptionalNote()
                );

            SmartIntakeDTO.IntakeResponse response = SmartIntakeService.submitCurrentAnswer(request);
            System.assertEquals(true, response.success, JSON.serialize(response));
            System.assert(response.answersJson.contains('"booking_note"'), response.answersJson);
        }
    }

    private static SmartIntakeDTO.HandoffPlanRequest handoffRequest(Boolean consentAccepted) {
        SmartIntakeDTO.HandoffPlanRequest request = new SmartIntakeDTO.HandoffPlanRequest();
        request.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        request.reason = 'coverage';
        request.consentAccepted = consentAccepted;
        request.contextSummaryJson = '{"guest_name":"Coverage Guest","room_type":"Premium","internal_note":"hidden"}';
        return request;
    }

    private static SmartIntakeMetadataService.RuntimeMetadata metadataWith(List<SmartIntake_Hook__mdt> hooks) {
        SmartIntakeMetadataService.RuntimeMetadata metadata = new SmartIntakeMetadataService.RuntimeMetadata();
        metadata.hooks = hooks;
        for (SmartIntake_Hook__mdt hookRecord : hooks) {
            String key = hookRecord.Question_Key__c + ':' + SmartIntakeHookService.EVENT_AFTER_ANSWER;
            if (!metadata.hooksByQuestionAndEvent.containsKey(key)) {
                metadata.hooksByQuestionAndEvent.put(key, new List<SmartIntake_Hook__mdt>());
            }
            metadata.hooksByQuestionAndEvent.get(key).add(hookRecord);
        }
        return metadata;
    }

    private static SmartIntake_Hook__mdt hook(String hookKey, String questionKey) {
        SmartIntake_Hook__mdt hookRecord = new SmartIntake_Hook__mdt();
        hookRecord.Template_Key__c = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        hookRecord.Hook_Key__c = hookKey;
        hookRecord.Question_Key__c = questionKey;
        hookRecord.Event__c = SmartIntakeHookService.EVENT_AFTER_ANSWER;
        hookRecord.Handler_Type__c = 'FLOW';
        hookRecord.Flow_API_Name__c = 'Get_Agent_User';
        hookRecord.Is_Active__c = true;
        hookRecord.Sort_Order__c = 10;
        return hookRecord;
    }

    private static SmartIntakeHookService.HookContext context(
        String questionKey,
        String answerValue,
        String answersJson
    ) {
        SmartIntakeHookService.HookContext context = new SmartIntakeHookService.HookContext();
        context.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        context.questionKey = questionKey;
        context.intakeSessionId = 'SI-coverage-hook';
        context.agentSessionKey = 'agent-coverage-hook';
        context.answerValue = answerValue;
        context.answersJson = answersJson;
        context.routableId = 'route-coverage-hook';
        return context;
    }

    private static String validSessionId(String seed) {
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(seed));
        return 'SI-' + EncodingUtil.convertToHex(digest).substring(0, 32);
    }

    private static String completeHotelAnswersBeforeOptionalNote() {
        return '{"guest_name":"Coverage Guest",' +
            '"guest_email":"coverage@example.test",' +
            '"guest_email_match_status":"NO_MATCH",' +
            '"guest_phone":"5550109999",' +
            '"guest_phone_match_status":"NO_MATCH",' +
            '"room_type":"Premium",' +
            '"arrival_date":"' + String.valueOf(Date.today().addDays(2)) + '"}';
    }
}