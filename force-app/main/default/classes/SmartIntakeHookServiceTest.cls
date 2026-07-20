@IsTest
private class SmartIntakeHookServiceTest {
    @IsTest
    static void noHooksReturnDefaultResult() {
        SmartIntakeHookService.HookResult nullMetadataResult =
            SmartIntakeHookService.runAfterAnswer(null, context('room_type', 'Premium', '{}'));
        System.assertEquals(true, nullMetadataResult.success);
        System.assertEquals(false, nullMetadataResult.blockContinue);
        System.assertEquals(0, nullMetadataResult.executedHookKeys.size());

        SmartIntakeHookService.HookResult noHookResult =
            SmartIntakeHookService.runAfterAnswer(new SmartIntakeMetadataService.RuntimeMetadata(), context('room_type', 'Premium', '{}'));
        System.assertEquals(true, noHookResult.success);
        System.assertEquals(0, noHookResult.executedHookKeys.size());
    }

    @IsTest
    static void runsConfiguredHooksAndAggregatesOutputs() {
        SmartIntake_Hook__mdt updateHook = hook('Update_Hook', 'room_type');
        SmartIntake_Hook__mdt blockHook = hook('Block_Hook', 'room_type');
        SmartIntakeMetadataService.RuntimeMetadata metadata = metadataWith(new List<SmartIntake_Hook__mdt>{
            updateHook,
            blockHook
        });
        SmartIntakeHookService.setExecutorForTest(new AggregateHookExecutor());

        try {
            SmartIntakeHookService.HookResult result = SmartIntakeHookService.runAfterAnswer(
                metadata,
                context('room_type', 'Premium', '{"room_type":"Premium"}')
            );

            System.assertEquals(true, result.success);
            System.assertEquals(true, result.blockContinue);
            System.assertEquals('arrival_date', result.nextQuestionKey);
            System.assertEquals('Blocked by policy.', result.userMessage);
            System.assert(result.updatedAnswersJson.contains('flowChecked'), result.updatedAnswersJson);
            System.assertEquals(new List<String>{ 'Update_Hook', 'Block_Hook' }, result.executedHookKeys);
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void basicOutputMappingMergesMappedFlowOutputs() {
        SmartIntake_Hook__mdt mappedHook = hook('Mapped_Output_Hook', 'room_type');
        mappedHook.Output_Mode__c = SmartIntakeHookService.OUTPUT_MODE_BASIC_MAPPING;
        mappedHook.Flow_Output_Mappings__c = 'matchedProducts -> PRODUCT_RESULTS\nwarrantyStatus -> WARRANTY_STATUS';
        SmartIntakeMetadataService.RuntimeMetadata metadata = metadataWith(new List<SmartIntake_Hook__mdt>{
            mappedHook
        });
        SmartIntakeHookService.setExecutorForTest(new MappedOutputHookExecutor());

        try {
            SmartIntakeHookService.HookResult result = SmartIntakeHookService.runAfterAnswer(
                metadata,
                context('room_type', 'Premium', '{"room_type":"Premium"}')
            );
            Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(result.updatedAnswersJson);

            System.assertEquals('Premium', answers.get('room_type'));
            System.assertEquals('Active', answers.get('WARRANTY_STATUS'));
            System.assertEquals(true, answers.containsKey('PRODUCT_RESULTS'));
            System.assertEquals(new List<String>{ 'Mapped_Output_Hook' }, result.executedHookKeys);
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void successFalseHookRaisesControlledException() {
        SmartIntakeMetadataService.RuntimeMetadata metadata = metadataWith(new List<SmartIntake_Hook__mdt>{
            hook('Failure_Hook', 'room_type')
        });
        SmartIntakeHookService.setExecutorForTest(new FailureHookExecutor());

        try {
            SmartIntakeHookService.runAfterAnswer(metadata, context('room_type', 'Premium', '{}'));
            System.assert(false, 'Expected the hook failure to raise a controlled SmartIntakeException.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('EXTENSION', ex.errorType);
            System.assertEquals('HOOK_FAILED', ex.errorCode);
            System.assertEquals('Room check failed.', ex.userMessage);
            System.assert(ex.adminMessage.contains('success=false'), ex.adminMessage);
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void nullHookResultIsIgnored() {
        SmartIntakeMetadataService.RuntimeMetadata metadata = metadataWith(new List<SmartIntake_Hook__mdt>{
            hook('Null_Result_Hook', 'room_type')
        });
        SmartIntakeHookService.setExecutorForTest(new NullHookExecutor());

        try {
            SmartIntakeHookService.HookResult result =
                SmartIntakeHookService.runAfterAnswer(metadata, context('room_type', 'Premium', '{}'));
            System.assertEquals(true, result.success);
            System.assertEquals(1, result.executedHookKeys.size());
            System.assertEquals(null, result.userMessage);
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void successFalseHookCanUseFallbackUserMessageAndAdminMessage() {
        SmartIntakeMetadataService.RuntimeMetadata metadata = metadataWith(new List<SmartIntake_Hook__mdt>{
            hook('Admin_Failure_Hook', 'room_type')
        });
        SmartIntakeHookService.setExecutorForTest(new AdminFailureHookExecutor());

        try {
            SmartIntakeHookService.runAfterAnswer(metadata, context('room_type', 'Premium', '{}'));
            System.assert(false, 'Expected the hook failure to raise a controlled SmartIntakeException.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('HOOK_FAILED', ex.errorCode);
            System.assert(ex.userMessage.contains('configured follow-up check'), ex.userMessage);
            System.assertEquals('Admin-specific hook failure.', ex.adminMessage);
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void invalidHookMetadataRaisesConfigurationError() {
        SmartIntake_Hook__mdt invalidHook = hook(null, 'room_type');
        SmartIntakeMetadataService.RuntimeMetadata metadata = metadataWith(new List<SmartIntake_Hook__mdt>{ invalidHook });
        SmartIntakeHookService.setExecutorForTest(new AggregateHookExecutor());

        try {
            SmartIntakeHookService.runAfterAnswer(metadata, context('room_type', 'Premium', '{}'));
            System.assert(false, 'Expected missing Hook Key to raise a controlled SmartIntakeException.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('CONFIGURATION', ex.errorType);
            System.assertEquals('HOOK_KEY_MISSING', ex.errorCode);
        } finally {
            SmartIntakeHookService.setExecutorForTest(null);
        }
    }

    @IsTest
    static void invalidHookEventAndFlowConfigRaiseConfigurationErrors() {
        SmartIntake_Hook__mdt wrongEventHook = hook('Wrong_Event_Hook', 'room_type');
        wrongEventHook.Event__c = 'BEFORE_ANSWER';
        SmartIntakeMetadataService.RuntimeMetadata wrongEventMetadata = new SmartIntakeMetadataService.RuntimeMetadata();
        wrongEventMetadata.hooksByQuestionAndEvent.put(
            'room_type:' + SmartIntakeHookService.EVENT_AFTER_ANSWER,
            new List<SmartIntake_Hook__mdt>{ wrongEventHook }
        );

        try {
            SmartIntakeHookService.runAfterAnswer(wrongEventMetadata, context('room_type', 'Premium', '{}'));
            System.assert(false, 'Expected unsupported event to fail.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('HOOK_EVENT_UNSUPPORTED', ex.errorCode);
        }

        SmartIntake_Hook__mdt missingFlowHook = hook('Missing_Flow_Name_Hook', 'room_type');
        missingFlowHook.Flow_API_Name__c = null;
        SmartIntakeMetadataService.RuntimeMetadata missingFlowMetadata = metadataWith(new List<SmartIntake_Hook__mdt>{
            missingFlowHook
        });

        try {
            SmartIntakeHookService.runAfterAnswer(missingFlowMetadata, context('room_type', 'Premium', '{}'));
            System.assert(false, 'Expected missing Flow API name to fail.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('HOOK_FLOW_REQUIRED', ex.errorCode);
        }

        SmartIntakeMetadataService.RuntimeMetadata nullHookMetadata = new SmartIntakeMetadataService.RuntimeMetadata();
        nullHookMetadata.hooksByQuestionAndEvent.put(
            'room_type:' + SmartIntakeHookService.EVENT_AFTER_ANSWER,
            new List<SmartIntake_Hook__mdt>{ null }
        );

        try {
            SmartIntakeHookService.runAfterAnswer(nullHookMetadata, context('room_type', 'Premium', '{}'));
            System.assert(false, 'Expected null hook record to fail.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('HOOK_MISSING', ex.errorCode);
        }
    }

    @IsTest
    static void missingDynamicFlowReturnsControlledExtensionError() {
        SmartIntake_Hook__mdt missingFlowHook = hook('Missing_Flow_Hook', 'room_type');
        missingFlowHook.Flow_API_Name__c = 'SmartIntake_Missing_Flow_For_Test';
        SmartIntakeMetadataService.RuntimeMetadata metadata = metadataWith(new List<SmartIntake_Hook__mdt>{ missingFlowHook });

        try {
            SmartIntakeHookService.runAfterAnswer(metadata, context('room_type', 'Premium', '{}'));
            System.assert(false, 'Expected missing configured Flow to raise a controlled SmartIntakeException.');
        } catch (SmartIntakeException ex) {
            System.assertEquals('EXTENSION', ex.errorType);
            System.assertEquals('HOOK_FLOW_ERROR', ex.errorCode);
            System.assert(ex.adminMessage.contains('SmartIntake_Missing_Flow_For_Test'), ex.adminMessage);
        }
    }

    private static SmartIntakeMetadataService.RuntimeMetadata metadataWith(List<SmartIntake_Hook__mdt> hooks) {
        SmartIntakeMetadataService.RuntimeMetadata metadata = new SmartIntakeMetadataService.RuntimeMetadata();
        metadata.hooks = hooks;
        for (SmartIntake_Hook__mdt hook : hooks) {
            String key = hook.Question_Key__c + ':' + SmartIntakeHookService.EVENT_AFTER_ANSWER;
            if (!metadata.hooksByQuestionAndEvent.containsKey(key)) {
                metadata.hooksByQuestionAndEvent.put(key, new List<SmartIntake_Hook__mdt>());
            }
            metadata.hooksByQuestionAndEvent.get(key).add(hook);
        }
        return metadata;
    }

    private static SmartIntake_Hook__mdt hook(String hookKey, String questionKey) {
        SmartIntake_Hook__mdt hook = new SmartIntake_Hook__mdt();
        hook.Template_Key__c = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        hook.Hook_Key__c = hookKey;
        hook.Question_Key__c = questionKey;
        hook.Event__c = SmartIntakeHookService.EVENT_AFTER_ANSWER;
        hook.Handler_Type__c = 'FLOW';
        hook.Flow_API_Name__c = 'Check_Room_Availability';
        hook.Is_Active__c = true;
        hook.Sort_Order__c = 10;
        return hook;
    }

    private static SmartIntakeHookService.HookContext context(String questionKey, String answerValue, String answersJson) {
        SmartIntakeHookService.HookContext context = new SmartIntakeHookService.HookContext();
        context.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        context.questionKey = questionKey;
        context.intakeSessionId = 'SI-test';
        context.agentSessionKey = 'agent-test';
        context.answerValue = answerValue;
        context.answersJson = answersJson;
        context.routableId = 'route-test';
        return context;
    }

    private class AggregateHookExecutor implements SmartIntakeHookService.HookExecutor {
        public SmartIntakeHookService.HookResult executeFlow(
            SmartIntake_Hook__mdt hook,
            SmartIntakeHookService.HookContext context
        ) {
            SmartIntakeHookService.HookResult result = new SmartIntakeHookService.HookResult();
            if (hook.Hook_Key__c == 'Update_Hook') {
                result.updatedAnswersJson = '{"room_type":"Premium","flowChecked":true}';
                result.userMessage = 'Updated answers.';
                result.nextQuestionKey = 'arrival_date';
            } else if (hook.Hook_Key__c == 'Block_Hook') {
                System.assert(context.answersJson.contains('flowChecked'), context.answersJson);
                result.userMessage = 'Blocked by policy.';
                result.blockContinue = true;
            }
            return result;
        }
    }

    private class FailureHookExecutor implements SmartIntakeHookService.HookExecutor {
        public SmartIntakeHookService.HookResult executeFlow(
            SmartIntake_Hook__mdt hook,
            SmartIntakeHookService.HookContext context
        ) {
            SmartIntakeHookService.HookResult result = new SmartIntakeHookService.HookResult();
            result.success = false;
            result.userMessage = 'Room check failed.';
            return result;
        }
    }

    private class MappedOutputHookExecutor implements SmartIntakeHookService.HookExecutor {
        public SmartIntakeHookService.HookResult executeFlow(
            SmartIntake_Hook__mdt hook,
            SmartIntakeHookService.HookContext context
        ) {
            SmartIntakeHookService.HookResult result = new SmartIntakeHookService.HookResult();
            result.mappedAnswers.put('WARRANTY_STATUS', 'Active');
            result.mappedAnswers.put('PRODUCT_RESULTS', new List<Object>{
                new Map<String, Object>{ 'Id' => '01t000000000001AAA', 'Name' => 'Laptop Pro 15' },
                new Map<String, Object>{ 'Id' => '01t000000000002AAA', 'Name' => 'Laptop Air 13' }
            });
            return result;
        }
    }

    private class NullHookExecutor implements SmartIntakeHookService.HookExecutor {
        public SmartIntakeHookService.HookResult executeFlow(
            SmartIntake_Hook__mdt hook,
            SmartIntakeHookService.HookContext context
        ) {
            return null;
        }
    }

    private class AdminFailureHookExecutor implements SmartIntakeHookService.HookExecutor {
        public SmartIntakeHookService.HookResult executeFlow(
            SmartIntake_Hook__mdt hook,
            SmartIntakeHookService.HookContext context
        ) {
            SmartIntakeHookService.HookResult result = new SmartIntakeHookService.HookResult();
            result.success = false;
            result.adminMessage = 'Admin-specific hook failure.';
            return result;
        }
    }
}