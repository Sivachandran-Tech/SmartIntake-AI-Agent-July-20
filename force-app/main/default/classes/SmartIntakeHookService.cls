public with sharing class SmartIntakeHookService {
    public static final String EVENT_AFTER_ANSWER = 'AFTER_ANSWER';
    public static final String OUTPUT_MODE_BASIC_MAPPING = 'BASIC_OUTPUT_MAPPING';
    public static final String OUTPUT_MODE_ADVANCED_JSON_OVERRIDE = 'ADVANCED_JSON_OVERRIDE';
    private static final String HANDLER_FLOW = 'FLOW';
    private static final String DEFAULT_SUCCESS_OUTPUT = 'success';
    private static final String DEFAULT_USER_MESSAGE_OUTPUT = 'userMessage';
    private static final String DEFAULT_NEXT_QUESTION_OUTPUT = 'nextQuestionKey';
    private static final String DEFAULT_ANSWERS_JSON_OUTPUT = 'updatedAnswersJson';
    private static final String DEFAULT_BLOCK_CONTINUE_OUTPUT = 'blockContinue';

    @TestVisible
    private static HookExecutor executor = new DynamicFlowHookExecutor();

    public interface HookExecutor {
        HookResult executeFlow(SmartIntake_Hook__mdt hook, HookContext context);
    }

    public class HookContext {
        public String templateKey;
        public String questionKey;
        public String intakeSessionId;
        public String agentSessionKey;
        public String answerValue;
        public String answersJson;
        public String routableId;
    }

    public class HookResult {
        public Boolean success = true;
        public Boolean blockContinue = false;
        public String userMessage;
        public String adminMessage;
        public String nextQuestionKey;
        public String updatedAnswersJson;
        public Map<String, Object> mappedAnswers = new Map<String, Object>();
        public List<String> executedHookKeys = new List<String>();
    }

    private class FlowOutputMapping {
        String outputVariableName;
        String answerKey;
    }

    private class FlowInputMapping {
        String inputVariableName;
        String sourceKey;
    }

    public static HookResult runAfterAnswer(SmartIntakeMetadataService.RuntimeMetadata metadata, HookContext context) {
        return runHooks(metadata, context, EVENT_AFTER_ANSWER);
    }

    @TestVisible
    private static void setExecutorForTest(HookExecutor testExecutor) {
        executor = testExecutor == null ? new DynamicFlowHookExecutor() : testExecutor;
    }

    private static HookResult runHooks(
        SmartIntakeMetadataService.RuntimeMetadata metadata,
        HookContext context,
        String eventName
    ) {
        HookResult aggregate = new HookResult();
        if (metadata == null || context == null || String.isBlank(context.questionKey)) {
            return aggregate;
        }

        List<SmartIntake_Hook__mdt> hooks = metadata.hooksByQuestionAndEvent.get(context.questionKey + ':' + normalize(eventName));
        if (hooks == null || hooks.isEmpty()) {
            return aggregate;
        }

        HookContext rollingContext = cloneContext(context);
        for (SmartIntake_Hook__mdt hook : hooks) {
            validateHook(hook, eventName);
            HookResult current = executeHook(hook, rollingContext);
            aggregate.executedHookKeys.add(hook.Hook_Key__c);

            if (current == null) {
                continue;
            }
            if (current.success == false) {
                throw new SmartIntakeException(
                    'EXTENSION',
                    'HOOK_FAILED',
                    String.isBlank(current.userMessage)
                        ? 'I could not complete the configured follow-up check. Please try again or ask an admin for help.'
                        : current.userMessage,
                    String.isBlank(current.adminMessage)
                        ? 'Hook ' + hook.DeveloperName + ' returned success=false.'
                        : current.adminMessage
                );
            }
            if (!String.isBlank(current.updatedAnswersJson)) {
                rollingContext.answersJson = current.updatedAnswersJson;
                aggregate.updatedAnswersJson = current.updatedAnswersJson;
            }
            if (current.mappedAnswers != null && !current.mappedAnswers.isEmpty()) {
                rollingContext.answersJson = mergeMappedAnswers(rollingContext.answersJson, current.mappedAnswers);
                aggregate.updatedAnswersJson = rollingContext.answersJson;
            }
            if (!String.isBlank(current.userMessage)) {
                aggregate.userMessage = current.userMessage;
            }
            if (!String.isBlank(current.nextQuestionKey)) {
                aggregate.nextQuestionKey = current.nextQuestionKey;
            }
            if (current.blockContinue == true) {
                aggregate.blockContinue = true;
                break;
            }
        }
        return aggregate;
    }

    private static HookResult executeHook(SmartIntake_Hook__mdt hook, HookContext context) {
        String handlerType = normalize(hook.Handler_Type__c);
        if (handlerType == HANDLER_FLOW) {
            return executor.executeFlow(hook, context);
        }
        throw configError('HOOK_HANDLER_UNSUPPORTED', 'Hook ' + hook.DeveloperName + ' uses unsupported handler type ' + hook.Handler_Type__c + '.');
    }

    private static void validateHook(SmartIntake_Hook__mdt hook, String expectedEvent) {
        if (hook == null) {
            throw configError('HOOK_MISSING', 'A SmartIntake hook record was null.');
        }
        if (String.isBlank(hook.Hook_Key__c)) {
            throw configError('HOOK_KEY_MISSING', 'Hook ' + hook.DeveloperName + ' is missing Hook Key.');
        }
        if (normalize(hook.Event__c) != normalize(expectedEvent)) {
            throw configError('HOOK_EVENT_UNSUPPORTED', 'Hook ' + hook.DeveloperName + ' cannot run for event ' + hook.Event__c + '.');
        }
        if (normalize(hook.Handler_Type__c) != HANDLER_FLOW) {
            throw configError('HOOK_HANDLER_UNSUPPORTED', 'Hook ' + hook.DeveloperName + ' uses unsupported handler type ' + hook.Handler_Type__c + '.');
        }
        if (String.isBlank(hook.Flow_API_Name__c)) {
            throw configError('HOOK_FLOW_REQUIRED', 'Hook ' + hook.DeveloperName + ' requires Flow API Name.');
        }
        String outputMode = outputMode(hook);
        if (outputMode != OUTPUT_MODE_BASIC_MAPPING && outputMode != OUTPUT_MODE_ADVANCED_JSON_OVERRIDE) {
            throw configError('HOOK_OUTPUT_MODE_UNSUPPORTED', 'Hook ' + hook.DeveloperName + ' uses unsupported output mode ' + hook.Output_Mode__c + '.');
        }
        if (outputMode == OUTPUT_MODE_BASIC_MAPPING) {
            parseFlowOutputMappings(hook.Flow_Output_Mappings__c, hook.DeveloperName);
        }
        parseFlowInputMappings(hook.Flow_Input_Mappings__c, hook.DeveloperName);
    }

    private class DynamicFlowHookExecutor implements HookExecutor {
        public HookResult executeFlow(SmartIntake_Hook__mdt hook, HookContext context) {
            Map<String, Object> inputs = flowInputs(hook, context);

            try {
                Flow.Interview interview = Flow.Interview.createInterview(hook.Flow_API_Name__c.trim(), inputs);
                interview.start();

                HookResult result = new HookResult();
                result.success = booleanOutput(interview, outputName(hook.Success_Output_Variable__c, DEFAULT_SUCCESS_OUTPUT), true);
                result.userMessage = stringOutput(interview, outputName(hook.User_Message_Output_Variable__c, DEFAULT_USER_MESSAGE_OUTPUT));
                result.nextQuestionKey = stringOutput(interview, outputName(hook.Next_Question_Output_Variable__c, DEFAULT_NEXT_QUESTION_OUTPUT));
                if (outputMode(hook) == OUTPUT_MODE_ADVANCED_JSON_OVERRIDE) {
                    result.updatedAnswersJson = stringOutput(interview, outputName(hook.Answers_JSON_Output_Variable__c, DEFAULT_ANSWERS_JSON_OUTPUT));
                } else {
                    result.mappedAnswers = mappedFlowOutputs(interview, hook);
                }
                result.blockContinue = booleanOutput(interview, outputName(hook.Block_Continue_Output_Variable__c, DEFAULT_BLOCK_CONTINUE_OUTPUT), false);
                return result;
            } catch (SmartIntakeException ex) {
                throw ex;
            } catch (Exception ex) {
                SmartIntakeApexDebugLogService.logException(
                    'SmartIntakeHookService',
                    'executeFlow',
                    context == null ? hook.Template_Key__c : context.templateKey,
                    context == null ? null : context.intakeSessionId,
                    ex,
                    new Map<String, Object>{
                        'hookDeveloperName' => hook.DeveloperName,
                        'hookKey' => hook.Hook_Key__c,
                        'flowApiName' => hook.Flow_API_Name__c,
                        'questionKey' => context == null ? hook.Question_Key__c : context.questionKey,
                        'agentSessionKey' => context == null ? null : context.agentSessionKey
                    }
                );
                throw new SmartIntakeException(
                    'EXTENSION',
                    'HOOK_FLOW_ERROR',
                    'I could not complete the configured follow-up check. Please try again or ask an admin for help.',
                    'Hook ' + hook.DeveloperName + ' failed while running Flow ' + hook.Flow_API_Name__c + ': ' + ex.getTypeName() + ': ' + ex.getMessage()
                );
            }
        }
    }

    private static Map<String, Object> flowInputs(SmartIntake_Hook__mdt hook, HookContext context) {
        Map<String, Object> inputs = new Map<String, Object>{
            'hookKey' => hook.Hook_Key__c,
            'templateKey' => context.templateKey,
            'questionKey' => context.questionKey,
            'intakeSessionId' => context.intakeSessionId,
            'agentSessionKey' => context.agentSessionKey,
            'answerValue' => context.answerValue,
            'answersJson' => context.answersJson,
            'routableId' => context.routableId
        };
        if (String.isBlank(hook.Flow_Input_Mappings__c)) {
            return inputs;
        }

        Map<String, Object> answers = null;
        for (FlowInputMapping mapping : parseFlowInputMappings(hook.Flow_Input_Mappings__c, hook.DeveloperName)) {
            if (answers == null && isAnswerMapSource(mapping.sourceKey)) {
                answers = readAnswers(context.answersJson);
            }
            inputs.put(mapping.inputVariableName, resolveInputValue(mapping.sourceKey, context, answers, inputs));
        }
        return inputs;
    }

    private static Boolean isAnswerMapSource(String sourceKey) {
        if (isQuotedLiteral(sourceKey == null ? null : sourceKey.trim())) {
            return false;
        }
        String normalized = normalizeSourceKey(sourceKey);
        return normalized != 'hookkey' &&
            normalized != 'templatekey' &&
            normalized != 'questionkey' &&
            normalized != 'intakesessionid' &&
            normalized != 'agentsessionkey' &&
            normalized != 'answervalue' &&
            normalized != 'answersjson' &&
            normalized != 'routableid';
    }

    private static Object resolveInputValue(
        String sourceKey,
        HookContext context,
        Map<String, Object> answers,
        Map<String, Object> defaultInputs
    ) {
        String source = sourceKey == null ? '' : sourceKey.trim();
        if (isQuotedLiteral(source)) {
            return source.substring(1, source.length() - 1);
        }

        String normalized = normalizeSourceKey(source);
        if (normalized == 'hookkey') {
            return defaultInputs == null ? null : defaultInputs.get('hookKey');
        }
        if (normalized == 'templatekey') {
            return defaultInputs == null ? null : defaultInputs.get('templateKey');
        }
        if (normalized == 'questionkey') {
            return defaultInputs == null ? null : defaultInputs.get('questionKey');
        }
        if (normalized == 'intakesessionid') {
            return defaultInputs == null ? null : defaultInputs.get('intakeSessionId');
        }
        if (normalized == 'agentsessionkey') {
            return defaultInputs == null ? null : defaultInputs.get('agentSessionKey');
        }
        if (normalized == 'answervalue') {
            return defaultInputs == null ? null : defaultInputs.get('answerValue');
        }
        if (normalized == 'answersjson') {
            return defaultInputs == null ? null : defaultInputs.get('answersJson');
        }
        if (normalized == 'routableid') {
            return defaultInputs == null ? null : defaultInputs.get('routableId');
        }
        return answers == null ? null : answers.get(source);
    }

    private static String normalizeSourceKey(String sourceKey) {
        String source = sourceKey == null ? '' : sourceKey.trim();
        if (source.startsWith('$')) {
            source = source.substring(1);
        }
        return source.replace('_', '').toLowerCase();
    }

    private static Boolean isQuotedLiteral(String source) {
        return source != null &&
            source.length() >= 2 &&
            ((source.startsWith('\'') && source.endsWith('\'')) ||
            (source.startsWith('"') && source.endsWith('"')));
    }

    private static HookContext cloneContext(HookContext source) {
        HookContext target = new HookContext();
        target.templateKey = source.templateKey;
        target.questionKey = source.questionKey;
        target.intakeSessionId = source.intakeSessionId;
        target.agentSessionKey = source.agentSessionKey;
        target.answerValue = source.answerValue;
        target.answersJson = source.answersJson;
        target.routableId = source.routableId;
        return target;
    }

    private static String outputName(String configuredName, String fallbackName) {
        return String.isBlank(configuredName) ? fallbackName : configuredName.trim();
    }

    private static String outputMode(SmartIntake_Hook__mdt hook) {
        String configuredMode = normalize(hook == null ? null : hook.Output_Mode__c);
        if (!String.isBlank(configuredMode)) {
            if (configuredMode == 'BASIC') {
                return OUTPUT_MODE_BASIC_MAPPING;
            }
            if (configuredMode == 'ADVANCED') {
                return OUTPUT_MODE_ADVANCED_JSON_OVERRIDE;
            }
            return configuredMode;
        }
        return hook != null && !String.isBlank(hook.Flow_Output_Mappings__c)
            ? OUTPUT_MODE_BASIC_MAPPING
            : OUTPUT_MODE_ADVANCED_JSON_OVERRIDE;
    }

    private static Map<String, Object> mappedFlowOutputs(Flow.Interview interview, SmartIntake_Hook__mdt hook) {
        Map<String, Object> mappedValues = new Map<String, Object>();
        for (FlowOutputMapping mapping : parseFlowOutputMappings(hook.Flow_Output_Mappings__c, hook.DeveloperName)) {
            Object output = outputValue(interview, mapping.outputVariableName);
            mappedValues.put(mapping.answerKey, jsonSafeValue(output));
        }
        return mappedValues;
    }

    private static List<FlowInputMapping> parseFlowInputMappings(String mappingsText, String hookName) {
        List<FlowInputMapping> mappings = new List<FlowInputMapping>();
        if (String.isBlank(mappingsText)) {
            return mappings;
        }

        String normalized = mappingsText.replace('\r\n', '\n').replace('\r', '\n').replace(';', '\n');
        for (String rawLine : normalized.split('\n')) {
            String line = rawLine == null ? null : rawLine.trim();
            if (String.isBlank(line) || line.startsWith('#')) {
                continue;
            }

            String delimiter = line.contains('<-') ? '<-' : (line.contains('=') ? '=' : (line.contains(':') ? ':' : null));
            if (String.isBlank(delimiter)) {
                throw configError('HOOK_INPUT_MAPPING_INVALID', 'Hook ' + hookName + ' has an invalid Flow input mapping: ' + line + '. Use FlowInputVariable <- ANSWER_KEY.');
            }
            Integer delimiterIndex = line.indexOf(delimiter);
            String inputVariableName = delimiterIndex < 0 ? null : line.substring(0, delimiterIndex).trim();
            String sourceKey = delimiterIndex < 0 ? null : line.substring(delimiterIndex + delimiter.length()).trim();
            if (String.isBlank(inputVariableName) || String.isBlank(sourceKey)) {
                throw configError('HOOK_INPUT_MAPPING_INVALID', 'Hook ' + hookName + ' has an invalid Flow input mapping: ' + line + '. Use FlowInputVariable <- ANSWER_KEY.');
            }
            if (!Pattern.matches('^[A-Za-z][A-Za-z0-9_]*$', inputVariableName)) {
                throw configError('HOOK_INPUT_VARIABLE_INVALID', 'Hook ' + hookName + ' has invalid Flow input variable name ' + inputVariableName + '.');
            }
            if (!isQuotedLiteral(sourceKey) && !Pattern.matches('^\\$?[A-Za-z][A-Za-z0-9_]*$', sourceKey)) {
                throw configError('HOOK_INPUT_SOURCE_INVALID', 'Hook ' + hookName + ' has invalid Flow input source ' + sourceKey + '. Use a SmartIntake answer key, built-in context key, or quoted literal.');
            }

            FlowInputMapping mapping = new FlowInputMapping();
            mapping.inputVariableName = inputVariableName;
            mapping.sourceKey = sourceKey;
            mappings.add(mapping);
        }
        return mappings;
    }

    private static List<FlowOutputMapping> parseFlowOutputMappings(String mappingsText, String hookName) {
        List<FlowOutputMapping> mappings = new List<FlowOutputMapping>();
        if (String.isBlank(mappingsText)) {
            return mappings;
        }

        String normalized = mappingsText.replace('\r\n', '\n').replace('\r', '\n').replace(';', '\n');
        for (String rawLine : normalized.split('\n')) {
            String line = rawLine == null ? null : rawLine.trim();
            if (String.isBlank(line) || line.startsWith('#')) {
                continue;
            }

            String delimiter = line.contains('->') ? '->' : (line.contains('=') ? '=' : (line.contains(':') ? ':' : null));
            if (String.isBlank(delimiter)) {
                throw configError('HOOK_OUTPUT_MAPPING_INVALID', 'Hook ' + hookName + ' has an invalid Flow output mapping: ' + line + '. Use FlowOutputVariable -> ANSWER_KEY.');
            }
            Integer delimiterIndex = line.indexOf(delimiter);
            String outputVariableName = delimiterIndex < 0 ? null : line.substring(0, delimiterIndex).trim();
            String answerKey = delimiterIndex < 0 ? null : line.substring(delimiterIndex + delimiter.length()).trim();
            if (String.isBlank(outputVariableName) || String.isBlank(answerKey)) {
                throw configError('HOOK_OUTPUT_MAPPING_INVALID', 'Hook ' + hookName + ' has an invalid Flow output mapping: ' + line + '. Use FlowOutputVariable -> ANSWER_KEY.');
            }
            if (!Pattern.matches('^[A-Za-z][A-Za-z0-9_]*$', outputVariableName)) {
                throw configError('HOOK_OUTPUT_VARIABLE_INVALID', 'Hook ' + hookName + ' has invalid Flow output variable name ' + outputVariableName + '.');
            }
            if (!Pattern.matches('^[A-Za-z][A-Za-z0-9_]{1,79}$', answerKey)) {
                throw configError('HOOK_OUTPUT_STORE_KEY_INVALID', 'Hook ' + hookName + ' has invalid Store As key ' + answerKey + '. Use letters, numbers, and underscores, starting with a letter.');
            }

            FlowOutputMapping mapping = new FlowOutputMapping();
            mapping.outputVariableName = outputVariableName;
            mapping.answerKey = answerKey;
            mappings.add(mapping);
        }
        return mappings;
    }

    private static String mergeMappedAnswers(String answersJson, Map<String, Object> mappedAnswers) {
        Map<String, Object> answers = readAnswers(answersJson);
        for (String answerKey : mappedAnswers.keySet()) {
            answers.put(answerKey, mappedAnswers.get(answerKey));
        }
        return JSON.serialize(answers);
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
            throw new SmartIntakeException(
                'EXTENSION',
                'HOOK_OUTPUT_MAPPING_ERROR',
                'I could not store the configured Flow output. Please try again or ask an admin for help.',
                'SmartIntake could not merge Flow output mappings because answers JSON could not be parsed: ' + ex.getMessage()
            );
        }
    }

    private static Object jsonSafeValue(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return JSON.deserializeUntyped(JSON.serialize(value));
        } catch (Exception ex) {
            return String.valueOf(value);
        }
    }

    private static String stringOutput(Flow.Interview interview, String variableName) {
        Object value = outputValue(interview, variableName);
        return value == null ? null : String.valueOf(value);
    }

    private static Boolean booleanOutput(Flow.Interview interview, String variableName, Boolean fallback) {
        Object value = outputValue(interview, variableName);
        if (value == null) {
            return fallback;
        }
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        return String.valueOf(value).trim().toLowerCase() == 'true';
    }

    private static Object outputValue(Flow.Interview interview, String variableName) {
        if (interview == null || String.isBlank(variableName)) {
            return null;
        }
        try {
            return interview.getVariableValue(variableName);
        } catch (Exception ex) {
            return null;
        }
    }

    private static String normalize(String value) {
        return String.isBlank(value) ? null : value.trim().toUpperCase();
    }

    private static SmartIntakeException configError(String code, String adminMessage) {
        return new SmartIntakeException(
            'CONFIGURATION',
            code,
            SmartIntakeMetadataService.message(null, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
            adminMessage
        );
    }
}