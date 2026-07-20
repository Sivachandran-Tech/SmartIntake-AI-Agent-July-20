public with sharing class SmartIntakeMetadataService {
    @TestVisible private static List<SmartIntake_Hook__mdt> hooksForTests;
    @TestVisible private static List<SmartIntake_Condition__mdt> conditionsForTests;

    public class RuntimeMetadata {
        public SmartIntake_Template__mdt template;
        public SmartIntake_Branding_Config__mdt brandingConfig;
        public SmartIntake_Handoff_Config__mdt handoffConfig;
        public List<SmartIntake_Question__mdt> questions = new List<SmartIntake_Question__mdt>();
        public List<SmartIntake_Field_Binding__mdt> bindings = new List<SmartIntake_Field_Binding__mdt>();
        public List<SmartIntake_Option__mdt> options = new List<SmartIntake_Option__mdt>();
        public List<SmartIntake_Validation_Rule__mdt> validationRules = new List<SmartIntake_Validation_Rule__mdt>();
        public List<SmartIntake_Condition__mdt> conditions = new List<SmartIntake_Condition__mdt>();
        public List<SmartIntake_Hook__mdt> hooks = new List<SmartIntake_Hook__mdt>();
        public List<SmartIntake_Matching_Rule__mdt> matchingRules = new List<SmartIntake_Matching_Rule__mdt>();
        public List<SmartIntake_Context_Config__mdt> contextConfigs = new List<SmartIntake_Context_Config__mdt>();
        public List<SmartIntake_File_Config__mdt> fileConfigs = new List<SmartIntake_File_Config__mdt>();
        public Map<String, SmartIntake_Question__mdt> questionsByKey = new Map<String, SmartIntake_Question__mdt>();
        public Map<String, SmartIntake_Field_Binding__mdt> bindingsByQuestionKey = new Map<String, SmartIntake_Field_Binding__mdt>();
        public Map<String, List<SmartIntake_Option__mdt>> optionsByQuestionKey = new Map<String, List<SmartIntake_Option__mdt>>();
        public Map<String, List<SmartIntake_Validation_Rule__mdt>> validationRulesByQuestionKey = new Map<String, List<SmartIntake_Validation_Rule__mdt>>();
        public Map<String, List<SmartIntake_Condition__mdt>> conditionsByTargetQuestionKey = new Map<String, List<SmartIntake_Condition__mdt>>();
        public Map<String, List<SmartIntake_Hook__mdt>> hooksByQuestionAndEvent = new Map<String, List<SmartIntake_Hook__mdt>>();
        public Map<String, SmartIntake_Matching_Rule__mdt> matchingRulesByKey = new Map<String, SmartIntake_Matching_Rule__mdt>();
        public Map<String, SmartIntake_Matching_Rule__mdt> matchingRulesByQuestionKey = new Map<String, SmartIntake_Matching_Rule__mdt>();
        public Map<String, SmartIntake_Context_Config__mdt> contextConfigsByQuestionKey = new Map<String, SmartIntake_Context_Config__mdt>();
        public Map<String, SmartIntake_File_Config__mdt> fileConfigsByQuestionKey = new Map<String, SmartIntake_File_Config__mdt>();
    }

    public static RuntimeMetadata load(String templateKey) {
        if (String.isBlank(templateKey)) {
            throw configError('MISSING_TEMPLATE_KEY', 'No template key was provided.');
        }

        RuntimeMetadata metadata = new RuntimeMetadata();
        List<SmartIntake_Template__mdt> templates = [
            SELECT DeveloperName, Template_Key__c, Template_Name__c, Is_Active__c,
                   Start_Question_Key__c, Requires_Consent__c,
                   Requires_Final_Confirmation__c, Consent_Message__c,
                   Completion_Message__c
            FROM SmartIntake_Template__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            LIMIT 1
        ];
        if (templates.isEmpty()) {
            throw configError('TEMPLATE_NOT_FOUND', 'No active SmartIntake template was found for key ' + templateKey + '.');
        }
        metadata.template = templates[0];

        List<SmartIntake_Branding_Config__mdt> brandingConfigs = [
            SELECT DeveloperName, Template_Key__c, Agent_Display_Name__c, Avatar_Icon_Name__c,
                   Avatar_Image_URL__c, Welcome_Message__c, Is_Active__c
            FROM SmartIntake_Branding_Config__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY DeveloperName ASC
            LIMIT 1
        ];
        if (!brandingConfigs.isEmpty()) {
            metadata.brandingConfig = brandingConfigs[0];
        }

        List<SmartIntake_Handoff_Config__mdt> handoffConfigs = [
            SELECT DeveloperName, Handoff_Config_Key__c, Template_Key__c, Provider_Type__c,
                   Availability_Mode__c, Requires_Consent__c, Consent_Message__c,
                   Trigger_Message__c, Available_Message__c, Offline_Message__c,
                   Declined_Message__c, Queue_Developer_Name__c,
                   Messaging_Channel_Developer_Name__c, Embedded_Service_Deployment_Name__c,
                   Handoff_URL__c, Is_Context_Sharing_Enabled__c,
                   Context_Fields_To_Share__c, Is_Active__c
            FROM SmartIntake_Handoff_Config__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY DeveloperName ASC
            LIMIT 2
        ];
        if (handoffConfigs.size() > 1) {
            throw configError('MULTIPLE_ACTIVE_HANDOFF_CONFIGS', 'Only one active handoff config is supported for template ' + templateKey + '.');
        }
        if (!handoffConfigs.isEmpty()) {
            metadata.handoffConfig = handoffConfigs[0];
        }

        metadata.questions = [
            SELECT DeveloperName, Template_Key__c, Question_Key__c, Question_Text__c,
                   Help_Text__c, Placeholder_Text__c, Question_Order__c, Is_Required__c,
                   Input_Type__c, UI_Control__c, Data_Source_Key__c,
                   Render_Lightning_Input__c, Confirm_AI_Extracted_Answer__c, Is_Active__c
            FROM SmartIntake_Question__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY Question_Order__c ASC, DeveloperName ASC
        ];
        if (metadata.questions.isEmpty()) {
            throw configError('NO_ACTIVE_QUESTIONS', 'Template ' + templateKey + ' has no active questions.');
        }

        for (SmartIntake_Question__mdt question : metadata.questions) {
            if (metadata.questionsByKey.containsKey(question.Question_Key__c)) {
                throw configError('DUPLICATE_QUESTION_KEY', 'Duplicate question key ' + question.Question_Key__c + ' in template ' + templateKey + '.');
            }
            metadata.questionsByKey.put(question.Question_Key__c, question);
        }

        metadata.bindings = [
            SELECT DeveloperName, Template_Key__c, Question_Key__c, Object_API_Name__c,
                   Field_API_Name__c, Is_Active__c
            FROM SmartIntake_Field_Binding__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY DeveloperName ASC
        ];
        for (SmartIntake_Field_Binding__mdt binding : metadata.bindings) {
            metadata.bindingsByQuestionKey.put(binding.Question_Key__c, binding);
        }

        metadata.options = [
            SELECT DeveloperName, Template_Key__c, Question_Key__c, Option_Label__c,
                   Option_Value__c, Sort_Order__c, Is_Active__c
            FROM SmartIntake_Option__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY Question_Key__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        Set<String> optionKeys = new Set<String>();
        for (SmartIntake_Option__mdt optionRecord : metadata.options) {
            if (!metadata.questionsByKey.containsKey(optionRecord.Question_Key__c)) {
                throw configError('OPTION_WITHOUT_QUESTION', 'Option ' + optionRecord.DeveloperName + ' points to missing question ' + optionRecord.Question_Key__c + '.');
            }
            String optionKey = optionRecord.Question_Key__c + ':' + optionRecord.Option_Value__c;
            if (optionKeys.contains(optionKey)) {
                throw configError('DUPLICATE_OPTION_VALUE', 'Question ' + optionRecord.Question_Key__c + ' has duplicate option value ' + optionRecord.Option_Value__c + '.');
            }
            optionKeys.add(optionKey);

            if (!metadata.optionsByQuestionKey.containsKey(optionRecord.Question_Key__c)) {
                metadata.optionsByQuestionKey.put(optionRecord.Question_Key__c, new List<SmartIntake_Option__mdt>());
            }
            metadata.optionsByQuestionKey.get(optionRecord.Question_Key__c).add(optionRecord);
        }

        metadata.validationRules = [
            SELECT DeveloperName, Template_Key__c, Validation_Rule_Key__c, Question_Key__c,
                   Validation_Type__c, Regex__c, Min_Length__c, Max_Length__c,
                   Min_Value__c, Max_Value__c, Min_Date__c, Max_Date__c,
                   Error_Message__c, Sort_Order__c, Is_Active__c
            FROM SmartIntake_Validation_Rule__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY Question_Key__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        Set<String> validationRuleKeys = new Set<String>();
        for (SmartIntake_Validation_Rule__mdt validationRule : metadata.validationRules) {
            if (!metadata.questionsByKey.containsKey(validationRule.Question_Key__c)) {
                throw configError('VALIDATION_RULE_WITHOUT_QUESTION', 'Validation rule ' + validationRule.DeveloperName + ' points to missing question ' + validationRule.Question_Key__c + '.');
            }
            if (!String.isBlank(validationRule.Validation_Rule_Key__c)) {
                if (validationRuleKeys.contains(validationRule.Validation_Rule_Key__c)) {
                    throw configError('DUPLICATE_VALIDATION_RULE_KEY', 'Duplicate validation rule key ' + validationRule.Validation_Rule_Key__c + ' in template ' + templateKey + '.');
                }
                validationRuleKeys.add(validationRule.Validation_Rule_Key__c);
            }
            if (!metadata.validationRulesByQuestionKey.containsKey(validationRule.Question_Key__c)) {
                metadata.validationRulesByQuestionKey.put(validationRule.Question_Key__c, new List<SmartIntake_Validation_Rule__mdt>());
            }
            metadata.validationRulesByQuestionKey.get(validationRule.Question_Key__c).add(validationRule);
        }

        metadata.conditions = [
            SELECT DeveloperName, Template_Key__c, Condition_Key__c, Source_Question_Key__c,
                   Operator__c, Compare_Value__c, Action__c, Target_Question_Key__c,
                   Condition_Group_Key__c, Condition_Logic__c, Condition_Number__c,
                   Custom_Logic__c, User_Message__c, Sort_Order__c, Is_Active__c
            FROM SmartIntake_Condition__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY Target_Question_Key__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        if (Test.isRunningTest() && conditionsForTests != null) {
            metadata.conditions = conditionsForTests;
        }
        Set<String> conditionKeys = new Set<String>();
        for (SmartIntake_Condition__mdt condition : metadata.conditions) {
            if (!metadata.questionsByKey.containsKey(condition.Target_Question_Key__c)) {
                throw configError('CONDITION_WITHOUT_TARGET_QUESTION', 'Condition ' + condition.DeveloperName + ' points to missing target question ' + condition.Target_Question_Key__c + '.');
            }
            if (!String.isBlank(condition.Condition_Key__c)) {
                if (conditionKeys.contains(condition.Condition_Key__c)) {
                    throw configError('DUPLICATE_CONDITION_KEY', 'Duplicate condition key ' + condition.Condition_Key__c + ' in template ' + templateKey + '.');
                }
                conditionKeys.add(condition.Condition_Key__c);
            }
            if (!metadata.conditionsByTargetQuestionKey.containsKey(condition.Target_Question_Key__c)) {
                metadata.conditionsByTargetQuestionKey.put(condition.Target_Question_Key__c, new List<SmartIntake_Condition__mdt>());
            }
            metadata.conditionsByTargetQuestionKey.get(condition.Target_Question_Key__c).add(condition);
        }

        metadata.hooks = [
            SELECT DeveloperName, Template_Key__c, Hook_Key__c, Question_Key__c,
                   Event__c, Handler_Type__c, Flow_API_Name__c,
                   Success_Output_Variable__c, User_Message_Output_Variable__c,
                   Next_Question_Output_Variable__c, Answers_JSON_Output_Variable__c,
                   Block_Continue_Output_Variable__c, Output_Mode__c, Flow_Input_Mappings__c,
                   Flow_Output_Mappings__c,
                   Sort_Order__c, Is_Active__c
            FROM SmartIntake_Hook__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY Question_Key__c ASC, Event__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        if (Test.isRunningTest() && hooksForTests != null) {
            metadata.hooks.addAll(hooksForTests);
        }
        Set<String> hookKeys = new Set<String>();
        for (SmartIntake_Hook__mdt hook : metadata.hooks) {
            if (!metadata.questionsByKey.containsKey(hook.Question_Key__c)) {
                throw configError('HOOK_WITHOUT_QUESTION', 'Hook ' + hook.DeveloperName + ' points to missing question ' + hook.Question_Key__c + '.');
            }
            if (!String.isBlank(hook.Hook_Key__c)) {
                if (hookKeys.contains(hook.Hook_Key__c)) {
                    throw configError('DUPLICATE_HOOK_KEY', 'Duplicate hook key ' + hook.Hook_Key__c + ' in template ' + templateKey + '.');
                }
                hookKeys.add(hook.Hook_Key__c);
            }
            String hookMapKey = hook.Question_Key__c + ':' + normalize(hook.Event__c);
            if (!metadata.hooksByQuestionAndEvent.containsKey(hookMapKey)) {
                metadata.hooksByQuestionAndEvent.put(hookMapKey, new List<SmartIntake_Hook__mdt>());
            }
            metadata.hooksByQuestionAndEvent.get(hookMapKey).add(hook);
        }

        metadata.matchingRules = [
            SELECT DeveloperName, Template_Key__c, Matching_Rule_Key__c, Question_Key__c,
                   Object_API_Name__c, Field_API_Name__c, Display_Field_API_Name__c,
                   Match_Type__c, Is_Active__c
            FROM SmartIntake_Matching_Rule__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY DeveloperName ASC
        ];
        for (SmartIntake_Matching_Rule__mdt matchingRule : metadata.matchingRules) {
            if (!metadata.questionsByKey.containsKey(matchingRule.Question_Key__c)) {
                throw configError('MATCHING_RULE_WITHOUT_QUESTION', 'Matching rule ' + matchingRule.DeveloperName + ' points to missing question ' + matchingRule.Question_Key__c + '.');
            }
            if (metadata.matchingRulesByKey.containsKey(matchingRule.Matching_Rule_Key__c)) {
                throw configError('DUPLICATE_MATCHING_RULE_KEY', 'Duplicate matching rule key ' + matchingRule.Matching_Rule_Key__c + ' in template ' + templateKey + '.');
            }
            metadata.matchingRulesByKey.put(matchingRule.Matching_Rule_Key__c, matchingRule);
            metadata.matchingRulesByQuestionKey.put(matchingRule.Question_Key__c, matchingRule);
        }

        metadata.contextConfigs = [
            SELECT DeveloperName, Template_Key__c, Context_Config_Key__c, Question_Key__c,
                   Context_Type__c, Context_Message__c, Object_API_Name__c,
                   Filter_Field_API_Name__c, Filter_Source_Question_Key__c,
                   Display_Field_API_Name__c, Allowed_Actions__c, Max_Records__c,
                   Is_Active__c
            FROM SmartIntake_Context_Config__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY DeveloperName ASC
        ];
        for (SmartIntake_Context_Config__mdt contextConfig : metadata.contextConfigs) {
            if (!metadata.questionsByKey.containsKey(contextConfig.Question_Key__c)) {
                throw configError('CONTEXT_CONFIG_WITHOUT_QUESTION', 'Context config ' + contextConfig.DeveloperName + ' points to missing question ' + contextConfig.Question_Key__c + '.');
            }
            if (!metadata.questionsByKey.containsKey(contextConfig.Filter_Source_Question_Key__c)) {
                throw configError('CONTEXT_CONFIG_WITHOUT_FILTER_SOURCE', 'Context config ' + contextConfig.DeveloperName + ' points to missing filter source question ' + contextConfig.Filter_Source_Question_Key__c + '.');
            }
            if (metadata.contextConfigsByQuestionKey.containsKey(contextConfig.Question_Key__c)) {
                throw configError('DUPLICATE_CONTEXT_QUESTION', 'Only one active context config is supported per question. Duplicate found for ' + contextConfig.Question_Key__c + '.');
            }
            metadata.contextConfigsByQuestionKey.put(contextConfig.Question_Key__c, contextConfig);
        }

        metadata.fileConfigs = [
            SELECT DeveloperName, File_Config_Key__c, Template_Key__c, Question_Key__c,
                   Accepted_File_Types__c, Allow_Multiple__c, Max_File_Count__c,
                   Link_To_Final_Record__c, Share_Type__c, Visibility__c,
                   Is_Active__c
            FROM SmartIntake_File_Config__mdt
            WHERE Template_Key__c = :templateKey AND Is_Active__c = true
            ORDER BY DeveloperName ASC
        ];
        Set<String> fileConfigKeys = new Set<String>();
        for (SmartIntake_File_Config__mdt fileConfig : metadata.fileConfigs) {
            if (!metadata.questionsByKey.containsKey(fileConfig.Question_Key__c)) {
                throw configError('FILE_CONFIG_WITHOUT_QUESTION', 'File config ' + fileConfig.DeveloperName + ' points to missing question ' + fileConfig.Question_Key__c + '.');
            }
            if (!String.isBlank(fileConfig.File_Config_Key__c)) {
                if (fileConfigKeys.contains(fileConfig.File_Config_Key__c)) {
                    throw configError('DUPLICATE_FILE_CONFIG_KEY', 'Duplicate file config key ' + fileConfig.File_Config_Key__c + ' in template ' + templateKey + '.');
                }
                fileConfigKeys.add(fileConfig.File_Config_Key__c);
            }
            if (metadata.fileConfigsByQuestionKey.containsKey(fileConfig.Question_Key__c)) {
                throw configError('DUPLICATE_FILE_CONFIG_QUESTION', 'Only one active file config is supported per question. Duplicate found for ' + fileConfig.Question_Key__c + '.');
            }
            metadata.fileConfigsByQuestionKey.put(fileConfig.Question_Key__c, fileConfig);
        }

        return metadata;
    }

    public static String message(String templateKey, String messageKey, String fallback) {
        if (String.isBlank(messageKey)) {
            return fallback;
        }

        List<SmartIntake_Message__mdt> templateMessages = [
            SELECT Message_Text__c
            FROM SmartIntake_Message__mdt
            WHERE Message_Key__c = :messageKey
              AND Template_Key__c = :templateKey
              AND Is_Active__c = true
            LIMIT 1
        ];
        if (!templateMessages.isEmpty()) {
            return templateMessages[0].Message_Text__c;
        }

        List<SmartIntake_Message__mdt> globalMessages = [
            SELECT Message_Text__c
            FROM SmartIntake_Message__mdt
            WHERE Message_Key__c = :messageKey
              AND Template_Key__c = 'GLOBAL'
              AND Is_Active__c = true
            LIMIT 1
        ];
        if (!globalMessages.isEmpty()) {
            return globalMessages[0].Message_Text__c;
        }

        return fallback;
    }

    @TestVisible
    private static void setHooksForTest(List<SmartIntake_Hook__mdt> hooks) {
        hooksForTests = hooks;
    }

    private static SmartIntakeException configError(String code, String adminMessage) {
        return new SmartIntakeException(
            'CONFIGURATION',
            code,
            message(null, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
            adminMessage
        );
    }

    private static String normalize(String value) {
        return String.isBlank(value) ? null : value.trim().toUpperCase();
    }
}