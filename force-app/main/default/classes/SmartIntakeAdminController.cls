public with sharing class SmartIntakeAdminController {
    private static final Integer CUSTOM_METADATA_LABEL_MAX_LENGTH = 40;
    private static final String SEVERITY_ERROR = 'ERROR';
    private static final String SEVERITY_WARNING = 'WARNING';
    private static final String SEVERITY_INFO = 'INFO';
    private static final String READINESS_READY = 'READY';
    private static final String READINESS_WARNING = 'WARNING';
    private static final String READINESS_BLOCKED = 'BLOCKED';
    private static final String READINESS_MANUAL = 'MANUAL';
    private static final Set<String> OPTION_INPUT_TYPES = new Set<String>{ 'PICKLIST', 'RADIO', 'MULTI_SELECT' };
    private static final Set<String> SUPPORTED_CONTEXT_TYPES = new Set<String>{ 'MATCHED_RECORDS' };
    private static final Set<String> SUPPORTED_MATCH_TYPES = new Set<String>{ 'EXACT' };
    private static final Set<String> SUPPORTED_CONDITION_ACTIONS = new Set<String>{ 'SHOW_WHEN', 'HIDE_WHEN', 'BLOCK_WHEN' };
    private static final Set<String> SUPPORTED_CONDITION_LOGICS = new Set<String>{ 'ALL', 'ANY', 'CUSTOM' };
    private static final Set<String> SUPPORTED_HOOK_EVENTS = new Set<String>{ 'AFTER_ANSWER' };
    private static final Set<String> SUPPORTED_HOOK_HANDLER_TYPES = new Set<String>{ 'FLOW' };
    private static final Set<String> SUPPORTED_HOOK_OUTPUT_MODES = new Set<String>{ 'BASIC_OUTPUT_MAPPING', 'ADVANCED_JSON_OVERRIDE' };
    private static final Set<String> FILE_INPUT_TYPES = new Set<String>{ 'FILE', 'IMAGE', 'PDF' };
    private static final Set<String> SAVE_SYSTEM_FIELDS = new Set<String>{
        'Template_Key__c',
        'Status__c',
        'Session_Id__c',
        'Answers_JSON__c'
    };
    private static final Set<String> BOOLEAN_BUILDER_METADATA_FIELDS = new Set<String>{
        'Allow_Multiple__c',
        'Confirm_AI_Extracted_Answer__c',
        'Is_Active__c',
        'Is_Required__c',
        'Render_Lightning_Input__c',
        'Is_Context_Sharing_Enabled__c',
        'Link_To_Final_Record__c',
        'Requires_Consent__c',
        'Requires_Final_Confirmation__c'
    };
    private static final Set<String> DECIMAL_BUILDER_METADATA_FIELDS = new Set<String>{
        'Max_File_Count__c',
        'Max_Length__c',
        'Max_Records__c',
        'Max_Value__c',
        'Min_Length__c',
        'Min_Value__c',
        'Question_Order__c',
        'Sort_Order__c'
    };
    private static final Set<String> DATE_BUILDER_METADATA_FIELDS = new Set<String>{
        'Max_Date__c',
        'Min_Date__c'
    };
    private static final Set<String> SUPPORTED_FILE_SHARE_TYPES = new Set<String>{ 'V', 'C', 'I' };
    private static final Set<String> SUPPORTED_FILE_VISIBILITIES = new Set<String>{ 'AllUsers', 'InternalUsers', 'SharedUsers' };
    private static final Set<String> SUPPORTED_HANDOFF_PROVIDER_TYPES = new Set<String>{ 'ENHANCED_OMNI', 'ENHANCED_CHAT_V2', 'EXTERNAL_URL' };
    private static final Set<String> SUPPORTED_HANDOFF_AVAILABILITY_MODES = new Set<String>{ 'CONFIGURED', 'ALWAYS_AVAILABLE', 'ALWAYS_OFFLINE' };
    private static final Set<String> SUPPORTED_DEACTIVATE_METADATA_TYPES = new Set<String>{
        'SmartIntake_Branding_Config__mdt',
        'SmartIntake_Condition__mdt',
        'SmartIntake_Context_Config__mdt',
        'SmartIntake_Control__mdt',
        'SmartIntake_Field_Binding__mdt',
        'SmartIntake_File_Config__mdt',
        'SmartIntake_Handoff_Config__mdt',
        'SmartIntake_Hook__mdt',
        'SmartIntake_Matching_Rule__mdt',
        'SmartIntake_Message__mdt',
        'SmartIntake_Option__mdt',
        'SmartIntake_Question__mdt',
        'SmartIntake_Template__mdt',
        'SmartIntake_Template_Route__mdt',
        'SmartIntake_Validation_Rule__mdt'
    };
    private static final Set<String> CONDITION_OPERATORS_REQUIRING_COMPARE_VALUE = new Set<String>{
        'EQUALS',
        'NOT_EQUALS',
        'IN',
        'NOT_IN',
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
    private static final Set<String> TEXT_VALIDATION_INPUT_TYPES = new Set<String>{ 'TEXT', 'LONG_TEXT', 'EMAIL', 'PHONE', 'URL', 'PICKLIST', 'RADIO', 'MULTI_SELECT' };
    private static final Set<String> NUMERIC_VALIDATION_INPUT_TYPES = new Set<String>{ 'NUMBER', 'CURRENCY' };
    private static final Set<String> DATE_VALIDATION_INPUT_TYPES = new Set<String>{ 'DATE' };
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
    private static final Set<String> SUPPORTED_ADMIN_CONFIG_TYPES = new Set<String>{
        'BRANDING',
        'MESSAGE',
        'HANDOFF',
        'MATCHING_RULE',
        'CONTEXT_CONFIG',
        'VALIDATION_RULE',
        'CONDITION',
        'HOOK',
        'FILE_CONFIG',
        'FIELD_BINDING'
    };
    private static final String CONTROL_REGISTRY_FILE_PATH = 'lwc/smartIntakeControlRegistry/smartIntakeControlRegistry.js';
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
    @TestVisible private static Boolean forceMetadataPermissionDeniedForTests = false;

    @AuraEnabled(cacheable=true)
    public static List<TemplateSummary> listTemplates() {
        List<TemplateSummary> summaries = new List<TemplateSummary>();
        for (SmartIntake_Template__mdt template : [
            SELECT Template_Key__c, Template_Name__c, Is_Active__c, Start_Question_Key__c
            FROM SmartIntake_Template__mdt
            ORDER BY Template_Name__c ASC, DeveloperName ASC
        ]) {
            TemplateSummary summary = new TemplateSummary();
            summary.templateKey = template.Template_Key__c;
            summary.templateName = template.Template_Name__c;
            summary.isActive = template.Is_Active__c;
            summary.startQuestionKey = template.Start_Question_Key__c;
            summaries.add(summary);
        }
        return summaries;
    }

    @AuraEnabled(cacheable=true)
    public static List<ControlDefinition> listSupportedControls() {
        return new List<ControlDefinition>{
            control('TEXT', 'Text', 'lightning-input', 'text', 'String, Text Area, Email, Phone, URL, Picklist', false, false, false, 'Single-line text answers.'),
            control('LONG_TEXT', 'Long Text', 'lightning-textarea', '', 'Text Area, String', false, false, false, 'Multi-line freeform answers.'),
            control('EMAIL', 'Email', 'lightning-input', 'email', 'Email, String', false, false, false, 'Email format input with metadata validation support.'),
            control('PHONE', 'Phone', 'lightning-input', 'tel', 'Phone, String', false, false, false, 'Phone input stored only after Apex validation and FLS checks.'),
            control('URL', 'URL', 'lightning-input', 'url', 'URL, String', false, false, false, 'URL input for website-style answers.'),
            control('NUMBER', 'Number', 'lightning-input', 'number', 'Integer, Double, Currency, Percent', false, false, false, 'Numeric answers with min and max validation support.'),
            control('CURRENCY', 'Currency', 'lightning-input', 'number', 'Currency, Double, Integer, Percent', false, false, false, 'Currency-like numeric answers; currency display is handled by admin labels.'),
            control('DATE', 'Date', 'lightning-input', 'date', 'Date', false, false, false, 'Date picker answer with min and max date validation support.'),
            control('DATETIME', 'Date/Time', 'lightning-input', 'datetime', 'DateTime', false, false, false, 'Date/time answer for DateTime target fields.'),
            control('BOOLEAN', 'Checkbox', 'lightning-input', 'checkbox', 'Boolean', false, false, false, 'Yes/no answers and consent-style questions.'),
            control('PICKLIST', 'Picklist', 'lightning-combobox', '', 'Picklist, String', true, false, false, 'Single-select options configured with SmartIntake Option metadata.'),
            control('RADIO', 'Radio', 'lightning-radio-group', '', 'Picklist, String', true, false, false, 'Single-select options rendered as radio buttons.'),
            control('MULTI_SELECT', 'Multi Select', 'lightning-checkbox-group', '', 'MultiPicklist, Text Area, String', true, true, false, 'Multi-value answers stored as semicolon-delimited values for save mapping.'),
            control('FILE', 'File Upload', 'lightning-file-upload', '', 'Salesforce Files only', false, true, true, 'Uploads are linked as Salesforce Files, not direct field bindings.'),
            control('IMAGE', 'Image Upload', 'lightning-file-upload', '', 'Salesforce Files only', false, true, true, 'Use File Config metadata to restrict accepted image extensions.'),
            control('PDF', 'PDF Upload', 'lightning-file-upload', '', 'Salesforce Files only', false, true, true, 'Use File Config metadata to restrict accepted PDF extensions.')
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<MetadataChoice> listCustomRenderers() {
        List<MetadataChoice> choices = new List<MetadataChoice>();
        for (SmartIntake_Control__mdt control : [
            SELECT MasterLabel, Control_Key__c, Component_Name__c, Aliases__c
            FROM SmartIntake_Control__mdt
            WHERE Is_Active__c = true
            ORDER BY MasterLabel ASC, DeveloperName ASC
        ]) {
            String rendererValue = String.isBlank(control.Component_Name__c)
                ? control.Control_Key__c
                : control.Component_Name__c;
            if (String.isBlank(rendererValue)) {
                continue;
            }
            choices.add(metadataChoice(
                metadataLabel(control.MasterLabel, rendererValue) + ' (' + rendererValue + ')',
                rendererValue,
                String.isBlank(control.Aliases__c) ? control.Control_Key__c : control.Aliases__c,
                true
            ));
        }
        choices.sort();
        return choices;
    }

    @AuraEnabled(cacheable=true)
    public static List<MetadataChoice> listInvocableFlows() {
        List<MetadataChoice> choices = new List<MetadataChoice>();
        for (FlowDefinitionView flowDefinition : [
            SELECT ApiName, Label, ProcessType, IsActive, ActiveVersionId
            FROM FlowDefinitionView
            WHERE IsActive = true
            AND ProcessType = 'AutoLaunchedFlow'
            AND ActiveVersionId != null
            ORDER BY Label ASC, ApiName ASC
            LIMIT 200
        ]) {
            if (String.isBlank(flowDefinition.ApiName)) {
                continue;
            }
            choices.add(metadataChoice(
                metadataLabel(flowDefinition.Label, flowDefinition.ApiName) + ' (' + flowDefinition.ApiName + ')',
                flowDefinition.ApiName,
                'Active autolaunched Flow',
                true
            ));
        }
        choices.sort();
        return choices;
    }

    @AuraEnabled(cacheable=true)
    public static List<FlowVariableChoice> listFlowVariables(String flowApiName) {
        List<FlowVariableChoice> choices = new List<FlowVariableChoice>();
        if (String.isBlank(flowApiName) || !isValidApiName(flowApiName)) {
            return choices;
        }

        List<FlowDefinitionView> flowDefinitions = [
            SELECT ApiName, ActiveVersionId
            FROM FlowDefinitionView
            WHERE ApiName = :flowApiName
            AND IsActive = true
            AND ProcessType = 'AutoLaunchedFlow'
            AND ActiveVersionId != null
            LIMIT 1
        ];
        if (flowDefinitions.isEmpty()) {
            return choices;
        }

        String activeVersionId = String.valueOf(flowDefinitions[0].ActiveVersionId);
        for (FlowVariableView variable : [
            SELECT DurableId, ApiName, Description, DataType, IsInput, IsOutput, IsCollection, ObjectType
            FROM FlowVariableView
            WHERE FlowVersionViewId = :activeVersionId
            ORDER BY ApiName ASC
        ]) {
            if (String.isBlank(variable.ApiName)) {
                continue;
            }
            FlowVariableChoice choice = new FlowVariableChoice();
            choice.apiName = variable.ApiName;
            choice.label = variable.ApiName;
            choice.value = variable.ApiName;
            choice.description = variable.Description;
            choice.dataType = variable.DataType;
            choice.objectType = variable.ObjectType;
            choice.isInput = variable.IsInput;
            choice.isOutput = variable.IsOutput;
            choice.isCollection = variable.IsCollection;
            choice.detail = flowVariableDetail(variable);
            choices.add(choice);
        }
        return choices;
    }

    @AuraEnabled(cacheable=true)
    public static List<MetadataChoice> listBindableObjects() {
        List<MetadataChoice> choices = new List<MetadataChoice>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String objectApiName : globalDescribe.keySet()) {
            Schema.DescribeSObjectResult objectDescribe = globalDescribe.get(objectApiName).getDescribe();
            if (!objectDescribe.isCreateable() || objectDescribe.isDeprecatedAndHidden()) {
                continue;
            }
            String objectName = objectDescribe.getName();
            if (objectName.endsWith('__mdt')) {
                continue;
            }
            choices.add(metadataChoice(
                objectDescribe.getLabel() + ' (' + objectName + ')',
                objectName,
                objectName,
                true
            ));
        }
        choices.sort();
        return choices;
    }

    @AuraEnabled(cacheable=true)
    public static List<MetadataChoice> listBindableFields(String objectApiName, String inputType) {
        List<MetadataChoice> choices = new List<MetadataChoice>();
        if (String.isBlank(objectApiName)) {
            return choices;
        }
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType == null) {
            return choices;
        }
        String normalizedInputType = normalize(inputType);
        Map<String, Schema.SObjectField> fieldsByName = objectType.getDescribe().fields.getMap();
        for (String fieldApiName : fieldsByName.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldsByName.get(fieldApiName).getDescribe();
            if (!fieldDescribe.isCreateable() ||
                fieldDescribe.isCalculated() ||
                fieldDescribe.isAutoNumber() ||
                fieldDescribe.isDeprecatedAndHidden()) {
                continue;
            }
            Boolean compatible = String.isBlank(normalizedInputType) ||
                isCompatibleFieldType(normalizedInputType, fieldDescribe.getType());
            String label = fieldDescribe.getLabel() + ' (' + fieldDescribe.getName() + ')';
            if (!compatible) {
                label += ' - may not match ' + normalizedInputType;
            }
            choices.add(fieldChoice(
                label,
                fieldDescribe.getName(),
                fieldChoiceDetail(fieldDescribe),
                compatible,
                fieldDescribe
            ));
        }
        choices.sort();
        return choices;
    }

    @AuraEnabled(cacheable=true)
    public static List<MetadataChoice> listActivePicklistValues(String objectApiName, String fieldApiName) {
        List<MetadataChoice> choices = new List<MetadataChoice>();
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            return choices;
        }
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType == null) {
            return choices;
        }
        Schema.SObjectField fieldToken = objectType.getDescribe().fields.getMap().get(fieldApiName);
        if (fieldToken == null) {
            return choices;
        }
        Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
        if (fieldDescribe.getType() != Schema.DisplayType.Picklist &&
            fieldDescribe.getType() != Schema.DisplayType.MultiPicklist) {
            return choices;
        }
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (!entry.isActive()) {
                continue;
            }
            choices.add(metadataChoice(
                entry.getLabel(),
                entry.getValue(),
                'API value: ' + entry.getValue(),
                true
            ));
        }
        return choices;
    }

    @AuraEnabled(cacheable=false)
    public static DeploymentStatus getMetadataDeploymentStatus(String deploymentJobId) {
        return SmartIntakeMetadataDeployCallback.getStatus(deploymentJobId);
    }

    @AuraEnabled(cacheable=true)
    public static ReadinessResult getTemplateReadiness(String templateKey) {
        ReadinessResult result = new ReadinessResult();
        result.templateKey = templateKey;
        result.items = new List<ReadinessItem>();

        if (String.isBlank(templateKey)) {
            addReadinessItem(result, 'template', 'Template', READINESS_BLOCKED, 'Select a SmartIntake template.');
            return finishReadiness(result);
        }

        ValidationResult validation = validateTemplate(templateKey);
        result.templateName = validation.templateName;
        if (validation.errorCount > 0) {
            addReadinessItem(
                result,
                'metadata',
                'Metadata Validation',
                READINESS_BLOCKED,
                'Fix ' + validation.errorCount + ' validation error(s) before this template can run.'
            );
        } else if (validation.warningCount > 0) {
            addReadinessItem(
                result,
                'metadata',
                'Metadata Validation',
                READINESS_WARNING,
                'Template can run, but review ' + validation.warningCount + ' warning(s).'
            );
        } else {
            addReadinessItem(result, 'metadata', 'Metadata Validation', READINESS_READY, 'Template metadata is valid.');
        }

        addSaveTargetReadiness(result, validation);
        addSubmissionReadiness(result);
        addFileReadiness(result, templateKey);
        addBrandingReadiness(result, templateKey);
        addMessageReadiness(result, templateKey);
        addHandoffReadiness(result, templateKey);
        addReadinessItem(
            result,
            'agentforce',
            'Agentforce Agent',
            READINESS_MANUAL,
            'Confirm Agentforce is enabled, the SmartIntake agent exists, and only approved SmartIntake actions are assigned to its topic.'
        );

        return finishReadiness(result);
    }

    @AuraEnabled
    public static BuilderPlan previewQuestionDraft(BuilderQuestionDraft draft) {
        BuilderPlan plan = new BuilderPlan();
        plan.records = new List<BuilderRecord>();
        plan.issues = new List<ValidationIssue>();
        plan.metadataWriteStatus = 'PLANNED_ONLY';
        plan.metadataWriteNotice = 'This preview validates the draft and shows the Custom Metadata records to create or update. Actual Metadata API deployment must run only after admin confirmation and metadata edit access checks.';

        if (draft == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'DRAFT_MISSING', 'Builder', null, 'Enter question details before creating a metadata plan.');
            return finishBuilderPlan(plan);
        }

        plan.templateKey = trimToNull(draft.templateKey);
        plan.questionKey = trimToNull(draft.questionKey);
        String inputType = normalize(draft.inputType);
        String uiControl = String.isBlank(draft.uiControl) ? defaultUiControl(inputType) : draft.uiControl.trim();

        validateQuestionDraftBasics(plan, draft, inputType);
        Decimal questionOrder = draft.questionOrder == null ? nextQuestionOrder(plan.templateKey) : draft.questionOrder;

        String questionRecordName = existingMetadataRecordName(
            SmartIntake_Question__mdt.SObjectType,
            plan.templateKey,
            'Question_Key__c',
            plan.questionKey,
            metadataRecordName(plan.templateKey, plan.questionKey)
        );
        BuilderRecord questionRecord = newBuilderRecord(
            'SmartIntake_Question__mdt',
            customMetadataFullName(SmartIntake_Question__mdt.SObjectType, questionRecordName),
            'Question'
        );
        questionRecord.metadataLabel = metadataLabel(draft.questionText, plan.questionKey);
        addBuilderField(questionRecord, 'Template_Key__c', plan.templateKey);
        addBuilderField(questionRecord, 'Question_Key__c', plan.questionKey);
        addBuilderField(questionRecord, 'Question_Text__c', draft.questionText);
        addBuilderField(questionRecord, 'Help_Text__c', draft.helpText);
        addBuilderField(questionRecord, 'Placeholder_Text__c', draft.placeholderText);
        addBuilderField(questionRecord, 'Question_Order__c', questionOrder);
        addBuilderField(questionRecord, 'Is_Required__c', draft.isRequired == true);
        addBuilderField(questionRecord, 'Confirm_AI_Extracted_Answer__c', draft.confirmAiExtractedAnswer == true);
        addBuilderField(questionRecord, 'Input_Type__c', inputType);
        addBuilderField(questionRecord, 'UI_Control__c', uiControl);
        addBuilderField(questionRecord, 'Render_Lightning_Input__c', draft.renderLightningInput == true);
        addBuilderField(questionRecord, 'Data_Source_Key__c', draft.dataSourceKey);
        addBuilderField(questionRecord, 'Is_Active__c', true);
        plan.records.add(questionRecord);

        addOptionPlanRecords(plan, draft, inputType, questionRecordName);
        addBindingPlanRecord(plan, draft, inputType, questionRecordName);
        addFileConfigPlanRecord(plan, draft, inputType, questionRecordName);

        return finishBuilderPlan(plan);
    }

    @AuraEnabled
    public static BuilderPlan previewQuestionDraftJson(String draftJson) {
        return previewQuestionDraft(questionDraftFromJson(draftJson));
    }

    @AuraEnabled
    public static BuilderPlan deployQuestionDraft(BuilderQuestionDraft draft, Boolean confirmed) {
        BuilderPlan plan = previewQuestionDraft(draft);
        return deployMetadataPlan(plan, confirmed, 'Question Builder', plan.questionKey);
    }

    @AuraEnabled
    public static BuilderPlan deployQuestionDraftJson(String draftJson, Boolean confirmed) {
        return deployQuestionDraft(questionDraftFromJson(draftJson), confirmed);
    }

    @AuraEnabled
    public static BuilderPlan previewTemplateDraft(TemplateDraft draft) {
        BuilderPlan plan = newBuilderPlan();
        plan.metadataWriteNotice = 'This preview validates the template starter and shows the Custom Metadata records to create. Actual Metadata API deployment must run only after admin confirmation and metadata edit access checks.';

        if (draft == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'TEMPLATE_DRAFT_MISSING', 'Setup Wizard', null, 'Enter template details before creating a metadata plan.');
            return finishBuilderPlan(plan);
        }

        plan.templateKey = normalizeTemplateKey(draft.templateKey);
        validateTemplateDraftBasics(plan, draft);

        String templateRecordName = standaloneMetadataRecordName(plan.templateKey);
        BuilderRecord templateRecord = newBuilderRecord(
            'SmartIntake_Template__mdt',
            customMetadataFullName(SmartIntake_Template__mdt.SObjectType, templateRecordName),
            'Template'
        );
        templateRecord.metadataLabel = metadataLabel(draft.templateName, plan.templateKey);
        addBuilderField(templateRecord, 'Template_Key__c', plan.templateKey);
        addBuilderField(templateRecord, 'Template_Name__c', draft.templateName);
        addBuilderField(templateRecord, 'Is_Active__c', draft.isActive != false);
        addBuilderField(templateRecord, 'Start_Question_Key__c', draft.startQuestionKey);
        addBuilderField(templateRecord, 'Requires_Consent__c', draft.requiresConsent == true);
        addBuilderField(templateRecord, 'Requires_Final_Confirmation__c', draft.requiresFinalConfirmation != false);
        addBuilderField(templateRecord, 'Consent_Message__c', draft.consentMessage);
        addBuilderField(templateRecord, 'Completion_Message__c', defaultCompletionMessage(draft));
        plan.records.add(templateRecord);

        if (draft.createBranding == true) {
            addBrandingStarterRecord(plan, draft);
        }

        return finishBuilderPlan(plan);
    }

    @AuraEnabled
    public static BuilderPlan previewTemplateDraftJson(String draftJson) {
        return previewTemplateDraft(templateDraftFromJson(draftJson));
    }

    @AuraEnabled
    public static BuilderPlan deployTemplateDraft(TemplateDraft draft, Boolean confirmed) {
        BuilderPlan plan = previewTemplateDraft(draft);
        return deployMetadataPlan(plan, confirmed, 'Setup Wizard', plan.templateKey);
    }

    @AuraEnabled
    public static BuilderPlan deployTemplateDraftJson(String draftJson, Boolean confirmed) {
        return deployTemplateDraft(templateDraftFromJson(draftJson), confirmed);
    }

    @AuraEnabled
    public static BuilderPlan previewAdminConfigDraft(AdminConfigDraft draft) {
        BuilderPlan plan = newBuilderPlan();
        plan.metadataWriteNotice = 'This preview validates the admin configuration and shows the Custom Metadata record to create or update. Deployment runs only after admin confirmation and metadata edit access checks.';

        if (draft == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'ADMIN_CONFIG_DRAFT_MISSING', 'Admin Config Builder', null, 'Enter configuration details before creating a metadata plan.');
            return finishBuilderPlan(plan);
        }

        plan.templateKey = trimToNull(draft.templateKey);
        plan.configType = normalize(draft.configType);
        plan.configKey = trimToNull(draft.configKey);
        plan.questionKey = plan.configKey;

        validateAdminConfigDraftBasics(plan, draft);
        if (!SUPPORTED_ADMIN_CONFIG_TYPES.contains(plan.configType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'ADMIN_CONFIG_TYPE_UNSUPPORTED', 'Admin Config Builder', plan.configType, 'Select a supported SmartIntake configuration type.');
            return finishBuilderPlan(plan);
        }

        if (plan.configType == 'BRANDING') {
            addBrandingConfigRecord(plan, draft);
        } else if (plan.configType == 'MESSAGE') {
            addMessageConfigRecord(plan, draft);
        } else if (plan.configType == 'HANDOFF') {
            addHandoffConfigRecord(plan, draft);
        } else if (plan.configType == 'MATCHING_RULE') {
            addMatchingRuleConfigRecord(plan, draft);
        } else if (plan.configType == 'CONTEXT_CONFIG') {
            addContextConfigRecord(plan, draft);
        } else if (plan.configType == 'VALIDATION_RULE') {
            addValidationRuleConfigRecord(plan, draft);
        } else if (plan.configType == 'CONDITION') {
            addConditionConfigRecord(plan, draft);
        } else if (plan.configType == 'HOOK') {
            addHookConfigRecord(plan, draft);
        } else if (plan.configType == 'FILE_CONFIG') {
            addStandaloneFileConfigRecord(plan, draft);
        } else if (plan.configType == 'FIELD_BINDING') {
            addFieldBindingConfigRecord(plan, draft);
        }

        addExistingConfigUpdateNotice(plan);
        return finishBuilderPlan(plan);
    }

    @AuraEnabled
    public static BuilderPlan deployAdminConfigDraft(AdminConfigDraft draft, Boolean confirmed) {
        BuilderPlan plan = previewAdminConfigDraft(draft);
        return deployMetadataPlan(plan, confirmed, 'Admin Config Builder', plan.configKey);
    }

    @AuraEnabled
    public static BuilderPlan previewAdminConfigDraftJson(String draftJson) {
        return previewAdminConfigDraft(adminConfigDraftFromJson(draftJson));
    }

    @AuraEnabled
    public static BuilderPlan deployAdminConfigDraftJson(String draftJson, Boolean confirmed) {
        return deployAdminConfigDraft(adminConfigDraftFromJson(draftJson), confirmed);
    }

    @AuraEnabled
    public static BuilderPlan deactivateMetadataRecord(
        String metadataType,
        String metadataFullName,
        String metadataLabel,
        Boolean confirmed
    ) {
        BuilderPlan plan = newBuilderPlan();
        plan.configType = 'DEACTIVATE';
        plan.configKey = trimToNull(metadataFullName);
        plan.metadataWriteNotice = 'This preview deactivates the selected SmartIntake Custom Metadata record by setting Is_Active__c to false.';

        String normalizedType = trimToNull(metadataType);
        String normalizedFullName = trimToNull(metadataFullName);
        Schema.SObjectType sObjectType = metadataTypeForDeactivate(normalizedType);
        if (sObjectType == null || String.isBlank(normalizedFullName)) {
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'METADATA_DEACTIVATE_TARGET_REQUIRED',
                'Metadata Explorer',
                normalizedFullName,
                'Select a supported SmartIntake metadata record before deleting.'
            );
            return finishBuilderPlan(plan);
        }

        String expectedPrefix = customMetadataTypeFullName(sObjectType) + '.';
        if (!normalizedFullName.startsWith(expectedPrefix)) {
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'METADATA_DEACTIVATE_TYPE_MISMATCH',
                normalizedType,
                normalizedFullName,
                'The metadata full name does not match the selected SmartIntake metadata type.'
            );
            return finishBuilderPlan(plan);
        }

        String label = metadataLabel(String.isBlank(metadataLabel) ? deactivateRecordName(normalizedFullName) : metadataLabel, deactivateRecordName(normalizedFullName));
        BuilderRecord record = newBuilderRecord(normalizedType, normalizedFullName, 'Deactivate Metadata');
        record.metadataLabel = label;
        addBuilderField(record, 'Is_Active__c', false);
        plan.records.add(record);
        plan = finishBuilderPlan(plan);
        return deployMetadataPlan(plan, confirmed, 'Metadata Explorer', normalizedFullName);
    }

    @AuraEnabled
    public static BuilderPlan previewCustomControlRegistry() {
        BuilderPlan plan = buildCustomControlRegistryPlan();
        plan.metadataWriteStatus = 'PLANNED_ONLY';
        plan.metadataWriteNotice = 'Preview generated the LWR-safe registry source from active question UI controls. Confirm and sync to update the registry LWC resource.';
        return finishBuilderPlan(plan);
    }

    @AuraEnabled
    public static BuilderPlan syncCustomControlRegistry(Boolean confirmed) {
        BuilderPlan plan = finishBuilderPlan(buildCustomControlRegistryPlan());
        if (!plan.isValid) {
            plan.metadataWriteStatus = 'BLOCKED';
            plan.metadataWriteNotice = 'Fix the registry validation errors before syncing the generated LWC registry.';
            return plan;
        }
        if (confirmed != true) {
            plan.metadataWriteStatus = 'CONFIRMATION_REQUIRED';
            plan.metadataWriteNotice = 'Confirm that SmartIntake can update the generated custom-control registry LWC in this org.';
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'CONTROL_REGISTRY_SYNC_CONFIRMATION_REQUIRED',
                'Custom Control Registry',
                'smartIntakeControlRegistry',
                'Registry sync confirmation is required before the generated LWC resource can be updated.'
            );
            return finishBuilderPlan(plan);
        }
        if (!currentUserCanDeployMetadata()) {
            plan.metadataWriteStatus = 'PERMISSION_REQUIRED';
            plan.metadataWriteNotice = 'The current user needs API Enabled and Modify Metadata Through Metadata API Functions or Modify All Data before SmartIntake can update the custom-control registry.';
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'CONTROL_REGISTRY_SYNC_PERMISSION_REQUIRED',
                'Custom Control Registry',
                'smartIntakeControlRegistry',
                'Assign metadata deployment access to the admin user, then retry.'
            );
            return finishBuilderPlan(plan);
        }

        try {
            if (Test.isRunningTest()) {
                plan.registryResourceId = '0Rd000000000000AAA';
            } else {
                plan.registryResourceId = updateCustomControlRegistryResource(plan.generatedSource);
            }
            plan.metadataWriteStatus = 'SYNCED';
            plan.metadataWriteNotice = 'SmartIntake updated the generated LWC registry. Start a fresh Enhanced Chat session before testing newly registered controls.';
        } catch (Exception ex) {
            SmartIntakeApexDebugLogService.logException(
                'SmartIntakeAdminController',
                'syncCustomControlRegistry',
                plan.templateKey,
                null,
                ex,
                new Map<String, Object>{
                    'status' => 'SYNC_FAILED',
                    'componentType' => 'Custom Control Registry',
                    'configKey' => 'smartIntakeControlRegistry'
                }
            );
            plan.metadataWriteStatus = 'SYNC_FAILED';
            plan.metadataWriteNotice = 'SmartIntake could not update the generated LWC registry.';
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'CONTROL_REGISTRY_SYNC_FAILED',
                'Custom Control Registry',
                'smartIntakeControlRegistry',
                safeErrorMessage(ex)
            );
        }
        return finishBuilderPlan(plan);
    }

    @AuraEnabled(cacheable=true)
    public static ValidationResult validateTemplate(String templateKey) {
        ValidationResult result = new ValidationResult();
        result.templateKey = templateKey;
        result.issues = new List<ValidationIssue>();

        if (String.isBlank(templateKey)) {
            addIssue(result, SEVERITY_ERROR, 'MISSING_TEMPLATE_KEY', 'Template', null, 'Select a SmartIntake template to validate.');
            return finish(result);
        }

        List<SmartIntake_Template__mdt> templates = [
            SELECT Template_Key__c, Template_Name__c, Is_Active__c, Start_Question_Key__c,
                   Requires_Consent__c, Requires_Final_Confirmation__c, Consent_Message__c
            FROM SmartIntake_Template__mdt
            WHERE Template_Key__c = :templateKey
            LIMIT 1
        ];
        if (templates.isEmpty()) {
            addIssue(result, SEVERITY_ERROR, 'TEMPLATE_NOT_FOUND', 'Template', templateKey, 'No SmartIntake template exists for this key.');
            return finish(result);
        }

        SmartIntake_Template__mdt template = templates[0];
        result.templateName = template.Template_Name__c;
        if (!template.Is_Active__c) {
            addIssue(result, SEVERITY_WARNING, 'TEMPLATE_INACTIVE', 'Template', templateKey, 'This template is inactive and cannot run until activated.');
        }
        if (template.Requires_Consent__c == true && String.isBlank(template.Consent_Message__c)) {
            addIssue(result, SEVERITY_WARNING, 'CONSENT_MESSAGE_MISSING', 'Template', templateKey, 'This template requires consent but has no custom consent message.');
        }

        List<SmartIntake_Question__mdt> questions = [
            SELECT DeveloperName, Template_Key__c, Question_Key__c, Question_Text__c,
                   Question_Order__c, Is_Required__c, Input_Type__c, UI_Control__c,
                   Data_Source_Key__c, Render_Lightning_Input__c, Confirm_AI_Extracted_Answer__c, Is_Active__c
            FROM SmartIntake_Question__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Order__c ASC, DeveloperName ASC
        ];
        List<SmartIntake_Branding_Config__mdt> brandingConfigs = [
            SELECT DeveloperName, Agent_Display_Name__c, Avatar_Icon_Name__c,
                   Avatar_Image_URL__c, Welcome_Message__c, Is_Active__c
            FROM SmartIntake_Branding_Config__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        List<SmartIntake_Field_Binding__mdt> bindings = [
            SELECT DeveloperName, Question_Key__c, Object_API_Name__c, Field_API_Name__c, Is_Active__c
            FROM SmartIntake_Field_Binding__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        List<SmartIntake_Option__mdt> options = [
            SELECT DeveloperName, Question_Key__c, Option_Label__c, Option_Value__c, Sort_Order__c, Is_Active__c
            FROM SmartIntake_Option__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Key__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        List<SmartIntake_Validation_Rule__mdt> validationRules = [
            SELECT DeveloperName, Validation_Rule_Key__c, Question_Key__c, Validation_Type__c,
                   Regex__c, Min_Length__c, Max_Length__c, Min_Value__c, Max_Value__c,
                   Min_Date__c, Max_Date__c, Sort_Order__c, Is_Active__c
            FROM SmartIntake_Validation_Rule__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Key__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        List<SmartIntake_Condition__mdt> conditions = [
            SELECT DeveloperName, Condition_Key__c, Source_Question_Key__c, Operator__c,
                   Compare_Value__c, Action__c, Target_Question_Key__c, Sort_Order__c,
                   Condition_Group_Key__c, Condition_Logic__c, Condition_Number__c,
                   Custom_Logic__c, User_Message__c, Is_Active__c
            FROM SmartIntake_Condition__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Target_Question_Key__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        List<SmartIntake_Hook__mdt> hooks = [
            SELECT DeveloperName, Hook_Key__c, Question_Key__c, Event__c, Handler_Type__c,
                   Flow_API_Name__c, Success_Output_Variable__c,
                   User_Message_Output_Variable__c, Next_Question_Output_Variable__c,
                   Answers_JSON_Output_Variable__c, Block_Continue_Output_Variable__c,
                   Output_Mode__c, Flow_Input_Mappings__c, Flow_Output_Mappings__c,
                   Sort_Order__c, Is_Active__c
            FROM SmartIntake_Hook__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Key__c ASC, Event__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        List<SmartIntake_Matching_Rule__mdt> matchingRules = [
            SELECT DeveloperName, Matching_Rule_Key__c, Question_Key__c, Object_API_Name__c,
                   Field_API_Name__c, Display_Field_API_Name__c, Match_Type__c, Is_Active__c
            FROM SmartIntake_Matching_Rule__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        List<SmartIntake_Context_Config__mdt> contextConfigs = [
            SELECT DeveloperName, Context_Config_Key__c, Question_Key__c, Context_Type__c,
                   Context_Message__c, Object_API_Name__c, Filter_Field_API_Name__c,
                   Filter_Source_Question_Key__c, Display_Field_API_Name__c,
                   Allowed_Actions__c, Max_Records__c, Is_Active__c
            FROM SmartIntake_Context_Config__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        List<SmartIntake_File_Config__mdt> fileConfigs = [
            SELECT DeveloperName, File_Config_Key__c, Question_Key__c, Accepted_File_Types__c,
                   Allow_Multiple__c, Max_File_Count__c, Link_To_Final_Record__c,
                   Share_Type__c, Visibility__c, Is_Active__c
            FROM SmartIntake_File_Config__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        List<SmartIntake_Handoff_Config__mdt> handoffConfigs = [
            SELECT DeveloperName, Handoff_Config_Key__c, Provider_Type__c,
                   Availability_Mode__c, Requires_Consent__c, Consent_Message__c,
                   Trigger_Message__c, Available_Message__c, Offline_Message__c,
                   Declined_Message__c, Queue_Developer_Name__c,
                   Messaging_Channel_Developer_Name__c, Embedded_Service_Deployment_Name__c,
                   Handoff_URL__c, Is_Context_Sharing_Enabled__c,
                   Context_Fields_To_Share__c, Is_Active__c
            FROM SmartIntake_Handoff_Config__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];

        validateQuestions(result, template, questions);
        validateBrandingConfigs(result, brandingConfigs);
        validateOptions(result, questions, options);
        validateValidationRules(result, questions, validationRules);
        validateHooks(result, questions, hooks);
        validateConditions(result, questions, conditions, mappedHookOutputStoreKeys(hooks));
        validateBindings(result, questions, options, bindings, mappedHookOutputStoreKeys(hooks));
        validateMatchingRules(result, questions, matchingRules);
        validateContextConfigs(result, questions, contextConfigs);
        validateFileConfigs(result, questions, fileConfigs);
        validateHandoffConfigs(result, handoffConfigs);

        return finish(result);
    }

    @AuraEnabled(cacheable=true)
    public static TemplateConfiguration getTemplateConfiguration(String templateKey) {
        if (String.isBlank(templateKey)) {
            throw new AuraHandledException('Select a SmartIntake template to inspect.');
        }

        List<SmartIntake_Template__mdt> templates = [
            SELECT DeveloperName, Template_Key__c, Template_Name__c, Is_Active__c, Start_Question_Key__c,
                   Requires_Consent__c, Requires_Final_Confirmation__c, Consent_Message__c,
                   Completion_Message__c
            FROM SmartIntake_Template__mdt
            WHERE Template_Key__c = :templateKey
            LIMIT 1
        ];
        if (templates.isEmpty()) {
            throw new AuraHandledException('No SmartIntake template exists for this key.');
        }

        SmartIntake_Template__mdt template = templates[0];
        TemplateConfiguration config = new TemplateConfiguration();
        config.templateKey = template.Template_Key__c;
        config.templateName = template.Template_Name__c;
        config.sections = new List<ConfigSection>();
        config.totalRecordCount = 0;

        ConfigSection templateSection = newSection('template', 'Template', 'utility:description');
        ConfigRecord templateRecord = newRecord(
            template.Template_Key__c,
            template.Template_Name__c,
            'Start question: ' + display(template.Start_Question_Key__c),
            template.Is_Active__c
        );
        addMetadataReference(templateRecord, SmartIntake_Template__mdt.SObjectType, template.DeveloperName, template.Template_Name__c);
        addField(templateRecord, 'Template Key', template.Template_Key__c);
        addField(templateRecord, 'Start Question', template.Start_Question_Key__c);
        addField(templateRecord, 'Requires Consent', template.Requires_Consent__c);
        addField(templateRecord, 'Requires Final Confirmation', template.Requires_Final_Confirmation__c);
        addField(templateRecord, 'Consent Message', template.Consent_Message__c);
        addField(templateRecord, 'Completion Message', template.Completion_Message__c);
        templateSection.records.add(templateRecord);
        addSection(config, templateSection);

        List<SmartIntake_Branding_Config__mdt> brandingConfigs = [
            SELECT DeveloperName, Agent_Display_Name__c, Avatar_Icon_Name__c,
                   Avatar_Image_URL__c, Welcome_Message__c, Is_Active__c
            FROM SmartIntake_Branding_Config__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        ConfigSection brandingSection = newSection('branding', 'Branding', 'utility:identity');
        for (SmartIntake_Branding_Config__mdt brandingConfig : brandingConfigs) {
            ConfigRecord record = newRecord(
                brandingConfig.DeveloperName,
                brandingConfig.Agent_Display_Name__c,
                display(brandingConfig.Avatar_Icon_Name__c),
                brandingConfig.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Branding_Config__mdt.SObjectType, brandingConfig.DeveloperName, brandingConfig.Agent_Display_Name__c);
            addField(record, 'Developer Name', brandingConfig.DeveloperName);
            addField(record, 'Agent Display Name', brandingConfig.Agent_Display_Name__c);
            addField(record, 'Avatar Icon', brandingConfig.Avatar_Icon_Name__c);
            addField(record, 'Avatar Image URL', brandingConfig.Avatar_Image_URL__c);
            addField(record, 'Welcome Message', brandingConfig.Welcome_Message__c);
            brandingSection.records.add(record);
        }
        addSection(config, brandingSection);

        List<SmartIntake_Question__mdt> questions = [
            SELECT DeveloperName, Question_Key__c, Question_Text__c, Help_Text__c,
                   Placeholder_Text__c, Question_Order__c, Is_Required__c, Input_Type__c,
                   UI_Control__c, Data_Source_Key__c, Render_Lightning_Input__c, Confirm_AI_Extracted_Answer__c, Is_Active__c
            FROM SmartIntake_Question__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Order__c ASC, DeveloperName ASC
        ];
        ConfigSection questionSection = newSection('questions', 'Questions', 'utility:question');
        for (SmartIntake_Question__mdt question : questions) {
            ConfigRecord record = newRecord(
                question.Question_Key__c,
                question.Question_Text__c,
                display(question.Input_Type__c) + ' / ' + display(question.UI_Control__c),
                question.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Question__mdt.SObjectType, question.DeveloperName, question.Question_Text__c);
            addField(record, 'Question Key', question.Question_Key__c);
            addField(record, 'Order', question.Question_Order__c);
            addField(record, 'Required', question.Is_Required__c);
            addField(record, 'Confirm AI Extracted Answer', question.Confirm_AI_Extracted_Answer__c);
            addField(record, 'Input Type', question.Input_Type__c);
            addField(record, 'UI Control', question.UI_Control__c);
            addField(record, 'Render Lightning Input', question.Render_Lightning_Input__c);
            addField(record, 'Data Source Key', question.Data_Source_Key__c);
            addField(record, 'Help Text', question.Help_Text__c);
            addField(record, 'Placeholder', question.Placeholder_Text__c);
            questionSection.records.add(record);
        }
        addSection(config, questionSection);

        List<SmartIntake_Field_Binding__mdt> bindings = [
            SELECT DeveloperName, Question_Key__c, Object_API_Name__c, Field_API_Name__c, Is_Active__c
            FROM SmartIntake_Field_Binding__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Key__c ASC, DeveloperName ASC
        ];
        ConfigSection bindingSection = newSection('fieldBindings', 'Field Bindings', 'utility:link');
        for (SmartIntake_Field_Binding__mdt binding : bindings) {
            ConfigRecord record = newRecord(
                binding.DeveloperName,
                binding.Question_Key__c,
                display(binding.Object_API_Name__c) + '.' + display(binding.Field_API_Name__c),
                binding.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Field_Binding__mdt.SObjectType, binding.DeveloperName, binding.DeveloperName);
            addField(record, 'Question Key', binding.Question_Key__c);
            addField(record, 'Object API Name', binding.Object_API_Name__c);
            addField(record, 'Field API Name', binding.Field_API_Name__c);
            bindingSection.records.add(record);
        }
        addSection(config, bindingSection);

        List<SmartIntake_Option__mdt> options = [
            SELECT DeveloperName, Question_Key__c, Option_Label__c, Option_Value__c, Sort_Order__c, Is_Active__c
            FROM SmartIntake_Option__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Key__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        ConfigSection optionSection = newSection('options', 'Options', 'utility:choice');
        for (SmartIntake_Option__mdt optionRecord : options) {
            ConfigRecord record = newRecord(
                optionRecord.DeveloperName,
                optionRecord.Option_Label__c,
                optionRecord.Question_Key__c,
                optionRecord.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Option__mdt.SObjectType, optionRecord.DeveloperName, optionRecord.Option_Label__c);
            addField(record, 'Question Key', optionRecord.Question_Key__c);
            addField(record, 'Option Label', optionRecord.Option_Label__c);
            addField(record, 'Option Value', optionRecord.Option_Value__c);
            addField(record, 'Sort Order', optionRecord.Sort_Order__c);
            optionSection.records.add(record);
        }
        addSection(config, optionSection);

        List<SmartIntake_Validation_Rule__mdt> validationRules = [
            SELECT DeveloperName, Validation_Rule_Key__c, Question_Key__c, Validation_Type__c,
                   Regex__c, Min_Length__c, Max_Length__c, Min_Value__c, Max_Value__c,
                   Min_Date__c, Max_Date__c, Sort_Order__c, Error_Message__c, Is_Active__c
            FROM SmartIntake_Validation_Rule__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Key__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        ConfigSection validationSection = newSection('validationRules', 'Validation Rules', 'utility:rules');
        for (SmartIntake_Validation_Rule__mdt validationRule : validationRules) {
            ConfigRecord record = newRecord(
                validationRule.Validation_Rule_Key__c,
                validationRule.Validation_Type__c,
                validationRule.Question_Key__c,
                validationRule.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Validation_Rule__mdt.SObjectType, validationRule.DeveloperName, validationRule.Validation_Rule_Key__c);
            addField(record, 'Question Key', validationRule.Question_Key__c);
            addField(record, 'Validation Type', validationRule.Validation_Type__c);
            addField(record, 'Regex', validationRule.Regex__c);
            addField(record, 'Min Length', validationRule.Min_Length__c);
            addField(record, 'Max Length', validationRule.Max_Length__c);
            addField(record, 'Min Value', validationRule.Min_Value__c);
            addField(record, 'Max Value', validationRule.Max_Value__c);
            addField(record, 'Min Date', validationRule.Min_Date__c);
            addField(record, 'Max Date', validationRule.Max_Date__c);
            addField(record, 'Error Message', validationRule.Error_Message__c);
            validationSection.records.add(record);
        }
        addSection(config, validationSection);

        List<SmartIntake_Condition__mdt> conditions = [
            SELECT DeveloperName, Condition_Key__c, Source_Question_Key__c, Operator__c,
                   Compare_Value__c, Action__c, Target_Question_Key__c, Sort_Order__c,
                   Condition_Group_Key__c, Condition_Logic__c, Condition_Number__c,
                   Custom_Logic__c, User_Message__c, Is_Active__c
            FROM SmartIntake_Condition__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Target_Question_Key__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        ConfigSection conditionSection = newSection('conditions', 'Conditions', 'utility:branch_merge');
        for (SmartIntake_Condition__mdt condition : conditions) {
            ConfigRecord record = newRecord(
                condition.Condition_Key__c,
                condition.Source_Question_Key__c + ' ' + condition.Operator__c,
                condition.Action__c + ': ' + condition.Target_Question_Key__c,
                condition.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Condition__mdt.SObjectType, condition.DeveloperName, condition.Condition_Key__c);
            addField(record, 'Source Question', condition.Source_Question_Key__c);
            addField(record, 'Operator', condition.Operator__c);
            addField(record, 'Compare Value', condition.Compare_Value__c);
            addField(record, 'Action', condition.Action__c);
            addField(record, 'Target Question', condition.Target_Question_Key__c);
            addField(record, 'Condition Group', condition.Condition_Group_Key__c);
            addField(record, 'Condition Logic', condition.Condition_Logic__c);
            addField(record, 'Condition Number', condition.Condition_Number__c);
            addField(record, 'Custom Logic', condition.Custom_Logic__c);
            addField(record, 'User Message', condition.User_Message__c);
            addField(record, 'Sort Order', condition.Sort_Order__c);
            conditionSection.records.add(record);
        }
        addSection(config, conditionSection);

        List<SmartIntake_Hook__mdt> hooks = [
            SELECT DeveloperName, Hook_Key__c, Question_Key__c, Event__c, Handler_Type__c,
                   Flow_API_Name__c, Success_Output_Variable__c,
                   User_Message_Output_Variable__c, Next_Question_Output_Variable__c,
                   Answers_JSON_Output_Variable__c, Block_Continue_Output_Variable__c,
                   Output_Mode__c, Flow_Input_Mappings__c, Flow_Output_Mappings__c,
                   Sort_Order__c, Is_Active__c
            FROM SmartIntake_Hook__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Key__c ASC, Event__c ASC, Sort_Order__c ASC, DeveloperName ASC
        ];
        ConfigSection hookSection = newSection('hooks', 'Flow Hooks', 'utility:flow');
        for (SmartIntake_Hook__mdt hook : hooks) {
            ConfigRecord record = newRecord(
                hook.Hook_Key__c,
                hook.Event__c + ' on ' + hook.Question_Key__c,
                hook.Handler_Type__c + ': ' + display(hook.Flow_API_Name__c),
                hook.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Hook__mdt.SObjectType, hook.DeveloperName, hook.Hook_Key__c);
            addField(record, 'Question Key', hook.Question_Key__c);
            addField(record, 'Event', hook.Event__c);
            addField(record, 'Handler Type', hook.Handler_Type__c);
            addField(record, 'Flow API Name', hook.Flow_API_Name__c);
            addField(record, 'Output Mode', hook.Output_Mode__c);
            addField(record, 'Flow Input Mappings', hook.Flow_Input_Mappings__c);
            addField(record, 'Flow Output Mappings', hook.Flow_Output_Mappings__c);
            addField(record, 'Success Output Variable', hook.Success_Output_Variable__c);
            addField(record, 'User Message Output Variable', hook.User_Message_Output_Variable__c);
            addField(record, 'Next Question Output Variable', hook.Next_Question_Output_Variable__c);
            addField(record, 'Answers JSON Output Variable', hook.Answers_JSON_Output_Variable__c);
            addField(record, 'Block Continue Output Variable', hook.Block_Continue_Output_Variable__c);
            addField(record, 'Sort Order', hook.Sort_Order__c);
            hookSection.records.add(record);
        }
        addSection(config, hookSection);

        List<SmartIntake_Matching_Rule__mdt> matchingRules = [
            SELECT DeveloperName, Matching_Rule_Key__c, Question_Key__c, Object_API_Name__c,
                   Field_API_Name__c, Display_Field_API_Name__c, Match_Type__c, Is_Active__c
            FROM SmartIntake_Matching_Rule__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        ConfigSection matchingSection = newSection('matchingRules', 'Matching Rules', 'utility:search');
        for (SmartIntake_Matching_Rule__mdt matchingRule : matchingRules) {
            ConfigRecord record = newRecord(
                matchingRule.Matching_Rule_Key__c,
                matchingRule.Object_API_Name__c,
                display(matchingRule.Field_API_Name__c) + ' via ' + display(matchingRule.Question_Key__c),
                matchingRule.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Matching_Rule__mdt.SObjectType, matchingRule.DeveloperName, matchingRule.Matching_Rule_Key__c);
            addField(record, 'Question Key', matchingRule.Question_Key__c);
            addField(record, 'Object API Name', matchingRule.Object_API_Name__c);
            addField(record, 'Match Field', matchingRule.Field_API_Name__c);
            addField(record, 'Display Field', matchingRule.Display_Field_API_Name__c);
            addField(record, 'Match Type', matchingRule.Match_Type__c);
            matchingSection.records.add(record);
        }
        addSection(config, matchingSection);

        List<SmartIntake_Context_Config__mdt> contextConfigs = [
            SELECT DeveloperName, Context_Config_Key__c, Question_Key__c, Context_Type__c,
                   Context_Message__c, Object_API_Name__c, Filter_Field_API_Name__c,
                   Filter_Source_Question_Key__c, Display_Field_API_Name__c,
                   Allowed_Actions__c, Max_Records__c, Is_Active__c
            FROM SmartIntake_Context_Config__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        ConfigSection contextSection = newSection('contextConfigs', 'Existing Context', 'utility:record_lookup');
        for (SmartIntake_Context_Config__mdt contextConfig : contextConfigs) {
            ConfigRecord record = newRecord(
                contextConfig.Context_Config_Key__c,
                contextConfig.Context_Type__c,
                contextConfig.Question_Key__c,
                contextConfig.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Context_Config__mdt.SObjectType, contextConfig.DeveloperName, contextConfig.Context_Config_Key__c);
            addField(record, 'Question Key', contextConfig.Question_Key__c);
            addField(record, 'Context Type', contextConfig.Context_Type__c);
            addField(record, 'Context Message', contextConfig.Context_Message__c);
            addField(record, 'Object API Name', contextConfig.Object_API_Name__c);
            addField(record, 'Filter Field', contextConfig.Filter_Field_API_Name__c);
            addField(record, 'Filter Source Question', contextConfig.Filter_Source_Question_Key__c);
            addField(record, 'Display Field', contextConfig.Display_Field_API_Name__c);
            addField(record, 'Allowed Actions', contextConfig.Allowed_Actions__c);
            addField(record, 'Max Records', contextConfig.Max_Records__c);
            contextSection.records.add(record);
        }
        addSection(config, contextSection);

        List<SmartIntake_File_Config__mdt> fileConfigs = [
            SELECT DeveloperName, File_Config_Key__c, Question_Key__c, Accepted_File_Types__c,
                   Allow_Multiple__c, Max_File_Count__c, Link_To_Final_Record__c,
                   Share_Type__c, Visibility__c, Is_Active__c
            FROM SmartIntake_File_Config__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        ConfigSection fileSection = newSection('fileConfigs', 'Files', 'utility:attach');
        for (SmartIntake_File_Config__mdt fileConfig : fileConfigs) {
            ConfigRecord record = newRecord(
                fileConfig.File_Config_Key__c,
                fileConfig.Question_Key__c,
                fileConfig.Accepted_File_Types__c,
                fileConfig.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_File_Config__mdt.SObjectType, fileConfig.DeveloperName, fileConfig.File_Config_Key__c);
            addField(record, 'Question Key', fileConfig.Question_Key__c);
            addField(record, 'Accepted File Types', fileConfig.Accepted_File_Types__c);
            addField(record, 'Allow Multiple', fileConfig.Allow_Multiple__c);
            addField(record, 'Max File Count', fileConfig.Max_File_Count__c);
            addField(record, 'Link To Final Record', fileConfig.Link_To_Final_Record__c);
            addField(record, 'Share Type', fileConfig.Share_Type__c);
            addField(record, 'Visibility', fileConfig.Visibility__c);
            fileSection.records.add(record);
        }
        addSection(config, fileSection);

        List<SmartIntake_Handoff_Config__mdt> handoffConfigs = [
            SELECT DeveloperName, Handoff_Config_Key__c, Provider_Type__c,
                   Availability_Mode__c, Requires_Consent__c, Consent_Message__c,
                   Trigger_Message__c, Available_Message__c, Offline_Message__c,
                   Declined_Message__c, Queue_Developer_Name__c,
                   Messaging_Channel_Developer_Name__c, Embedded_Service_Deployment_Name__c,
                   Handoff_URL__c, Is_Context_Sharing_Enabled__c,
                   Context_Fields_To_Share__c, Is_Active__c
            FROM SmartIntake_Handoff_Config__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY DeveloperName ASC
        ];
        ConfigSection handoffSection = newSection('handoffConfigs', 'Handoff', 'utility:service_crew');
        for (SmartIntake_Handoff_Config__mdt handoffConfig : handoffConfigs) {
            ConfigRecord record = newRecord(
                handoffConfig.Handoff_Config_Key__c,
                handoffConfig.Provider_Type__c,
                handoffConfig.Availability_Mode__c,
                handoffConfig.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Handoff_Config__mdt.SObjectType, handoffConfig.DeveloperName, handoffConfig.Handoff_Config_Key__c);
            addField(record, 'Provider Type', handoffConfig.Provider_Type__c);
            addField(record, 'Availability Mode', handoffConfig.Availability_Mode__c);
            addField(record, 'Requires Consent', handoffConfig.Requires_Consent__c);
            addField(record, 'Consent Message', handoffConfig.Consent_Message__c);
            addField(record, 'Trigger Message', handoffConfig.Trigger_Message__c);
            addField(record, 'Available Message', handoffConfig.Available_Message__c);
            addField(record, 'Offline Message', handoffConfig.Offline_Message__c);
            addField(record, 'Declined Message', handoffConfig.Declined_Message__c);
            addField(record, 'Queue Developer Name', handoffConfig.Queue_Developer_Name__c);
            addField(record, 'Messaging Channel', handoffConfig.Messaging_Channel_Developer_Name__c);
            addField(record, 'Embedded Service Deployment', handoffConfig.Embedded_Service_Deployment_Name__c);
            addField(record, 'Handoff URL', handoffConfig.Handoff_URL__c);
            addField(record, 'Share Context', handoffConfig.Is_Context_Sharing_Enabled__c);
            addField(record, 'Context Fields To Share', handoffConfig.Context_Fields_To_Share__c);
            handoffSection.records.add(record);
        }
        addSection(config, handoffSection);

        Set<String> messageTemplateKeys = new Set<String>{ templateKey, 'GLOBAL' };
        List<SmartIntake_Message__mdt> messages = [
            SELECT DeveloperName, Message_Key__c, Template_Key__c, Message_Type__c,
                   Message_Text__c, Is_Active__c
            FROM SmartIntake_Message__mdt
            WHERE Template_Key__c IN :messageTemplateKeys
            ORDER BY Template_Key__c ASC, Message_Type__c ASC, DeveloperName ASC
        ];
        ConfigSection messageSection = newSection('messages', 'Messages', 'utility:comments');
        for (SmartIntake_Message__mdt message : messages) {
            ConfigRecord record = newRecord(
                message.Message_Key__c,
                message.Message_Type__c,
                message.Template_Key__c,
                message.Is_Active__c
            );
            addMetadataReference(record, SmartIntake_Message__mdt.SObjectType, message.DeveloperName, message.Message_Key__c);
            addField(record, 'Message Key', message.Message_Key__c);
            addField(record, 'Template Scope', message.Template_Key__c);
            addField(record, 'Message Type', message.Message_Type__c);
            addField(record, 'Message Text', message.Message_Text__c);
            messageSection.records.add(record);
        }
        addSection(config, messageSection);

        return config;
    }

    private static void validateQuestions(
        ValidationResult result,
        SmartIntake_Template__mdt template,
        List<SmartIntake_Question__mdt> questions
    ) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = new Map<String, SmartIntake_Question__mdt>();
        Set<String> seenKeys = new Set<String>();
        Set<String> registeredControls = registeredControlAliases();
        Integer activeQuestionCount = 0;

        for (SmartIntake_Question__mdt question : questions) {
            if (!question.Is_Active__c) {
                continue;
            }
            activeQuestionCount++;

            if (String.isBlank(question.Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'QUESTION_KEY_MISSING', 'Question', question.DeveloperName, 'An active question is missing Question Key.');
                continue;
            }
            if (seenKeys.contains(question.Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'DUPLICATE_QUESTION_KEY', 'Question', question.Question_Key__c, 'Question keys must be unique within a template.');
            }
            seenKeys.add(question.Question_Key__c);
            activeQuestionsByKey.put(question.Question_Key__c, question);

            if (String.isBlank(question.Question_Text__c)) {
                addIssue(result, SEVERITY_ERROR, 'QUESTION_TEXT_MISSING', 'Question', question.Question_Key__c, 'Question text is required for runtime display.');
            }

            String inputType = normalize(question.Input_Type__c);
            if (!SUPPORTED_INPUT_TYPES.contains(inputType)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_INPUT_TYPE', 'Question', question.Question_Key__c, 'Input type ' + question.Input_Type__c + ' is not supported by the runtime.');
            }

            validateRegisteredUiControl(result, question.Question_Key__c, question.UI_Control__c, registeredControls);
        }

        result.questionCount = activeQuestionCount;
        if (activeQuestionCount == 0) {
            addIssue(result, SEVERITY_ERROR, 'NO_ACTIVE_QUESTIONS', 'Template', template.Template_Key__c, 'At least one active question is required.');
        }

        if (!String.isBlank(template.Start_Question_Key__c) && !activeQuestionsByKey.containsKey(template.Start_Question_Key__c)) {
            addIssue(result, SEVERITY_ERROR, 'START_QUESTION_NOT_FOUND', 'Template', template.Template_Key__c, 'Start Question Key does not match an active question.');
        }
    }

    private static void validateBrandingConfigs(
        ValidationResult result,
        List<SmartIntake_Branding_Config__mdt> brandingConfigs
    ) {
        Integer activeBrandingCount = 0;

        for (SmartIntake_Branding_Config__mdt brandingConfig : brandingConfigs) {
            if (!brandingConfig.Is_Active__c) {
                continue;
            }
            activeBrandingCount++;

            if (String.isBlank(brandingConfig.Agent_Display_Name__c)) {
                addIssue(result, SEVERITY_ERROR, 'AGENT_DISPLAY_NAME_MISSING', 'Branding Config', brandingConfig.DeveloperName, 'Active branding config requires Agent Display Name.');
            }
            if (String.isBlank(brandingConfig.Avatar_Icon_Name__c) && String.isBlank(brandingConfig.Avatar_Image_URL__c)) {
                addIssue(result, SEVERITY_WARNING, 'AGENT_AVATAR_MISSING', 'Branding Config', brandingConfig.DeveloperName, 'No avatar icon or image URL is configured. Runtime will use the default icon.');
            }
            if (!String.isBlank(brandingConfig.Avatar_Icon_Name__c) && !brandingConfig.Avatar_Icon_Name__c.contains(':')) {
                addIssue(result, SEVERITY_WARNING, 'AGENT_ICON_FORMAT_MAY_BE_INVALID', 'Branding Config', brandingConfig.DeveloperName, 'Avatar Icon Name should use a Lightning icon format such as utility:einstein.');
            }
        }

        result.brandingConfigCount = activeBrandingCount;
        if (activeBrandingCount > 1) {
            addIssue(result, SEVERITY_ERROR, 'MULTIPLE_ACTIVE_BRANDING_CONFIGS', 'Branding Config', result.templateKey, 'Only one active branding config is supported per template.');
        }
    }

    private static void validateOptions(
        ValidationResult result,
        List<SmartIntake_Question__mdt> questions,
        List<SmartIntake_Option__mdt> options
    ) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = activeQuestionsByKey(questions);
        Map<String, Integer> activeOptionCountByQuestion = new Map<String, Integer>();
        Set<String> optionValuesByQuestion = new Set<String>();

        for (SmartIntake_Option__mdt optionRecord : options) {
            if (!optionRecord.Is_Active__c) {
                continue;
            }
            if (!activeQuestionsByKey.containsKey(optionRecord.Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'OPTION_WITHOUT_ACTIVE_QUESTION', 'Option', optionRecord.DeveloperName, 'This option points to a missing or inactive question.');
                continue;
            }
            if (String.isBlank(optionRecord.Option_Label__c) || String.isBlank(optionRecord.Option_Value__c)) {
                addIssue(result, SEVERITY_ERROR, 'OPTION_LABEL_OR_VALUE_MISSING', 'Option', optionRecord.DeveloperName, 'Active options require both label and value.');
            }

            String countKey = optionRecord.Question_Key__c;
            activeOptionCountByQuestion.put(countKey, (activeOptionCountByQuestion.containsKey(countKey) ? activeOptionCountByQuestion.get(countKey) : 0) + 1);

            String duplicateKey = optionRecord.Question_Key__c + ':' + optionRecord.Option_Value__c;
            if (optionValuesByQuestion.contains(duplicateKey)) {
                addIssue(result, SEVERITY_ERROR, 'DUPLICATE_OPTION_VALUE', 'Option', optionRecord.Question_Key__c, 'Option values must be unique for a question.');
            }
            optionValuesByQuestion.add(duplicateKey);
        }

        result.optionCount = 0;
        for (Integer optionCount : activeOptionCountByQuestion.values()) {
            result.optionCount += optionCount;
        }

        for (SmartIntake_Question__mdt question : activeQuestionsByKey.values()) {
            if (OPTION_INPUT_TYPES.contains(normalize(question.Input_Type__c)) &&
                (!activeOptionCountByQuestion.containsKey(question.Question_Key__c) || activeOptionCountByQuestion.get(question.Question_Key__c) == 0)) {
                addIssue(result, SEVERITY_ERROR, 'OPTIONS_REQUIRED', 'Question', question.Question_Key__c, 'This input type requires at least one active option.');
            }
        }
    }

    @TestVisible
    private static void validateValidationRules(
        ValidationResult result,
        List<SmartIntake_Question__mdt> questions,
        List<SmartIntake_Validation_Rule__mdt> validationRules
    ) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = activeQuestionsByKey(questions);
        Set<String> seenRuleKeys = new Set<String>();
        Map<String, Decimal> minLengthByQuestion = new Map<String, Decimal>();
        Map<String, Decimal> maxLengthByQuestion = new Map<String, Decimal>();
        Map<String, Decimal> minValueByQuestion = new Map<String, Decimal>();
        Map<String, Decimal> maxValueByQuestion = new Map<String, Decimal>();
        Map<String, Date> minDateByQuestion = new Map<String, Date>();
        Map<String, Date> maxDateByQuestion = new Map<String, Date>();
        Integer activeRuleCount = 0;

        for (SmartIntake_Validation_Rule__mdt validationRule : validationRules) {
            if (!validationRule.Is_Active__c) {
                continue;
            }
            activeRuleCount++;

            if (String.isBlank(validationRule.Validation_Rule_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'VALIDATION_RULE_KEY_MISSING', 'Validation Rule', validationRule.DeveloperName, 'Active validation rules require Validation Rule Key.');
            } else {
                if (seenRuleKeys.contains(validationRule.Validation_Rule_Key__c)) {
                    addIssue(result, SEVERITY_ERROR, 'DUPLICATE_VALIDATION_RULE_KEY', 'Validation Rule', validationRule.Validation_Rule_Key__c, 'Validation rule keys must be unique within a template.');
                }
                seenRuleKeys.add(validationRule.Validation_Rule_Key__c);
            }

            SmartIntake_Question__mdt question = activeQuestionsByKey.get(validationRule.Question_Key__c);
            if (question == null) {
                addIssue(result, SEVERITY_ERROR, 'VALIDATION_RULE_WITHOUT_ACTIVE_QUESTION', 'Validation Rule', validationRule.DeveloperName, 'This validation rule points to a missing or inactive question.');
                continue;
            }

            String validationType = normalize(validationRule.Validation_Type__c);
            if (!SUPPORTED_VALIDATION_TYPES.contains(validationType)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_VALIDATION_TYPE', 'Validation Rule', validationRule.DeveloperName, 'Validation type ' + validationRule.Validation_Type__c + ' is not supported by the runtime.');
                continue;
            }

            String inputType = normalize(question.Input_Type__c);
            if (validationType == 'REGEX') {
                validateRegexRule(result, validationRule, inputType);
            } else if (validationType == 'MIN_LENGTH') {
                validateLengthRule(result, validationRule, inputType, validationRule.Min_Length__c, 'Min Length', 'VALIDATION_MIN_LENGTH_MISSING', 'VALIDATION_MIN_LENGTH_NEGATIVE');
                minLengthByQuestion.put(question.Question_Key__c, validationRule.Min_Length__c);
            } else if (validationType == 'MAX_LENGTH') {
                validateLengthRule(result, validationRule, inputType, validationRule.Max_Length__c, 'Max Length', 'VALIDATION_MAX_LENGTH_MISSING', 'VALIDATION_MAX_LENGTH_NEGATIVE');
                maxLengthByQuestion.put(question.Question_Key__c, validationRule.Max_Length__c);
            } else if (validationType == 'MIN_VALUE') {
                validateNumericRule(result, validationRule, inputType, validationRule.Min_Value__c, 'Min Value', 'VALIDATION_MIN_VALUE_MISSING');
                minValueByQuestion.put(question.Question_Key__c, validationRule.Min_Value__c);
            } else if (validationType == 'MAX_VALUE') {
                validateNumericRule(result, validationRule, inputType, validationRule.Max_Value__c, 'Max Value', 'VALIDATION_MAX_VALUE_MISSING');
                maxValueByQuestion.put(question.Question_Key__c, validationRule.Max_Value__c);
            } else if (validationType == 'MIN_DATE') {
                validateDateRule(result, validationRule, inputType, validationRule.Min_Date__c, 'Min Date', 'VALIDATION_MIN_DATE_MISSING');
                minDateByQuestion.put(question.Question_Key__c, validationRule.Min_Date__c);
            } else if (validationType == 'MIN_TODAY') {
                validateDateInputType(result, validationRule, inputType, 'Today or Future');
                minDateByQuestion.put(question.Question_Key__c, Date.today());
            } else if (validationType == 'MAX_DATE') {
                validateDateRule(result, validationRule, inputType, validationRule.Max_Date__c, 'Max Date', 'VALIDATION_MAX_DATE_MISSING');
                maxDateByQuestion.put(question.Question_Key__c, validationRule.Max_Date__c);
            }
        }

        for (String questionKey : minLengthByQuestion.keySet()) {
            if (maxLengthByQuestion.containsKey(questionKey) &&
                minLengthByQuestion.get(questionKey) != null &&
                maxLengthByQuestion.get(questionKey) != null &&
                minLengthByQuestion.get(questionKey) > maxLengthByQuestion.get(questionKey)) {
                addIssue(result, SEVERITY_ERROR, 'VALIDATION_LENGTH_RANGE_INVALID', 'Validation Rule', questionKey, 'Min Length cannot be greater than Max Length.');
            }
        }
        for (String questionKey : minValueByQuestion.keySet()) {
            if (maxValueByQuestion.containsKey(questionKey) &&
                minValueByQuestion.get(questionKey) != null &&
                maxValueByQuestion.get(questionKey) != null &&
                minValueByQuestion.get(questionKey) > maxValueByQuestion.get(questionKey)) {
                addIssue(result, SEVERITY_ERROR, 'VALIDATION_VALUE_RANGE_INVALID', 'Validation Rule', questionKey, 'Min Value cannot be greater than Max Value.');
            }
        }
        for (String questionKey : minDateByQuestion.keySet()) {
            if (maxDateByQuestion.containsKey(questionKey) &&
                minDateByQuestion.get(questionKey) != null &&
                maxDateByQuestion.get(questionKey) != null &&
                minDateByQuestion.get(questionKey) > maxDateByQuestion.get(questionKey)) {
                addIssue(result, SEVERITY_ERROR, 'VALIDATION_DATE_RANGE_INVALID', 'Validation Rule', questionKey, 'Min Date cannot be later than Max Date.');
            }
        }

        result.validationRuleCount = activeRuleCount;
    }

    private static void validateRegexRule(
        ValidationResult result,
        SmartIntake_Validation_Rule__mdt validationRule,
        String inputType
    ) {
        if (!TEXT_VALIDATION_INPUT_TYPES.contains(inputType)) {
            addIssue(result, SEVERITY_ERROR, 'VALIDATION_TYPE_INCOMPATIBLE_WITH_INPUT', 'Validation Rule', validationRule.DeveloperName, 'REGEX validation is only supported for text-like inputs.');
        }
        if (String.isBlank(validationRule.Regex__c)) {
            addIssue(result, SEVERITY_ERROR, 'VALIDATION_REGEX_MISSING', 'Validation Rule', validationRule.DeveloperName, 'REGEX validation requires Regex.');
            return;
        }
        try {
            Pattern.compile(validationRule.Regex__c);
        } catch (Exception ex) {
            addIssue(result, SEVERITY_ERROR, 'VALIDATION_REGEX_INVALID', 'Validation Rule', validationRule.DeveloperName, 'Regex is invalid and cannot be compiled.');
        }
    }

    private static void validateLengthRule(
        ValidationResult result,
        SmartIntake_Validation_Rule__mdt validationRule,
        String inputType,
        Decimal configuredValue,
        String label,
        String missingCode,
        String negativeCode
    ) {
        if (!TEXT_VALIDATION_INPUT_TYPES.contains(inputType)) {
            addIssue(result, SEVERITY_ERROR, 'VALIDATION_TYPE_INCOMPATIBLE_WITH_INPUT', 'Validation Rule', validationRule.DeveloperName, label + ' validation is only supported for text-like inputs.');
        }
        if (configuredValue == null) {
            addIssue(result, SEVERITY_ERROR, missingCode, 'Validation Rule', validationRule.DeveloperName, label + ' validation requires ' + label + '.');
        } else if (configuredValue < 0) {
            addIssue(result, SEVERITY_ERROR, negativeCode, 'Validation Rule', validationRule.DeveloperName, label + ' cannot be negative.');
        }
    }

    private static void validateNumericRule(
        ValidationResult result,
        SmartIntake_Validation_Rule__mdt validationRule,
        String inputType,
        Decimal configuredValue,
        String label,
        String missingCode
    ) {
        if (!NUMERIC_VALIDATION_INPUT_TYPES.contains(inputType)) {
            addIssue(result, SEVERITY_ERROR, 'VALIDATION_TYPE_INCOMPATIBLE_WITH_INPUT', 'Validation Rule', validationRule.DeveloperName, label + ' validation is only supported for number and currency inputs.');
        }
        if (configuredValue == null) {
            addIssue(result, SEVERITY_ERROR, missingCode, 'Validation Rule', validationRule.DeveloperName, label + ' validation requires ' + label + '.');
        }
    }

    private static void validateDateRule(
        ValidationResult result,
        SmartIntake_Validation_Rule__mdt validationRule,
        String inputType,
        Date configuredValue,
        String label,
        String missingCode
    ) {
        if (!DATE_VALIDATION_INPUT_TYPES.contains(inputType)) {
            addIssue(result, SEVERITY_ERROR, 'VALIDATION_TYPE_INCOMPATIBLE_WITH_INPUT', 'Validation Rule', validationRule.DeveloperName, label + ' validation is only supported for date inputs.');
        }
        if (configuredValue == null) {
            addIssue(result, SEVERITY_ERROR, missingCode, 'Validation Rule', validationRule.DeveloperName, label + ' validation requires ' + label + '.');
        }
    }

    private static void validateDateInputType(
        ValidationResult result,
        SmartIntake_Validation_Rule__mdt validationRule,
        String inputType,
        String label
    ) {
        if (!DATE_VALIDATION_INPUT_TYPES.contains(inputType)) {
            addIssue(result, SEVERITY_ERROR, 'VALIDATION_TYPE_INCOMPATIBLE_WITH_INPUT', 'Validation Rule', validationRule.DeveloperName, label + ' validation is only supported for date inputs.');
        }
    }

    private static void validateBindings(
        ValidationResult result,
        List<SmartIntake_Question__mdt> questions,
        List<SmartIntake_Option__mdt> options,
        List<SmartIntake_Field_Binding__mdt> bindings,
        Set<String> mappedHookOutputStoreKeys
    ) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = activeQuestionsByKey(questions);
        Set<String> validDataKeys = mappedHookOutputStoreKeys == null
            ? new Set<String>()
            : mappedHookOutputStoreKeys;
        Map<String, List<SmartIntake_Option__mdt>> activeOptionsByQuestionKey = activeOptionsByQuestionKey(options);
        Map<String, Schema.DescribeSObjectResult> objectDescribesByName = new Map<String, Schema.DescribeSObjectResult>();
        Map<String, Set<String>> boundFieldsByObjectName = new Map<String, Set<String>>();
        List<BindingDescribeContext> validBindings = new List<BindingDescribeContext>();
        Integer activeBindingCount = 0;

        for (SmartIntake_Field_Binding__mdt binding : bindings) {
            if (!binding.Is_Active__c) {
                continue;
            }
            activeBindingCount++;

            SmartIntake_Question__mdt question = activeQuestionsByKey.get(binding.Question_Key__c);
            if (question == null && !validDataKeys.contains(binding.Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'BINDING_SOURCE_KEY_NOT_FOUND', 'Binding', binding.DeveloperName, 'Source Key must match an active question or a Flow Output Mapping Store As key.');
                continue;
            }
            if (question != null && FILE_INPUT_TYPES.contains(normalize(question.Input_Type__c))) {
                addIssue(result, SEVERITY_ERROR, 'FILE_FIELD_BINDING_NOT_SUPPORTED', 'Binding', binding.DeveloperName, 'File questions are saved as Salesforce Files links, not as direct field bindings.');
                continue;
            }

            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(binding.Object_API_Name__c);
            if (objectType == null) {
                addIssue(result, SEVERITY_ERROR, 'OBJECT_NOT_FOUND', 'Binding', binding.DeveloperName, 'Configured object does not exist: ' + binding.Object_API_Name__c + '.');
                continue;
            }

            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Schema.SObjectField fieldToken = objectDescribe.fields.getMap().get(binding.Field_API_Name__c);
            if (fieldToken == null) {
                addIssue(result, SEVERITY_ERROR, 'FIELD_NOT_FOUND', 'Binding', binding.DeveloperName, 'Configured field does not exist on ' + binding.Object_API_Name__c + ': ' + binding.Field_API_Name__c + '.');
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
            if (question != null && !isCompatibleFieldType(normalize(question.Input_Type__c), fieldDescribe.getType())) {
                addIssue(result, SEVERITY_WARNING, 'FIELD_TYPE_MAY_NOT_MATCH_INPUT', 'Binding', binding.DeveloperName, 'Question input type ' + question.Input_Type__c + ' may not safely save into field type ' + String.valueOf(fieldDescribe.getType()) + '.');
            }

            if (!objectDescribe.isCreateable()) {
                addIssue(result, SEVERITY_WARNING, 'OBJECT_CREATE_ACCESS_NOT_VISIBLE', 'Binding', binding.DeveloperName, 'The current user cannot create this object. Runtime users need create access.');
            }
            if (!fieldDescribe.isCreateable()) {
                addIssue(result, SEVERITY_WARNING, 'FIELD_CREATE_ACCESS_NOT_VISIBLE', 'Binding', binding.DeveloperName, 'The current user cannot create this field. Runtime users need field edit access.');
            }

            objectDescribesByName.put(objectDescribe.getName(), objectDescribe);
            addBoundField(boundFieldsByObjectName, objectDescribe.getName(), fieldDescribe.getName());
            validBindings.add(bindingContext(binding, question, objectDescribe, fieldDescribe));
        }

        if (objectDescribesByName.size() > 1) {
            addIssue(result, SEVERITY_ERROR, 'MULTIPLE_FINAL_SAVE_OBJECTS', 'Template', result.templateKey, 'All final save mappings must target the same Salesforce object.');
        }
        validateDependentPicklistBindings(result, validBindings, boundFieldsByObjectName);
        validateRestrictedPicklistOptions(result, validBindings, activeOptionsByQuestionKey);
        validateRequiredCreateFields(result, objectDescribesByName, boundFieldsByObjectName);

        result.bindingCount = activeBindingCount;
        if (activeBindingCount == 0) {
            addIssue(result, SEVERITY_INFO, 'NO_ACTIVE_FIELD_BINDINGS', 'Template', result.templateKey, 'This template collects answers only; no active save bindings are configured.');
        }
    }

    private static void validateDependentPicklistBindings(
        ValidationResult result,
        List<BindingDescribeContext> validBindings,
        Map<String, Set<String>> boundFieldsByObjectName
    ) {
        for (BindingDescribeContext context : validBindings) {
            if (!isPicklistField(context.fieldDescribe) || !context.fieldDescribe.isDependentPicklist()) {
                continue;
            }
            String controllerFieldName = controllerFieldApiName(context.fieldDescribe);
            if (String.isBlank(controllerFieldName)) {
                continue;
            }
            Set<String> boundFields = boundFieldsByObjectName.get(context.objectDescribe.getName());
            if (boundFields != null && boundFields.contains(controllerFieldName)) {
                continue;
            }
            addIssue(
                result,
                SEVERITY_ERROR,
                'DEPENDENT_PICKLIST_CONTROLLER_NOT_MAPPED',
                'Binding',
                context.binding.DeveloperName,
                context.binding.Field_API_Name__c + ' depends on ' + controllerFieldName + '. Add an active SmartIntake field binding for the controlling field on ' + context.binding.Object_API_Name__c + '.'
            );
        }
    }

    private static void validateRestrictedPicklistOptions(
        ValidationResult result,
        List<BindingDescribeContext> validBindings,
        Map<String, List<SmartIntake_Option__mdt>> activeOptionsByQuestionKey
    ) {
        for (BindingDescribeContext context : validBindings) {
            if (context.question == null ||
                !isPicklistField(context.fieldDescribe) ||
                !OPTION_INPUT_TYPES.contains(normalize(context.question.Input_Type__c))) {
                continue;
            }
            List<SmartIntake_Option__mdt> questionOptions = activeOptionsByQuestionKey.get(context.question.Question_Key__c);
            if (questionOptions == null || questionOptions.isEmpty()) {
                continue;
            }
            Set<String> activeFieldValues = activePicklistApiValues(context.fieldDescribe);
            for (SmartIntake_Option__mdt optionRecord : questionOptions) {
                if (!activeFieldValues.contains(optionRecord.Option_Value__c)) {
                    addIssue(
                        result,
                        SEVERITY_ERROR,
                        'OPTION_VALUE_NOT_ACTIVE_FOR_TARGET_FIELD',
                        'Option',
                        optionRecord.DeveloperName,
                        'Option value ' + optionRecord.Option_Value__c + ' is not an active value for ' + context.binding.Object_API_Name__c + '.' + context.binding.Field_API_Name__c + '.'
                    );
                }
            }
        }
    }

    private static void validateRequiredCreateFields(
        ValidationResult result,
        Map<String, Schema.DescribeSObjectResult> objectDescribesByName,
        Map<String, Set<String>> boundFieldsByObjectName
    ) {
        for (String objectName : objectDescribesByName.keySet()) {
            Schema.DescribeSObjectResult objectDescribe = objectDescribesByName.get(objectName);
            Set<String> boundFields = boundFieldsByObjectName.get(objectName);
            for (Schema.SObjectField fieldToken : objectDescribe.fields.getMap().values()) {
                Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                if (!isRequiredForCreate(fieldDescribe)) {
                    continue;
                }
                if (boundFields != null && boundFields.contains(fieldDescribe.getName())) {
                    continue;
                }
                addIssue(
                    result,
                    SEVERITY_ERROR,
                    'REQUIRED_CREATE_FIELD_NOT_MAPPED',
                    'Binding',
                    objectName,
                    objectName + '.' + fieldDescribe.getName() + ' is required when creating records. Add a SmartIntake question and field binding for this field, or provide a Salesforce default/automation value before final save.'
                );
            }
        }
    }

    @TestVisible
    private static void validateConditions(
        ValidationResult result,
        List<SmartIntake_Question__mdt> questions,
        List<SmartIntake_Condition__mdt> conditions,
        Set<String> mappedOutputStoreKeys
    ) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = activeQuestionsByKey(questions);
        Set<String> validSourceKeys = new Set<String>(activeQuestionsByKey.keySet());
        if (mappedOutputStoreKeys != null) {
            validSourceKeys.addAll(mappedOutputStoreKeys);
        }
        Set<String> seenConditionKeys = new Set<String>();
        Integer activeConditionCount = 0;

        for (SmartIntake_Condition__mdt condition : conditions) {
            if (!condition.Is_Active__c) {
                continue;
            }
            activeConditionCount++;

            if (String.isBlank(condition.Condition_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'CONDITION_KEY_MISSING', 'Condition', condition.DeveloperName, 'Active conditions require Condition Key.');
            } else {
                if (seenConditionKeys.contains(condition.Condition_Key__c)) {
                    addIssue(result, SEVERITY_ERROR, 'DUPLICATE_CONDITION_KEY', 'Condition', condition.Condition_Key__c, 'Condition keys must be unique within a template.');
                }
                seenConditionKeys.add(condition.Condition_Key__c);
            }

            if (String.isBlank(condition.Source_Question_Key__c) || !validSourceKeys.contains(condition.Source_Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'CONDITION_SOURCE_KEY_NOT_FOUND', 'Condition', condition.DeveloperName, 'Source Question Key must match an active question or a Flow Output Mapping Store As key.');
            }
            if (String.isBlank(condition.Target_Question_Key__c) || !activeQuestionsByKey.containsKey(condition.Target_Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'CONDITION_TARGET_QUESTION_NOT_FOUND', 'Condition', condition.DeveloperName, 'Target Question Key must match an active question.');
            }
            String action = normalize(condition.Action__c);
            if (!SUPPORTED_CONDITION_ACTIONS.contains(action)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_CONDITION_ACTION', 'Condition', condition.DeveloperName, 'Condition action ' + condition.Action__c + ' is not supported by the runtime.');
            }
            if (!String.isBlank(condition.Source_Question_Key__c) &&
                condition.Source_Question_Key__c == condition.Target_Question_Key__c &&
                action != 'BLOCK_WHEN') {
                addIssue(result, SEVERITY_ERROR, 'CONDITION_SELF_REFERENCE', 'Condition', condition.DeveloperName, 'Visibility conditions cannot use the same question as both source and target. Use BLOCK_WHEN for answer validation rules.');
            }

            String operator = normalize(condition.Operator__c);
            if (!SUPPORTED_CONDITION_OPERATORS.contains(operator)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_CONDITION_OPERATOR', 'Condition', condition.DeveloperName, 'Condition operator ' + condition.Operator__c + ' is not supported by the runtime.');
            } else if (CONDITION_OPERATORS_REQUIRING_COMPARE_VALUE.contains(operator) && String.isBlank(condition.Compare_Value__c)) {
                addIssue(result, SEVERITY_ERROR, 'CONDITION_COMPARE_VALUE_REQUIRED', 'Condition', condition.DeveloperName, 'This condition operator requires Compare Value.');
            }

            String logic = String.isBlank(condition.Condition_Logic__c) ? 'ALL' : normalize(condition.Condition_Logic__c);
            if (!SUPPORTED_CONDITION_LOGICS.contains(logic)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_CONDITION_LOGIC', 'Condition', condition.DeveloperName, 'Condition Logic must be ALL, ANY, or CUSTOM.');
            }
            if (logic == 'CUSTOM' && String.isBlank(condition.Custom_Logic__c)) {
                addIssue(result, SEVERITY_ERROR, 'CONDITION_CUSTOM_LOGIC_REQUIRED', 'Condition', condition.DeveloperName, 'CUSTOM condition logic requires a Custom Logic expression such as 1 AND (2 OR 3).');
            }
            if (condition.Condition_Number__c != null && condition.Condition_Number__c <= 0) {
                addIssue(result, SEVERITY_ERROR, 'CONDITION_NUMBER_INVALID', 'Condition', condition.DeveloperName, 'Condition Number must be greater than zero.');
            }
        }

        result.conditionCount = activeConditionCount;
    }

    @TestVisible
    private static void validateHooks(
        ValidationResult result,
        List<SmartIntake_Question__mdt> questions,
        List<SmartIntake_Hook__mdt> hooks
    ) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = activeQuestionsByKey(questions);
        Set<String> seenHookKeys = new Set<String>();
        Integer activeHookCount = 0;

        for (SmartIntake_Hook__mdt hook : hooks) {
            if (!hook.Is_Active__c) {
                continue;
            }
            activeHookCount++;

            if (String.isBlank(hook.Hook_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'HOOK_KEY_MISSING', 'Hook', hook.DeveloperName, 'Active hooks require Hook Key.');
            } else {
                if (seenHookKeys.contains(hook.Hook_Key__c)) {
                    addIssue(result, SEVERITY_ERROR, 'DUPLICATE_HOOK_KEY', 'Hook', hook.Hook_Key__c, 'Hook keys must be unique within a template.');
                }
                seenHookKeys.add(hook.Hook_Key__c);
            }

            if (String.isBlank(hook.Question_Key__c) || !activeQuestionsByKey.containsKey(hook.Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'HOOK_QUESTION_NOT_FOUND', 'Hook', hook.DeveloperName, 'Question Key must match an active question.');
            }

            String eventName = normalize(hook.Event__c);
            if (!SUPPORTED_HOOK_EVENTS.contains(eventName)) {
                addIssue(result, SEVERITY_ERROR, 'HOOK_EVENT_UNSUPPORTED', 'Hook', hook.DeveloperName, 'Hook event must be AFTER_ANSWER.');
            }

            String handlerType = normalize(hook.Handler_Type__c);
            if (!SUPPORTED_HOOK_HANDLER_TYPES.contains(handlerType)) {
                addIssue(result, SEVERITY_ERROR, 'HOOK_HANDLER_UNSUPPORTED', 'Hook', hook.DeveloperName, 'Hook handler must be FLOW.');
            }
            if (handlerType == 'FLOW' && String.isBlank(hook.Flow_API_Name__c)) {
                addIssue(result, SEVERITY_ERROR, 'HOOK_FLOW_REQUIRED', 'Hook', hook.DeveloperName, 'Flow API Name is required for Flow hooks.');
            } else if (!String.isBlank(hook.Flow_API_Name__c) && !isValidApiName(hook.Flow_API_Name__c)) {
                addIssue(result, SEVERITY_ERROR, 'HOOK_FLOW_API_NAME_INVALID', 'Hook', hook.DeveloperName, 'Flow API Name must be a valid Salesforce API name.');
            }

            String outputMode = hookOutputMode(hook.Output_Mode__c, hook.Flow_Output_Mappings__c);
            if (!SUPPORTED_HOOK_OUTPUT_MODES.contains(outputMode)) {
                addIssue(result, SEVERITY_ERROR, 'HOOK_OUTPUT_MODE_UNSUPPORTED', 'Hook', hook.DeveloperName, 'Output Mode must be BASIC_OUTPUT_MAPPING or ADVANCED_JSON_OVERRIDE.');
            } else if (outputMode == 'BASIC_OUTPUT_MAPPING') {
                for (FlowOutputMappingParts mapping : parseFlowOutputMappings(hook.Flow_Output_Mappings__c)) {
                    if (!mapping.isValid) {
                        addIssue(result, SEVERITY_ERROR, mapping.errorCode, 'Hook', hook.DeveloperName, mapping.errorMessage);
                    }
                }
            } else if (!String.isBlank(hook.Flow_Output_Mappings__c)) {
                addIssue(result, SEVERITY_WARNING, 'HOOK_OUTPUT_MAPPINGS_IGNORED', 'Hook', hook.DeveloperName, 'Flow Output Mappings are ignored in Advanced JSON Override mode.');
            }
            for (FlowInputMappingParts mapping : parseFlowInputMappings(hook.Flow_Input_Mappings__c)) {
                if (!mapping.isValid) {
                    addIssue(result, SEVERITY_ERROR, mapping.errorCode, 'Hook', hook.DeveloperName, mapping.errorMessage);
                }
            }
        }

        result.hookCount = activeHookCount;
    }

    private class FlowInputMappingParts {
        Boolean isValid = true;
        String inputVariableName;
        String sourceKey;
        String errorCode;
        String errorMessage;
    }

    private class FlowOutputMappingParts {
        Boolean isValid = true;
        String outputVariableName;
        String answerKey;
        String errorCode;
        String errorMessage;
    }

    private static Set<String> mappedHookOutputStoreKeys(List<SmartIntake_Hook__mdt> hooks) {
        Set<String> storeKeys = new Set<String>();
        for (SmartIntake_Hook__mdt hook : hooks) {
            if (hook == null || hook.Is_Active__c != true || hookOutputMode(hook.Output_Mode__c, hook.Flow_Output_Mappings__c) != 'BASIC_OUTPUT_MAPPING') {
                continue;
            }
            for (FlowOutputMappingParts mapping : parseFlowOutputMappings(hook.Flow_Output_Mappings__c)) {
                if (mapping.isValid) {
                    storeKeys.add(mapping.answerKey);
                }
            }
        }
        return storeKeys;
    }

    private static String hookOutputMode(String configuredMode, String mappingsText) {
        String normalizedMode = normalize(configuredMode);
        if (!String.isBlank(normalizedMode)) {
            if (normalizedMode == 'BASIC') {
                return 'BASIC_OUTPUT_MAPPING';
            }
            if (normalizedMode == 'ADVANCED') {
                return 'ADVANCED_JSON_OVERRIDE';
            }
            return normalizedMode;
        }
        return String.isBlank(mappingsText) ? 'ADVANCED_JSON_OVERRIDE' : 'BASIC_OUTPUT_MAPPING';
    }

    private static List<FlowInputMappingParts> parseFlowInputMappings(String mappingsText) {
        List<FlowInputMappingParts> mappings = new List<FlowInputMappingParts>();
        if (String.isBlank(mappingsText)) {
            return mappings;
        }

        String normalizedText = mappingsText.replace('\r\n', '\n').replace('\r', '\n').replace(';', '\n');
        for (String rawLine : normalizedText.split('\n')) {
            String line = rawLine == null ? null : rawLine.trim();
            if (String.isBlank(line) || line.startsWith('#')) {
                continue;
            }

            FlowInputMappingParts mapping = new FlowInputMappingParts();
            String delimiter = line.contains('<-') ? '<-' : (line.contains('=') ? '=' : (line.contains(':') ? ':' : null));
            if (String.isBlank(delimiter)) {
                mapping.isValid = false;
                mapping.errorCode = 'HOOK_INPUT_MAPPING_INVALID';
                mapping.errorMessage = 'Flow Input Mappings must use FlowInputVariable <- SOURCE_KEY. Invalid line: ' + line;
                mappings.add(mapping);
                continue;
            }

            Integer delimiterIndex = line.indexOf(delimiter);
            mapping.inputVariableName = delimiterIndex < 0 ? null : line.substring(0, delimiterIndex).trim();
            mapping.sourceKey = delimiterIndex < 0 ? null : line.substring(delimiterIndex + delimiter.length()).trim();
            if (String.isBlank(mapping.inputVariableName) || String.isBlank(mapping.sourceKey)) {
                mapping.isValid = false;
                mapping.errorCode = 'HOOK_INPUT_MAPPING_INVALID';
                mapping.errorMessage = 'Flow Input Mappings must use FlowInputVariable <- SOURCE_KEY. Invalid line: ' + line;
            } else if (!isValidApiName(mapping.inputVariableName)) {
                mapping.isValid = false;
                mapping.errorCode = 'HOOK_INPUT_VARIABLE_INVALID';
                mapping.errorMessage = 'Flow input variable names must be valid API names. Invalid variable: ' + mapping.inputVariableName;
            } else if (!isValidInputSource(mapping.sourceKey)) {
                mapping.isValid = false;
                mapping.errorCode = 'HOOK_INPUT_SOURCE_INVALID';
                mapping.errorMessage = 'Flow input sources must be answer keys, built-in context keys, or quoted literals. Invalid source: ' + mapping.sourceKey;
            }
            mappings.add(mapping);
        }
        return mappings;
    }

    private static List<FlowOutputMappingParts> parseFlowOutputMappings(String mappingsText) {
        List<FlowOutputMappingParts> mappings = new List<FlowOutputMappingParts>();
        if (String.isBlank(mappingsText)) {
            return mappings;
        }

        String normalizedText = mappingsText.replace('\r\n', '\n').replace('\r', '\n').replace(';', '\n');
        for (String rawLine : normalizedText.split('\n')) {
            String line = rawLine == null ? null : rawLine.trim();
            if (String.isBlank(line) || line.startsWith('#')) {
                continue;
            }

            FlowOutputMappingParts mapping = new FlowOutputMappingParts();
            String delimiter = line.contains('->') ? '->' : (line.contains('=') ? '=' : (line.contains(':') ? ':' : null));
            if (String.isBlank(delimiter)) {
                mapping.isValid = false;
                mapping.errorCode = 'HOOK_OUTPUT_MAPPING_INVALID';
                mapping.errorMessage = 'Flow Output Mappings must use FlowOutputVariable -> STORE_AS_KEY. Invalid line: ' + line;
                mappings.add(mapping);
                continue;
            }

            Integer delimiterIndex = line.indexOf(delimiter);
            mapping.outputVariableName = delimiterIndex < 0 ? null : line.substring(0, delimiterIndex).trim();
            mapping.answerKey = delimiterIndex < 0 ? null : line.substring(delimiterIndex + delimiter.length()).trim();
            if (String.isBlank(mapping.outputVariableName) || String.isBlank(mapping.answerKey)) {
                mapping.isValid = false;
                mapping.errorCode = 'HOOK_OUTPUT_MAPPING_INVALID';
                mapping.errorMessage = 'Flow Output Mappings must use FlowOutputVariable -> STORE_AS_KEY. Invalid line: ' + line;
            } else if (!isValidApiName(mapping.outputVariableName)) {
                mapping.isValid = false;
                mapping.errorCode = 'HOOK_OUTPUT_VARIABLE_INVALID';
                mapping.errorMessage = 'Flow output variable names must be valid API names. Invalid variable: ' + mapping.outputVariableName;
            } else if (!isValidAnswerStoreKey(mapping.answerKey)) {
                mapping.isValid = false;
                mapping.errorCode = 'HOOK_OUTPUT_STORE_KEY_INVALID';
                mapping.errorMessage = 'Store As keys must start with a letter and contain only letters, numbers, and underscores. Invalid key: ' + mapping.answerKey;
            }
            mappings.add(mapping);
        }
        return mappings;
    }

    private static void validateMatchingRules(
        ValidationResult result,
        List<SmartIntake_Question__mdt> questions,
        List<SmartIntake_Matching_Rule__mdt> matchingRules
    ) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = activeQuestionsByKey(questions);
        Set<String> seenRuleKeys = new Set<String>();
        Integer activeRuleCount = 0;

        for (SmartIntake_Matching_Rule__mdt matchingRule : matchingRules) {
            if (!matchingRule.Is_Active__c) {
                continue;
            }
            activeRuleCount++;

            if (String.isBlank(matchingRule.Matching_Rule_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'MATCHING_RULE_KEY_MISSING', 'Matching Rule', matchingRule.DeveloperName, 'Active matching rules require Matching Rule Key.');
            } else {
                if (seenRuleKeys.contains(matchingRule.Matching_Rule_Key__c)) {
                    addIssue(result, SEVERITY_ERROR, 'DUPLICATE_MATCHING_RULE_KEY', 'Matching Rule', matchingRule.Matching_Rule_Key__c, 'Matching rule keys must be unique within a template.');
                }
                seenRuleKeys.add(matchingRule.Matching_Rule_Key__c);
            }

            if (String.isBlank(matchingRule.Question_Key__c) || !activeQuestionsByKey.containsKey(matchingRule.Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'MATCHING_RULE_WITHOUT_ACTIVE_QUESTION', 'Matching Rule', matchingRule.DeveloperName, 'This matching rule points to a missing or inactive question.');
            }

            String matchType = normalize(matchingRule.Match_Type__c);
            if (!SUPPORTED_MATCH_TYPES.contains(matchType)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_MATCH_TYPE', 'Matching Rule', matchingRule.DeveloperName, 'Match type ' + matchingRule.Match_Type__c + ' is not supported by the runtime.');
            }

            if (String.isBlank(matchingRule.Object_API_Name__c) || String.isBlank(matchingRule.Field_API_Name__c)) {
                addIssue(result, SEVERITY_ERROR, 'MATCHING_OBJECT_OR_FIELD_MISSING', 'Matching Rule', matchingRule.DeveloperName, 'Active matching rules require Object API Name and Field API Name.');
                continue;
            }

            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(matchingRule.Object_API_Name__c);
            if (objectType == null) {
                addIssue(result, SEVERITY_ERROR, 'MATCHING_OBJECT_NOT_FOUND', 'Matching Rule', matchingRule.DeveloperName, 'Configured matching object does not exist: ' + matchingRule.Object_API_Name__c + '.');
                continue;
            }

            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            if (!objectDescribe.isAccessible()) {
                addIssue(result, SEVERITY_WARNING, 'MATCHING_OBJECT_READ_ACCESS_NOT_VISIBLE', 'Matching Rule', matchingRule.DeveloperName, 'The current user cannot read this object. Runtime users need read access for matching.');
            }

            validateReadableMatchingField(result, objectDescribe, matchingRule, matchingRule.Field_API_Name__c, 'MATCHING_FIELD_NOT_FOUND', 'MATCHING_FIELD_READ_ACCESS_NOT_VISIBLE');
            if (!String.isBlank(matchingRule.Display_Field_API_Name__c)) {
                validateReadableMatchingField(result, objectDescribe, matchingRule, matchingRule.Display_Field_API_Name__c, 'MATCHING_DISPLAY_FIELD_NOT_FOUND', 'MATCHING_DISPLAY_FIELD_READ_ACCESS_NOT_VISIBLE');
            }
        }

        result.matchingRuleCount = activeRuleCount;
    }

    private static void validateReadableMatchingField(
        ValidationResult result,
        Schema.DescribeSObjectResult objectDescribe,
        SmartIntake_Matching_Rule__mdt matchingRule,
        String fieldApiName,
        String missingCode,
        String accessCode
    ) {
        Schema.SObjectField fieldToken = objectDescribe.fields.getMap().get(fieldApiName);
        if (fieldToken == null) {
            addIssue(result, SEVERITY_ERROR, missingCode, 'Matching Rule', matchingRule.DeveloperName, 'Configured field does not exist on ' + matchingRule.Object_API_Name__c + ': ' + fieldApiName + '.');
            return;
        }

        if (!fieldToken.getDescribe().isAccessible()) {
            addIssue(result, SEVERITY_WARNING, accessCode, 'Matching Rule', matchingRule.DeveloperName, 'The current user cannot read field ' + fieldApiName + '. Runtime users need field read access for matching.');
        }
    }

    private static void validateContextConfigs(
        ValidationResult result,
        List<SmartIntake_Question__mdt> questions,
        List<SmartIntake_Context_Config__mdt> contextConfigs
    ) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = activeQuestionsByKey(questions);
        Set<String> seenConfigKeys = new Set<String>();
        Set<String> seenQuestionKeys = new Set<String>();
        Integer activeConfigCount = 0;

        for (SmartIntake_Context_Config__mdt contextConfig : contextConfigs) {
            if (!contextConfig.Is_Active__c) {
                continue;
            }
            activeConfigCount++;

            if (String.isBlank(contextConfig.Context_Config_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'CONTEXT_CONFIG_KEY_MISSING', 'Context Config', contextConfig.DeveloperName, 'Active context configs require Context Config Key.');
            } else {
                if (seenConfigKeys.contains(contextConfig.Context_Config_Key__c)) {
                    addIssue(result, SEVERITY_ERROR, 'DUPLICATE_CONTEXT_CONFIG_KEY', 'Context Config', contextConfig.Context_Config_Key__c, 'Context config keys must be unique within a template.');
                }
                seenConfigKeys.add(contextConfig.Context_Config_Key__c);
            }

            if (String.isBlank(contextConfig.Question_Key__c) || !activeQuestionsByKey.containsKey(contextConfig.Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'CONTEXT_CONFIG_WITHOUT_ACTIVE_QUESTION', 'Context Config', contextConfig.DeveloperName, 'This context config points to a missing or inactive current question.');
            } else {
                if (seenQuestionKeys.contains(contextConfig.Question_Key__c)) {
                    addIssue(result, SEVERITY_ERROR, 'DUPLICATE_CONTEXT_QUESTION', 'Context Config', contextConfig.Question_Key__c, 'Only one active context config is supported per question.');
                }
                seenQuestionKeys.add(contextConfig.Question_Key__c);
            }

            if (String.isBlank(contextConfig.Filter_Source_Question_Key__c) || !activeQuestionsByKey.containsKey(contextConfig.Filter_Source_Question_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'CONTEXT_FILTER_SOURCE_NOT_FOUND', 'Context Config', contextConfig.DeveloperName, 'Filter Source Question Key must match an active question.');
            }

            String contextType = normalize(contextConfig.Context_Type__c);
            if (!SUPPORTED_CONTEXT_TYPES.contains(contextType)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_CONTEXT_TYPE', 'Context Config', contextConfig.DeveloperName, 'Context type ' + contextConfig.Context_Type__c + ' is not supported by the runtime.');
            }

            if (String.isBlank(contextConfig.Object_API_Name__c) || String.isBlank(contextConfig.Filter_Field_API_Name__c)) {
                addIssue(result, SEVERITY_ERROR, 'CONTEXT_OBJECT_OR_FIELD_MISSING', 'Context Config', contextConfig.DeveloperName, 'Active context configs require Object API Name and Filter Field API Name.');
                continue;
            }

            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(contextConfig.Object_API_Name__c);
            if (objectType == null) {
                addIssue(result, SEVERITY_ERROR, 'CONTEXT_OBJECT_NOT_FOUND', 'Context Config', contextConfig.DeveloperName, 'Configured context object does not exist: ' + contextConfig.Object_API_Name__c + '.');
                continue;
            }

            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            if (!objectDescribe.isAccessible()) {
                addIssue(result, SEVERITY_WARNING, 'CONTEXT_OBJECT_READ_ACCESS_NOT_VISIBLE', 'Context Config', contextConfig.DeveloperName, 'The current user cannot read this object. Runtime users need read access for context.');
            }

            validateReadableContextField(result, objectDescribe, contextConfig, contextConfig.Filter_Field_API_Name__c, 'CONTEXT_FILTER_FIELD_NOT_FOUND', 'CONTEXT_FILTER_FIELD_READ_ACCESS_NOT_VISIBLE');
            if (!String.isBlank(contextConfig.Display_Field_API_Name__c)) {
                validateReadableContextField(result, objectDescribe, contextConfig, contextConfig.Display_Field_API_Name__c, 'CONTEXT_DISPLAY_FIELD_NOT_FOUND', 'CONTEXT_DISPLAY_FIELD_READ_ACCESS_NOT_VISIBLE');
            }

            if (contextConfig.Max_Records__c != null && (contextConfig.Max_Records__c < 1 || contextConfig.Max_Records__c > 10)) {
                addIssue(result, SEVERITY_WARNING, 'CONTEXT_MAX_RECORDS_OUT_OF_RANGE', 'Context Config', contextConfig.DeveloperName, 'Max Records should be between 1 and 10. Runtime clamps unsafe values.');
            }
        }

        result.contextConfigCount = activeConfigCount;
    }

    @TestVisible
    private static void validateFileConfigs(
        ValidationResult result,
        List<SmartIntake_Question__mdt> questions,
        List<SmartIntake_File_Config__mdt> fileConfigs
    ) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = activeQuestionsByKey(questions);
        Set<String> seenConfigKeys = new Set<String>();
        Set<String> seenQuestionKeys = new Set<String>();
        Integer activeConfigCount = 0;

        for (SmartIntake_File_Config__mdt fileConfig : fileConfigs) {
            if (!fileConfig.Is_Active__c) {
                continue;
            }
            activeConfigCount++;

            if (String.isBlank(fileConfig.File_Config_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'FILE_CONFIG_KEY_MISSING', 'File Config', fileConfig.DeveloperName, 'Active file configs require File Config Key.');
            } else {
                if (seenConfigKeys.contains(fileConfig.File_Config_Key__c)) {
                    addIssue(result, SEVERITY_ERROR, 'DUPLICATE_FILE_CONFIG_KEY', 'File Config', fileConfig.File_Config_Key__c, 'File config keys must be unique within a template.');
                }
                seenConfigKeys.add(fileConfig.File_Config_Key__c);
            }

            SmartIntake_Question__mdt question = activeQuestionsByKey.get(fileConfig.Question_Key__c);
            if (question == null) {
                addIssue(result, SEVERITY_ERROR, 'FILE_CONFIG_WITHOUT_ACTIVE_QUESTION', 'File Config', fileConfig.DeveloperName, 'This file config points to a missing or inactive question.');
            } else {
                if (seenQuestionKeys.contains(fileConfig.Question_Key__c)) {
                    addIssue(result, SEVERITY_ERROR, 'DUPLICATE_FILE_CONFIG_QUESTION', 'File Config', fileConfig.Question_Key__c, 'Only one active file config is supported per file question.');
                }
                seenQuestionKeys.add(fileConfig.Question_Key__c);

                if (!FILE_INPUT_TYPES.contains(normalize(question.Input_Type__c))) {
                    addIssue(result, SEVERITY_ERROR, 'FILE_CONFIG_FOR_NON_FILE_QUESTION', 'File Config', fileConfig.DeveloperName, 'File config can only be used with FILE, IMAGE, or PDF input questions.');
                }
            }

            validateAcceptedFileTypes(result, fileConfig);

            if (fileConfig.Max_File_Count__c != null && (fileConfig.Max_File_Count__c < 1 || fileConfig.Max_File_Count__c > 25)) {
                addIssue(result, SEVERITY_WARNING, 'FILE_MAX_COUNT_OUT_OF_RANGE', 'File Config', fileConfig.DeveloperName, 'Max File Count should be between 1 and 25. Runtime clamps unsafe values.');
            }
            if (fileConfig.Allow_Multiple__c != true && fileConfig.Max_File_Count__c != null && fileConfig.Max_File_Count__c > 1) {
                addIssue(result, SEVERITY_WARNING, 'FILE_MAX_COUNT_IGNORED_FOR_SINGLE_UPLOAD', 'File Config', fileConfig.DeveloperName, 'Allow Multiple is disabled, so runtime accepts only one file.');
            }

            String shareType = String.isBlank(fileConfig.Share_Type__c) ? 'V' : fileConfig.Share_Type__c.trim();
            if (!SUPPORTED_FILE_SHARE_TYPES.contains(shareType)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_FILE_SHARE_TYPE', 'File Config', fileConfig.DeveloperName, 'Share Type must be V, C, or I.');
            }

            String visibility = String.isBlank(fileConfig.Visibility__c) ? 'AllUsers' : fileConfig.Visibility__c.trim();
            if (!SUPPORTED_FILE_VISIBILITIES.contains(visibility)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_FILE_VISIBILITY', 'File Config', fileConfig.DeveloperName, 'Visibility must be AllUsers, InternalUsers, or SharedUsers.');
            }
        }

        for (SmartIntake_Question__mdt question : activeQuestionsByKey.values()) {
            if (FILE_INPUT_TYPES.contains(normalize(question.Input_Type__c)) && !seenQuestionKeys.contains(question.Question_Key__c)) {
                addIssue(result, SEVERITY_WARNING, 'FILE_CONFIG_RECOMMENDED', 'Question', question.Question_Key__c, 'File questions should have a file config so admins can control accepted types, max count, and final record linking.');
            }
        }

        result.fileConfigCount = activeConfigCount;
    }

    @TestVisible
    private static void validateHandoffConfigs(
        ValidationResult result,
        List<SmartIntake_Handoff_Config__mdt> handoffConfigs
    ) {
        Set<String> seenConfigKeys = new Set<String>();
        Integer activeConfigCount = 0;

        for (SmartIntake_Handoff_Config__mdt handoffConfig : handoffConfigs) {
            if (!handoffConfig.Is_Active__c) {
                continue;
            }
            activeConfigCount++;

            if (String.isBlank(handoffConfig.Handoff_Config_Key__c)) {
                addIssue(result, SEVERITY_ERROR, 'HANDOFF_CONFIG_KEY_MISSING', 'Handoff Config', handoffConfig.DeveloperName, 'Active handoff configs require Handoff Config Key.');
            } else {
                if (seenConfigKeys.contains(handoffConfig.Handoff_Config_Key__c)) {
                    addIssue(result, SEVERITY_ERROR, 'DUPLICATE_HANDOFF_CONFIG_KEY', 'Handoff Config', handoffConfig.Handoff_Config_Key__c, 'Handoff config keys must be unique within a template.');
                }
                seenConfigKeys.add(handoffConfig.Handoff_Config_Key__c);
            }

            String providerType = normalize(handoffConfig.Provider_Type__c);
            if (String.isBlank(providerType)) {
                addIssue(result, SEVERITY_ERROR, 'HANDOFF_PROVIDER_MISSING', 'Handoff Config', handoffConfig.DeveloperName, 'Active handoff configs require Provider Type.');
            } else if (!SUPPORTED_HANDOFF_PROVIDER_TYPES.contains(providerType)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_HANDOFF_PROVIDER', 'Handoff Config', handoffConfig.DeveloperName, 'Provider Type must be ENHANCED_OMNI, ENHANCED_CHAT_V2, or EXTERNAL_URL.');
            }

            String availabilityMode = normalize(handoffConfig.Availability_Mode__c);
            if (!String.isBlank(availabilityMode) && !SUPPORTED_HANDOFF_AVAILABILITY_MODES.contains(availabilityMode)) {
                addIssue(result, SEVERITY_ERROR, 'UNSUPPORTED_HANDOFF_AVAILABILITY_MODE', 'Handoff Config', handoffConfig.DeveloperName, 'Availability Mode must be CONFIGURED, ALWAYS_AVAILABLE, or ALWAYS_OFFLINE.');
            }

            if (handoffConfig.Requires_Consent__c == true && String.isBlank(handoffConfig.Consent_Message__c)) {
                addIssue(result, SEVERITY_WARNING, 'HANDOFF_CONSENT_MESSAGE_MISSING', 'Handoff Config', handoffConfig.DeveloperName, 'This handoff requires consent but has no custom consent message.');
            }

            if (providerType == 'ENHANCED_OMNI') {
                if (!Schema.getGlobalDescribe().containsKey('PendingServiceRouting') ||
                    !Schema.getGlobalDescribe().containsKey('AgentWork')) {
                    addIssue(result, SEVERITY_WARNING, 'HANDOFF_OMNI_OBJECTS_NOT_AVAILABLE', 'Handoff Config', handoffConfig.DeveloperName, 'Enhanced Omni-Channel objects are not available to the current org/user. Verify Service setup, licenses, and permissions.');
                }
                if (String.isBlank(handoffConfig.Queue_Developer_Name__c)) {
                    addIssue(result, SEVERITY_WARNING, 'HANDOFF_QUEUE_MISSING', 'Handoff Config', handoffConfig.DeveloperName, 'Enhanced Omni-Channel handoff should specify Queue Developer Name.');
                }
            } else if (providerType == 'ENHANCED_CHAT_V2') {
                if (!Schema.getGlobalDescribe().containsKey('MessagingChannel')) {
                    addIssue(result, SEVERITY_WARNING, 'HANDOFF_MESSAGING_CHANNEL_OBJECT_NOT_AVAILABLE', 'Handoff Config', handoffConfig.DeveloperName, 'MessagingChannel is not available to the current org/user. Verify Enhanced Chat v2 or Messaging setup.');
                }
                if (String.isBlank(handoffConfig.Messaging_Channel_Developer_Name__c) &&
                    String.isBlank(handoffConfig.Embedded_Service_Deployment_Name__c)) {
                    addIssue(result, SEVERITY_WARNING, 'HANDOFF_CHAT_DEPLOYMENT_MISSING', 'Handoff Config', handoffConfig.DeveloperName, 'Enhanced Chat v2 handoff should specify a Messaging Channel Developer Name or Embedded Service Deployment Name.');
                }
            } else if (providerType == 'EXTERNAL_URL' && String.isBlank(handoffConfig.Handoff_URL__c)) {
                addIssue(result, SEVERITY_ERROR, 'HANDOFF_URL_MISSING', 'Handoff Config', handoffConfig.DeveloperName, 'External URL handoff requires Handoff URL.');
            }

            if (handoffConfig.Is_Context_Sharing_Enabled__c == true && String.isBlank(handoffConfig.Context_Fields_To_Share__c)) {
                addIssue(result, SEVERITY_WARNING, 'HANDOFF_CONTEXT_FIELDS_MISSING', 'Handoff Config', handoffConfig.DeveloperName, 'Context sharing is enabled but no answer keys are configured in Context Fields To Share.');
            }
        }

        result.handoffConfigCount = activeConfigCount;
        if (activeConfigCount > 1) {
            addIssue(result, SEVERITY_ERROR, 'MULTIPLE_ACTIVE_HANDOFF_CONFIGS', 'Handoff Config', result.templateKey, 'Only one active handoff config is supported per template.');
        }
    }

    private static void validateAcceptedFileTypes(
        ValidationResult result,
        SmartIntake_File_Config__mdt fileConfig
    ) {
        if (String.isBlank(fileConfig.Accepted_File_Types__c)) {
            return;
        }
        for (String acceptedType : fileConfig.Accepted_File_Types__c.replace(';', ',').split(',')) {
            if (String.isBlank(acceptedType)) {
                continue;
            }
            String trimmed = acceptedType.trim();
            Boolean isExtension = Pattern.matches('^\\.[A-Za-z0-9]+$', trimmed);
            Boolean isMimeType = Pattern.matches('^[A-Za-z0-9.+-]+/[A-Za-z0-9.+*-]+$', trimmed);
            if (!isExtension && !isMimeType) {
                addIssue(result, SEVERITY_ERROR, 'FILE_ACCEPT_TYPE_INVALID', 'File Config', fileConfig.DeveloperName, 'Accepted file types must be extensions like .pdf or MIME types like image/png.');
            }
        }
    }

    private static void validateReadableContextField(
        ValidationResult result,
        Schema.DescribeSObjectResult objectDescribe,
        SmartIntake_Context_Config__mdt contextConfig,
        String fieldApiName,
        String missingCode,
        String accessCode
    ) {
        Schema.SObjectField fieldToken = objectDescribe.fields.getMap().get(fieldApiName);
        if (fieldToken == null) {
            addIssue(result, SEVERITY_ERROR, missingCode, 'Context Config', contextConfig.DeveloperName, 'Configured field does not exist on ' + contextConfig.Object_API_Name__c + ': ' + fieldApiName + '.');
            return;
        }

        if (!fieldToken.getDescribe().isAccessible()) {
            addIssue(result, SEVERITY_WARNING, accessCode, 'Context Config', contextConfig.DeveloperName, 'The current user cannot read field ' + fieldApiName + '. Runtime users need field read access for context.');
        }
    }

    private static void addSubmissionReadiness(ReadinessResult result) {
        Schema.DescribeSObjectResult submissionDescribe = SmartIntake_Submission__c.SObjectType.getDescribe();
        if (!submissionDescribe.isCreateable()) {
            addReadinessItem(result, 'submissionObject', 'Runtime Submission Object', READINESS_BLOCKED, 'Runtime users need create access to SmartIntake Submission.');
            return;
        }

        Map<String, Schema.SObjectField> fields = submissionDescribe.fields.getMap();
        List<String> missingAccess = new List<String>();
        for (String fieldApiName : new List<String>{
            'Template_Key__c',
            'Session_Id__c',
            'Answers_JSON__c',
            'Status__c'
        }) {
            Schema.SObjectField fieldToken = fields.get(fieldApiName);
            if (fieldToken == null || !fieldToken.getDescribe().isCreateable()) {
                missingAccess.add(fieldApiName);
            }
        }

        if (missingAccess.isEmpty()) {
            addReadinessItem(result, 'submissionObject', 'Runtime Submission Object', READINESS_READY, 'Current user can create runtime submission state.');
        } else {
            addReadinessItem(
                result,
                'submissionObject',
                'Runtime Submission Object',
                READINESS_BLOCKED,
                'Runtime users need create access to these SmartIntake Submission fields: ' + String.join(missingAccess, ', ') + '.'
            );
        }
    }

    private static void addFileReadiness(ReadinessResult result, String templateKey) {
        Integer activeFileConfigCount = [
            SELECT COUNT()
            FROM SmartIntake_File_Config__mdt
            WHERE Template_Key__c = :templateKey
            AND Is_Active__c = true
        ];
        if (activeFileConfigCount == 0) {
            addReadinessItem(result, 'files', 'Files', READINESS_READY, 'No active file questions require Salesforce Files setup.');
            return;
        }

        Boolean canCreateContentVersion = ContentVersion.SObjectType.getDescribe().isCreateable();
        Boolean canCreateContentDocumentLink = ContentDocumentLink.SObjectType.getDescribe().isCreateable();
        if (canCreateContentVersion && canCreateContentDocumentLink) {
            addReadinessItem(result, 'files', 'Files', READINESS_READY, activeFileConfigCount + ' active file config(s) can use Salesforce Files.');
        } else {
            addReadinessItem(
                result,
                'files',
                'Files',
                READINESS_BLOCKED,
                'Active file questions require create access to ContentVersion and ContentDocumentLink.'
            );
        }
    }

    private static void addBrandingReadiness(ReadinessResult result, String templateKey) {
        Integer activeBrandingCount = [
            SELECT COUNT()
            FROM SmartIntake_Branding_Config__mdt
            WHERE Template_Key__c = :templateKey
            AND Is_Active__c = true
        ];
        if (activeBrandingCount == 1) {
            addReadinessItem(result, 'branding', 'Agent Branding', READINESS_READY, 'One active agent branding record is configured.');
        } else if (activeBrandingCount == 0) {
            addReadinessItem(result, 'branding', 'Agent Branding', READINESS_WARNING, 'No active agent branding record is configured; runtime defaults will be used.');
        } else {
            addReadinessItem(result, 'branding', 'Agent Branding', READINESS_BLOCKED, 'Only one active agent branding record is supported per template.');
        }
    }

    private static void addMessageReadiness(ReadinessResult result, String templateKey) {
        Set<String> messageTemplateKeys = new Set<String>{ templateKey, 'GLOBAL' };
        Integer activeMessageCount = [
            SELECT COUNT()
            FROM SmartIntake_Message__mdt
            WHERE Template_Key__c IN :messageTemplateKeys
            AND Is_Active__c = true
        ];
        if (activeMessageCount > 0) {
            addReadinessItem(result, 'messages', 'User Messages', READINESS_READY, activeMessageCount + ' active global/template message(s) are available.');
        } else {
            addReadinessItem(result, 'messages', 'User Messages', READINESS_WARNING, 'No active global or template messages are configured for friendly runtime fallback text.');
        }
    }

    private static void addHandoffReadiness(ReadinessResult result, String templateKey) {
        List<SmartIntake_Handoff_Config__mdt> handoffConfigs = [
            SELECT Handoff_Config_Key__c, Provider_Type__c, Availability_Mode__c,
                   Handoff_URL__c, Queue_Developer_Name__c,
                   Messaging_Channel_Developer_Name__c, Embedded_Service_Deployment_Name__c,
                   Is_Active__c
            FROM SmartIntake_Handoff_Config__mdt
            WHERE Template_Key__c = :templateKey
            AND Is_Active__c = true
            ORDER BY DeveloperName ASC
            LIMIT 2
        ];
        if (handoffConfigs.isEmpty()) {
            addReadinessItem(result, 'handoff', 'Human Handoff', READINESS_WARNING, 'No active handoff config is set. Intake can run without escalation.');
            return;
        }
        if (handoffConfigs.size() > 1) {
            addReadinessItem(result, 'handoff', 'Human Handoff', READINESS_BLOCKED, 'Only one active handoff config is supported per template.');
            return;
        }

        SmartIntake_Handoff_Config__mdt handoffConfig = handoffConfigs[0];
        String providerType = normalize(handoffConfig.Provider_Type__c);
        if (providerType == 'EXTERNAL_URL') {
            if (String.isBlank(handoffConfig.Handoff_URL__c)) {
                addReadinessItem(result, 'handoff', 'Human Handoff', READINESS_BLOCKED, 'External URL handoff requires Handoff URL.');
            } else {
                addReadinessItem(result, 'handoff', 'Human Handoff', READINESS_READY, 'External URL handoff is configured.');
            }
            return;
        }

        if (providerType == 'ENHANCED_OMNI' || providerType == 'ENHANCED_CHAT_V2') {
            addReadinessItem(
                result,
                'handoff',
                'Human Handoff',
                READINESS_MANUAL,
                'Verify Service or Chat entitlement, routing, channel or deployment activation, and agent availability in Setup for ' + handoffConfig.Provider_Type__c + '.'
            );
            return;
        }

        addReadinessItem(result, 'handoff', 'Human Handoff', READINESS_BLOCKED, 'Unsupported handoff provider: ' + display(handoffConfig.Provider_Type__c) + '.');
    }

    private static void validateTemplateDraftBasics(BuilderPlan plan, TemplateDraft draft) {
        if (String.isBlank(plan.templateKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'SETUP_TEMPLATE_KEY_REQUIRED', 'Setup Wizard', null, 'Template Key is required.');
        } else {
            if (!Pattern.matches('^[A-Z][A-Z0-9_]{1,79}$', plan.templateKey)) {
                addBuilderIssue(plan, SEVERITY_ERROR, 'SETUP_TEMPLATE_KEY_INVALID', 'Setup Wizard', plan.templateKey, 'Template Key must start with a letter and contain only uppercase letters, numbers, and underscores.');
            }
            Integer templateCount = [
                SELECT COUNT()
                FROM SmartIntake_Template__mdt
                WHERE Template_Key__c = :plan.templateKey
            ];
            if (templateCount > 0) {
                addBuilderIssue(plan, SEVERITY_ERROR, 'SETUP_TEMPLATE_KEY_EXISTS', 'Setup Wizard', plan.templateKey, 'This template key already exists.');
            }
        }

        if (String.isBlank(draft.templateName)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'SETUP_TEMPLATE_NAME_REQUIRED', 'Setup Wizard', plan.templateKey, 'Template Name is required.');
        }
        if (!String.isBlank(draft.startQuestionKey) && !Pattern.matches('^[A-Za-z][A-Za-z0-9_]{1,79}$', draft.startQuestionKey.trim())) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'SETUP_START_QUESTION_INVALID', 'Setup Wizard', plan.templateKey, 'Start Question Key must start with a letter and contain only letters, numbers, and underscores.');
        }
        if (draft.requiresConsent == true && String.isBlank(draft.consentMessage)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'SETUP_CONSENT_MESSAGE_REQUIRED', 'Setup Wizard', plan.templateKey, 'Consent Message is required when consent is enabled.');
        }
        if (draft.createBranding == true && String.isBlank(draft.agentDisplayName)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'SETUP_AGENT_NAME_REQUIRED', 'Setup Wizard', plan.templateKey, 'Agent Display Name is required when branding is created.');
        }
    }

    private static void addBrandingStarterRecord(BuilderPlan plan, TemplateDraft draft) {
        String brandingRecordName = metadataRecordName(plan.templateKey, 'agent_branding');
        BuilderRecord brandingRecord = newBuilderRecord(
            'SmartIntake_Branding_Config__mdt',
            customMetadataFullName(SmartIntake_Branding_Config__mdt.SObjectType, brandingRecordName),
            'Agent Branding'
        );
        brandingRecord.metadataLabel = metadataLabel(draft.agentDisplayName, plan.templateKey + ' Agent');
        addBuilderField(brandingRecord, 'Template_Key__c', plan.templateKey);
        addBuilderField(brandingRecord, 'Agent_Display_Name__c', draft.agentDisplayName);
        addBuilderField(brandingRecord, 'Avatar_Icon_Name__c', defaultAvatarIconName(draft));
        addBuilderField(brandingRecord, 'Avatar_Image_URL__c', draft.avatarImageUrl);
        addBuilderField(brandingRecord, 'Welcome_Message__c', defaultWelcomeMessage(draft));
        addBuilderField(brandingRecord, 'Is_Active__c', true);
        plan.records.add(brandingRecord);
    }

    private static void validateAdminConfigDraftBasics(BuilderPlan plan, AdminConfigDraft draft) {
        if (String.isBlank(plan.configType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'ADMIN_CONFIG_TYPE_REQUIRED', 'Admin Config Builder', null, 'Configuration Type is required.');
        }
        if (String.isBlank(plan.configKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'ADMIN_CONFIG_KEY_REQUIRED', 'Admin Config Builder', plan.configType, 'Configuration Key is required.');
        } else if (!Pattern.matches('^[A-Za-z][A-Za-z0-9_]{1,79}$', plan.configKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'ADMIN_CONFIG_KEY_INVALID', 'Admin Config Builder', plan.configKey, 'Configuration Key must start with a letter and contain only letters, numbers, and underscores.');
        }

        if (String.isBlank(plan.templateKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'ADMIN_CONFIG_TEMPLATE_REQUIRED', 'Admin Config Builder', plan.configKey, 'Template Key is required. Use GLOBAL only for shared message fallback records.');
            return;
        }
        if (plan.templateKey != 'GLOBAL' && !templateExists(plan.templateKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'ADMIN_CONFIG_TEMPLATE_NOT_FOUND', 'Admin Config Builder', plan.templateKey, 'No SmartIntake template exists for this key.');
        }
        if (plan.templateKey == 'GLOBAL' && normalize(draft.configType) != 'MESSAGE') {
            addBuilderIssue(plan, SEVERITY_ERROR, 'ADMIN_CONFIG_GLOBAL_ONLY_FOR_MESSAGES', 'Admin Config Builder', plan.configKey, 'GLOBAL configuration is supported only for shared message records.');
        }
    }

    private static void addBrandingConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        if (String.isBlank(draft.agentDisplayName)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BRANDING_AGENT_NAME_REQUIRED', 'Branding Config', plan.configKey, 'Agent Display Name is required.');
        }

        BuilderRecord record = newBuilderRecord(
            'SmartIntake_Branding_Config__mdt',
            customMetadataFullName(SmartIntake_Branding_Config__mdt.SObjectType, metadataRecordName(plan.templateKey, plan.configKey)),
            'Branding Config'
        );
        record.metadataLabel = metadataLabel(draft.label, draft.agentDisplayName);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'Agent_Display_Name__c', draft.agentDisplayName);
        addBuilderField(record, 'Avatar_Icon_Name__c', draft.avatarIconName);
        addBuilderField(record, 'Avatar_Image_URL__c', draft.avatarImageUrl);
        addBuilderField(record, 'Welcome_Message__c', draft.welcomeMessage);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static void addMessageConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        if (String.isBlank(draft.messageType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'MESSAGE_TYPE_REQUIRED', 'Message Config', plan.configKey, 'Message Type is required.');
        }
        if (String.isBlank(draft.messageText)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'MESSAGE_TEXT_REQUIRED', 'Message Config', plan.configKey, 'Message Text is required.');
        }

        BuilderRecord record = newBuilderRecord(
            'SmartIntake_Message__mdt',
            customMetadataFullName(
                SmartIntake_Message__mdt.SObjectType,
                existingMetadataRecordName(SmartIntake_Message__mdt.SObjectType, plan.templateKey, 'Message_Key__c', plan.configKey, metadataRecordName(plan.templateKey, plan.configKey))
            ),
            'Message Config'
        );
        record.metadataLabel = metadataLabel(draft.label, plan.configKey);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'Message_Key__c', plan.configKey);
        addBuilderField(record, 'Message_Type__c', draft.messageType);
        addBuilderField(record, 'Message_Text__c', draft.messageText);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static void addHandoffConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        String providerType = normalize(draft.providerType);
        String availabilityMode = normalize(draft.availabilityMode);
        if (String.isBlank(providerType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HANDOFF_PROVIDER_REQUIRED', 'Handoff Config', plan.configKey, 'Provider Type is required.');
        } else if (!SUPPORTED_HANDOFF_PROVIDER_TYPES.contains(providerType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HANDOFF_PROVIDER_UNSUPPORTED', 'Handoff Config', plan.configKey, 'Provider Type must be ENHANCED_OMNI, ENHANCED_CHAT_V2, or EXTERNAL_URL.');
        }
        if (String.isBlank(availabilityMode)) {
            availabilityMode = 'CONFIGURED';
        }
        if (!SUPPORTED_HANDOFF_AVAILABILITY_MODES.contains(availabilityMode)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HANDOFF_AVAILABILITY_UNSUPPORTED', 'Handoff Config', plan.configKey, 'Availability Mode must be CONFIGURED, ALWAYS_AVAILABLE, or ALWAYS_OFFLINE.');
        }
        if (draft.requiresConsent == true && String.isBlank(draft.consentMessage)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HANDOFF_CONSENT_REQUIRED', 'Handoff Config', plan.configKey, 'Consent Message is required when handoff consent is enabled.');
        }
        if (providerType == 'ENHANCED_OMNI' && String.isBlank(draft.queueDeveloperName)) {
            addBuilderIssue(plan, SEVERITY_WARNING, 'HANDOFF_QUEUE_RECOMMENDED', 'Handoff Config', plan.configKey, 'Enhanced Omni-Channel should include Queue Developer Name.');
        }
        if (providerType == 'ENHANCED_CHAT_V2' &&
            String.isBlank(draft.messagingChannelDeveloperName) &&
            String.isBlank(draft.embeddedServiceDeploymentName)) {
            addBuilderIssue(plan, SEVERITY_WARNING, 'HANDOFF_CHAT_DEPLOYMENT_RECOMMENDED', 'Handoff Config', plan.configKey, 'Enhanced Chat v2 should include Messaging Channel Developer Name or Embedded Service Deployment Name.');
        }
        if (providerType == 'EXTERNAL_URL' && String.isBlank(draft.handoffUrl)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HANDOFF_URL_REQUIRED', 'Handoff Config', plan.configKey, 'External URL handoff requires Handoff URL.');
        }
        if (draft.isContextSharingEnabled == true && String.isBlank(draft.contextFieldsToShare)) {
            addBuilderIssue(plan, SEVERITY_WARNING, 'HANDOFF_CONTEXT_FIELDS_RECOMMENDED', 'Handoff Config', plan.configKey, 'Context sharing should list the answer keys to share.');
        }

        BuilderRecord record = newBuilderRecord(
            'SmartIntake_Handoff_Config__mdt',
            customMetadataFullName(
                SmartIntake_Handoff_Config__mdt.SObjectType,
                existingMetadataRecordName(SmartIntake_Handoff_Config__mdt.SObjectType, plan.templateKey, 'Handoff_Config_Key__c', plan.configKey, metadataRecordName(plan.templateKey, plan.configKey))
            ),
            'Handoff Config'
        );
        record.metadataLabel = metadataLabel(draft.label, plan.configKey);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'Handoff_Config_Key__c', plan.configKey);
        addBuilderField(record, 'Provider_Type__c', providerType);
        addBuilderField(record, 'Availability_Mode__c', availabilityMode);
        addBuilderField(record, 'Trigger_Message__c', draft.triggerMessage);
        addBuilderField(record, 'Available_Message__c', draft.availableMessage);
        addBuilderField(record, 'Offline_Message__c', draft.offlineMessage);
        addBuilderField(record, 'Declined_Message__c', draft.declinedMessage);
        addBuilderField(record, 'Requires_Consent__c', draft.requiresConsent == true);
        addBuilderField(record, 'Consent_Message__c', draft.consentMessage);
        addBuilderField(record, 'Queue_Developer_Name__c', draft.queueDeveloperName);
        addBuilderField(record, 'Messaging_Channel_Developer_Name__c', draft.messagingChannelDeveloperName);
        addBuilderField(record, 'Embedded_Service_Deployment_Name__c', draft.embeddedServiceDeploymentName);
        addBuilderField(record, 'Handoff_URL__c', draft.handoffUrl);
        addBuilderField(record, 'Is_Context_Sharing_Enabled__c', draft.isContextSharingEnabled == true);
        addBuilderField(record, 'Context_Fields_To_Share__c', draft.contextFieldsToShare);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static void addMatchingRuleConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        validateQuestionKeyForConfig(plan, draft.questionKey, 'Matching Rule');
        validateObjectAndFieldForConfig(plan, draft.objectApiName, draft.fieldApiName, 'Matching Rule', true);
        if (!String.isBlank(draft.displayFieldApiName)) {
            validateObjectAndFieldForConfig(plan, draft.objectApiName, draft.displayFieldApiName, 'Matching Rule', false);
        }
        String matchType = normalize(draft.matchType);
        if (String.isBlank(matchType)) {
            matchType = 'EXACT';
        }
        if (!SUPPORTED_MATCH_TYPES.contains(matchType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'MATCH_TYPE_UNSUPPORTED', 'Matching Rule', plan.configKey, 'Only EXACT matching is supported in this MVP runtime.');
        }

        BuilderRecord record = newBuilderRecord(
            'SmartIntake_Matching_Rule__mdt',
            customMetadataFullName(
                SmartIntake_Matching_Rule__mdt.SObjectType,
                existingMetadataRecordName(SmartIntake_Matching_Rule__mdt.SObjectType, plan.templateKey, 'Matching_Rule_Key__c', plan.configKey, metadataRecordName(plan.templateKey, plan.configKey))
            ),
            'Matching Rule'
        );
        record.metadataLabel = metadataLabel(draft.label, plan.configKey);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'Matching_Rule_Key__c', plan.configKey);
        addBuilderField(record, 'Question_Key__c', draft.questionKey);
        addBuilderField(record, 'Object_API_Name__c', draft.objectApiName);
        addBuilderField(record, 'Field_API_Name__c', draft.fieldApiName);
        addBuilderField(record, 'Display_Field_API_Name__c', draft.displayFieldApiName);
        addBuilderField(record, 'Match_Type__c', matchType);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static void addContextConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        validateQuestionKeyForConfig(plan, draft.questionKey, 'Context Config');
        validateObjectAndFieldForConfig(plan, draft.objectApiName, draft.displayFieldApiName, 'Context Config', true);
        if (!String.isBlank(draft.filterFieldApiName)) {
            validateObjectAndFieldForConfig(plan, draft.objectApiName, draft.filterFieldApiName, 'Context Config', false);
        }
        if (String.isBlank(draft.filterSourceQuestionKey)) {
            addBuilderIssue(plan, SEVERITY_WARNING, 'CONTEXT_FILTER_SOURCE_RECOMMENDED', 'Context Config', plan.configKey, 'Filter Source Question Key is recommended so context stays relevant to current answers.');
        } else {
            validateQuestionKeyForConfig(plan, draft.filterSourceQuestionKey, 'Context Config');
        }
        String contextType = normalize(draft.contextType);
        if (String.isBlank(contextType)) {
            contextType = 'MATCHED_RECORDS';
        }
        if (!SUPPORTED_CONTEXT_TYPES.contains(contextType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'CONTEXT_TYPE_UNSUPPORTED', 'Context Config', plan.configKey, 'Only MATCHED_RECORDS context is supported in this MVP runtime.');
        }
        if (draft.maxRecords != null && (draft.maxRecords <= 0 || draft.maxRecords > 10)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'CONTEXT_MAX_RECORDS_OUT_OF_RANGE', 'Context Config', plan.configKey, 'Max Records must be between 1 and 10.');
        }

        BuilderRecord record = newBuilderRecord(
            'SmartIntake_Context_Config__mdt',
            customMetadataFullName(
                SmartIntake_Context_Config__mdt.SObjectType,
                existingMetadataRecordName(SmartIntake_Context_Config__mdt.SObjectType, plan.templateKey, 'Context_Config_Key__c', plan.configKey, metadataRecordName(plan.templateKey, plan.configKey))
            ),
            'Context Config'
        );
        record.metadataLabel = metadataLabel(draft.label, plan.configKey);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'Context_Config_Key__c', plan.configKey);
        addBuilderField(record, 'Question_Key__c', draft.questionKey);
        addBuilderField(record, 'Context_Type__c', contextType);
        addBuilderField(record, 'Context_Message__c', draft.contextMessage);
        addBuilderField(record, 'Object_API_Name__c', draft.objectApiName);
        addBuilderField(record, 'Filter_Field_API_Name__c', draft.filterFieldApiName);
        addBuilderField(record, 'Filter_Source_Question_Key__c', draft.filterSourceQuestionKey);
        addBuilderField(record, 'Display_Field_API_Name__c', draft.displayFieldApiName);
        addBuilderField(record, 'Allowed_Actions__c', draft.allowedActions);
        addBuilderField(record, 'Max_Records__c', draft.maxRecords == null ? 5 : draft.maxRecords);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static void addValidationRuleConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        validateQuestionKeyForConfig(plan, draft.questionKey, 'Validation Rule');
        String validationType = normalize(draft.validationType);
        if (String.isBlank(validationType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_TYPE_REQUIRED', 'Validation Rule', plan.configKey, 'Validation Type is required.');
        } else if (!SUPPORTED_VALIDATION_TYPES.contains(validationType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_TYPE_UNSUPPORTED', 'Validation Rule', plan.configKey, 'Validation Type is not supported.');
        }
        if (validationType == 'REGEX' && String.isBlank(draft.regex)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_REGEX_REQUIRED', 'Validation Rule', plan.configKey, 'Regex is required for REGEX validation.');
        }
        if (validationType == 'MIN_LENGTH' && draft.minLength == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_MIN_LENGTH_REQUIRED', 'Validation Rule', plan.configKey, 'Min Length is required for MIN_LENGTH validation.');
        }
        if (validationType == 'MAX_LENGTH' && draft.maxLength == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_MAX_LENGTH_REQUIRED', 'Validation Rule', plan.configKey, 'Max Length is required for MAX_LENGTH validation.');
        }
        if (validationType == 'MIN_VALUE' && draft.minValue == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_MIN_VALUE_REQUIRED', 'Validation Rule', plan.configKey, 'Min Value is required for MIN_VALUE validation.');
        }
        if (validationType == 'MAX_VALUE' && draft.maxValue == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_MAX_VALUE_REQUIRED', 'Validation Rule', plan.configKey, 'Max Value is required for MAX_VALUE validation.');
        }
        Date minDate = parseDraftDate(plan, draft.minDate, 'Min Date', 'Validation Rule');
        Date maxDate = parseDraftDate(plan, draft.maxDate, 'Max Date', 'Validation Rule');
        if (validationType == 'MIN_DATE' && minDate == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_MIN_DATE_REQUIRED', 'Validation Rule', plan.configKey, 'Min Date is required for MIN_DATE validation.');
        }
        if (validationType == 'MAX_DATE' && maxDate == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_MAX_DATE_REQUIRED', 'Validation Rule', plan.configKey, 'Max Date is required for MAX_DATE validation.');
        }
        if (draft.minLength != null && draft.maxLength != null && draft.minLength > draft.maxLength) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_LENGTH_RANGE_INVALID', 'Validation Rule', plan.configKey, 'Min Length cannot be greater than Max Length.');
        }
        if (draft.minValue != null && draft.maxValue != null && draft.minValue > draft.maxValue) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_VALUE_RANGE_INVALID', 'Validation Rule', plan.configKey, 'Min Value cannot be greater than Max Value.');
        }
        if (minDate != null && maxDate != null && minDate > maxDate) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'VALIDATION_DATE_RANGE_INVALID', 'Validation Rule', plan.configKey, 'Min Date cannot be after Max Date.');
        }

        BuilderRecord record = newBuilderRecord(
            'SmartIntake_Validation_Rule__mdt',
            customMetadataFullName(
                SmartIntake_Validation_Rule__mdt.SObjectType,
                existingMetadataRecordName(SmartIntake_Validation_Rule__mdt.SObjectType, plan.templateKey, 'Validation_Rule_Key__c', plan.configKey, metadataRecordName(plan.templateKey, plan.configKey))
            ),
            'Validation Rule'
        );
        record.metadataLabel = metadataLabel(draft.label, plan.configKey);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'Validation_Rule_Key__c', plan.configKey);
        addBuilderField(record, 'Question_Key__c', draft.questionKey);
        addBuilderField(record, 'Validation_Type__c', validationType);
        addBuilderField(record, 'Regex__c', draft.regex);
        addBuilderField(record, 'Min_Length__c', draft.minLength);
        addBuilderField(record, 'Max_Length__c', draft.maxLength);
        addBuilderField(record, 'Min_Value__c', draft.minValue);
        addBuilderField(record, 'Max_Value__c', draft.maxValue);
        addBuilderField(record, 'Min_Date__c', minDate);
        addBuilderField(record, 'Max_Date__c', maxDate);
        addBuilderField(record, 'Sort_Order__c', draft.sortOrder == null ? 10 : draft.sortOrder);
        addBuilderField(record, 'Error_Message__c', draft.errorMessage);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static void addConditionConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        validateQuestionKeyForConfig(plan, draft.sourceQuestionKey, 'Condition');
        validateQuestionKeyForConfig(plan, draft.targetQuestionKey, 'Condition');
        String action = normalize(draft.action);
        String operator = normalize(draft.operator);
        if (String.isBlank(action)) {
            action = 'SHOW_WHEN';
        }
        if (String.isBlank(operator)) {
            operator = 'EQUALS';
        }
        if (!SUPPORTED_CONDITION_ACTIONS.contains(action)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'CONDITION_ACTION_UNSUPPORTED', 'Condition', plan.configKey, 'Action must be SHOW_WHEN, HIDE_WHEN, or BLOCK_WHEN.');
        }
        if (!SUPPORTED_CONDITION_OPERATORS.contains(operator)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'CONDITION_OPERATOR_UNSUPPORTED', 'Condition', plan.configKey, 'Operator is not supported.');
        }
        if (CONDITION_OPERATORS_REQUIRING_COMPARE_VALUE.contains(operator) && String.isBlank(draft.compareValue)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'CONDITION_COMPARE_VALUE_REQUIRED', 'Condition', plan.configKey, 'Compare Value is required for this operator.');
        }
        if (!String.isBlank(draft.sourceQuestionKey) && draft.sourceQuestionKey == draft.targetQuestionKey && action != 'BLOCK_WHEN') {
            addBuilderIssue(plan, SEVERITY_ERROR, 'CONDITION_SELF_REFERENCE', 'Condition', plan.configKey, 'Source and Target Question Key can match only for BLOCK_WHEN validation rules.');
        }
        String conditionLogic = String.isBlank(draft.conditionLogic) ? 'ALL' : normalize(draft.conditionLogic);
        if (!SUPPORTED_CONDITION_LOGICS.contains(conditionLogic)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'CONDITION_LOGIC_UNSUPPORTED', 'Condition', plan.configKey, 'Condition Logic must be ALL, ANY, or CUSTOM.');
        }
        if (conditionLogic == 'CUSTOM' && String.isBlank(draft.customLogic)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'CONDITION_CUSTOM_LOGIC_REQUIRED', 'Condition', plan.configKey, 'Custom Logic is required when Condition Logic is CUSTOM.');
        }
        if (draft.conditionNumber != null && draft.conditionNumber <= 0) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'CONDITION_NUMBER_INVALID', 'Condition', plan.configKey, 'Condition Number must be greater than zero.');
        }

        BuilderRecord record = newBuilderRecord(
            'SmartIntake_Condition__mdt',
            customMetadataFullName(
                SmartIntake_Condition__mdt.SObjectType,
                existingMetadataRecordName(SmartIntake_Condition__mdt.SObjectType, plan.templateKey, 'Condition_Key__c', plan.configKey, metadataRecordName(plan.templateKey, plan.configKey))
            ),
            'Condition'
        );
        record.metadataLabel = metadataLabel(draft.label, plan.configKey);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'Condition_Key__c', plan.configKey);
        addBuilderField(record, 'Source_Question_Key__c', draft.sourceQuestionKey);
        addBuilderField(record, 'Operator__c', operator);
        addBuilderField(record, 'Compare_Value__c', draft.compareValue);
        addBuilderField(record, 'Action__c', action);
        addBuilderField(record, 'Target_Question_Key__c', draft.targetQuestionKey);
        addBuilderField(record, 'Condition_Group_Key__c', draft.conditionGroupKey);
        addBuilderField(record, 'Condition_Logic__c', conditionLogic);
        addBuilderField(record, 'Condition_Number__c', draft.conditionNumber);
        addBuilderField(record, 'Custom_Logic__c', draft.customLogic);
        addBuilderField(record, 'User_Message__c', draft.userMessage);
        addBuilderField(record, 'Sort_Order__c', draft.sortOrder == null ? 10 : draft.sortOrder);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static void addHookConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        validateQuestionKeyForConfig(plan, draft.questionKey, 'Hook');
        String eventName = normalize(draft.eventName);
        String handlerType = normalize(draft.handlerType);
        if (String.isBlank(eventName)) {
            eventName = 'AFTER_ANSWER';
        }
        if (String.isBlank(handlerType)) {
            handlerType = 'FLOW';
        }
        String outputMode = hookOutputMode(draft.outputMode, draft.flowOutputMappings);
        if (!SUPPORTED_HOOK_EVENTS.contains(eventName)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HOOK_EVENT_UNSUPPORTED', 'Hook', plan.configKey, 'Hook Event must be AFTER_ANSWER.');
        }
        if (!SUPPORTED_HOOK_HANDLER_TYPES.contains(handlerType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HOOK_HANDLER_UNSUPPORTED', 'Hook', plan.configKey, 'Hook Handler Type must be FLOW.');
        }
        if (handlerType == 'FLOW' && String.isBlank(draft.flowApiName)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HOOK_FLOW_REQUIRED', 'Hook', plan.configKey, 'Flow API Name is required for Flow hooks.');
        } else if (!String.isBlank(draft.flowApiName) && !isValidApiName(draft.flowApiName)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HOOK_FLOW_API_NAME_INVALID', 'Hook', plan.configKey, 'Flow API Name must be a valid Salesforce API name.');
        }
        if (!SUPPORTED_HOOK_OUTPUT_MODES.contains(outputMode)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'HOOK_OUTPUT_MODE_UNSUPPORTED', 'Hook', plan.configKey, 'Output Mode must be BASIC_OUTPUT_MAPPING or ADVANCED_JSON_OVERRIDE.');
        } else if (outputMode == 'BASIC_OUTPUT_MAPPING') {
            for (FlowOutputMappingParts mapping : parseFlowOutputMappings(draft.flowOutputMappings)) {
                if (!mapping.isValid) {
                    addBuilderIssue(plan, SEVERITY_ERROR, mapping.errorCode, 'Hook', plan.configKey, mapping.errorMessage);
                }
            }
        } else if (!String.isBlank(draft.flowOutputMappings)) {
            addBuilderIssue(plan, SEVERITY_WARNING, 'HOOK_OUTPUT_MAPPINGS_IGNORED', 'Hook', plan.configKey, 'Flow Output Mappings are ignored in Advanced JSON Override mode.');
        }
        for (FlowInputMappingParts mapping : parseFlowInputMappings(draft.flowInputMappings)) {
            if (!mapping.isValid) {
                addBuilderIssue(plan, SEVERITY_ERROR, mapping.errorCode, 'Hook', plan.configKey, mapping.errorMessage);
            }
        }

        BuilderRecord record = newBuilderRecord(
            'SmartIntake_Hook__mdt',
            customMetadataFullName(
                SmartIntake_Hook__mdt.SObjectType,
                existingMetadataRecordName(SmartIntake_Hook__mdt.SObjectType, plan.templateKey, 'Hook_Key__c', plan.configKey, metadataRecordName(plan.templateKey, plan.configKey))
            ),
            'Flow Hook'
        );
        record.metadataLabel = metadataLabel(draft.label, plan.configKey);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'Hook_Key__c', plan.configKey);
        addBuilderField(record, 'Question_Key__c', draft.questionKey);
        addBuilderField(record, 'Event__c', eventName);
        addBuilderField(record, 'Handler_Type__c', handlerType);
        addBuilderField(record, 'Flow_API_Name__c', draft.flowApiName);
        addBuilderField(record, 'Output_Mode__c', outputMode);
        addBuilderField(record, 'Flow_Input_Mappings__c', draft.flowInputMappings);
        addBuilderField(record, 'Flow_Output_Mappings__c', draft.flowOutputMappings);
        addBuilderField(record, 'Success_Output_Variable__c', draft.successOutputVariable);
        addBuilderField(record, 'User_Message_Output_Variable__c', draft.userMessageOutputVariable);
        addBuilderField(record, 'Next_Question_Output_Variable__c', draft.nextQuestionOutputVariable);
        addBuilderField(record, 'Answers_JSON_Output_Variable__c', draft.answersJsonOutputVariable);
        addBuilderField(record, 'Block_Continue_Output_Variable__c', draft.blockContinueOutputVariable);
        addBuilderField(record, 'Sort_Order__c', draft.sortOrder == null ? 10 : draft.sortOrder);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static void addStandaloneFileConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        validateQuestionKeyForConfig(plan, draft.questionKey, 'File Config');
        Decimal maxFileCount = draft.maxFileCount == null ? (draft.allowMultipleFiles == true ? 5 : 1) : draft.maxFileCount;
        if (maxFileCount <= 0 || maxFileCount > 25) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'FILE_MAX_COUNT_OUT_OF_RANGE', 'File Config', plan.configKey, 'Max File Count must be between 1 and 25.');
        }
        String shareType = String.isBlank(draft.shareType) ? 'V' : draft.shareType.trim();
        String visibility = String.isBlank(draft.visibility) ? 'AllUsers' : draft.visibility.trim();
        if (!SUPPORTED_FILE_SHARE_TYPES.contains(shareType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'FILE_SHARE_TYPE_UNSUPPORTED', 'File Config', plan.configKey, 'Share Type must be V, C, or I.');
        }
        if (!SUPPORTED_FILE_VISIBILITIES.contains(visibility)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'FILE_VISIBILITY_UNSUPPORTED', 'File Config', plan.configKey, 'Visibility must be AllUsers, InternalUsers, or SharedUsers.');
        }

        BuilderRecord record = newBuilderRecord(
            'SmartIntake_File_Config__mdt',
            customMetadataFullName(
                SmartIntake_File_Config__mdt.SObjectType,
                existingMetadataRecordName(SmartIntake_File_Config__mdt.SObjectType, plan.templateKey, 'File_Config_Key__c', plan.configKey, metadataRecordName(plan.templateKey, plan.configKey))
            ),
            'File Config'
        );
        record.metadataLabel = metadataLabel(draft.label, plan.configKey);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'File_Config_Key__c', plan.configKey);
        addBuilderField(record, 'Question_Key__c', draft.questionKey);
        addBuilderField(record, 'Accepted_File_Types__c', draft.acceptedFileTypes);
        addBuilderField(record, 'Allow_Multiple__c', draft.allowMultipleFiles == true);
        addBuilderField(record, 'Max_File_Count__c', maxFileCount);
        addBuilderField(record, 'Link_To_Final_Record__c', draft.linkToFinalRecord != false);
        addBuilderField(record, 'Share_Type__c', shareType);
        addBuilderField(record, 'Visibility__c', visibility);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static void addFieldBindingConfigRecord(BuilderPlan plan, AdminConfigDraft draft) {
        validateFieldBindingSourceKeyForConfig(plan, draft.questionKey);
        validateObjectAndFieldForConfig(plan, draft.objectApiName, draft.fieldApiName, 'Field Binding', true);

        String fallbackRecordName = metadataRecordName(plan.templateKey, plan.configKey);
        BuilderRecord record = newBuilderRecord(
            'SmartIntake_Field_Binding__mdt',
            customMetadataFullName(
                SmartIntake_Field_Binding__mdt.SObjectType,
                existingFieldBindingRecordName(
                    plan.templateKey,
                    plan.configKey,
                    draft.questionKey,
                    fallbackRecordName
                )
            ),
            'Field Binding'
        );
        record.metadataLabel = metadataLabel(draft.label, plan.configKey);
        addBuilderField(record, 'Template_Key__c', plan.templateKey);
        addBuilderField(record, 'Question_Key__c', draft.questionKey);
        addBuilderField(record, 'Object_API_Name__c', draft.objectApiName);
        addBuilderField(record, 'Field_API_Name__c', draft.fieldApiName);
        addBuilderField(record, 'Is_Active__c', draft.isActive != false);
        plan.records.add(record);
    }

    private static String existingFieldBindingRecordName(
        String templateKey,
        String configKey,
        String sourceKey,
        String fallbackName
    ) {
        if (String.isBlank(templateKey)) {
            return fallbackName;
        }
        List<SmartIntake_Field_Binding__mdt> exactMatches = String.isBlank(configKey)
            ? new List<SmartIntake_Field_Binding__mdt>()
            : [
                SELECT DeveloperName
                FROM SmartIntake_Field_Binding__mdt
                WHERE Template_Key__c = :templateKey
                  AND DeveloperName = :configKey
                LIMIT 1
            ];
        if (!exactMatches.isEmpty()) {
            return exactMatches[0].DeveloperName;
        }
        if (String.isBlank(sourceKey)) {
            return fallbackName;
        }
        List<SmartIntake_Field_Binding__mdt> sourceMatches = [
            SELECT DeveloperName, Question_Key__c, Is_Active__c
            FROM SmartIntake_Field_Binding__mdt
            WHERE Template_Key__c = :templateKey
              AND Question_Key__c = :sourceKey
            ORDER BY Is_Active__c DESC, DeveloperName ASC
        ];
        return sourceMatches.isEmpty() ? fallbackName : sourceMatches[0].DeveloperName;
    }

    private static void validateFieldBindingSourceKeyForConfig(BuilderPlan plan, String sourceKey) {
        if (String.isBlank(sourceKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'FIELD_BINDING_SOURCE_REQUIRED', 'Field Binding', plan.configKey, 'Source Key is required.');
            return;
        }
        if (questionExists(plan.templateKey, sourceKey)) {
            return;
        }
        List<SmartIntake_Hook__mdt> hooks = [
            SELECT Output_Mode__c, Flow_Output_Mappings__c, Is_Active__c
            FROM SmartIntake_Hook__mdt
            WHERE Template_Key__c = :plan.templateKey
        ];
        if (!mappedHookOutputStoreKeys(hooks).contains(sourceKey)) {
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'FIELD_BINDING_SOURCE_NOT_FOUND',
                'Field Binding',
                plan.configKey,
                'Source Key must match an active question or a Flow Output Mapping Store As key.'
            );
        }
    }

    private static void validateQuestionKeyForConfig(BuilderPlan plan, String questionKey, String componentType) {
        if (String.isBlank(questionKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, componentType.replace(' ', '_').toUpperCase() + '_QUESTION_REQUIRED', componentType, plan.configKey, 'Question Key is required.');
            return;
        }
        if (!questionExists(plan.templateKey, questionKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, componentType.replace(' ', '_').toUpperCase() + '_QUESTION_NOT_FOUND', componentType, plan.configKey, 'No active question exists for this key: ' + questionKey + '.');
        }
    }

    private static void validateObjectAndFieldForConfig(
        BuilderPlan plan,
        String objectApiName,
        String fieldApiName,
        String componentType,
        Boolean requireField
    ) {
        if (String.isBlank(objectApiName)) {
            addBuilderIssue(plan, SEVERITY_ERROR, componentType.replace(' ', '_').toUpperCase() + '_OBJECT_REQUIRED', componentType, plan.configKey, 'Object API Name is required.');
            return;
        }
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, componentType.replace(' ', '_').toUpperCase() + '_OBJECT_NOT_FOUND', componentType, plan.configKey, 'Configured object does not exist: ' + objectApiName + '.');
            return;
        }
        if (String.isBlank(fieldApiName)) {
            if (requireField) {
                addBuilderIssue(plan, SEVERITY_ERROR, componentType.replace(' ', '_').toUpperCase() + '_FIELD_REQUIRED', componentType, plan.configKey, 'Field API Name is required.');
            }
            return;
        }
        if (!objectType.getDescribe().fields.getMap().containsKey(fieldApiName)) {
            addBuilderIssue(plan, SEVERITY_ERROR, componentType.replace(' ', '_').toUpperCase() + '_FIELD_NOT_FOUND', componentType, plan.configKey, 'Configured field does not exist on ' + objectApiName + ': ' + fieldApiName + '.');
        }
    }

    private static Date parseDraftDate(BuilderPlan plan, String value, String label, String componentType) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            return Date.valueOf(value.trim());
        } catch (Exception ex) {
            addBuilderIssue(plan, SEVERITY_ERROR, componentType.replace(' ', '_').toUpperCase() + '_' + label.replace(' ', '_').toUpperCase() + '_INVALID', componentType, plan.configKey, label + ' must use YYYY-MM-DD format.');
            return null;
        }
    }

    private static Boolean templateExists(String templateKey) {
        if (String.isBlank(templateKey)) {
            return false;
        }
        Integer templateCount = [
            SELECT COUNT()
            FROM SmartIntake_Template__mdt
            WHERE Template_Key__c = :templateKey
        ];
        return templateCount > 0;
    }

    private static Boolean questionExists(String templateKey, String questionKey) {
        if (String.isBlank(templateKey) || String.isBlank(questionKey)) {
            return false;
        }
        Integer questionCount = [
            SELECT COUNT()
            FROM SmartIntake_Question__mdt
            WHERE Template_Key__c = :templateKey
            AND Question_Key__c = :questionKey
            AND Is_Active__c = true
        ];
        return questionCount > 0;
    }

    private static void addExistingConfigUpdateNotice(BuilderPlan plan) {
        if (plan.records != null && !plan.records.isEmpty()) {
            plan.metadataWriteNotice += ' If the metadata full name already exists, Salesforce updates that record instead of creating a duplicate.';
        }
    }

    private static BuilderPlan deployMetadataPlan(
        BuilderPlan plan,
        Boolean confirmed,
        String componentType,
        String componentKey
    ) {
        if (!plan.isValid) {
            plan.metadataWriteStatus = 'BLOCKED';
            plan.metadataWriteNotice = 'Fix the validation errors before deploying Custom Metadata.';
            return finishBuilderPlan(plan);
        }
        if (confirmed != true) {
            plan.metadataWriteStatus = 'CONFIRMATION_REQUIRED';
            plan.metadataWriteNotice = 'Confirm that SmartIntake can create or update Custom Metadata records in this org.';
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'METADATA_DEPLOY_CONFIRMATION_REQUIRED',
                componentType,
                componentKey,
                'Deployment confirmation is required before metadata can be queued.'
            );
            return finishBuilderPlan(plan);
        }
        if (!currentUserCanDeployMetadata()) {
            plan.metadataWriteStatus = 'PERMISSION_REQUIRED';
            plan.metadataWriteNotice = 'The current user needs API Enabled and Modify Metadata Through Metadata API Functions or Modify All Data before SmartIntake can queue this deployment.';
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'METADATA_DEPLOY_PERMISSION_REQUIRED',
                componentType,
                componentKey,
                'Assign metadata deployment access to the admin user, then retry.'
            );
            return finishBuilderPlan(plan);
        }

        try {
            Metadata.DeployContainer container = buildDeployContainer(plan);
            if (container.getMetadata().isEmpty()) {
                plan.metadataWriteStatus = 'BLOCKED';
                plan.metadataWriteNotice = 'No Custom Metadata records are available to deploy.';
                addBuilderIssue(plan, SEVERITY_ERROR, 'METADATA_DEPLOY_EMPTY', componentType, componentKey, 'Create a valid metadata plan before deployment.');
                return finishBuilderPlan(plan);
            }
            if (Test.isRunningTest()) {
                plan.deploymentJobId = '0Af000000000000AAA';
            } else {
                Id jobId = Metadata.Operations.enqueueDeployment(container, new SmartIntakeMetadataDeployCallback());
                plan.deploymentJobId = String.valueOf(jobId);
            }
            SmartIntakeMetadataDeployCallback.recordQueued(plan.deploymentJobId, plan, componentType, componentKey);
            plan.metadataWriteStatus = 'QUEUED';
            plan.metadataWriteNotice = 'Salesforce queued the Custom Metadata deployment. Refresh validation after the deployment finishes.';
        } catch (Exception ex) {
            SmartIntakeApexDebugLogService.logException(
                'SmartIntakeAdminController',
                'deployMetadataPlan',
                plan.templateKey,
                null,
                ex,
                new Map<String, Object>{
                    'status' => 'QUEUE_FAILED',
                    'componentType' => componentType,
                    'componentKey' => componentKey,
                    'configKey' => plan.configKey
                }
            );
            plan.metadataWriteStatus = 'QUEUE_FAILED';
            plan.metadataWriteNotice = 'Salesforce could not queue the Custom Metadata deployment.';
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'METADATA_DEPLOY_QUEUE_FAILED',
                componentType,
                componentKey,
                safeErrorMessage(ex)
            );
        }
        return finishBuilderPlan(plan);
    }

    private static void validateQuestionDraftBasics(
        BuilderPlan plan,
        BuilderQuestionDraft draft,
        String inputType
    ) {
        if (String.isBlank(plan.templateKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_TEMPLATE_REQUIRED', 'Question Builder', null, 'Select a template before creating a question.');
        } else {
            Integer templateCount = [
                SELECT COUNT()
                FROM SmartIntake_Template__mdt
                WHERE Template_Key__c = :plan.templateKey
            ];
            if (templateCount == 0) {
                addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_TEMPLATE_NOT_FOUND', 'Question Builder', plan.templateKey, 'No SmartIntake template exists for this key.');
            }
        }

        if (String.isBlank(plan.questionKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_QUESTION_KEY_REQUIRED', 'Question Builder', null, 'Question Key is required.');
        } else {
            if (!Pattern.matches('^[A-Za-z][A-Za-z0-9_]{1,79}$', plan.questionKey)) {
                addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_QUESTION_KEY_INVALID', 'Question Builder', plan.questionKey, 'Question Key must start with a letter and contain only letters, numbers, and underscores.');
            }
            Integer questionCount = [
                SELECT COUNT()
                FROM SmartIntake_Question__mdt
                WHERE Template_Key__c = :plan.templateKey
                AND Question_Key__c = :plan.questionKey
            ];
            if (questionCount > 0) {
                addBuilderIssue(plan, SEVERITY_INFO, 'BUILDER_QUESTION_KEY_WILL_UPDATE', 'Question Builder', plan.questionKey, 'This question key already exists in the selected template. Deployment will update the existing metadata record.');
            }
        }

        if (String.isBlank(draft.questionText)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_QUESTION_TEXT_REQUIRED', 'Question Builder', plan.questionKey, 'Question Text is required.');
        }

        if (!SUPPORTED_INPUT_TYPES.contains(inputType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_INPUT_TYPE_UNSUPPORTED', 'Question Builder', plan.questionKey, 'Input Type is not supported by the runtime.');
        }

        validateBuilderUiControl(plan, plan.questionKey, draft.uiControl);
        if (!String.isBlank(draft.dataSourceKey) && !isValidAnswerStoreKey(draft.dataSourceKey)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_DATA_SOURCE_KEY_INVALID', 'Question Builder', plan.questionKey, 'Data Source Key must start with a letter and contain only letters, numbers, and underscores.');
        }

        if (draft.questionOrder != null && draft.questionOrder < 0) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_ORDER_INVALID', 'Question Builder', plan.questionKey, 'Question Order cannot be negative.');
        }
    }

    private static void addOptionPlanRecords(
        BuilderPlan plan,
        BuilderQuestionDraft draft,
        String inputType,
        String questionRecordName
    ) {
        List<String> optionLines = parseLines(draft.optionLines);
        if (!OPTION_INPUT_TYPES.contains(inputType)) {
            if (!optionLines.isEmpty()) {
                addBuilderIssue(plan, SEVERITY_WARNING, 'BUILDER_OPTIONS_IGNORED', 'Question Builder', plan.questionKey, 'Options are used only for picklist, radio, and multi-select questions.');
            }
            return;
        }
        if (optionLines.isEmpty()) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_OPTIONS_REQUIRED', 'Question Builder', plan.questionKey, 'This input type requires at least one option.');
            return;
        }

        Schema.DescribeFieldResult targetFieldDescribe = builderTargetFieldDescribe(draft);
        Set<String> activeTargetFieldValues = activePicklistApiValues(targetFieldDescribe);
        Set<String> values = new Set<String>();
        Decimal sortOrder = 10;
        for (String optionLine : optionLines) {
            String label = optionLine;
            String value = optionValue(optionLine);
            Integer separatorIndex = optionLine.indexOf('=');
            if (separatorIndex > -1) {
                label = optionLine.substring(0, separatorIndex).trim();
                value = optionLine.substring(separatorIndex + 1).trim();
            }
            if (String.isBlank(label) || String.isBlank(value)) {
                addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_OPTION_INVALID', 'Question Builder', plan.questionKey, 'Each option must include a label and value.');
                continue;
            }
            if (values.contains(value)) {
                addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_OPTION_DUPLICATE', 'Question Builder', plan.questionKey, 'Option values must be unique: ' + value + '.');
            }
            values.add(value);
            if (isPicklistField(targetFieldDescribe) && !activeTargetFieldValues.contains(value)) {
                addBuilderIssue(
                    plan,
                    SEVERITY_ERROR,
                    'BUILDER_OPTION_VALUE_NOT_ACTIVE_FOR_TARGET_FIELD',
                    'Question Builder',
                    plan.questionKey,
                    'Option value ' + value + ' is not an active API value for the selected target field.'
                );
            }

            String optionRecordName = metadataRecordName(plan.templateKey, plan.questionKey + '_' + value);
            BuilderRecord optionRecord = newBuilderRecord(
                'SmartIntake_Option__mdt',
                customMetadataFullName(SmartIntake_Option__mdt.SObjectType, optionRecordName),
                'Option'
            );
            optionRecord.metadataLabel = metadataLabel(label, value);
            addBuilderField(optionRecord, 'Template_Key__c', plan.templateKey);
            addBuilderField(optionRecord, 'Question_Key__c', plan.questionKey);
            addBuilderField(optionRecord, 'Option_Label__c', label);
            addBuilderField(optionRecord, 'Option_Value__c', value);
            addBuilderField(optionRecord, 'Sort_Order__c', sortOrder);
            addBuilderField(optionRecord, 'Is_Active__c', true);
            plan.records.add(optionRecord);
            sortOrder += 10;
        }
    }

    private static void addBindingPlanRecord(
        BuilderPlan plan,
        BuilderQuestionDraft draft,
        String inputType,
        String questionRecordName
    ) {
        String objectApiName = trimToNull(draft.objectApiName);
        String fieldApiName = trimToNull(draft.fieldApiName);
        if (String.isBlank(objectApiName) && String.isBlank(fieldApiName)) {
            return;
        }
        if (FILE_INPUT_TYPES.contains(inputType)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_FILE_BINDING_NOT_SUPPORTED', 'Question Builder', plan.questionKey, 'File, image, and PDF questions are saved as Salesforce Files, not direct field bindings.');
            return;
        }
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_BINDING_INCOMPLETE', 'Question Builder', plan.questionKey, 'Object API Name and Field API Name are both required for a field binding.');
            return;
        }

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_OBJECT_NOT_FOUND', 'Question Builder', plan.questionKey, 'Configured object does not exist: ' + objectApiName + '.');
            return;
        }
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Schema.SObjectField fieldToken = objectDescribe.fields.getMap().get(fieldApiName);
        if (fieldToken == null) {
            addBuilderIssue(plan, SEVERITY_ERROR, 'BUILDER_FIELD_NOT_FOUND', 'Question Builder', plan.questionKey, 'Configured field does not exist on ' + objectApiName + ': ' + fieldApiName + '.');
            return;
        }
        if (!isCompatibleFieldType(inputType, fieldToken.getDescribe().getType())) {
            addBuilderIssue(plan, SEVERITY_WARNING, 'BUILDER_FIELD_TYPE_WARNING', 'Question Builder', plan.questionKey, 'Question input type may not safely save into the configured Salesforce field type.');
        }
        validateBuilderSaveReadiness(plan, plan.templateKey, plan.questionKey, objectDescribe, fieldToken.getDescribe());

        String bindingRecordName = metadataRecordName(plan.templateKey, plan.questionKey + '_binding');
        BuilderRecord bindingRecord = newBuilderRecord(
            'SmartIntake_Field_Binding__mdt',
            customMetadataFullName(SmartIntake_Field_Binding__mdt.SObjectType, bindingRecordName),
            'Field Binding'
        );
        bindingRecord.metadataLabel = metadataLabel(plan.questionKey + ' Binding', plan.questionKey);
        addBuilderField(bindingRecord, 'Template_Key__c', plan.templateKey);
        addBuilderField(bindingRecord, 'Question_Key__c', plan.questionKey);
        addBuilderField(bindingRecord, 'Object_API_Name__c', objectApiName);
        addBuilderField(bindingRecord, 'Field_API_Name__c', fieldApiName);
        addBuilderField(bindingRecord, 'Is_Active__c', true);
        plan.records.add(bindingRecord);
    }

    private static Schema.DescribeFieldResult builderTargetFieldDescribe(BuilderQuestionDraft draft) {
        if (draft == null || String.isBlank(draft.objectApiName) || String.isBlank(draft.fieldApiName)) {
            return null;
        }
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(draft.objectApiName);
        if (objectType == null) {
            return null;
        }
        Schema.SObjectField fieldToken = objectType.getDescribe().fields.getMap().get(draft.fieldApiName);
        return fieldToken == null ? null : fieldToken.getDescribe();
    }

    private static void validateBuilderSaveReadiness(
        BuilderPlan plan,
        String templateKey,
        String questionKey,
        Schema.DescribeSObjectResult objectDescribe,
        Schema.DescribeFieldResult selectedFieldDescribe
    ) {
        if (objectDescribe == null || selectedFieldDescribe == null) {
            return;
        }
        Set<String> boundFields = activeTemplateBindingFields(templateKey, objectDescribe.getName(), questionKey);
        boundFields.add(selectedFieldDescribe.getName());

        if (isPicklistField(selectedFieldDescribe) && selectedFieldDescribe.isDependentPicklist()) {
            String controllerFieldName = controllerFieldApiName(selectedFieldDescribe);
            if (!String.isBlank(controllerFieldName) && !boundFields.contains(controllerFieldName)) {
                addBuilderIssue(
                    plan,
                    SEVERITY_ERROR,
                    'BUILDER_DEPENDENT_PICKLIST_CONTROLLER_REQUIRED',
                    'Question Builder',
                    questionKey,
                    selectedFieldDescribe.getName() + ' depends on ' + controllerFieldName + '. Create or map a SmartIntake question for the controlling field first.'
                );
            }
        }

        for (Schema.SObjectField fieldToken : objectDescribe.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
            if (!isRequiredForCreate(fieldDescribe) || boundFields.contains(fieldDescribe.getName())) {
                continue;
            }
            addBuilderIssue(
                plan,
                SEVERITY_ERROR,
                'BUILDER_REQUIRED_CREATE_FIELD_NOT_MAPPED',
                'Question Builder',
                questionKey,
                objectDescribe.getName() + '.' + fieldDescribe.getName() + ' is required for new records. Add a SmartIntake binding for it or provide a Salesforce default/automation value.'
            );
        }
    }

    private static Set<String> activeTemplateBindingFields(String templateKey, String objectApiName, String replacingQuestionKey) {
        Set<String> fieldNames = new Set<String>();
        if (String.isBlank(templateKey) || String.isBlank(objectApiName)) {
            return fieldNames;
        }
        for (SmartIntake_Field_Binding__mdt binding : [
            SELECT Question_Key__c, Field_API_Name__c
            FROM SmartIntake_Field_Binding__mdt
            WHERE Template_Key__c = :templateKey
            AND Object_API_Name__c = :objectApiName
            AND Is_Active__c = true
        ]) {
            if (binding.Question_Key__c == replacingQuestionKey) {
                continue;
            }
            fieldNames.add(binding.Field_API_Name__c);
        }
        return fieldNames;
    }

    private static void addFileConfigPlanRecord(
        BuilderPlan plan,
        BuilderQuestionDraft draft,
        String inputType,
        String questionRecordName
    ) {
        if (!FILE_INPUT_TYPES.contains(inputType)) {
            if (!String.isBlank(draft.acceptedFileTypes)) {
                addBuilderIssue(plan, SEVERITY_WARNING, 'BUILDER_FILE_CONFIG_IGNORED', 'Question Builder', plan.questionKey, 'File settings apply only to FILE, IMAGE, and PDF questions.');
            }
            return;
        }

        String acceptedFileTypes = trimToNull(draft.acceptedFileTypes);
        if (String.isBlank(acceptedFileTypes)) {
            acceptedFileTypes = inputType == 'PDF' ? '.pdf' : (inputType == 'IMAGE' ? '.png,.jpg,.jpeg' : '');
        }
        Decimal maxFileCount = draft.maxFileCount == null ? (draft.allowMultipleFiles == true ? 5 : 1) : draft.maxFileCount;

        String fileRecordName = metadataRecordName(plan.templateKey, plan.questionKey + '_file');
        BuilderRecord fileRecord = newBuilderRecord(
            'SmartIntake_File_Config__mdt',
            customMetadataFullName(SmartIntake_File_Config__mdt.SObjectType, fileRecordName),
            'File Config'
        );
        fileRecord.metadataLabel = metadataLabel(plan.questionKey + ' File Config', plan.questionKey);
        addBuilderField(fileRecord, 'Template_Key__c', plan.templateKey);
        addBuilderField(fileRecord, 'File_Config_Key__c', plan.questionKey + '_file');
        addBuilderField(fileRecord, 'Question_Key__c', plan.questionKey);
        addBuilderField(fileRecord, 'Accepted_File_Types__c', acceptedFileTypes);
        addBuilderField(fileRecord, 'Allow_Multiple__c', draft.allowMultipleFiles == true);
        addBuilderField(fileRecord, 'Max_File_Count__c', maxFileCount);
        addBuilderField(fileRecord, 'Link_To_Final_Record__c', true);
        addBuilderField(fileRecord, 'Share_Type__c', 'V');
        addBuilderField(fileRecord, 'Visibility__c', 'AllUsers');
        addBuilderField(fileRecord, 'Is_Active__c', true);
        plan.records.add(fileRecord);
    }

    private static List<String> parseLines(String value) {
        List<String> lines = new List<String>();
        if (String.isBlank(value)) {
            return lines;
        }
        for (String line : value.replace('\r', '').split('\n')) {
            if (!String.isBlank(line)) {
                lines.add(line.trim());
            }
        }
        return lines;
    }

    private static List<String> parseSemicolonValues(String value) {
        List<String> values = new List<String>();
        if (String.isBlank(value)) {
            return values;
        }
        for (String entry : value.split(';')) {
            if (!String.isBlank(entry)) {
                values.add(entry.trim());
            }
        }
        return values;
    }

    private static String optionValue(String label) {
        String value = String.isBlank(label) ? '' : label.trim().toLowerCase();
        value = value.replaceAll('[^a-z0-9]+', '_');
        value = value.replaceAll('^_+', '').replaceAll('_+$', '');
        return String.isBlank(value) ? 'option' : value;
    }

    private static String defaultAvatarIconName(TemplateDraft draft) {
        String iconName = trimToNull(draft.avatarIconName);
        return String.isBlank(iconName) ? 'standard:service_appointment' : iconName;
    }

    private static String defaultWelcomeMessage(TemplateDraft draft) {
        String message = trimToNull(draft.welcomeMessage);
        if (!String.isBlank(message)) {
            return message;
        }
        return 'Welcome. I will guide this intake one question at a time.';
    }

    private static String defaultCompletionMessage(TemplateDraft draft) {
        String message = trimToNull(draft.completionMessage);
        if (!String.isBlank(message)) {
            return message;
        }
        return 'Thanks. Your intake has been saved.';
    }

    private static Decimal nextQuestionOrder(String templateKey) {
        if (String.isBlank(templateKey)) {
            return 10;
        }
        List<SmartIntake_Question__mdt> questions = [
            SELECT Question_Order__c, DeveloperName
            FROM SmartIntake_Question__mdt
            WHERE Template_Key__c = :templateKey
            ORDER BY Question_Order__c DESC NULLS LAST, DeveloperName DESC
            LIMIT 1
        ];
        Decimal maxOrder = questions.isEmpty() ? null : questions[0].Question_Order__c;
        return maxOrder == null ? 10 : maxOrder + 10;
    }

    private static String defaultUiControl(String inputType) {
        if (inputType == 'LONG_TEXT') {
            return 'lightning-textarea';
        }
        if (inputType == 'PICKLIST') {
            return 'lightning-combobox';
        }
        if (inputType == 'RADIO') {
            return 'lightning-radio-group';
        }
        if (inputType == 'MULTI_SELECT') {
            return 'lightning-checkbox-group';
        }
        if (FILE_INPUT_TYPES.contains(inputType)) {
            return 'lightning-file-upload';
        }
        return 'lightning-input';
    }

    private static void validateRegisteredUiControl(
        ValidationResult result,
        String questionKey,
        String uiControl,
        Set<String> registeredControls
    ) {
        if (String.isBlank(uiControl) || !uiControl.trim().toLowerCase().startsWith('c/')) {
            return;
        }
        if (isDirectCustomLwcName(uiControl) || registeredControls.contains(uiControl.trim().toLowerCase())) {
            return;
        }
        addIssue(
            result,
            SEVERITY_WARNING,
            'CUSTOM_UI_CONTROL_INVALID_NAME',
            'Question',
            questionKey,
            'Custom UI control ' + uiControl + ' must use a direct LWC module name like c/myComponent.'
        );
    }

    private static void validateBuilderUiControl(BuilderPlan plan, String questionKey, String uiControl) {
        if (String.isBlank(uiControl)) {
            return;
        }
        String normalizedUiControl = uiControl.trim().toLowerCase();
        if (!normalizedUiControl.startsWith('c/')) {
            return;
        }
        if (isDirectCustomLwcName(uiControl) || registeredControlAliases().contains(normalizedUiControl)) {
            return;
        }
        addBuilderIssue(
            plan,
            SEVERITY_WARNING,
            'BUILDER_CUSTOM_UI_CONTROL_INVALID_NAME',
            'Question Builder',
            questionKey,
            'Custom UI control ' + uiControl + ' must use a direct LWC module name like c/myComponent.'
        );
    }

    private static Boolean isDirectCustomLwcName(String uiControl) {
        return !String.isBlank(uiControl) &&
            Pattern.matches('^c/[A-Za-z][A-Za-z0-9_]*$', uiControl.trim());
    }

    private static Set<String> registeredControlAliases() {
        Set<String> registeredControls = new Set<String>();
        for (SmartIntake_Control__mdt control : [
            SELECT Control_Key__c, Component_Name__c, Aliases__c
            FROM SmartIntake_Control__mdt
            WHERE Is_Active__c = true
        ]) {
            addRegisteredControlAlias(registeredControls, control.Control_Key__c);
            addRegisteredControlAlias(registeredControls, control.Component_Name__c);
            for (String aliasValue : parseSemicolonValues(control.Aliases__c)) {
                addRegisteredControlAlias(registeredControls, aliasValue);
            }
        }
        return registeredControls;
    }

    private static void addRegisteredControlAlias(Set<String> registeredControls, String value) {
        if (!String.isBlank(value)) {
            registeredControls.add(value.trim().toLowerCase());
        }
    }

    private class CustomControlRegistryEntry {
        String metadataType;
        String fullName;
        String label;
        String metadataLabel;
        String controlKey;
        String componentName;
        String aliases;
        String templateKey;
        String questionKey;
    }

    private static BuilderPlan buildCustomControlRegistryPlan() {
        BuilderPlan plan = newBuilderPlan();
        plan.configType = 'CUSTOM_CONTROL_REGISTRY';
        plan.configKey = 'smartIntakeControlRegistry';
        plan.generatedControlCount = 0;

        List<CustomControlRegistryEntry> entries = customControlRegistryEntries(plan);

        if (entries.isEmpty()) {
            addBuilderIssue(
                plan,
                SEVERITY_WARNING,
                'CONTROL_REGISTRY_NO_ACTIVE_CONTROLS',
                'Custom Control Registry',
                'smartIntakeControlRegistry',
                'No active questions with direct c/... UI controls were found. The generated registry will contain no custom LWC loaders.'
            );
        }

        plan.generatedSource = generateCustomControlRegistrySource(entries, plan);
        for (CustomControlRegistryEntry entry : entries) {
            BuilderRecord record = newBuilderRecord(
                entry.metadataType,
                entry.fullName,
                entry.label
            );
            record.metadataLabel = entry.metadataLabel;
            addBuilderField(record, 'Template_Key__c', entry.templateKey);
            addBuilderField(record, 'Question_Key__c', entry.questionKey);
            addBuilderField(record, 'Control Key', entry.controlKey);
            addBuilderField(record, 'Component Name', entry.componentName);
            addBuilderField(record, 'Aliases', entry.aliases);
            plan.records.add(record);
        }

        plan.metadataWriteStatus = 'PLANNED_ONLY';
        return plan;
    }

    private static List<CustomControlRegistryEntry> customControlRegistryEntries(BuilderPlan plan) {
        List<CustomControlRegistryEntry> entries = new List<CustomControlRegistryEntry>();

        for (SmartIntake_Control__mdt control : [
            SELECT DeveloperName, MasterLabel, Control_Key__c, Component_Name__c, Aliases__c, Description__c, Is_Active__c
            FROM SmartIntake_Control__mdt
            WHERE Is_Active__c = true
            ORDER BY Control_Key__c ASC, DeveloperName ASC
        ]) {
            CustomControlRegistryEntry entry = new CustomControlRegistryEntry();
            entry.metadataType = 'SmartIntake_Control__mdt';
            entry.fullName = customMetadataFullName(SmartIntake_Control__mdt.SObjectType, control.DeveloperName);
            entry.label = 'Packaged Control';
            entry.metadataLabel = control.MasterLabel;
            entry.controlKey = normalize(control.Control_Key__c);
            entry.componentName = trimToNull(control.Component_Name__c);
            entry.aliases = control.Aliases__c;
            entries.add(entry);
        }

        for (SmartIntake_Question__mdt question : [
            SELECT DeveloperName, MasterLabel, Template_Key__c, Question_Key__c, Question_Text__c,
                   UI_Control__c, Render_Lightning_Input__c, Is_Active__c, Question_Order__c
            FROM SmartIntake_Question__mdt
            WHERE Is_Active__c = true
            AND Render_Lightning_Input__c = true
            AND UI_Control__c != null
            ORDER BY Template_Key__c ASC, Question_Order__c ASC NULLS LAST, DeveloperName ASC
        ]) {
            String componentName = trimToNull(question.UI_Control__c);
            if (String.isBlank(componentName) || !componentName.trim().toLowerCase().startsWith('c/')) {
                continue;
            }
            if (!isValidControlComponentName(componentName)) {
                addBuilderIssue(
                    plan,
                    SEVERITY_ERROR,
                    'CONTROL_REGISTRY_QUESTION_COMPONENT_INVALID',
                    'Question',
                    question.Question_Key__c,
                    'UI Control must use a direct LWC module name like c/myComponent before it can be added to the LWR-safe registry.'
                );
                continue;
            }

            CustomControlRegistryEntry entry = new CustomControlRegistryEntry();
            entry.metadataType = 'SmartIntake_Question__mdt';
            entry.fullName = customMetadataFullName(SmartIntake_Question__mdt.SObjectType, question.DeveloperName);
            entry.label = 'Question Custom LWC';
            entry.metadataLabel = metadataLabel(question.Question_Text__c, question.Question_Key__c);
            entry.controlKey = generatedControlKeyForComponentName(componentName);
            entry.componentName = componentName.trim();
            entry.aliases = '';
            entry.templateKey = question.Template_Key__c;
            entry.questionKey = question.Question_Key__c;
            entries.add(entry);
        }

        return entries;
    }

    private static String generateCustomControlRegistrySource(List<CustomControlRegistryEntry> entries, BuilderPlan plan) {
        Map<String, String> controlLoaders = new Map<String, String>();
        Map<String, String> controlAliases = new Map<String, String>();
        Map<String, String> componentToControlKey = new Map<String, String>();

        for (CustomControlRegistryEntry entry : entries) {
            String controlKey = normalize(entry.controlKey);
            String componentName = trimToNull(entry.componentName);
            if (String.isBlank(controlKey)) {
                addBuilderIssue(
                    plan,
                    SEVERITY_ERROR,
                    'CONTROL_REGISTRY_KEY_REQUIRED',
                    'Custom Control Registry',
                    entry.fullName,
                    'Control Key is required for active custom controls.'
                );
                continue;
            }
            if (!isValidControlComponentName(componentName)) {
                addBuilderIssue(
                    plan,
                    SEVERITY_ERROR,
                    'CONTROL_REGISTRY_COMPONENT_INVALID',
                    'Custom Control Registry',
                    controlKey,
                    'Component Name must be a c/myComponent LWC specifier.'
                );
                continue;
            }

            String componentAliasKey = componentName.toLowerCase();
            if (componentToControlKey.containsKey(componentAliasKey)) {
                controlKey = componentToControlKey.get(componentAliasKey);
            } else {
                controlLoaders.put(controlKey, componentName);
                componentToControlKey.put(componentAliasKey, controlKey);
            }
            addControlAlias(controlAliases, componentName, controlKey);
            addControlAlias(controlAliases, controlKey, controlKey);
            for (String aliasValue : parseSemicolonValues(entry.aliases)) {
                addControlAlias(controlAliases, aliasValue, controlKey);
            }
        }

        plan.generatedControlCount = controlLoaders.size();

        List<String> aliasKeys = new List<String>(controlAliases.keySet());
        aliasKeys.sort();
        List<String> aliasLines = new List<String>();
        for (String aliasKey : aliasKeys) {
            aliasLines.add('    ' + jsString(aliasKey) + ': ' + jsString(controlAliases.get(aliasKey)));
        }

        List<String> loaderKeys = new List<String>(controlLoaders.keySet());
        loaderKeys.sort();
        List<String> loaderLines = new List<String>();
        for (String loaderKey : loaderKeys) {
            loaderLines.add('    ' + jsString(loaderKey) + ': () => import(' + jsString(controlLoaders.get(loaderKey)) + ')');
        }

        return '// Generated by SmartIntake Admin Console from active SmartIntake questions and optional packaged controls.\n' +
            '// Do not hand-edit registry entries; update question UI_Control__c and use Sync Custom Control Registry.\n' +
            'const CONTROL_ALIASES = {\n' +
            String.join(aliasLines, ',\n') +
            '\n};\n\n' +
            'const CONTROL_LOADERS = {\n' +
            String.join(loaderLines, ',\n') +
            '\n};\n\n' +
            'export function normalizeSmartIntakeControlKey(uiControl) {\n' +
            '    const rawValue = (uiControl || \'\').trim();\n' +
            '    if (!rawValue) {\n' +
            '        return \'\';\n' +
            '    }\n\n' +
            '    const normalized = rawValue.toLowerCase();\n' +
            '    return CONTROL_ALIASES[normalized] || rawValue.trim().toUpperCase();\n' +
            '}\n\n' +
            'export function isSmartIntakeRegisteredControl(uiControl) {\n' +
            '    return Boolean(CONTROL_LOADERS[normalizeSmartIntakeControlKey(uiControl)]);\n' +
            '}\n\n' +
            'export async function loadSmartIntakeControl(uiControl) {\n' +
            '    const loader = CONTROL_LOADERS[normalizeSmartIntakeControlKey(uiControl)];\n' +
            '    if (!loader) {\n' +
            '        return undefined;\n' +
            '    }\n\n' +
            '    const module = await loader();\n' +
            '    return module.default;\n' +
            '}\n';
    }

    private static String generatedControlKeyForComponentName(String componentName) {
        String baseName = String.isBlank(componentName) ? '' : componentName.trim();
        if (baseName.toLowerCase().startsWith('c/')) {
            baseName = baseName.substring(2);
        }
        baseName = baseName.replaceAll('[^A-Za-z0-9]+', '_').toUpperCase();
        return 'DIRECT_' + baseName;
    }

    private static void addControlAlias(Map<String, String> controlAliases, String aliasValue, String controlKey) {
        if (!String.isBlank(aliasValue) && !String.isBlank(controlKey)) {
            controlAliases.put(aliasValue.trim().toLowerCase(), controlKey);
        }
    }

    private static Boolean isValidControlComponentName(String componentName) {
        return !String.isBlank(componentName) &&
            Pattern.matches('^c\\/[A-Za-z][A-Za-z0-9_]*$', componentName);
    }

    private static Boolean isValidApiName(String apiName) {
        return !String.isBlank(apiName) &&
            Pattern.matches('^[A-Za-z][A-Za-z0-9_]*$', apiName.trim());
    }

    private static Boolean isValidAnswerStoreKey(String answerKey) {
        return !String.isBlank(answerKey) &&
            Pattern.matches('^[A-Za-z][A-Za-z0-9_]{1,79}$', answerKey.trim());
    }

    private static Boolean isValidInputSource(String sourceKey) {
        if (String.isBlank(sourceKey)) {
            return false;
        }
        String source = sourceKey.trim();
        if (source.length() >= 2 &&
            ((source.startsWith('\'') && source.endsWith('\'')) ||
            (source.startsWith('"') && source.endsWith('"')))) {
            return true;
        }
        return Pattern.matches('^\\$?[A-Za-z][A-Za-z0-9_]{0,79}$', source);
    }

    private static String jsString(String value) {
        return JSON.serialize(value == null ? '' : value);
    }

    private static String updateCustomControlRegistryResource(String generatedSource) {
        if (String.isBlank(generatedSource)) {
            throw new SmartIntakeAdminException('Generated registry source is empty.');
        }
        String resourceId = findRegistryResourceId();
        Map<String, Object> body = new Map<String, Object>{ 'Source' => generatedSource };
        HttpResponse response = sendToolingRequest(
            'PATCH',
            '/sobjects/LightningComponentResource/' + EncodingUtil.urlEncode(resourceId, 'UTF-8'),
            JSON.serialize(body)
        );
        if (response.getStatusCode() != 200 && response.getStatusCode() != 204) {
            throw new SmartIntakeAdminException('Tooling API update failed: ' + response.getStatusCode() + ' ' + response.getBody());
        }
        return resourceId;
    }

    private static String findRegistryResourceId() {
        String query = 'SELECT Id, FilePath FROM LightningComponentResource WHERE FilePath = \'' +
            CONTROL_REGISTRY_FILE_PATH +
            '\' LIMIT 1';
        HttpResponse response = sendToolingRequest(
            'GET',
            '/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8'),
            null
        );
        if (response.getStatusCode() != 200) {
            throw new SmartIntakeAdminException('Tooling API query failed: ' + response.getStatusCode() + ' ' + response.getBody());
        }
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> records = (List<Object>) payload.get('records');
        if (records == null || records.isEmpty()) {
            throw new SmartIntakeAdminException('Registry LWC resource was not found. Deploy smartIntakeControlRegistry before syncing.');
        }
        Map<String, Object> record = (Map<String, Object>) records[0];
        return String.valueOf(record.get('Id'));
    }

    private static HttpResponse sendToolingRequest(String method, String path, String body) {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId)) {
            throw new SmartIntakeAdminException('Current session is not available for Tooling API registry sync.');
        }
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v66.0/tooling' + path);
        request.setMethod(method);
        request.setHeader('Authorization', 'Bearer ' + sessionId);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        if (body != null) {
            request.setBody(body);
        }
        return new Http().send(request);
    }

    private static String normalizeTemplateKey(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        String normalized = value.trim().toUpperCase();
        normalized = normalized.replaceAll('[^A-Z0-9]+', '_');
        normalized = normalized.replaceAll('^_+', '').replaceAll('_+$', '');
        return normalized;
    }

    private static String standaloneMetadataRecordName(String key) {
        String candidate = String.isBlank(key) ? 'SmartIntake_Metadata' : key;
        candidate = candidate.replaceAll('[^A-Za-z0-9_]', '_');
        if (!Pattern.matches('^[A-Za-z].*', candidate)) {
            candidate = 'SI_' + candidate;
        }
        candidate = candidate.replaceAll('_+', '_');
        return candidate.length() > 40 ? candidate.substring(0, 40) : candidate;
    }

    private static String metadataRecordName(String templateKey, String key) {
        String candidate = (String.isBlank(templateKey) ? 'Draft' : templateKey) + '_' + (String.isBlank(key) ? 'Question' : key);
        return standaloneMetadataRecordName(candidate);
    }

    private static String existingMetadataRecordName(
        Schema.SObjectType metadataType,
        String templateKey,
        String keyFieldApiName,
        String keyValue,
        String fallbackName
    ) {
        if (String.isBlank(templateKey) || String.isBlank(keyFieldApiName) || String.isBlank(keyValue)) {
            return fallbackName;
        }
        String objectApiName = metadataType.getDescribe().getName();
        String query =
            'SELECT DeveloperName FROM ' + objectApiName +
            ' WHERE Template_Key__c = :templateKey' +
            ' AND ' + keyFieldApiName + ' = :keyValue' +
            ' ORDER BY Is_Active__c DESC, DeveloperName ASC';
        List<SObject> records = Database.query(query);
        if (records.isEmpty()) {
            return fallbackName;
        }
        for (SObject record : records) {
            String developerName = String.valueOf(record.get('DeveloperName'));
            if (developerName != fallbackName) {
                return developerName;
            }
        }
        return String.valueOf(records[0].get('DeveloperName'));
    }

    private static String deactivateRecordName(String metadataFullName) {
        if (String.isBlank(metadataFullName)) {
            return 'SmartIntake Metadata';
        }
        Integer separatorIndex = metadataFullName.lastIndexOf('.');
        return separatorIndex >= 0 && separatorIndex < metadataFullName.length() - 1
            ? metadataFullName.substring(separatorIndex + 1)
            : metadataFullName;
    }

    private static Schema.SObjectType metadataTypeForDeactivate(String metadataType) {
        if (String.isBlank(metadataType) || !SUPPORTED_DEACTIVATE_METADATA_TYPES.contains(metadataType)) {
            return null;
        }
        if (metadataType == 'SmartIntake_Branding_Config__mdt') {
            return SmartIntake_Branding_Config__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Condition__mdt') {
            return SmartIntake_Condition__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Context_Config__mdt') {
            return SmartIntake_Context_Config__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Control__mdt') {
            return SmartIntake_Control__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Field_Binding__mdt') {
            return SmartIntake_Field_Binding__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_File_Config__mdt') {
            return SmartIntake_File_Config__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Handoff_Config__mdt') {
            return SmartIntake_Handoff_Config__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Hook__mdt') {
            return SmartIntake_Hook__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Matching_Rule__mdt') {
            return SmartIntake_Matching_Rule__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Message__mdt') {
            return SmartIntake_Message__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Option__mdt') {
            return SmartIntake_Option__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Question__mdt') {
            return SmartIntake_Question__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Template__mdt') {
            return SmartIntake_Template__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Template_Route__mdt') {
            return SmartIntake_Template_Route__mdt.SObjectType;
        }
        if (metadataType == 'SmartIntake_Validation_Rule__mdt') {
            return SmartIntake_Validation_Rule__mdt.SObjectType;
        }
        return null;
    }

    private static String trimToNull(String value) {
        return String.isBlank(value) ? null : value.trim();
    }

    private static BuilderQuestionDraft questionDraftFromJson(String draftJson) {
        if (String.isBlank(draftJson)) {
            return null;
        }
        return (BuilderQuestionDraft) JSON.deserialize(draftJson, BuilderQuestionDraft.class);
    }

    private static TemplateDraft templateDraftFromJson(String draftJson) {
        if (String.isBlank(draftJson)) {
            return null;
        }
        return (TemplateDraft) JSON.deserialize(draftJson, TemplateDraft.class);
    }

    private static AdminConfigDraft adminConfigDraftFromJson(String draftJson) {
        if (String.isBlank(draftJson)) {
            return null;
        }
        return (AdminConfigDraft) JSON.deserialize(draftJson, AdminConfigDraft.class);
    }

    @TestVisible
    private static Metadata.DeployContainer buildDeployContainer(BuilderPlan plan) {
        Metadata.DeployContainer container = new Metadata.DeployContainer();
        if (plan == null || plan.records == null) {
            return container;
        }

        Set<String> fullNames = new Set<String>();
        for (BuilderRecord record : plan.records) {
            if (record == null || String.isBlank(record.fullName) || fullNames.contains(record.fullName)) {
                continue;
            }
            fullNames.add(record.fullName);

            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = record.fullName;
            customMetadata.label = metadataLabel(record.metadataLabel, record.label);
            if (record.fields != null) {
                for (ConfigField field : record.fields) {
                    Object value = metadataFieldValue(field);
                    if (value == null) {
                        continue;
                    }
                    Metadata.CustomMetadataValue customValue = new Metadata.CustomMetadataValue();
                    customValue.field = field.label;
                    customValue.value = value;
                    customMetadata.values.add(customValue);
                }
            }
            container.addMetadata(customMetadata);
        }
        return container;
    }

    private static Object metadataFieldValue(ConfigField field) {
        if (field == null || String.isBlank(field.label) || String.isBlank(field.value)) {
            return null;
        }
        if (BOOLEAN_BUILDER_METADATA_FIELDS.contains(field.label)) {
            return field.value == 'true';
        }
        if (DECIMAL_BUILDER_METADATA_FIELDS.contains(field.label)) {
            return Decimal.valueOf(field.value);
        }
        if (DATE_BUILDER_METADATA_FIELDS.contains(field.label)) {
            return Date.valueOf(field.value);
        }
        return field.value;
    }

    private static Boolean currentUserCanDeployMetadata() {
        if (Test.isRunningTest()) {
            return forceMetadataPermissionDeniedForTests != true;
        }

        Boolean hasApiEnabled = false;
        Boolean hasMetadataAccess = false;
        for (PermissionSetAssignment assignment : [
            SELECT PermissionSet.PermissionsApiEnabled,
                PermissionSet.PermissionsModifyAllData,
                PermissionSet.PermissionsModifyMetadata
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
        ]) {
            if (assignment.PermissionSet.PermissionsApiEnabled == true) {
                hasApiEnabled = true;
            }
            if (assignment.PermissionSet.PermissionsModifyAllData == true ||
                assignment.PermissionSet.PermissionsModifyMetadata == true
            ) {
                hasMetadataAccess = true;
            }
            if (hasApiEnabled && hasMetadataAccess) {
                return true;
            }
        }
        return false;
    }

    private static String customMetadataFullName(Schema.SObjectType metadataType, String recordDeveloperName) {
        return customMetadataTypeFullName(metadataType) + '.' + recordDeveloperName;
    }

    private static String customMetadataTypeFullName(Schema.SObjectType metadataType) {
        String apiName = metadataType.getDescribe().getName();
        return apiName.endsWith('__mdt') ? apiName.substring(0, apiName.length() - 5) : apiName;
    }

    private static String metadataLabel(String candidate, String fallback) {
        String value = trimToNull(candidate);
        if (String.isBlank(value)) {
            value = trimToNull(fallback);
        }
        if (String.isBlank(value)) {
            value = 'SmartIntake Metadata';
        }
        return value.length() > CUSTOM_METADATA_LABEL_MAX_LENGTH
            ? value.substring(0, CUSTOM_METADATA_LABEL_MAX_LENGTH)
            : value;
    }

    private static String safeErrorMessage(Exception ex) {
        String message = ex == null ? null : ex.getMessage();
        if (String.isBlank(message)) {
            return 'Salesforce returned an unexpected metadata deployment error.';
        }
        return message.length() > 255 ? message.substring(0, 255) : message;
    }

    private static Map<String, SmartIntake_Question__mdt> activeQuestionsByKey(List<SmartIntake_Question__mdt> questions) {
        Map<String, SmartIntake_Question__mdt> activeQuestionsByKey = new Map<String, SmartIntake_Question__mdt>();
        for (SmartIntake_Question__mdt question : questions) {
            if (question.Is_Active__c && !String.isBlank(question.Question_Key__c)) {
                activeQuestionsByKey.put(question.Question_Key__c, question);
            }
        }
        return activeQuestionsByKey;
    }

    private static Map<String, List<SmartIntake_Option__mdt>> activeOptionsByQuestionKey(List<SmartIntake_Option__mdt> options) {
        Map<String, List<SmartIntake_Option__mdt>> optionsByQuestionKey = new Map<String, List<SmartIntake_Option__mdt>>();
        for (SmartIntake_Option__mdt optionRecord : options) {
            if (!optionRecord.Is_Active__c || String.isBlank(optionRecord.Question_Key__c)) {
                continue;
            }
            if (!optionsByQuestionKey.containsKey(optionRecord.Question_Key__c)) {
                optionsByQuestionKey.put(optionRecord.Question_Key__c, new List<SmartIntake_Option__mdt>());
            }
            optionsByQuestionKey.get(optionRecord.Question_Key__c).add(optionRecord);
        }
        return optionsByQuestionKey;
    }

    private static BindingDescribeContext bindingContext(
        SmartIntake_Field_Binding__mdt binding,
        SmartIntake_Question__mdt question,
        Schema.DescribeSObjectResult objectDescribe,
        Schema.DescribeFieldResult fieldDescribe
    ) {
        BindingDescribeContext context = new BindingDescribeContext();
        context.binding = binding;
        context.question = question;
        context.objectDescribe = objectDescribe;
        context.fieldDescribe = fieldDescribe;
        return context;
    }

    private static void addBoundField(Map<String, Set<String>> fieldsByObjectName, String objectName, String fieldName) {
        if (String.isBlank(objectName) || String.isBlank(fieldName)) {
            return;
        }
        if (!fieldsByObjectName.containsKey(objectName)) {
            fieldsByObjectName.put(objectName, new Set<String>());
        }
        fieldsByObjectName.get(objectName).add(fieldName);
    }

    private static Boolean isPicklistField(Schema.DescribeFieldResult fieldDescribe) {
        if (fieldDescribe == null) {
            return false;
        }
        return fieldDescribe.getType() == Schema.DisplayType.Picklist ||
            fieldDescribe.getType() == Schema.DisplayType.MultiPicklist;
    }

    private static Set<String> activePicklistApiValues(Schema.DescribeFieldResult fieldDescribe) {
        Set<String> values = new Set<String>();
        if (!isPicklistField(fieldDescribe)) {
            return values;
        }
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }

    private static String controllerFieldApiName(Schema.DescribeFieldResult fieldDescribe) {
        if (!isPicklistField(fieldDescribe) || !fieldDescribe.isDependentPicklist()) {
            return null;
        }
        Schema.SObjectField controller = fieldDescribe.getController();
        return controller == null ? null : controller.getDescribe().getName();
    }

    private static String controllerFieldLabel(Schema.DescribeFieldResult fieldDescribe) {
        if (!isPicklistField(fieldDescribe) || !fieldDescribe.isDependentPicklist()) {
            return null;
        }
        Schema.SObjectField controller = fieldDescribe.getController();
        return controller == null ? null : controller.getDescribe().getLabel();
    }

    private static Boolean isRequiredForCreate(Schema.DescribeFieldResult fieldDescribe) {
        if (fieldDescribe == null) {
            return false;
        }
        if (SAVE_SYSTEM_FIELDS.contains(fieldDescribe.getName())) {
            return false;
        }
        return fieldDescribe.isCreateable() &&
            !fieldDescribe.isNillable() &&
            !fieldDescribe.isDefaultedOnCreate() &&
            !fieldDescribe.isCalculated() &&
            !fieldDescribe.isAutoNumber();
    }

    private static String fieldChoiceDetail(Schema.DescribeFieldResult fieldDescribe) {
        List<String> details = new List<String>{ String.valueOf(fieldDescribe.getType()) };
        if (isRequiredForCreate(fieldDescribe)) {
            details.add('Required on create');
        }
        if (isPicklistField(fieldDescribe)) {
            if (fieldDescribe.isRestrictedPicklist()) {
                details.add('Restricted values');
            }
            if (fieldDescribe.isDependentPicklist()) {
                details.add('Depends on ' + controllerFieldApiName(fieldDescribe));
            }
        }
        return String.join(details, ' | ');
    }

    private static Boolean isCompatibleFieldType(String inputType, Schema.DisplayType fieldType) {
        if (inputType == 'DATE') {
            return fieldType == Schema.DisplayType.Date;
        }
        if (inputType == 'DATETIME') {
            return fieldType == Schema.DisplayType.DateTime;
        }
        if (inputType == 'BOOLEAN') {
            return fieldType == Schema.DisplayType.Boolean;
        }
        if (inputType == 'NUMBER' || inputType == 'CURRENCY') {
            return fieldType == Schema.DisplayType.Integer ||
                fieldType == Schema.DisplayType.Double ||
                fieldType == Schema.DisplayType.Currency ||
                fieldType == Schema.DisplayType.Percent;
        }
        return fieldType == Schema.DisplayType.String ||
            fieldType == Schema.DisplayType.TextArea ||
            fieldType == Schema.DisplayType.Email ||
            fieldType == Schema.DisplayType.Phone ||
            fieldType == Schema.DisplayType.Url ||
            fieldType == Schema.DisplayType.Picklist ||
            fieldType == Schema.DisplayType.MultiPicklist;
    }

    private static ValidationResult finish(ValidationResult result) {
        result.errorCount = 0;
        result.warningCount = 0;
        result.infoCount = 0;
        for (ValidationIssue issue : result.issues) {
            if (issue.severity == SEVERITY_ERROR) {
                result.errorCount++;
            } else if (issue.severity == SEVERITY_WARNING) {
                result.warningCount++;
            } else {
                result.infoCount++;
            }
        }
        result.isValid = result.errorCount == 0;
        return result;
    }

    private static ReadinessResult finishReadiness(ReadinessResult result) {
        result.blockingCount = 0;
        result.warningCount = 0;
        result.manualCount = 0;
        for (ReadinessItem item : result.items) {
            if (item.status == READINESS_BLOCKED) {
                result.blockingCount++;
            } else if (item.status == READINESS_WARNING) {
                result.warningCount++;
            } else if (item.status == READINESS_MANUAL) {
                result.manualCount++;
            }
        }

        if (result.blockingCount > 0) {
            result.overallStatus = READINESS_BLOCKED;
        } else if (result.warningCount > 0) {
            result.overallStatus = READINESS_WARNING;
        } else if (result.manualCount > 0) {
            result.overallStatus = READINESS_MANUAL;
        } else {
            result.overallStatus = READINESS_READY;
        }
        return result;
    }

    private static void addReadinessItem(
        ReadinessResult result,
        String key,
        String label,
        String status,
        String message
    ) {
        ReadinessItem item = new ReadinessItem();
        item.key = key;
        item.label = label;
        item.status = status;
        item.message = message;
        result.items.add(item);
    }

    private static void addSaveTargetReadiness(ReadinessResult result, ValidationResult validation) {
        if (validation == null) {
            return;
        }
        Set<String> blockingCodes = new Set<String>{
            'DEPENDENT_PICKLIST_CONTROLLER_NOT_MAPPED',
            'OPTION_VALUE_NOT_ACTIVE_FOR_TARGET_FIELD',
            'REQUIRED_CREATE_FIELD_NOT_MAPPED',
            'FIELD_NOT_FOUND',
            'OBJECT_NOT_FOUND'
        };
        Integer blockerCount = 0;
        for (ValidationIssue issue : validation.issues) {
            if (issue.severity == SEVERITY_ERROR && blockingCodes.contains(issue.code)) {
                blockerCount++;
            }
        }
        if (blockerCount > 0) {
            addReadinessItem(
                result,
                'saveTarget',
                'Final Save Target',
                READINESS_BLOCKED,
                'Fix ' + blockerCount + ' target field readiness issue(s): required fields, dependent picklist controllers, or active picklist values.'
            );
            return;
        }
        if (validation.bindingCount == null || validation.bindingCount == 0) {
            addReadinessItem(result, 'saveTarget', 'Final Save Target', READINESS_WARNING, 'No active field bindings are configured; final save will not create a business record.');
            return;
        }
        addReadinessItem(result, 'saveTarget', 'Final Save Target', READINESS_READY, 'Mapped target fields are ready for create-time validation.');
    }

    private static BuilderPlan finishBuilderPlan(BuilderPlan plan) {
        plan.errorCount = 0;
        plan.warningCount = 0;
        for (ValidationIssue issue : plan.issues) {
            if (issue.severity == SEVERITY_ERROR) {
                plan.errorCount++;
            } else if (issue.severity == SEVERITY_WARNING) {
                plan.warningCount++;
            }
        }
        plan.recordCount = plan.records == null ? 0 : plan.records.size();
        plan.isValid = plan.errorCount == 0;
        return plan;
    }

    private static void addBuilderIssue(
        BuilderPlan plan,
        String severity,
        String code,
        String componentType,
        String componentKey,
        String message
    ) {
        ValidationIssue issue = new ValidationIssue();
        issue.severity = severity;
        issue.code = code;
        issue.componentType = componentType;
        issue.componentKey = componentKey;
        issue.message = message;
        plan.issues.add(issue);
    }

    private static void addIssue(
        ValidationResult result,
        String severity,
        String code,
        String componentType,
        String componentKey,
        String message
    ) {
        ValidationIssue issue = new ValidationIssue();
        issue.severity = severity;
        issue.code = code;
        issue.componentType = componentType;
        issue.componentKey = componentKey;
        issue.message = message;
        result.issues.add(issue);
    }

    private static String normalize(String value) {
        return String.isBlank(value) ? '' : value.trim().toUpperCase();
    }

    private static ControlDefinition control(
        String inputType,
        String label,
        String lightningComponent,
        String lightningType,
        String supportedFieldTypes,
        Boolean requiresOptions,
        Boolean supportsMultiple,
        Boolean requiresFileConfig,
        String notes
    ) {
        ControlDefinition definition = new ControlDefinition();
        definition.inputType = inputType;
        definition.label = label;
        definition.lightningComponent = lightningComponent;
        definition.lightningType = lightningType;
        definition.supportedFieldTypes = supportedFieldTypes;
        definition.requiresOptions = requiresOptions;
        definition.supportsMultiple = supportsMultiple;
        definition.requiresFileConfig = requiresFileConfig;
        definition.notes = notes;
        return definition;
    }

    private static MetadataChoice metadataChoice(String label, String value, String detail, Boolean compatible) {
        MetadataChoice choice = new MetadataChoice();
        choice.label = label;
        choice.value = value;
        choice.apiName = value;
        choice.detail = detail;
        choice.compatible = compatible;
        return choice;
    }

    private static String flowVariableDetail(FlowVariableView variable) {
        if (variable == null) {
            return null;
        }
        String direction;
        if (variable.IsInput == true && variable.IsOutput == true) {
            direction = 'Input/Output';
        } else if (variable.IsInput == true) {
            direction = 'Input';
        } else if (variable.IsOutput == true) {
            direction = 'Output';
        } else {
            direction = 'Variable';
        }
        String dataType = String.isBlank(variable.DataType) ? 'Unknown' : variable.DataType;
        String collectionSuffix = variable.IsCollection == true ? ' collection' : '';
        String objectType = String.isBlank(variable.ObjectType) ? '' : ' - ' + variable.ObjectType;
        return direction + ' - ' + dataType + collectionSuffix + objectType;
    }

    private static MetadataChoice fieldChoice(
        String label,
        String value,
        String detail,
        Boolean compatible,
        Schema.DescribeFieldResult fieldDescribe
    ) {
        MetadataChoice choice = metadataChoice(label, value, detail, compatible);
        choice.fieldType = String.valueOf(fieldDescribe.getType());
        choice.requiredOnCreate = isRequiredForCreate(fieldDescribe);
        choice.dependentPicklist = isPicklistField(fieldDescribe) && fieldDescribe.isDependentPicklist();
        choice.controllerFieldApiName = controllerFieldApiName(fieldDescribe);
        choice.controllerFieldLabel = controllerFieldLabel(fieldDescribe);
        choice.restrictedPicklist = isPicklistField(fieldDescribe) && fieldDescribe.isRestrictedPicklist();
        choice.createable = fieldDescribe.isCreateable();
        choice.nillable = fieldDescribe.isNillable();
        choice.defaultedOnCreate = fieldDescribe.isDefaultedOnCreate();
        return choice;
    }

    private static ConfigSection newSection(String key, String label, String iconName) {
        ConfigSection section = new ConfigSection();
        section.key = key;
        section.label = label;
        section.iconName = iconName;
        section.records = new List<ConfigRecord>();
        section.count = 0;
        return section;
    }

    private static ConfigRecord newRecord(String key, String label, String subtitle, Boolean isActive) {
        ConfigRecord record = new ConfigRecord();
        record.key = display(key);
        record.label = display(label);
        record.subtitle = display(subtitle);
        record.status = isActive == true ? 'Active' : 'Inactive';
        record.fields = new List<ConfigField>();
        return record;
    }

    private static ConfigRecord addMetadataReference(
        ConfigRecord record,
        Schema.SObjectType metadataType,
        String developerName,
        String metadataLabel
    ) {
        if (record == null || metadataType == null || String.isBlank(developerName)) {
            return record;
        }
        String apiName = metadataType.getDescribe().getName();
        record.metadataType = apiName;
        record.metadataFullName = customMetadataFullName(metadataType, developerName);
        record.metadataLabel = metadataLabel(metadataLabel, developerName);
        record.canDeactivate = SUPPORTED_DEACTIVATE_METADATA_TYPES.contains(apiName);
        return record;
    }

    private static BuilderPlan newBuilderPlan() {
        BuilderPlan plan = new BuilderPlan();
        plan.records = new List<BuilderRecord>();
        plan.issues = new List<ValidationIssue>();
        plan.metadataWriteStatus = 'PLANNED_ONLY';
        return plan;
    }

    private static BuilderRecord newBuilderRecord(String metadataType, String fullName, String label) {
        BuilderRecord record = new BuilderRecord();
        record.metadataType = metadataType;
        record.fullName = fullName;
        record.label = label;
        record.metadataLabel = label;
        record.fields = new List<ConfigField>();
        return record;
    }

    private static void addField(ConfigRecord record, String label, Object value) {
        ConfigField field = new ConfigField();
        field.label = label;
        field.value = display(value);
        record.fields.add(field);
    }

    private static void addBuilderField(BuilderRecord record, String label, Object value) {
        ConfigField field = new ConfigField();
        field.label = label;
        field.value = display(value);
        record.fields.add(field);
    }

    private static void addSection(TemplateConfiguration config, ConfigSection section) {
        section.count = section.records.size();
        config.totalRecordCount += section.count;
        config.sections.add(section);
    }

    private static String display(Object value) {
        if (value == null) {
            return '';
        }
        return String.valueOf(value);
    }

    public class TemplateSummary {
        @AuraEnabled public String templateKey;
        @AuraEnabled public String templateName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String startQuestionKey;
    }

    public class ControlDefinition {
        @AuraEnabled public String inputType;
        @AuraEnabled public String label;
        @AuraEnabled public String lightningComponent;
        @AuraEnabled public String lightningType;
        @AuraEnabled public String supportedFieldTypes;
        @AuraEnabled public Boolean requiresOptions;
        @AuraEnabled public Boolean supportsMultiple;
        @AuraEnabled public Boolean requiresFileConfig;
        @AuraEnabled public String notes;
    }

    public class MetadataChoice implements Comparable {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String apiName;
        @AuraEnabled public String detail;
        @AuraEnabled public Boolean compatible;
        @AuraEnabled public String fieldType;
        @AuraEnabled public Boolean requiredOnCreate;
        @AuraEnabled public Boolean dependentPicklist;
        @AuraEnabled public String controllerFieldApiName;
        @AuraEnabled public String controllerFieldLabel;
        @AuraEnabled public Boolean restrictedPicklist;
        @AuraEnabled public Boolean createable;
        @AuraEnabled public Boolean nillable;
        @AuraEnabled public Boolean defaultedOnCreate;

        public Integer compareTo(Object compareTo) {
            MetadataChoice other = (MetadataChoice) compareTo;
            String left = String.isBlank(label) ? '' : label.toLowerCase();
            String right = String.isBlank(other.label) ? '' : other.label.toLowerCase();
            Integer labelCompare = left.compareTo(right);
            if (labelCompare != 0) {
                return labelCompare;
            }
            String leftValue = String.isBlank(value) ? '' : value.toLowerCase();
            String rightValue = String.isBlank(other.value) ? '' : other.value.toLowerCase();
            return leftValue.compareTo(rightValue);
        }
    }

    public class FlowVariableChoice {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String apiName;
        @AuraEnabled public String detail;
        @AuraEnabled public String description;
        @AuraEnabled public String dataType;
        @AuraEnabled public String objectType;
        @AuraEnabled public Boolean isInput;
        @AuraEnabled public Boolean isOutput;
        @AuraEnabled public Boolean isCollection;
    }

    private class BindingDescribeContext {
        SmartIntake_Field_Binding__mdt binding;
        SmartIntake_Question__mdt question;
        Schema.DescribeSObjectResult objectDescribe;
        Schema.DescribeFieldResult fieldDescribe;
    }

    public class ReadinessResult {
        @AuraEnabled public String templateKey;
        @AuraEnabled public String templateName;
        @AuraEnabled public String overallStatus;
        @AuraEnabled public Integer blockingCount;
        @AuraEnabled public Integer warningCount;
        @AuraEnabled public Integer manualCount;
        @AuraEnabled public List<ReadinessItem> items;
    }

    public class ReadinessItem {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String status;
        @AuraEnabled public String message;
    }

    public class AdminConfigDraft {
        @AuraEnabled public String templateKey;
        @AuraEnabled public String configType;
        @AuraEnabled public String configKey;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String questionKey;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String displayFieldApiName;
        @AuraEnabled public String agentDisplayName;
        @AuraEnabled public String avatarIconName;
        @AuraEnabled public String avatarImageUrl;
        @AuraEnabled public String welcomeMessage;
        @AuraEnabled public String messageType;
        @AuraEnabled public String messageText;
        @AuraEnabled public String providerType;
        @AuraEnabled public String availabilityMode;
        @AuraEnabled public String triggerMessage;
        @AuraEnabled public String availableMessage;
        @AuraEnabled public String offlineMessage;
        @AuraEnabled public String declinedMessage;
        @AuraEnabled public Boolean requiresConsent;
        @AuraEnabled public String consentMessage;
        @AuraEnabled public String queueDeveloperName;
        @AuraEnabled public String messagingChannelDeveloperName;
        @AuraEnabled public String embeddedServiceDeploymentName;
        @AuraEnabled public String handoffUrl;
        @AuraEnabled public Boolean isContextSharingEnabled;
        @AuraEnabled public String contextFieldsToShare;
        @AuraEnabled public String matchType;
        @AuraEnabled public String contextType;
        @AuraEnabled public String contextMessage;
        @AuraEnabled public String filterFieldApiName;
        @AuraEnabled public String filterSourceQuestionKey;
        @AuraEnabled public String allowedActions;
        @AuraEnabled public Decimal maxRecords;
        @AuraEnabled public String validationType;
        @AuraEnabled public String regex;
        @AuraEnabled public Decimal minLength;
        @AuraEnabled public Decimal maxLength;
        @AuraEnabled public Decimal minValue;
        @AuraEnabled public Decimal maxValue;
        @AuraEnabled public String minDate;
        @AuraEnabled public String maxDate;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String sourceQuestionKey;
        @AuraEnabled public String targetQuestionKey;
        @AuraEnabled public String action;
        @AuraEnabled public String operator;
        @AuraEnabled public String compareValue;
        @AuraEnabled public String conditionGroupKey;
        @AuraEnabled public String conditionLogic;
        @AuraEnabled public Decimal conditionNumber;
        @AuraEnabled public String customLogic;
        @AuraEnabled public String userMessage;
        @AuraEnabled public String eventName;
        @AuraEnabled public String handlerType;
        @AuraEnabled public String flowApiName;
        @AuraEnabled public String outputMode;
        @AuraEnabled public String flowInputMappings;
        @AuraEnabled public String flowOutputMappings;
        @AuraEnabled public String successOutputVariable;
        @AuraEnabled public String userMessageOutputVariable;
        @AuraEnabled public String nextQuestionOutputVariable;
        @AuraEnabled public String answersJsonOutputVariable;
        @AuraEnabled public String blockContinueOutputVariable;
        @AuraEnabled public Decimal sortOrder;
        @AuraEnabled public String acceptedFileTypes;
        @AuraEnabled public Boolean allowMultipleFiles;
        @AuraEnabled public Decimal maxFileCount;
        @AuraEnabled public Boolean linkToFinalRecord;
        @AuraEnabled public String shareType;
        @AuraEnabled public String visibility;
    }

    public class BuilderQuestionDraft {
        @AuraEnabled public String templateKey;
        @AuraEnabled public String questionKey;
        @AuraEnabled public String questionText;
        @AuraEnabled public String helpText;
        @AuraEnabled public String placeholderText;
        @AuraEnabled public Decimal questionOrder;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean confirmAiExtractedAnswer;
        @AuraEnabled public Boolean renderLightningInput;
        @AuraEnabled public String inputType;
        @AuraEnabled public String uiControl;
        @AuraEnabled public String dataSourceKey;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String optionLines;
        @AuraEnabled public String acceptedFileTypes;
        @AuraEnabled public Boolean allowMultipleFiles;
        @AuraEnabled public Decimal maxFileCount;
    }

    public class TemplateDraft {
        @AuraEnabled public String templateKey;
        @AuraEnabled public String templateName;
        @AuraEnabled public String startQuestionKey;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Boolean requiresConsent;
        @AuraEnabled public Boolean requiresFinalConfirmation;
        @AuraEnabled public String consentMessage;
        @AuraEnabled public String completionMessage;
        @AuraEnabled public Boolean createBranding;
        @AuraEnabled public String agentDisplayName;
        @AuraEnabled public String avatarIconName;
        @AuraEnabled public String avatarImageUrl;
        @AuraEnabled public String welcomeMessage;
    }

    public class BuilderPlan {
        @AuraEnabled public String templateKey;
        @AuraEnabled public String questionKey;
        @AuraEnabled public String configType;
        @AuraEnabled public String configKey;
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public Integer errorCount;
        @AuraEnabled public Integer warningCount;
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public String generatedSource;
        @AuraEnabled public Integer generatedControlCount;
        @AuraEnabled public String registryResourceId;
        @AuraEnabled public String metadataWriteStatus;
        @AuraEnabled public String metadataWriteNotice;
        @AuraEnabled public String deploymentJobId;
        @AuraEnabled public List<ValidationIssue> issues;
        @AuraEnabled public List<BuilderRecord> records;
    }

    public class DeploymentStatus {
        @AuraEnabled public String deploymentJobId;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean done;
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer numberComponentsDeployed;
        @AuraEnabled public Integer numberComponentsTotal;
        @AuraEnabled public Integer numberComponentErrors;
        @AuraEnabled public Integer numberTestsCompleted;
        @AuraEnabled public Integer numberTestsTotal;
        @AuraEnabled public Integer numberTestErrors;
        @AuraEnabled public String stateDetail;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String errorStatusCode;
        @AuraEnabled public Datetime completedDate;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Datetime startDate;
    }

    public class BuilderRecord {
        @AuraEnabled public String metadataType;
        @AuraEnabled public String fullName;
        @AuraEnabled public String label;
        @AuraEnabled public String metadataLabel;
        @AuraEnabled public List<ConfigField> fields;
    }

    public class ValidationResult {
        @AuraEnabled public String templateKey;
        @AuraEnabled public String templateName;
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public Integer questionCount;
        @AuraEnabled public Integer brandingConfigCount;
        @AuraEnabled public Integer bindingCount;
        @AuraEnabled public Integer optionCount;
        @AuraEnabled public Integer validationRuleCount;
        @AuraEnabled public Integer conditionCount;
        @AuraEnabled public Integer hookCount;
        @AuraEnabled public Integer matchingRuleCount;
        @AuraEnabled public Integer contextConfigCount;
        @AuraEnabled public Integer fileConfigCount;
        @AuraEnabled public Integer handoffConfigCount;
        @AuraEnabled public Integer errorCount;
        @AuraEnabled public Integer warningCount;
        @AuraEnabled public Integer infoCount;
        @AuraEnabled public List<ValidationIssue> issues;
    }

    public class ValidationIssue {
        @AuraEnabled public String severity;
        @AuraEnabled public String code;
        @AuraEnabled public String componentType;
        @AuraEnabled public String componentKey;
        @AuraEnabled public String message;
    }

    public class TemplateConfiguration {
        @AuraEnabled public String templateKey;
        @AuraEnabled public String templateName;
        @AuraEnabled public Integer totalRecordCount;
        @AuraEnabled public List<ConfigSection> sections;
    }

    public class ConfigSection {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String iconName;
        @AuraEnabled public Integer count;
        @AuraEnabled public List<ConfigRecord> records;
    }

    public class ConfigRecord {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String subtitle;
        @AuraEnabled public String status;
        @AuraEnabled public String metadataType;
        @AuraEnabled public String metadataFullName;
        @AuraEnabled public String metadataLabel;
        @AuraEnabled public Boolean canDeactivate;
        @AuraEnabled public List<ConfigField> fields;
    }

    public class ConfigField {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    private class SmartIntakeAdminException extends Exception {}
}