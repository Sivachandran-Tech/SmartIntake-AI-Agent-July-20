import { LightningElement, track } from 'lwc';
import getTemplateConfiguration from '@salesforce/apex/SmartIntakeAdminController.getTemplateConfiguration';
import getTemplateReadiness from '@salesforce/apex/SmartIntakeAdminController.getTemplateReadiness';
import listBindableFields from '@salesforce/apex/SmartIntakeAdminController.listBindableFields';
import listBindableObjects from '@salesforce/apex/SmartIntakeAdminController.listBindableObjects';
import listCustomRenderers from '@salesforce/apex/SmartIntakeAdminController.listCustomRenderers';
import listFlowVariables from '@salesforce/apex/SmartIntakeAdminController.listFlowVariables';
import listInvocableFlows from '@salesforce/apex/SmartIntakeAdminController.listInvocableFlows';
import listTemplates from '@salesforce/apex/SmartIntakeAdminController.listTemplates';
import listSupportedControls from '@salesforce/apex/SmartIntakeAdminController.listSupportedControls';
import deactivateMetadataRecord from '@salesforce/apex/SmartIntakeAdminController.deactivateMetadataRecord';
import deployAdminConfigDraftJson from '@salesforce/apex/SmartIntakeAdminController.deployAdminConfigDraftJson';
import deployQuestionDraftJson from '@salesforce/apex/SmartIntakeAdminController.deployQuestionDraftJson';
import deployTemplateDraftJson from '@salesforce/apex/SmartIntakeAdminController.deployTemplateDraftJson';
import getMetadataDeploymentStatus from '@salesforce/apex/SmartIntakeAdminController.getMetadataDeploymentStatus';
import previewAdminConfigDraftJson from '@salesforce/apex/SmartIntakeAdminController.previewAdminConfigDraftJson';
import previewQuestionDraftJson from '@salesforce/apex/SmartIntakeAdminController.previewQuestionDraftJson';
import previewTemplateDraftJson from '@salesforce/apex/SmartIntakeAdminController.previewTemplateDraftJson';
import previewCustomControlRegistry from '@salesforce/apex/SmartIntakeAdminController.previewCustomControlRegistry';
import syncCustomControlRegistry from '@salesforce/apex/SmartIntakeAdminController.syncCustomControlRegistry';
import validateTemplate from '@salesforce/apex/SmartIntakeAdminController.validateTemplate';

const DEPLOYMENT_POLL_INTERVAL_MS = 2500;
const DEPLOYMENT_MAX_POLL_ATTEMPTS = 90;
const DEPLOYMENT_TERMINAL_STATUSES = new Set([
    'Succeeded',
    'SucceededPartial',
    'Failed',
    'FinalizingDeployFailed',
    'Canceled'
]);
const CUSTOM_RENDERER_QUESTION_TYPE = 'CUSTOM_LWC_RENDERER';
const FILE_INPUT_TYPES = new Set(['FILE', 'IMAGE', 'PDF']);
const OPTION_INPUT_TYPES = new Set(['PICKLIST', 'RADIO', 'MULTI_SELECT']);
const PLAIN_CHAT_INPUT_TYPES = new Set(['TEXT', 'LONG_TEXT', 'EMAIL', 'PHONE', 'URL']);
const DEFAULT_FLOW_INPUT_SOURCE_VALUES = new Set([
    'hookKey',
    'templateKey',
    'questionKey',
    'intakeSessionId',
    'agentSessionKey',
    'answerValue',
    'answersJson',
    'routableId'
]);
const DEFAULT_FLOW_INPUT_SOURCES = [
    { label: 'Current Answer Value', value: 'answerValue' },
    { label: 'All Answers JSON', value: 'answersJson' },
    { label: 'Current Question Key', value: 'questionKey' },
    { label: 'Template Key', value: 'templateKey' },
    { label: 'Hook Key', value: 'hookKey' },
    { label: 'Intake Session Id', value: 'intakeSessionId' },
    { label: 'Agent Session Key', value: 'agentSessionKey' },
    { label: 'Routable Id', value: 'routableId' }
];
const HOOK_CONTROL_OUTPUT_VALUES = new Set([
    'success',
    'userMessage',
    'nextQuestionKey',
    'blockContinue',
    'updatedAnswersJson'
]);

export default class SmartIntakeAdminConsole extends LightningElement {
    @track templates = [];
    @track validation;
    @track configuration;
    @track controlDefinitions = [];
    @track customRendererOptions = [];
    @track invocableFlowOptions = [];
    @track flowVariables = [];
    @track flowVariableOptions = [];
    @track bindableObjectOptions = [];
    @track finalSaveFieldOptions = [];
    @track readiness;
    @track setupDraft = {
        isActive: true,
        requiresConsent: true,
        requiresFinalConfirmation: true,
        createBranding: false,
        avatarIconName: 'standard:service_appointment',
        consentMessage: 'I agree that this intake can be saved and reviewed by the assigned team.',
        completionMessage: 'Thanks. Your intake has been saved.',
        welcomeMessage: 'Welcome. I will guide this intake one question at a time.'
    };
    @track setupPlan;
    @track builderDraft = {
        inputType: 'TEXT',
        storedAnswerType: 'TEXT',
        dataSourceKey: '',
        isRequired: false,
        confirmAiExtractedAnswer: false,
        renderLightningInput: false,
        allowMultipleFiles: false
    };
    @track builderPlan;
    @track configDraft = {
        configType: 'VALIDATION_RULE',
        isActive: true,
        providerType: 'ENHANCED_CHAT_V2',
        availabilityMode: 'CONFIGURED',
        requiresConsent: false,
        isContextSharingEnabled: false,
        matchType: 'EXACT',
        contextType: 'MATCHED_RECORDS',
        allowedActions: 'select;update',
        maxRecords: 5,
        validationType: 'MAX_LENGTH',
        action: 'SHOW_WHEN',
        operator: 'EQUALS',
        conditionLogic: 'ALL',
        eventName: 'AFTER_ANSWER',
        handlerType: 'FLOW',
        outputMode: 'BASIC_OUTPUT_MAPPING',
        flowInputMappings: '',
        flowOutputMappings: '',
        successOutputVariable: 'success',
        userMessageOutputVariable: 'userMessage',
        nextQuestionOutputVariable: 'nextQuestionKey',
        answersJsonOutputVariable: 'updatedAnswersJson',
        blockContinueOutputVariable: 'blockContinue',
        sortOrder: 10,
        allowMultipleFiles: false,
        maxFileCount: 1,
        linkToFinalRecord: true,
        shareType: 'V',
        visibility: 'AllUsers'
    };
    @track configPlan;
    @track configDraftVisible = {
        validation: false,
        actions: false,
        finalSaveMapping: false
    };
    @track registryPlan;
    @track deletePlan;
    @track toastMessage;
    @track confirmModal;
    @track accordionOpen = {
        question: true,
        control: false,
        rules: false,
        validation: false,
        actions: false
    };
    activeAdminTab = 'overview';
    selectedBuilderQuestionKey;

    selectedTemplateKey;
    isLoading = false;
    isConfigurationLoading = false;
    isSetupLoading = false;
    isSetupDeploying = false;
    isBuilderLoading = false;
    isDeploying = false;
    isConfigLoading = false;
    isFlowMetadataLoading = false;
    isConfigDeploying = false;
    isRegistryLoading = false;
    isRegistrySyncing = false;
    isDeleteDeploying = false;
    isCreatingTemplate = false;
    setupStep = 1;
    setupKeyManuallyEdited = false;
    toastTimer;
    deploymentPollTimers = {};
    completedDeploymentJobs = {};

    connectedCallback() {
        this.loadTemplates();
    }

    disconnectedCallback() {
        Object.values(this.deploymentPollTimers || {}).forEach((timer) => window.clearTimeout(timer));
        this.deploymentPollTimers = {};
    }

    get templateOptions() {
        return this.templates.map((template) => ({
            label: template.templateName || template.templateKey,
            value: template.templateKey
        }));
    }

    get hasTemplates() {
        return Boolean(this.templates.length);
    }

    get showTemplateEmptyState() {
        return !this.isLoading && !this.hasTemplates;
    }

    get showTemplateWorkspace() {
        return this.hasTemplates && Boolean(this.validation);
    }

    get hasToast() {
        return Boolean(this.toastMessage);
    }

    get toastClass() {
        const type = this.toastMessage?.type || 'info';
        return `toast toast_${type}`;
    }

    get toastIconName() {
        const type = this.toastMessage?.type || 'info';
        const icons = {
            success: 'utility:success',
            error: 'utility:error',
            warning: 'utility:warning',
            info: 'utility:info'
        };
        return icons[type] || icons.info;
    }

    get hasConfirmModal() {
        return Boolean(this.confirmModal);
    }

    get hasIssues() {
        return Boolean(this.validation?.issues?.length);
    }

    get healthScore() {
        if (!this.validation) {
            return 100;
        }
        const errors = this.validation.errorCount || 0;
        const warnings = this.validation.warningCount || 0;
        return Math.max(0, 100 - (errors * 10 + warnings * 5));
    }

    get hasConfiguration() {
        return Boolean(this.configuration?.sections?.length);
    }

    get configurationSections() {
        return this.configuration?.sections || [];
    }

    get channelConfigurationSections() {
        const channelKeys = new Set(['handoffs', 'handoffConfigs', 'messages', 'matchingRules', 'contextConfigs']);
        return this.configurationSections.filter((section) => {
            const text = `${section.key || ''} ${section.label || ''}`.toLowerCase();
            return channelKeys.has(section.key) || /handoff|message|matching|context/.test(text);
        });
    }

    get hasChannelConfigurationSections() {
        return Boolean(this.channelConfigurationSections.length);
    }

    get hasControlDefinitions() {
        return Boolean(this.controlDefinitions.length);
    }

    get hasReadinessItems() {
        return Boolean(this.readiness?.items?.length);
    }

    get readinessItems() {
        return this.readiness?.items || [];
    }

    get readinessPassedCount() {
        return this.readinessItems.filter((item) => {
            const status = (item.status || '').toUpperCase();
            return ['READY', 'PASS', 'PASSED'].includes(status);
        }).length;
    }

    get readinessWarningCount() {
        return this.readinessItems.filter((item) => {
            const status = (item.status || '').toUpperCase();
            return ['WARNING', 'WARN', 'MANUAL'].includes(status);
        }).length;
    }

    get readinessBlockedCount() {
        return this.readinessItems.filter((item) => {
            const status = (item.status || '').toUpperCase();
            return ['BLOCKED', 'ERROR', 'FAILED'].includes(status);
        }).length;
    }

    get inputTypeOptions() {
        return this.controlDefinitions.map((control) => ({
            label: `${control.label} (${control.inputType})`,
            value: control.inputType
        }));
    }

    get questionTypeOptions() {
        return [
            ...this.inputTypeOptions,
            { label: 'Custom LWC Renderer', value: CUSTOM_RENDERER_QUESTION_TYPE }
        ];
    }

    get storedAnswerTypeOptions() {
        return this.inputTypeOptions;
    }

    get customRendererSelectOptions() {
        const options = [...this.customRendererOptions];
        const selectedRenderer = this.builderDraft.uiControl;
        if (selectedRenderer && !options.some((option) => option.value === selectedRenderer)) {
            options.push({
                label: `${selectedRenderer} (current renderer)`,
                value: selectedRenderer
            });
        }
        return options;
    }

    get selectedCustomRendererOption() {
        return this.customRendererSelectOptions.find((option) => option.value === this.builderDraft.uiControl);
    }

    get builderQuestionType() {
        if (this.builderDraft.questionType === CUSTOM_RENDERER_QUESTION_TYPE) {
            return CUSTOM_RENDERER_QUESTION_TYPE;
        }
        return this.isCustomUiControl ? CUSTOM_RENDERER_QUESTION_TYPE : this.effectiveBuilderInputType;
    }

    get isCustomRendererQuestion() {
        return this.builderQuestionType === CUSTOM_RENDERER_QUESTION_TYPE;
    }

    get storedAnswerTypeValue() {
        return this.builderDraft.storedAnswerType || this.effectiveBuilderInputType;
    }

    get effectiveBuilderInputType() {
        return (this.builderDraft.inputType || 'TEXT').toUpperCase();
    }

    get isOptionInputType() {
        return OPTION_INPUT_TYPES.has(this.effectiveBuilderInputType);
    }

    get isFileInputType() {
        return FILE_INPUT_TYPES.has(this.effectiveBuilderInputType);
    }

    get questionRecords() {
        const questionSection = this.configurationSections.find((section) => section.key === 'questions');
        return questionSection?.records || [];
    }

    get questionItems() {
        return this.questionRecords.map((question, index) => ({
            ...question,
            listNumber: index + 1,
            displayText: question.questionText || question.questionKey || 'Untitled question',
            displayInputType: question.inputType || 'No input type',
            displayUiControl: question.uiControl || 'Default control',
            listClass:
                question.questionKey === this.selectedBuilderQuestionKey
                    ? 'question-select question-select_active'
                    : 'question-select'
        }));
    }

    get hasQuestionRecords() {
        return Boolean(this.questionRecords.length);
    }

    get builderModeLabel() {
        return this.selectedBuilderQuestionKey
            ? `Editing ${this.selectedBuilderQuestionKey}`
            : 'Create a question';
    }

    get adminTabItems() {
        return [
            {
                label: 'Overview',
                value: 'overview',
                iconName: 'utility:metrics',
                description: 'Readiness and metadata health',
                testId: 'admin-tab-overview',
                badgeCount: this.validation?.errorCount || 0,
                badgeType: 'error'
            },
            {
                label: 'Build',
                value: 'build',
                iconName: 'utility:flow',
                description: 'Questions, controls, options, rules',
                testId: 'admin-tab-build',
                badgeCount: this.builderPlan ? 1 : 0,
                badgeType: 'info'
            },
            {
                label: 'Channels',
                value: 'channels',
                iconName: 'utility:share',
                description: 'Routing, matching, handoff, context',
                testId: 'admin-tab-channels',
                badgeCount: this.configPlan ? 1 : 0,
                badgeType: 'info'
            },
            {
                label: 'Test',
                value: 'test',
                iconName: 'utility:check',
                description: 'Validation and conversation preview',
                testId: 'admin-tab-test',
                badgeCount: this.readinessBlockedCount,
                badgeType: 'error'
            },
            {
                label: 'Advanced',
                value: 'advanced',
                iconName: 'utility:settings',
                description: 'Registry and metadata explorer',
                testId: 'admin-tab-advanced',
                badgeCount: this.registryPlan ? 1 : 0,
                badgeType: 'info'
            }
        ].map((item) => {
            const showBadge = item.badgeCount > 0;
            return {
                ...item,
                selected: this.activeAdminTab === item.value,
                showBadge,
                badgeClass: this.tabBadgeClass(item.badgeType),
                buttonClass: this.adminTabButtonClass(item.value),
                navItemClass: this.adminTabNavItemClass(item.value)
            };
        });
    }

    get workspaceTitle() {
        const activeItem = this.adminTabItems.find((item) => item.value === this.activeAdminTab);
        return activeItem?.label || 'Overview';
    }

    get workspaceDescription() {
        const activeItem = this.adminTabItems.find((item) => item.value === this.activeAdminTab);
        return activeItem?.description || 'Readiness and metadata health';
    }

    get isOverviewTab() {
        return this.activeAdminTab === 'overview';
    }

    get isBuildTab() {
        return this.activeAdminTab === 'build';
    }

    get isChannelsTab() {
        return this.activeAdminTab === 'channels';
    }

    get isTestTab() {
        return this.activeAdminTab === 'test';
    }

    get isAdvancedTab() {
        return this.activeAdminTab === 'advanced';
    }

    get selectedTemplateName() {
        const template = this.templates.find((item) => item.templateKey === this.selectedTemplateKey);
        return template?.templateName || this.validation?.templateName || this.selectedTemplateKey || 'No template selected';
    }

    get summaryItems() {
        return [
            { key: 'questions', label: 'Questions', value: this.validation?.questionCount || 0 },
            { key: 'bindings', label: 'Mappings', value: this.validation?.bindingCount || 0 },
            { key: 'controls', label: 'Options', value: this.validation?.optionCount || 0 },
            { key: 'rules', label: 'Rules', value: (this.validation?.validationRuleCount || 0) + (this.validation?.conditionCount || 0) },
            { key: 'hooks', label: 'Flow Hooks', value: this.validation?.hookCount || 0 },
            { key: 'handoffs', label: 'Handoffs', value: this.validation?.handoffConfigCount || 0 },
            { key: 'health', label: 'Health', value: `${this.healthScore}%` }
        ];
    }

    get selectedControlDefinition() {
        const uiControl = (this.builderDraft.uiControl || '').toLowerCase();
        if (this.isCustomRendererQuestion) {
            return undefined;
        }
        const inputType = (this.builderDraft.inputType || '').toUpperCase();
        return this.controlDefinitions.find((control) => {
            const controlName = (control.uiControl || '').toLowerCase();
            return control.inputType === inputType || (uiControl && controlName === uiControl);
        });
    }

    get isCustomUiControl() {
        const uiControl = (this.builderDraft.uiControl || '').trim().toLowerCase();
        return uiControl.startsWith('c/') || uiControl.includes(':');
    }

    get selectedControlTitle() {
        if (this.isCustomRendererQuestion) {
            return this.selectedCustomRendererOption?.label || this.builderDraft.uiControl || 'Custom LWC Renderer';
        }
        return this.selectedControlDefinition?.label || this.builderDraft.uiControl || 'Default renderer';
    }

    get selectedControlComponent() {
        if (this.isCustomRendererQuestion) {
            return this.builderDraft.uiControl ? 'Direct custom LWC component' : 'Enter a c/... component name';
        }
        return this.selectedControlDefinition?.lightningLabel || this.builderDraft.uiControl || 'Resolved by runtime';
    }

    get selectedControlNotes() {
        if (this.isCustomRendererQuestion) {
            return 'Direct c/... LWC component names are loaded through the generated SmartIntake registry for LWR-safe rendering.';
        }
        return this.selectedControlDefinition?.notes || 'Use a standard input type, or choose Custom LWC Renderer and enter a c/... component name.';
    }

    get previewQuestionText() {
        return this.builderDraft.questionText || 'Question preview';
    }

    get previewHelpText() {
        return this.builderDraft.helpText || 'Help text appears here when configured.';
    }

    get previewPlaceholderText() {
        return this.builderDraft.placeholderText || 'Answer placeholder';
    }

    get previewInputType() {
        return this.builderDraft.inputType || 'TEXT';
    }

    get previewUiControl() {
        return this.builderDraft.uiControl || this.selectedControlTitle;
    }

    get previewRequiredLabel() {
        return this.builderDraft.isRequired ? 'Required' : 'Optional';
    }

    get questionConfigTypeOptions() {
        return [
            { label: 'Validation Rule', value: 'VALIDATION_RULE' },
            { label: 'Condition / Rule', value: 'CONDITION' },
            { label: 'Flow Hook', value: 'HOOK' }
        ];
    }

    get validationConfigTypeOptions() {
        return [
            { label: 'Validation Rule', value: 'VALIDATION_RULE' }
        ];
    }

    get actionConfigTypeOptions() {
        return [
            { label: 'Condition / Rule', value: 'CONDITION' },
            { label: 'Flow Hook', value: 'HOOK' }
        ];
    }

    get channelConfigTypeOptions() {
        return [
            { label: 'Handoff Route', value: 'HANDOFF' },
            { label: 'Message', value: 'MESSAGE' },
            { label: 'Matching Rule', value: 'MATCHING_RULE' },
            { label: 'Context Config', value: 'CONTEXT_CONFIG' }
        ];
    }

    get buildConfigTypeValue() {
        return this.isQuestionConfigType(this.configDraft.configType) ? this.configDraft.configType : '';
    }

    get channelConfigTypeValue() {
        return this.isChannelConfigType(this.configDraft.configType) ? this.configDraft.configType : '';
    }

    get hasBuildConfigType() {
        return Boolean(this.buildConfigTypeValue);
    }

    get hasChannelConfigType() {
        return Boolean(this.channelConfigTypeValue);
    }

    get activeConfigQuestionKey() {
        return this.configDraft.questionKey || this.builderDraft.questionKey || this.selectedBuilderQuestionKey || '';
    }

    get currentQuestionKeyForConfigDraft() {
        return this.normalizeDraftKey(this.builderDraft.questionKey || this.selectedBuilderQuestionKey || this.configDraft.questionKey);
    }

    get isQuestionConfigDraftButtonDisabled() {
        return !this.currentQuestionKeyForConfigDraft;
    }

    get questionConfigDraftButtonTitle() {
        return this.isQuestionConfigDraftButtonDisabled ? 'Enter a Question Key first.' : '';
    }

    get hasSelectedQuestionConfigRecords() {
        return Boolean(this.selectedQuestionConfigRecords.length);
    }

    get selectedQuestionConfigRecords() {
        const questionKey = this.builderDraft.questionKey || this.selectedBuilderQuestionKey || this.configDraft.questionKey;
        return this.questionConfigRecordsFor(questionKey);
    }

    get selectedQuestionValidationConfigRecords() {
        return this.selectedQuestionConfigRecords.filter((record) => record.configType === 'VALIDATION_RULE');
    }

    get selectedQuestionActionConfigRecords() {
        return this.selectedQuestionConfigRecords.filter((record) => record.configType !== 'VALIDATION_RULE');
    }

    get hasSelectedQuestionValidationConfigRecords() {
        return Boolean(this.selectedQuestionValidationConfigRecords.length);
    }

    get hasSelectedQuestionActionConfigRecords() {
        return Boolean(this.selectedQuestionActionConfigRecords.length);
    }

    get finalSaveSourceOptions() {
        const configuredSources = this.finalSaveMappingRecords.map((mapping) => ({
            label: `${mapping.sourceKey} (configured source)`,
            value: mapping.sourceKey
        }));
        return this.uniqueOptions([
            ...this.questionRecords.map((question) => ({
                label: `${question.questionText || question.questionKey} (${question.questionKey})`,
                value: question.questionKey
            })),
            ...this.mappedOutputStoreKeyOptions,
            ...configuredSources
        ]);
    }

    get finalSaveTargetObjectOptions() {
        const options = [...this.bindableObjectOptions];
        const currentObject = this.configDraft.objectApiName;
        if (currentObject && !options.some((option) => option.value === currentObject)) {
            options.push({
                label: `${currentObject} (current object)`,
                value: currentObject
            });
        }
        return options;
    }

    get finalSaveTargetFieldOptions() {
        const options = [...this.finalSaveFieldOptions];
        const currentField = this.configDraft.fieldApiName;
        if (currentField && !options.some((option) => option.value === currentField)) {
            options.push({
                label: `${currentField} (current field)`,
                value: currentField
            });
        }
        return options;
    }

    get isFinalSaveTargetFieldDisabled() {
        return !this.configDraft.objectApiName;
    }

    get finalSaveMappingRecords() {
        return (this.configSection('fieldBindings')?.records || [])
            .filter((record) => record.status === 'Active')
            .map((record) => {
                const sourceKey = this.configFieldValue(record, 'Question Key');
                const objectApiName = this.configFieldValue(record, 'Object API Name');
                const fieldApiName = this.configFieldValue(record, 'Field API Name');
                const isQuestionSource = this.questionRecords.some((question) => question.questionKey === sourceKey);
                return {
                    key: `final-save-${record.configKey}`,
                    configType: 'FIELD_BINDING',
                    configKey: record.configKey,
                    record,
                    sourceKey,
                    objectApiName,
                    fieldApiName,
                    sourceType: isQuestionSource ? 'Question answer' : 'Flow output',
                    title: `${sourceKey} → ${objectApiName}.${fieldApiName}`,
                    meta: record.status,
                    isDeactivateDisabled: record.isDeactivateDisabled
                };
            });
    }

    get hasFinalSaveMappingRecords() {
        return Boolean(this.finalSaveMappingRecords.length);
    }

    adminTabButtonClass(value) {
        return this.activeAdminTab === value
            ? 'setup-nav__button setup-nav__button_active'
            : 'setup-nav__button';
    }

    adminTabNavItemClass(value) {
        return this.activeAdminTab === value
            ? 'slds-nav-vertical__item slds-is-active'
            : 'slds-nav-vertical__item';
    }

    tabBadgeClass(type) {
        return type === 'error'
            ? 'tab-badge tab-badge_error'
            : 'tab-badge';
    }

    get isQuestionAccordionOpen() {
        return Boolean(this.accordionOpen.question);
    }

    get isControlAccordionOpen() {
        return Boolean(this.accordionOpen.control);
    }

    get isRulesAccordionOpen() {
        return Boolean(this.accordionOpen.rules);
    }

    get isValidationAccordionOpen() {
        return Boolean(this.accordionOpen.validation);
    }

    get isActionsAccordionOpen() {
        return Boolean(this.accordionOpen.actions);
    }

    get questionAccordionBodyClass() {
        return this.accordionBodyClass('question');
    }

    get controlAccordionBodyClass() {
        return this.accordionBodyClass('control');
    }

    get rulesAccordionBodyClass() {
        return this.accordionBodyClass('rules');
    }

    get validationAccordionBodyClass() {
        return this.accordionBodyClass('validation');
    }

    get actionsAccordionBodyClass() {
        return this.accordionBodyClass('actions');
    }

    accordionBodyClass(key) {
        return this.accordionOpen[key]
            ? 'accordion-section__body'
            : 'accordion-section__body accordion-section__body_collapsed';
    }

    get questionAccordionIcon() {
        return this.accordionOpen.question ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get controlAccordionIcon() {
        return this.accordionOpen.control ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get rulesAccordionIcon() {
        return this.accordionOpen.rules ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get validationAccordionIcon() {
        return this.accordionOpen.validation ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get actionsAccordionIcon() {
        return this.accordionOpen.actions ? 'utility:chevrondown' : 'utility:chevronright';
    }

    isQuestionConfigType(value) {
        return ['VALIDATION_RULE', 'CONDITION', 'HOOK'].includes(value);
    }

    isChannelConfigType(value) {
        return ['HANDOFF', 'MESSAGE', 'MATCHING_RULE', 'CONTEXT_CONFIG'].includes(value);
    }

    get hasSetupPlan() {
        return Boolean(this.setupPlan);
    }

    get hasSetupIssues() {
        return Boolean(this.setupPlan?.issues?.length);
    }

    get hasSetupRecords() {
        return Boolean(this.setupPlan?.records?.length);
    }

    get isSetupDeployReady() {
        return Boolean(this.setupPlan?.isValid);
    }

    get isSetupDeployButtonDisabled() {
        return this.isSetupLoading || this.isSetupDeploying || !this.isSetupDeployReady;
    }

    get isSetupStepOne() {
        return this.setupStep === 1;
    }

    get isSetupStepTwo() {
        return this.setupStep === 2;
    }

    get isSetupStepThree() {
        return this.setupStep === 3;
    }

    get wizardBackDisabled() {
        return this.setupStep <= 1 || this.isSetupLoading || this.isSetupDeploying;
    }

    get wizardNextLabel() {
        return this.setupStep === 2 ? 'Review' : 'Next';
    }

    get wizardStepOneClass() {
        return this.wizardStepClass(1);
    }

    get wizardStepTwoClass() {
        return this.wizardStepClass(2);
    }

    get wizardStepThreeClass() {
        return this.wizardStepClass(3);
    }

    wizardStepClass(step) {
        return this.setupStep === step
            ? 'wizard-step wizard-step_active'
            : 'wizard-step';
    }

    get hasBuilderPlan() {
        return Boolean(this.builderPlan);
    }

    get hasBuilderIssues() {
        return Boolean(this.builderPlan?.issues?.length);
    }

    get hasBuilderRecords() {
        return Boolean(this.builderPlan?.records?.length);
    }

    get isDeployReady() {
        return Boolean(this.builderPlan?.isValid);
    }

    get isDeployButtonDisabled() {
        return this.isBuilderLoading || this.isDeploying || !this.isDeployReady;
    }

    get configTypeOptions() {
        return [
            { label: 'Branding', value: 'BRANDING' },
            { label: 'Message', value: 'MESSAGE' },
            { label: 'Handoff', value: 'HANDOFF' },
            { label: 'Matching Rule', value: 'MATCHING_RULE' },
            { label: 'Context Config', value: 'CONTEXT_CONFIG' },
            { label: 'Validation Rule', value: 'VALIDATION_RULE' },
            { label: 'Condition', value: 'CONDITION' },
            { label: 'Flow Hook', value: 'HOOK' },
            { label: 'File Config', value: 'FILE_CONFIG' },
            { label: 'Field Binding', value: 'FIELD_BINDING' }
        ];
    }

    get hookEventOptions() {
        return [
            { label: 'After Answer', value: 'AFTER_ANSWER' }
        ];
    }

    get hookHandlerTypeOptions() {
        return [
            { label: 'Flow', value: 'FLOW' }
        ];
    }

    get hookOutputModeOptions() {
        return [
            { label: 'Basic Output Mapping', value: 'BASIC_OUTPUT_MAPPING' },
            { label: 'Advanced JSON Override', value: 'ADVANCED_JSON_OVERRIDE' }
        ];
    }

    get providerTypeOptions() {
        return [
            { label: 'Enhanced Chat v2', value: 'ENHANCED_CHAT_V2' },
            { label: 'Enhanced Omni-Channel', value: 'ENHANCED_OMNI' },
            { label: 'External URL', value: 'EXTERNAL_URL' }
        ];
    }

    get availabilityModeOptions() {
        return [
            { label: 'Configured', value: 'CONFIGURED' },
            { label: 'Always Available', value: 'ALWAYS_AVAILABLE' },
            { label: 'Always Offline', value: 'ALWAYS_OFFLINE' }
        ];
    }

    get validationTypeOptions() {
        return [
            { label: 'Regex', value: 'REGEX' },
            { label: 'Minimum Length', value: 'MIN_LENGTH' },
            { label: 'Maximum Length', value: 'MAX_LENGTH' },
            { label: 'Minimum Value', value: 'MIN_VALUE' },
            { label: 'Maximum Value', value: 'MAX_VALUE' },
            { label: 'Minimum Date', value: 'MIN_DATE' },
            { label: 'Today or Future Date', value: 'MIN_TODAY' },
            { label: 'Maximum Date', value: 'MAX_DATE' }
        ];
    }

    get conditionActionOptions() {
        return [
            { label: 'Show When', value: 'SHOW_WHEN' },
            { label: 'Hide When', value: 'HIDE_WHEN' },
            { label: 'Block Answer When', value: 'BLOCK_WHEN' }
        ];
    }

    get conditionOperatorOptions() {
        return [
            { label: 'Equals', value: 'EQUALS' },
            { label: 'Not Equals', value: 'NOT_EQUALS' },
            { label: 'In', value: 'IN' },
            { label: 'Not In', value: 'NOT_IN' },
            { label: 'Is Blank', value: 'IS_BLANK' },
            { label: 'Is Not Blank', value: 'IS_NOT_BLANK' },
            { label: 'Contains', value: 'CONTAINS' },
            { label: 'Does Not Contain', value: 'NOT_CONTAINS' },
            { label: 'Starts With', value: 'STARTS_WITH' },
            { label: 'Ends With', value: 'ENDS_WITH' },
            { label: 'Greater Than', value: 'GREATER_THAN' },
            { label: 'Greater Than or Equal', value: 'GREATER_OR_EQUAL' },
            { label: 'Less Than', value: 'LESS_THAN' },
            { label: 'Less Than or Equal', value: 'LESS_OR_EQUAL' },
            { label: 'Before', value: 'BEFORE' },
            { label: 'After', value: 'AFTER' },
            { label: 'On or Before', value: 'ON_OR_BEFORE' },
            { label: 'On or After', value: 'ON_OR_AFTER' }
        ];
    }

    get conditionLogicOptions() {
        return [
            { label: 'All Conditions Are Met (AND)', value: 'ALL' },
            { label: 'Any Condition Is Met (OR)', value: 'ANY' },
            { label: 'Custom Logic', value: 'CUSTOM' }
        ];
    }

    get conditionOperatorOptionsForSource() {
        const inputType = (this.selectedConditionSourceQuestion?.inputType || '').toUpperCase();
        const blankOptions = ['IS_BLANK', 'IS_NOT_BLANK'];
        let allowed = ['EQUALS', 'NOT_EQUALS', 'IN', 'NOT_IN', ...blankOptions];
        if (['TEXT', 'LONG_TEXT', 'EMAIL', 'PHONE', 'URL'].includes(inputType)) {
            allowed = ['EQUALS', 'NOT_EQUALS', 'CONTAINS', 'NOT_CONTAINS', 'STARTS_WITH', 'ENDS_WITH', ...blankOptions];
        } else if (['NUMBER', 'CURRENCY'].includes(inputType)) {
            allowed = ['EQUALS', 'NOT_EQUALS', 'GREATER_THAN', 'GREATER_OR_EQUAL', 'LESS_THAN', 'LESS_OR_EQUAL', ...blankOptions];
        } else if (['DATE', 'DATETIME'].includes(inputType)) {
            allowed = ['EQUALS', 'NOT_EQUALS', 'BEFORE', 'AFTER', 'ON_OR_BEFORE', 'ON_OR_AFTER', ...blankOptions];
        } else if (['BOOLEAN'].includes(inputType)) {
            allowed = ['EQUALS', 'NOT_EQUALS', ...blankOptions];
        } else if (['PICKLIST', 'RADIO', 'MULTI_SELECT'].includes(inputType)) {
            allowed = ['EQUALS', 'NOT_EQUALS', 'IN', 'NOT_IN', ...blankOptions];
        }
        return this.conditionOperatorOptions.filter((option) => allowed.includes(option.value));
    }

    get selectedConditionSourceQuestion() {
        const sourceKey = this.configDraft.sourceQuestionKey || this.builderDraft.questionKey || this.selectedBuilderQuestionKey;
        return this.questionRecords.find((question) => question.questionKey === sourceKey);
    }

    get conditionComparePlaceholder() {
        const inputType = (this.selectedConditionSourceQuestion?.inputType || '').toUpperCase();
        if (['DATE', 'DATETIME'].includes(inputType)) {
            return 'TODAY, TODAY+7, or YYYY-MM-DD';
        }
        if (['NUMBER', 'CURRENCY'].includes(inputType)) {
            return 'Numeric value';
        }
        if (['PICKLIST', 'RADIO', 'MULTI_SELECT'].includes(inputType)) {
            return 'One value, or semicolon-separated values';
        }
        return 'Compare value';
    }

    get isCustomConditionLogic() {
        return this.configDraft.conditionLogic === 'CUSTOM';
    }

    get isBlockCondition() {
        return this.configDraft.action === 'BLOCK_WHEN';
    }

    get matchTypeOptions() {
        return [
            { label: 'Exact', value: 'EXACT' }
        ];
    }

    get contextTypeOptions() {
        return [
            { label: 'Matched Records', value: 'MATCHED_RECORDS' }
        ];
    }

    get shareTypeOptions() {
        return [
            { label: 'Viewer', value: 'V' },
            { label: 'Collaborator', value: 'C' },
            { label: 'Inferred', value: 'I' }
        ];
    }

    get visibilityOptions() {
        return [
            { label: 'All Users', value: 'AllUsers' },
            { label: 'Internal Users', value: 'InternalUsers' },
            { label: 'Shared Users', value: 'SharedUsers' }
        ];
    }

    get isBrandingConfig() {
        return this.configDraft.configType === 'BRANDING';
    }

    get isMessageConfig() {
        return this.configDraft.configType === 'MESSAGE';
    }

    get isHandoffConfig() {
        return this.configDraft.configType === 'HANDOFF';
    }

    get isMatchingConfig() {
        return this.configDraft.configType === 'MATCHING_RULE';
    }

    get isContextConfig() {
        return this.configDraft.configType === 'CONTEXT_CONFIG';
    }

    get isValidationConfig() {
        return this.configDraft.configType === 'VALIDATION_RULE';
    }

    get isValidationConfigDraftVisible() {
        return this.isValidationConfig && this.configDraftVisible.validation;
    }

    get hasValidationConfigDraftVisible() {
        return this.isValidationConfigDraftVisible;
    }

    get showValidationRegexField() {
        return this.configDraft.validationType === 'REGEX';
    }

    get showValidationMinLengthField() {
        return this.configDraft.validationType === 'MIN_LENGTH';
    }

    get showValidationMaxLengthField() {
        return this.configDraft.validationType === 'MAX_LENGTH';
    }

    get showValidationMinValueField() {
        return this.configDraft.validationType === 'MIN_VALUE';
    }

    get showValidationMaxValueField() {
        return this.configDraft.validationType === 'MAX_VALUE';
    }

    get showValidationMinDateField() {
        return this.configDraft.validationType === 'MIN_DATE';
    }

    get showValidationMaxDateField() {
        return this.configDraft.validationType === 'MAX_DATE';
    }

    get isActionConfig() {
        return this.configDraft.configType === 'CONDITION' || this.configDraft.configType === 'HOOK';
    }

    get isActionConfigDraftVisible() {
        return this.isActionConfig && this.configDraftVisible.actions;
    }

    get hasActionConfigDraftVisible() {
        return this.isActionConfigDraftVisible;
    }

    get isConditionConfig() {
        return this.configDraft.configType === 'CONDITION';
    }

    get isHookConfig() {
        return this.configDraft.configType === 'HOOK';
    }

    get flowApiNameOptions() {
        const options = [...this.invocableFlowOptions];
        const currentFlow = this.configDraft.flowApiName;
        if (currentFlow && !options.some((option) => option.value === currentFlow)) {
            options.push({
                label: `${currentFlow} (current flow)`,
                value: currentFlow
            });
        }
        return options;
    }

    get selectedFlowInputVariables() {
        return this.flowVariables.filter((variable) => variable.isInput);
    }

    get selectedFlowOutputVariables() {
        return this.flowVariables.filter((variable) => variable.isOutput);
    }

    get hasSelectedFlowInputVariables() {
        return Boolean(this.selectedFlowInputVariables.length);
    }

    get hasSelectedFlowOutputVariables() {
        return Boolean(this.selectedFlowOutputVariables.length);
    }

    get hasSelectedFlowVariables() {
        return this.hasSelectedFlowInputVariables || this.hasSelectedFlowOutputVariables;
    }

    get flowInputSourceOptions() {
        const configuredSources = Array.from(this.parseInputMappings(this.configDraft.flowInputMappings).values())
            .filter((sourceKey) => sourceKey && !DEFAULT_FLOW_INPUT_SOURCE_VALUES.has(sourceKey))
            .map((sourceKey) => ({
                label: `${sourceKey} (configured source)`,
                value: sourceKey
            }));
        const options = [
            ...DEFAULT_FLOW_INPUT_SOURCES,
            ...this.questionRecords.map((question) => ({
                label: `${question.questionText || question.questionKey} (${question.questionKey})`,
                value: question.questionKey
            })),
            ...this.mappedOutputStoreKeyOptions,
            ...configuredSources
        ];
        return this.uniqueOptions(options);
    }

    get mappedOutputStoreKeyOptions() {
        const storeKeys = new Set();
        (this.configSection('hooks')?.records || []).forEach((record) => {
            this.parseOutputMappings(this.configFieldValue(record, 'Flow Output Mappings')).forEach((answerKey) => {
                if (answerKey) {
                    storeKeys.add(answerKey);
                }
            });
        });
        return Array.from(storeKeys).sort().map((key) => ({
            label: `${key} (mapped data key)`,
            value: key
        }));
    }

    get flowInputMappingRows() {
        const mappingsByVariable = this.parseInputMappings(this.configDraft.flowInputMappings);
        return this.selectedFlowInputVariables.map((variable) => {
            const sourceKey = mappingsByVariable.get(variable.apiName) || this.defaultFlowInputSource(variable.apiName);
            return {
                ...variable,
                key: `input-${variable.apiName}`,
                sourceKey,
                typeDetail: variable.detail || this.flowVariableTypeDetail(variable),
                isDefaultContextInput: DEFAULT_FLOW_INPUT_SOURCE_VALUES.has(variable.apiName)
            };
        });
    }

    get flowOutputMappingRows() {
        const mappingsByVariable = this.parseOutputMappings(this.configDraft.flowOutputMappings);
        return this.selectedFlowOutputVariables.map((variable) => {
            const isHookControlOutput = this.isHookControlOutput(variable.apiName);
            const suggestedAnswerKey = isHookControlOutput ? '' : this.suggestAnswerKeyForFlowOutput(variable.apiName);
            return {
                ...variable,
                key: `output-${variable.apiName}`,
                answerKey: mappingsByVariable.get(variable.apiName) || suggestedAnswerKey,
                typeDetail: variable.detail || this.flowVariableTypeDetail(variable),
                isHookControlOutput,
                storeAsPlaceholder: isHookControlOutput ? 'Handled by SmartIntake' : suggestedAnswerKey,
                outputMappingHelpText: isHookControlOutput
                    ? 'SmartIntake reads this control output directly. No Store As value is needed.'
                    : `Suggested key: ${suggestedAnswerKey}`
            };
        });
    }

    get isBasicHookOutputMode() {
        return (this.configDraft.outputMode || 'BASIC_OUTPUT_MAPPING') === 'BASIC_OUTPUT_MAPPING';
    }

    get isAdvancedHookOutputMode() {
        return this.configDraft.outputMode === 'ADVANCED_JSON_OVERRIDE';
    }

    get isFileConfig() {
        return this.configDraft.configType === 'FILE_CONFIG';
    }

    get isFieldBindingConfig() {
        return this.configDraft.configType === 'FIELD_BINDING';
    }

    get isFinalSaveMappingDraftVisible() {
        return this.isFieldBindingConfig && this.configDraftVisible.finalSaveMapping;
    }

    get hasFinalSaveMappingDraftVisible() {
        return this.isFinalSaveMappingDraftVisible;
    }

    get hasConfigPlan() {
        return Boolean(this.configPlan);
    }

    get hasDeletePlan() {
        return Boolean(this.deletePlan);
    }

    get hasConfigIssues() {
        return Boolean(this.configPlan?.issues?.length);
    }

    get hasConfigRecords() {
        return Boolean(this.configPlan?.records?.length);
    }

    get isConfigDeployReady() {
        return Boolean(this.configPlan?.isValid);
    }

    get isConfigDeployButtonDisabled() {
        return this.isConfigLoading || this.isConfigDeploying || !this.isConfigDeployReady;
    }

    get hasRegistryPlan() {
        return Boolean(this.registryPlan);
    }

    get hasRegistryIssues() {
        return Boolean(this.registryPlan?.issues?.length);
    }

    get hasRegistryRecords() {
        return Boolean(this.registryPlan?.records?.length);
    }

    get isRegistrySyncReady() {
        return Boolean(this.registryPlan?.isValid);
    }

    get isRegistrySyncButtonDisabled() {
        return this.isRegistryLoading || this.isRegistrySyncing || !this.isRegistrySyncReady;
    }

    get statusLabel() {
        if (!this.validation) {
            return '';
        }
        return this.validation.isValid ? 'Ready' : 'Needs Attention';
    }

    get statusIcon() {
        return this.validation?.isValid ? 'utility:success' : 'utility:error';
    }

    get statusClass() {
        return this.validation?.isValid ? 'status status_ready' : 'status status_error';
    }

    async loadTemplates() {
        this.isLoading = true;
        try {
            const [templates, controls, customRenderers, invocableFlows, bindableObjects] = await Promise.all([
                listTemplates(),
                listSupportedControls(),
                listCustomRenderers(),
                listInvocableFlows(),
                listBindableObjects()
            ]);
            this.templates = templates;
            this.controlDefinitions = this.decorateControls(controls);
            this.customRendererOptions = this.decorateMetadataChoices(customRenderers);
            this.invocableFlowOptions = this.decorateMetadataChoices(invocableFlows);
            this.bindableObjectOptions = this.decorateMetadataChoices(bindableObjects);
            const activeTemplate = this.templates.find((template) => template.isActive);
            const firstTemplate = activeTemplate || this.templates[0];
            this.selectedTemplateKey = firstTemplate?.templateKey;
            this.configuration = undefined;
            this.builderDraft = {
                ...this.builderDraft,
                templateKey: this.selectedTemplateKey
            };
            this.configDraft = {
                ...this.configDraft,
                templateKey: this.selectedTemplateKey
            };
            if (this.selectedTemplateKey) {
                await this.runValidation();
                if (this.shouldLoadConfigurationForActiveTab()) {
                    await this.loadConfiguration();
                }
            } else {
                this.validation = undefined;
                this.readiness = undefined;
            }
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isLoading = false;
        }
    }

    async handleTemplateChange(event) {
        this.selectedTemplateKey = event.detail.value;
        this.configuration = undefined;
        this.selectedBuilderQuestionKey = undefined;
        this.builderPlan = undefined;
        this.configPlan = undefined;
        this.registryPlan = undefined;
        this.deletePlan = undefined;
        this.builderDraft = {
            ...this.builderDraft,
            templateKey: this.selectedTemplateKey
        };
        this.configDraft = {
            ...this.configDraft,
            templateKey: this.selectedTemplateKey
        };
        await this.runValidation();
        if (this.shouldLoadConfigurationForActiveTab()) {
            await this.loadConfiguration();
        }
    }

    async handleValidate() {
        await this.runValidation();
        if (this.shouldLoadConfigurationForActiveTab()) {
            await this.loadConfiguration(true);
        }
    }

    async handleAdminSectionClick(event) {
        const tabValue = event.currentTarget?.dataset?.tab;
        if (tabValue) {
            this.activeAdminTab = tabValue;
            this.prepareDraftForActiveSection(tabValue);
            if (this.shouldLoadConfigurationForActiveTab()) {
                await this.loadConfiguration();
            }
        }
    }

    async handleAdminTabActive(event) {
        const tabValue = event.currentTarget?.value;
        if (tabValue) {
            this.activeAdminTab = tabValue;
            this.prepareDraftForActiveSection(tabValue);
            if (this.shouldLoadConfigurationForActiveTab()) {
                await this.loadConfiguration();
            }
        }
    }

    shouldLoadConfigurationForActiveTab() {
        return ['build', 'channels', 'advanced'].includes(this.activeAdminTab);
    }

    prepareDraftForActiveSection(tabValue) {
        if (tabValue === 'build' && !this.isQuestionConfigType(this.configDraft.configType)) {
            const questionKey = this.builderDraft.questionKey || this.configDraft.questionKey || '';
            this.configDraft = {
                ...this.configDraft,
                configType: 'VALIDATION_RULE',
                configKey: this.suggestConfigKey('VALIDATION_RULE', questionKey),
                label: '',
                questionKey,
                targetQuestionKey: this.configDraft.targetQuestionKey || questionKey
            };
            this.configPlan = undefined;
        }
        if (tabValue === 'channels' && !this.isChannelConfigType(this.configDraft.configType)) {
            this.configDraft = {
                ...this.configDraft,
                configType: 'HANDOFF',
                configKey: this.suggestConfigKey('HANDOFF', this.selectedTemplateKey),
                label: ''
            };
            this.configPlan = undefined;
        }
    }

    handleSetupChange(event) {
        const control = this.fieldControlFromEvent(event);
        const fieldName = control?.dataset?.field;
        if (!fieldName) {
            return;
        }
        const value = this.valueFromEvent(event, control);
        if (fieldName === 'templateKey') {
            this.setupKeyManuallyEdited = true;
        }
        const updatedDraft = {
            ...this.setupDraft,
            [fieldName]: value
        };
        if (fieldName === 'templateName' && !this.setupKeyManuallyEdited) {
            updatedDraft.templateKey = this.suggestTemplateKey(value);
        }
        this.setupDraft = updatedDraft;
        this.setupPlan = undefined;
    }

    async handlePreviewTemplateDraft() {
        this.setupDraft = this.syncDraftFromControls('section[aria-label="Template creation wizard"]', this.setupDraft);
        this.isSetupLoading = true;
        try {
            const result = await previewTemplateDraftJson({ draftJson: JSON.stringify(this.setupPayload) });
            this.setupPlan = this.decorateBuilderPlan(result);
            this.showToast('Template metadata preview is ready.', 'success');
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isSetupLoading = false;
        }
    }

    async handleDeployTemplateDraft() {
        this.setupDraft = this.syncDraftFromControls('section[aria-label="Template creation wizard"]', this.setupDraft);
        this.isSetupDeploying = true;
        try {
            const result = await deployTemplateDraftJson({
                draftJson: JSON.stringify(this.setupPayload),
                confirmed: true
            });
            this.setupPlan = this.decorateBuilderPlan(result);
            this.showToast(
                result.deploymentJobId
                    ? `Template metadata deployment queued: ${result.deploymentJobId}`
                    : result.metadataWriteNotice,
                'success',
                false
            );
            if (result.metadataWriteStatus === 'QUEUED') {
                this.trackDeployment('setupPlan', result, 'Template metadata');
            }
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isSetupDeploying = false;
        }
    }

    handleNewTemplate() {
        this.setupDraft = this.createDefaultSetupDraft();
        this.setupPlan = undefined;
        this.setupStep = 1;
        this.setupKeyManuallyEdited = false;
        this.isCreatingTemplate = true;
    }

    handleWizardClose() {
        this.isCreatingTemplate = false;
    }

    handleWizardBack() {
        this.setupStep = Math.max(1, this.setupStep - 1);
    }

    async handleWizardNext() {
        this.setupDraft = this.syncDraftFromControls('section[aria-label="Template creation wizard"]', this.setupDraft);
        if (this.setupStep === 1) {
            if (!this.setupDraft.templateName || !this.setupDraft.templateKey) {
                this.showToast('Template name and key are required before continuing.', 'error', false);
                return;
            }
            this.setupStep = 2;
            return;
        }
        if (this.setupStep === 2) {
            await this.handlePreviewTemplateDraft();
            this.setupStep = 3;
        }
    }

    handleWizardFinish() {
        this.handleDeployTemplateClick();
    }

    async loadFinalSaveFieldOptions() {
        const objectApiName = this.configDraft.objectApiName;
        if (!objectApiName) {
            this.finalSaveFieldOptions = [];
            return;
        }
        const sourceQuestion = this.questionRecords.find(
            (question) => question.questionKey === this.configDraft.questionKey
        );
        try {
            const fields = await listBindableFields({
                objectApiName,
                inputType: sourceQuestion?.inputType || ''
            });
            this.finalSaveFieldOptions = this.decorateMetadataChoices(fields);
        } catch (error) {
            this.finalSaveFieldOptions = [];
            this.showToast(this.reduceError(error), 'error', false);
        }
    }

    handleBuilderChange(event) {
        const control = this.fieldControlFromEvent(event);
        const fieldName = control?.dataset?.field;
        if (!fieldName) {
            return;
        }
        const value = this.valueFromEvent(event, control);
        const updatedDraft = {
            ...this.builderDraft,
            [fieldName]: value
        };
        if (fieldName === 'questionType') {
            if (value === CUSTOM_RENDERER_QUESTION_TYPE) {
                updatedDraft.inputType = updatedDraft.storedAnswerType || updatedDraft.inputType || 'TEXT';
                updatedDraft.storedAnswerType = updatedDraft.inputType;
                updatedDraft.uiControl = updatedDraft.uiControl || '';
                updatedDraft.renderLightningInput = true;
            } else {
                updatedDraft.inputType = value;
                updatedDraft.storedAnswerType = value;
                updatedDraft.uiControl = '';
                updatedDraft.dataSourceKey = '';
                updatedDraft.renderLightningInput = this.defaultRenderLightningInput(value, '');
            }
        }
        if (fieldName === 'storedAnswerType' || fieldName === 'inputType') {
            updatedDraft.inputType = value;
            updatedDraft.storedAnswerType = value;
            updatedDraft.renderLightningInput = updatedDraft.questionType === CUSTOM_RENDERER_QUESTION_TYPE
                ? true
                : this.defaultRenderLightningInput(value, updatedDraft.uiControl);
        }
        if (['questionType', 'storedAnswerType', 'inputType'].includes(fieldName)) {
            if (FILE_INPUT_TYPES.has((updatedDraft.inputType || '').toUpperCase())) {
                updatedDraft.optionLines = '';
            } else {
                updatedDraft.acceptedFileTypes = '';
                updatedDraft.allowMultipleFiles = false;
                updatedDraft.maxFileCount = null;
                if (!OPTION_INPUT_TYPES.has((updatedDraft.inputType || '').toUpperCase())) {
                    updatedDraft.optionLines = '';
                }
            }
        }
        this.builderDraft = updatedDraft;
        if (fieldName === 'questionKey') {
            const questionKey = this.normalizeDraftKey(value);
            const previousSuggestedKey = this.suggestConfigKey(this.configDraft.configType, this.configDraft.questionKey || '');
            const shouldRefreshConfigKey = !this.configDraft.configKey || this.configDraft.configKey === previousSuggestedKey;
            this.configDraft = {
                ...this.configDraft,
                configKey: shouldRefreshConfigKey ? this.suggestConfigKey(this.configDraft.configType, questionKey) : this.configDraft.configKey,
                questionKey,
                sourceQuestionKey: this.configDraft.sourceQuestionKey || questionKey,
                targetQuestionKey: this.configDraft.targetQuestionKey || questionKey
            };
        }
        this.builderPlan = undefined;
    }

    defaultRenderLightningInput(inputType, uiControl) {
        const normalizedInputType = (inputType || 'TEXT').toUpperCase();
        const normalizedUiControl = (uiControl || '').trim().toLowerCase();
        if (normalizedUiControl.startsWith('c/') || normalizedUiControl.includes(':')) {
            return true;
        }
        return !PLAIN_CHAT_INPUT_TYPES.has(normalizedInputType);
    }

    async handleEditQuestion(event) {
        const questionKey = event.currentTarget?.dataset?.questionKey;
        const question = this.questionRecords.find((record) => record.questionKey === questionKey);
        if (!question) {
            return;
        }
        this.selectedBuilderQuestionKey = question.questionKey;
        this.builderDraft = {
            ...this.builderDraft,
            templateKey: this.selectedTemplateKey,
            questionKey: question.questionKey,
            questionText: question.questionText,
            helpText: question.helpText,
            placeholderText: question.placeholderText,
            questionOrder: question.questionOrder,
            isRequired: question.isRequired,
            confirmAiExtractedAnswer: question.confirmAiExtractedAnswer,
            renderLightningInput: question.renderLightningInput,
            inputType: question.inputType || 'TEXT',
            storedAnswerType: question.inputType || 'TEXT',
            uiControl: question.uiControl,
            dataSourceKey: question.dataSourceKey,
            objectApiName: '',
            fieldApiName: '',
            optionLines: this.relatedOptionLines(question.questionKey),
            acceptedFileTypes: this.relatedFileConfigValue(question.questionKey, 'Accepted File Types'),
            allowMultipleFiles: this.toBoolean(this.relatedFileConfigValue(question.questionKey, 'Allow Multiple')),
            maxFileCount: this.relatedFileConfigValue(question.questionKey, 'Max File Count')
        };
        const existingConfig = this.questionConfigRecordsFor(question.questionKey)[0];
        this.configDraft = existingConfig
            ? this.configDraftFromQuestionConfig(existingConfig)
            : this.defaultQuestionConfigDraft(question.questionKey);
        this.accordionOpen = {
            ...this.accordionOpen,
            rules: true,
            validation: true,
            actions: true
        };
        this.configDraftVisible = {
            validation: this.configDraft.configType === 'VALIDATION_RULE',
            actions: this.configDraft.configType === 'CONDITION' || this.configDraft.configType === 'HOOK'
        };
        this.builderPlan = undefined;
        this.configPlan = undefined;
    }

    handleNewQuestionDraft() {
        this.selectedBuilderQuestionKey = undefined;
        this.builderDraft = {
            templateKey: this.selectedTemplateKey,
            inputType: 'TEXT',
            storedAnswerType: 'TEXT',
            dataSourceKey: '',
            isRequired: false,
            confirmAiExtractedAnswer: false,
            renderLightningInput: false,
            allowMultipleFiles: false
        };
        this.configDraft = {
            ...this.defaultQuestionConfigDraft('')
        };
        this.configDraftVisible = {
            validation: false,
            actions: false
        };
        this.builderPlan = undefined;
        this.configPlan = undefined;
    }

    async handlePreviewQuestionDraft() {
        this.builderDraft = this.syncDraftFromControls('section[aria-label="Question metadata builder"]', this.builderDraft);
        this.isBuilderLoading = true;
        try {
            const result = await previewQuestionDraftJson({ draftJson: JSON.stringify(this.builderPayload) });
            this.builderPlan = this.decorateBuilderPlan(result);
            this.showToast('Question metadata preview is ready.', 'success');
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isBuilderLoading = false;
        }
    }

    async handleDeployQuestionDraft() {
        this.builderDraft = this.syncDraftFromControls('section[aria-label="Question metadata builder"]', this.builderDraft);
        this.isDeploying = true;
        try {
            const result = await deployQuestionDraftJson({
                draftJson: JSON.stringify(this.builderPayload),
                confirmed: true
            });
            this.builderPlan = this.decorateBuilderPlan(result);
            this.showToast(
                result.deploymentJobId
                    ? `Question metadata deployment queued: ${result.deploymentJobId}`
                    : result.metadataWriteNotice,
                'success',
                false
            );
            if (result.metadataWriteStatus === 'QUEUED') {
                this.trackDeployment('builderPlan', result, 'Question metadata');
            }
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isDeploying = false;
        }
    }

    async handleConfigChange(event) {
        const control = this.fieldControlFromEvent(event);
        const fieldName = control?.dataset?.field;
        if (!fieldName) {
            return;
        }
        const value = this.valueFromEvent(event, control);
        let updatedDraft = {
            ...this.configDraft,
            [fieldName]: value
        };
        if (fieldName === 'configType') {
            const questionKey = updatedDraft.questionKey || this.currentQuestionKeyForConfigDraft;
            updatedDraft.questionKey = updatedDraft.questionKey || questionKey;
            updatedDraft.configKey = this.suggestConfigKey(value, questionKey);
            updatedDraft.label = '';
            this.flowVariables = [];
            this.flowVariableOptions = [];
            this.configDraftVisible = {
                validation: value === 'VALIDATION_RULE',
                actions: value === 'CONDITION' || value === 'HOOK'
            };
        }
        if (fieldName === 'configType' && this.isQuestionConfigType(value) && !updatedDraft.questionKey) {
            updatedDraft.questionKey = this.currentQuestionKeyForConfigDraft;
            updatedDraft.targetQuestionKey = updatedDraft.targetQuestionKey || this.currentQuestionKeyForConfigDraft;
        }
        if (fieldName === 'questionKey') {
            const questionKey = this.normalizeDraftKey(value);
            const previousSuggestedKey = this.suggestConfigKey(this.configDraft.configType, this.configDraft.questionKey || '');
            const shouldRefreshConfigKey = !this.configDraft.configKey || this.configDraft.configKey === previousSuggestedKey;
            updatedDraft.questionKey = questionKey;
            updatedDraft.configKey = shouldRefreshConfigKey ? this.suggestConfigKey(updatedDraft.configType, questionKey) : updatedDraft.configKey;
            updatedDraft.sourceQuestionKey = updatedDraft.sourceQuestionKey || questionKey;
            updatedDraft.targetQuestionKey = updatedDraft.targetQuestionKey || questionKey;
        }
        if (fieldName === 'configType' && value === 'CONDITION') {
            const questionKey = updatedDraft.questionKey || this.builderDraft.questionKey || this.selectedBuilderQuestionKey || '';
            updatedDraft.sourceQuestionKey = updatedDraft.sourceQuestionKey || questionKey;
            updatedDraft.targetQuestionKey = updatedDraft.targetQuestionKey || questionKey;
            updatedDraft.action = 'BLOCK_WHEN';
            updatedDraft.conditionGroupKey = updatedDraft.conditionGroupKey || (questionKey ? `${questionKey}_rules` : '');
            updatedDraft.conditionLogic = updatedDraft.conditionLogic || 'ALL';
        }
        if (fieldName === 'configType' && value === 'HOOK') {
            updatedDraft.eventName = updatedDraft.eventName || 'AFTER_ANSWER';
            updatedDraft.handlerType = updatedDraft.handlerType || 'FLOW';
            updatedDraft.outputMode = updatedDraft.outputMode || 'BASIC_OUTPUT_MAPPING';
            updatedDraft.flowInputMappings = updatedDraft.flowInputMappings || '';
            updatedDraft.successOutputVariable = updatedDraft.successOutputVariable || 'success';
            updatedDraft.userMessageOutputVariable = updatedDraft.userMessageOutputVariable || 'userMessage';
            updatedDraft.nextQuestionOutputVariable = updatedDraft.nextQuestionOutputVariable || 'nextQuestionKey';
            updatedDraft.answersJsonOutputVariable = updatedDraft.answersJsonOutputVariable || 'updatedAnswersJson';
            updatedDraft.blockContinueOutputVariable = updatedDraft.blockContinueOutputVariable || 'blockContinue';
        }
        if (fieldName === 'validationType') {
            updatedDraft = this.sanitizeValidationDraft(updatedDraft);
        }
        this.configDraft = updatedDraft;
        if (fieldName === 'sourceQuestionKey') {
            const allowedOperators = this.conditionOperatorOptionsForSource.map((option) => option.value);
            if (!allowedOperators.includes(this.configDraft.operator)) {
                this.configDraft = {
                    ...this.configDraft,
                    operator: 'EQUALS'
                };
            }
        }
        if (fieldName === 'flowApiName') {
            await this.loadFlowVariables(value);
        }
        if (this.configDraft.configType === 'FIELD_BINDING' && fieldName === 'objectApiName') {
            this.configDraft = {
                ...this.configDraft,
                fieldApiName: ''
            };
            await this.loadFinalSaveFieldOptions();
        }
        if (this.configDraft.configType === 'FIELD_BINDING' && fieldName === 'questionKey') {
            await this.loadFinalSaveFieldOptions();
        }
        this.configPlan = undefined;
    }

    handleFlowInputMappingChange(event) {
        const variableName = event.currentTarget?.dataset?.variableName;
        if (!variableName) {
            return;
        }
        const rows = this.flowInputMappingRows.map((row) => ({
            ...row,
            sourceKey: row.apiName === variableName ? event.detail?.value || event.target?.value || '' : row.sourceKey
        }));
        this.configDraft = {
            ...this.configDraft,
            flowInputMappings: this.serializeInputMappings(rows)
        };
        this.configPlan = undefined;
    }

    handleFlowOutputMappingChange(event) {
        const variableName = event.currentTarget?.dataset?.variableName;
        if (!variableName) {
            return;
        }
        const rows = this.flowOutputMappingRows.map((row) => ({
            ...row,
            answerKey: row.apiName === variableName ? event.detail?.value || event.target?.value || '' : row.answerKey
        }));
        this.configDraft = {
            ...this.configDraft,
            flowOutputMappings: this.serializeOutputMappings(rows)
        };
        this.configPlan = undefined;
    }

    handleNewValidationConfigDraft() {
        const questionKey = this.resolveQuestionKeyForNewQuestionConfig();
        if (!questionKey) {
            this.showToast('Enter a Question Key before adding a validation rule.', 'error', false);
            return;
        }
        this.configDraft = this.defaultQuestionConfigDraft(questionKey, 'VALIDATION_RULE');
        this.configDraftVisible = {
            ...this.configDraftVisible,
            validation: true
        };
        this.configPlan = undefined;
    }

    handleNewActionConfigDraft() {
        const questionKey = this.resolveQuestionKeyForNewQuestionConfig();
        if (!questionKey) {
            this.showToast('Enter a Question Key before adding an action.', 'error', false);
            return;
        }
        this.configDraft = this.defaultQuestionConfigDraft(questionKey, 'CONDITION');
        this.configDraftVisible = {
            ...this.configDraftVisible,
            actions: true
        };
        this.flowVariables = [];
        this.flowVariableOptions = [];
        this.configPlan = undefined;
    }

    handleRemoveValidationConfigDraft() {
        this.configDraftVisible = {
            ...this.configDraftVisible,
            validation: false
        };
        this.configPlan = undefined;
    }

    handleRemoveActionConfigDraft() {
        this.configDraftVisible = {
            ...this.configDraftVisible,
            actions: false
        };
        this.flowVariables = [];
        this.flowVariableOptions = [];
        this.configPlan = undefined;
    }

    handleNewFinalSaveMappingDraft() {
        const suggestedSource = this.mappedOutputStoreKeyOptions[0]?.value || this.questionRecords[0]?.questionKey || '';
        this.configDraft = {
            ...this.defaultQuestionConfigDraft(suggestedSource, 'FIELD_BINDING'),
            configKey: this.suggestConfigKey('FIELD_BINDING', suggestedSource),
            objectApiName: this.finalSaveMappingRecords[0]?.objectApiName || '',
            fieldApiName: ''
        };
        this.configDraftVisible = {
            ...this.configDraftVisible,
            finalSaveMapping: true
        };
        this.finalSaveFieldOptions = [];
        this.configPlan = undefined;
        this.loadFinalSaveFieldOptions();
    }

    handleRemoveFinalSaveMappingDraft() {
        this.configDraftVisible = {
            ...this.configDraftVisible,
            finalSaveMapping: false
        };
        this.finalSaveFieldOptions = [];
        this.configPlan = undefined;
    }

    handleNewQuestionConfigDraft() {
        this.handleNewActionConfigDraft();
    }

    resolveQuestionKeyForNewQuestionConfig() {
        this.builderDraft = this.syncDraftFromControls('section[aria-label="Question metadata builder"]', this.builderDraft);
        const questionKey = this.normalizeDraftKey(this.builderDraft.questionKey || this.selectedBuilderQuestionKey || this.configDraft.questionKey);
        if (questionKey && this.builderDraft.questionKey !== questionKey) {
            this.builderDraft = {
                ...this.builderDraft,
                questionKey
            };
        }
        return questionKey;
    }

    async handleLoadQuestionConfig(event) {
        const configType = event.currentTarget?.dataset?.configType;
        const configKey = event.currentTarget?.dataset?.configKey;
        const record = this.selectedQuestionConfigRecords.find(
            (item) => item.configType === configType && item.configKey === configKey
        );
        if (!record) {
            this.showToast('Could not load that rule/action from the current metadata view.', 'error', false);
            return;
        }
        this.configDraft = this.configDraftFromQuestionConfig(record);
        this.configDraftVisible = {
            validation: this.configDraft.configType === 'VALIDATION_RULE',
            actions: this.configDraft.configType === 'CONDITION' || this.configDraft.configType === 'HOOK'
        };
        this.configPlan = undefined;
        if (this.configDraft.configType === 'HOOK') {
            await this.loadFlowVariables(this.configDraft.flowApiName);
        } else {
            this.flowVariables = [];
            this.flowVariableOptions = [];
        }
    }

    async handleLoadFinalSaveMapping(event) {
        const configKey = event.currentTarget?.dataset?.configKey;
        const item = this.finalSaveMappingRecords.find((mapping) => mapping.configKey === configKey);
        if (!item) {
            this.showToast('Could not load that final save mapping from the current metadata view.', 'error', false);
            return;
        }
        this.configDraft = {
            ...this.defaultQuestionConfigDraft(item.sourceKey, 'FIELD_BINDING'),
            configKey: item.configKey,
            label: item.configKey,
            questionKey: item.sourceKey,
            objectApiName: item.objectApiName,
            fieldApiName: item.fieldApiName,
            isActive: item.record.status === 'Active'
        };
        this.configDraftVisible = {
            ...this.configDraftVisible,
            finalSaveMapping: true
        };
        this.configPlan = undefined;
        await this.loadFinalSaveFieldOptions();
    }

    handleDeactivateFinalSaveMappingClick(event) {
        const configKey = event.currentTarget?.dataset?.configKey;
        const item = this.finalSaveMappingRecords.find((mapping) => mapping.configKey === configKey);
        if (!item?.record) {
            this.showToast('Could not find that final save mapping in the current metadata view.', 'error', false);
            return;
        }
        this.confirmDeactivateRecord(item.record);
    }

    handleDeactivateQuestionConfigClick(event) {
        const configType = event.currentTarget?.dataset?.configType;
        const configKey = event.currentTarget?.dataset?.configKey;
        const item = this.selectedQuestionConfigRecords.find(
            (record) => record.configType === configType && record.configKey === configKey
        );
        if (!item?.record) {
            this.showToast('Could not find that rule/action in the current metadata view.', 'error', false);
            return;
        }
        this.confirmDeactivateRecord(item.record);
    }

    async handlePreviewAdminConfigDraft() {
        this.configDraft = this.syncDraftFromControls('section[aria-label="Admin configuration builder"]', this.configDraft);
        this.isConfigLoading = true;
        try {
            const result = await previewAdminConfigDraftJson({ draftJson: JSON.stringify(this.configPayload) });
            this.configPlan = this.decorateBuilderPlan(result);
            this.showToast('Configuration metadata preview is ready.', 'success');
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isConfigLoading = false;
        }
    }

    async handleDeployAdminConfigDraft() {
        this.configDraft = this.syncDraftFromControls('section[aria-label="Admin configuration builder"]', this.configDraft);
        this.isConfigDeploying = true;
        try {
            const result = await deployAdminConfigDraftJson({
                draftJson: JSON.stringify(this.configPayload),
                confirmed: true
            });
            this.configPlan = this.decorateBuilderPlan(result);
            this.showToast(
                result.deploymentJobId
                    ? `Configuration metadata deployment queued: ${result.deploymentJobId}`
                    : result.metadataWriteNotice,
                'success',
                false
            );
            if (result.metadataWriteStatus === 'QUEUED') {
                this.trackDeployment('configPlan', result, 'Configuration metadata');
            }
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isConfigDeploying = false;
        }
    }

    async handlePreviewCustomControlRegistry() {
        this.isRegistryLoading = true;
        try {
            const result = await previewCustomControlRegistry();
            this.registryPlan = this.decorateBuilderPlan(result);
            this.showToast('Custom control registry preview is ready.', 'success');
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isRegistryLoading = false;
        }
    }

    async handleSyncCustomControlRegistry() {
        this.isRegistrySyncing = true;
        try {
            const result = await syncCustomControlRegistry({
                confirmed: true
            });
            this.registryPlan = this.decorateBuilderPlan(result);
            const isSynced = result.metadataWriteStatus === 'SYNCED' && result.isValid;
            const registryIssue = result.issues?.find((issue) => issue.severity === 'ERROR') || result.issues?.[0];
            this.showToast(
                isSynced && result.registryResourceId
                    ? `${result.metadataWriteNotice} Resource: ${result.registryResourceId}`
                    : registryIssue?.message || result.metadataWriteNotice,
                isSynced ? 'success' : 'error',
                false
            );
            if (isSynced) {
                await this.runValidation();
            }
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isRegistrySyncing = false;
        }
    }

    async handleDeactivateConfigRecordClick(event) {
        const sectionKey = event.currentTarget?.dataset?.sectionKey;
        const metadataFullName = event.currentTarget?.dataset?.metadataFullName;
        const record = this.findConfigRecord(sectionKey, metadataFullName);
        if (!record) {
            this.showToast('Could not find that metadata record in the current view.', 'error', false);
            return;
        }
        this.confirmDeactivateRecord(record);
    }

    confirmDeactivateRecord(record) {
        if (!record?.canDeactivate || !record.metadataType || !record.metadataFullName) {
            this.showToast('This record cannot be deleted from SmartIntake Admin.', 'error', false);
            return;
        }
        if (record.status !== 'Active') {
            this.showToast('This record is already inactive.', 'info');
            return;
        }
        this.confirmModal = {
            action: 'deactivate',
            record,
            title: 'Delete metadata record?',
            body: `This will deactivate ${record.metadataFullName} by setting Is Active to false. It will no longer be used by SmartIntake runtime after Salesforce completes the deployment.`,
            confirmLabel: 'Delete'
        };
    }

    async handleDeactivateMetadataRecord(record) {
        this.isDeleteDeploying = true;
        try {
            const result = await deactivateMetadataRecord({
                metadataType: record.metadataType,
                metadataFullName: record.metadataFullName,
                metadataLabel: record.metadataLabel || record.label,
                confirmed: true
            });
            this.deletePlan = this.decorateBuilderPlan(result);
            this.showToast(
                result.deploymentJobId
                    ? `Delete deployment queued: ${result.deploymentJobId}`
                    : result.metadataWriteNotice,
                result.metadataWriteStatus === 'QUEUED' ? 'success' : 'info',
                false
            );
            if (result.metadataWriteStatus === 'QUEUED') {
                this.trackDeployment('deletePlan', result, 'Metadata delete');
            }
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isDeleteDeploying = false;
        }
    }

    trackDeployment(planProperty, result, label) {
        const deploymentJobId = result?.deploymentJobId;
        if (!deploymentJobId) {
            return;
        }
        this.clearDeploymentTimer(deploymentJobId);
        this.updatePlanDeploymentStatus(
            planProperty,
            deploymentJobId,
            this.decorateDeploymentStatus({
                deploymentJobId,
                status: 'Pending',
                done: false,
                success: false,
                numberComponentsDeployed: 0,
                numberComponentsTotal: result.recordCount || 0,
                numberComponentErrors: 0,
                numberTestsCompleted: 0,
                numberTestsTotal: 0,
                numberTestErrors: 0,
                stateDetail: 'Waiting for Salesforce to start the deployment.'
            }),
            result
        );
        this.pollDeploymentStatus(planProperty, deploymentJobId, label, 0);
    }

    async pollDeploymentStatus(planProperty, deploymentJobId, label, attempt) {
        try {
            const deploymentStatus = await this.fetchDeploymentStatus(deploymentJobId);
            if (!deploymentStatus) {
                throw new Error('Salesforce returned an empty deployment status response.');
            }
            this.updatePlanDeploymentStatus(planProperty, deploymentJobId, deploymentStatus);
            if (deploymentStatus.isComplete) {
                this.clearDeploymentTimer(deploymentJobId);
                await this.handleDeploymentFinished(planProperty, deploymentStatus, label);
                return;
            }
        } catch (error) {
            const message = this.reduceError(error);
            this.updatePlanDeploymentStatus(
                planProperty,
                deploymentJobId,
                this.decorateDeploymentStatus({
                    deploymentJobId,
                    status: 'StatusUnavailable',
                    done: false,
                    success: false,
                    errorMessage: `Could not read the Salesforce deployment status yet. ${message}`
                })
            );
        }

        if (attempt >= DEPLOYMENT_MAX_POLL_ATTEMPTS) {
            this.clearDeploymentTimer(deploymentJobId);
            this.updatePlanDeploymentStatus(
                planProperty,
                deploymentJobId,
                this.decorateDeploymentStatus({
                    deploymentJobId,
                    status: 'StatusTimeout',
                    done: false,
                    success: false,
                    errorMessage: 'Salesforce has not reported a final status yet. Leave this page open or refresh validation from the admin console after Deployment Status completes.'
                })
            );
            return;
        }

        this.deploymentPollTimers[deploymentJobId] = window.setTimeout(
            () => this.pollDeploymentStatus(planProperty, deploymentJobId, label, attempt + 1),
            DEPLOYMENT_POLL_INTERVAL_MS
        );
    }

    async fetchDeploymentStatus(deploymentJobId) {
        const deploymentStatus = await getMetadataDeploymentStatus({ deploymentJobId });
        return this.normalizeDeploymentStatus(deploymentStatus, { deploymentJobId });
    }

    normalizeDeploymentStatus(deployResult, envelope = {}) {
        const status = this.deployField(deployResult, 'status', 'Status') || 'Pending';
        const doneValue = this.deployField(deployResult, 'done', 'Done');
        const successValue = this.deployField(deployResult, 'success', 'Success');
        const deploymentJobId =
            this.deployField(deployResult, 'deploymentJobId', 'DeploymentJobId') ||
            this.deployField(deployResult, 'id', 'Id') ||
            this.deployField(envelope, 'deploymentJobId', 'DeploymentJobId') ||
            this.deployField(envelope, 'id', 'Id');
        const done = doneValue === undefined || doneValue === null
            ? DEPLOYMENT_TERMINAL_STATUSES.has(status)
            : this.toBoolean(doneValue);
        const success = successValue === undefined || successValue === null
            ? status === 'Succeeded'
            : this.toBoolean(successValue);
        return this.decorateDeploymentStatus({
            deploymentJobId,
            status,
            done,
            success,
            numberComponentsDeployed: this.safeNumber(this.deployField(deployResult, 'numberComponentsDeployed', 'NumberComponentsDeployed')),
            numberComponentsTotal: this.safeNumber(this.deployField(deployResult, 'numberComponentsTotal', 'NumberComponentsTotal')),
            numberComponentErrors: this.safeNumber(this.deployField(deployResult, 'numberComponentErrors', 'NumberComponentErrors')),
            numberTestsCompleted: this.safeNumber(this.deployField(deployResult, 'numberTestsCompleted', 'NumberTestsCompleted')),
            numberTestsTotal: this.safeNumber(this.deployField(deployResult, 'numberTestsTotal', 'NumberTestsTotal')),
            numberTestErrors: this.safeNumber(this.deployField(deployResult, 'numberTestErrors', 'NumberTestErrors')),
            stateDetail: this.deployField(deployResult, 'stateDetail', 'StateDetail'),
            errorMessage: this.deployField(deployResult, 'errorMessage', 'ErrorMessage'),
            errorStatusCode: this.deployField(deployResult, 'errorStatusCode', 'ErrorStatusCode'),
            completedDate: this.deployField(deployResult, 'completedDate', 'CompletedDate'),
            createdDate: this.deployField(deployResult, 'createdDate', 'CreatedDate'),
            startDate: this.deployField(deployResult, 'startDate', 'StartDate')
        });
    }

    decorateDeploymentStatus(status) {
        if (!status?.deploymentJobId) {
            return undefined;
        }
        const rawStatus = status.status || status.rawStatus || 'Pending';
        const metadataWriteStatus = this.metadataWriteStatusForDeployStatus(rawStatus);
        const componentsTotal = this.safeNumber(status.numberComponentsTotal);
        const componentsDeployed = this.safeNumber(status.numberComponentsDeployed);
        const componentErrors = this.safeNumber(status.numberComponentErrors);
        const testsTotal = this.safeNumber(status.numberTestsTotal);
        const testsCompleted = this.safeNumber(status.numberTestsCompleted);
        const testErrors = this.safeNumber(status.numberTestErrors);
        const isComplete = this.toBoolean(status.done) || DEPLOYMENT_TERMINAL_STATUSES.has(rawStatus);
        const isSuccess = this.toBoolean(status.success) || rawStatus === 'Succeeded';
        const isFailure = isComplete && !isSuccess;
        const progressValue = this.deploymentProgressValue(rawStatus, componentsDeployed, componentsTotal, isComplete, isSuccess);
        const statusLabel = this.deploymentStatusLabel(rawStatus, isComplete, isSuccess);
        const componentProgressLabel = componentsTotal
            ? `${componentsDeployed}/${componentsTotal} components deployed`
            : 'Component progress not available yet';
        const testProgressLabel = testsTotal
            ? `${testsCompleted}/${testsTotal} tests completed`
            : 'No Apex tests reported for this deployment';
        return {
            ...status,
            rawStatus,
            metadataWriteStatus,
            statusLabel,
            componentProgressLabel,
            testProgressLabel,
            progressValue,
            progressStyle: `width: ${progressValue}%;`,
            isComplete,
            isSuccess,
            isFailure,
            componentErrors,
            testErrors,
            notice: this.deploymentNotice({
                rawStatus,
                metadataWriteStatus,
                statusLabel,
                componentsTotal,
                componentsDeployed,
                componentErrors,
                testsTotal,
                testsCompleted,
                testErrors,
                errorMessage: status.errorMessage,
                errorStatusCode: status.errorStatusCode,
                stateDetail: status.stateDetail,
                isComplete,
                isSuccess
            })
        };
    }

    updatePlanDeploymentStatus(planProperty, deploymentJobId, deploymentStatus, fallbackPlan = {}) {
        const currentPlan = this[planProperty] || fallbackPlan || {};
        if (currentPlan.deploymentJobId && currentPlan.deploymentJobId !== deploymentJobId) {
            return;
        }
        this[planProperty] = this.decorateBuilderPlan({
            ...fallbackPlan,
            ...currentPlan,
            deploymentJobId,
            deploymentStatus,
            metadataWriteStatus: deploymentStatus?.metadataWriteStatus || currentPlan.metadataWriteStatus,
            metadataWriteNotice: deploymentStatus?.notice || currentPlan.metadataWriteNotice
        });
    }

    async handleDeploymentFinished(planProperty, deploymentStatus, label) {
        if (this.completedDeploymentJobs[deploymentStatus.deploymentJobId]) {
            return;
        }
        this.completedDeploymentJobs = {
            ...this.completedDeploymentJobs,
            [deploymentStatus.deploymentJobId]: true
        };
        if (deploymentStatus.isSuccess) {
            this.showToast(`${label} deployment completed: ${deploymentStatus.deploymentJobId}`, 'success', false);
            await this.refreshAfterDeployment(planProperty);
        } else {
            this.showToast(`${label} deployment did not complete successfully. ${deploymentStatus.errorMessage || deploymentStatus.statusLabel}`, 'error', false);
        }
    }

    async refreshAfterDeployment(planProperty) {
        if (planProperty === 'setupPlan') {
            await this.loadTemplates();
            return;
        }
        if (planProperty === 'builderPlan' || planProperty === 'configPlan' || planProperty === 'deletePlan') {
            await this.runValidation();
            await this.loadConfiguration(true);
        }
    }

    clearDeploymentTimer(deploymentJobId) {
        if (this.deploymentPollTimers?.[deploymentJobId]) {
            window.clearTimeout(this.deploymentPollTimers[deploymentJobId]);
            delete this.deploymentPollTimers[deploymentJobId];
        }
    }

    deployField(source, lowerName, upperName) {
        if (!source) {
            return undefined;
        }
        if (source[lowerName] !== undefined) {
            return source[lowerName];
        }
        return source[upperName];
    }

    safeNumber(value) {
        if (value === undefined || value === null || value === '') {
            return 0;
        }
        const numericValue = Number(value);
        return Number.isFinite(numericValue) ? numericValue : 0;
    }

    metadataWriteStatusForDeployStatus(status) {
        const normalized = String(status || '').toUpperCase();
        if (normalized === 'INPROGRESS') {
            return 'IN_PROGRESS';
        }
        if (normalized === 'FINALIZINGDEPLOY') {
            return 'FINALIZING';
        }
        if (normalized === 'FINALIZINGDEPLOYFAILED') {
            return 'FINALIZING_FAILED';
        }
        if (normalized === 'SUCCEEDED') {
            return 'SUCCEEDED';
        }
        if (normalized === 'SUCCEEDEDPARTIAL') {
            return 'SUCCEEDED_PARTIAL';
        }
        if (normalized === 'STATUSUNAVAILABLE') {
            return 'STATUS_UNAVAILABLE';
        }
        if (normalized === 'STATUSTIMEOUT') {
            return 'STATUS_PENDING';
        }
        return normalized || 'PENDING';
    }

    deploymentStatusLabel(status, isComplete, isSuccess) {
        if (status === 'StatusUnavailable') {
            return 'Checking Salesforce Deployment Status';
        }
        if (status === 'StatusTimeout') {
            return 'Still Waiting For Final Status';
        }
        if (status === 'FinalizingDeploy') {
            return 'Finalizing Deployment';
        }
        if (status === 'FinalizingDeployFailed') {
            return 'Finalizing Failed';
        }
        if (status === 'SucceededPartial') {
            return 'Partially Succeeded';
        }
        if (isComplete && isSuccess) {
            return 'Deployment Complete';
        }
        if (isComplete) {
            return 'Deployment Failed';
        }
        if (status === 'InProgress') {
            return 'Deployment In Progress';
        }
        return 'Deployment Queued';
    }

    deploymentProgressValue(status, componentsDeployed, componentsTotal, isComplete, isSuccess) {
        if (isComplete) {
            return isSuccess ? 100 : Math.max(componentsTotal ? Math.round((componentsDeployed / componentsTotal) * 100) : 100, 5);
        }
        if (componentsTotal > 0) {
            return Math.max(5, Math.min(95, Math.round((componentsDeployed / componentsTotal) * 100)));
        }
        if (status === 'FinalizingDeploy') {
            return 95;
        }
        if (status === 'InProgress') {
            return 45;
        }
        return 10;
    }

    deploymentNotice(status) {
        const progress = status.componentsTotal
            ? `${status.componentsDeployed}/${status.componentsTotal} components`
            : 'component count pending';
        const tests = status.testsTotal
            ? ` ${status.testsCompleted}/${status.testsTotal} tests.`
            : ' No Apex tests reported.';
        if (status.isComplete && status.isSuccess) {
            return `Salesforce completed the Custom Metadata deployment successfully. ${progress}.${tests}`;
        }
        if (status.isComplete) {
            const errorDetail = status.errorMessage || status.errorStatusCode || status.stateDetail || 'Review Salesforce Deployment Status for details.';
            return `Salesforce finished the deployment with status ${status.metadataWriteStatus}. ${errorDetail}`;
        }
        if (status.rawStatus === 'StatusUnavailable' || status.rawStatus === 'StatusTimeout') {
            return status.errorMessage;
        }
        const currentStep = status.stateDetail ? ` Current step: ${status.stateDetail}.` : '';
        return `Salesforce is processing the Custom Metadata deployment: ${status.statusLabel}. ${progress}.${tests}${currentStep}`;
    }

    async runValidation() {
        if (!this.selectedTemplateKey) {
            this.validation = undefined;
            this.configuration = undefined;
            this.readiness = undefined;
            return;
        }

        this.isLoading = true;
        try {
            const [result, readiness] = await Promise.all([
                validateTemplate({ templateKey: this.selectedTemplateKey }),
                getTemplateReadiness({ templateKey: this.selectedTemplateKey })
            ]);
            this.validation = {
                ...result,
                issues: (result.issues || []).map((issue, index) => ({
                    ...issue,
                    key: `${issue.code}-${issue.componentKey}-${index}`,
                    className: `issue issue_${(issue.severity || 'INFO').toLowerCase()}`
                }))
            };
            this.readiness = this.decorateReadiness(readiness);
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isLoading = false;
        }
    }

    async loadConfiguration(force = false) {
        if (!this.selectedTemplateKey || (this.configuration && !force)) {
            return;
        }
        this.isConfigurationLoading = true;
        try {
            const configuration = await getTemplateConfiguration({ templateKey: this.selectedTemplateKey });
            this.configuration = this.decorateConfiguration(configuration);
        } catch (error) {
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isConfigurationLoading = false;
        }
    }

    async loadFlowVariables(flowApiName) {
        if (!flowApiName) {
            this.flowVariables = [];
            this.flowVariableOptions = [];
            return;
        }
        this.isFlowMetadataLoading = true;
        try {
            const variables = await listFlowVariables({ flowApiName });
            this.flowVariables = (variables || []).map((variable) => ({
                ...variable,
                key: variable.apiName,
                detail: variable.detail || this.flowVariableTypeDetail(variable)
            }));
            this.flowVariableOptions = this.flowVariables.map((variable) => ({
                label: `${variable.apiName} (${variable.detail})`,
                value: variable.apiName
            }));
            this.applySuggestedFlowOutputMappings();
        } catch (error) {
            this.flowVariables = [];
            this.flowVariableOptions = [];
            this.showToast(this.reduceError(error), 'error', false);
        } finally {
            this.isFlowMetadataLoading = false;
        }
    }

    handleAccordionToggle(event) {
        const section = event.currentTarget?.dataset?.section;
        if (!section) {
            return;
        }
        this.accordionOpen = {
            ...this.accordionOpen,
            [section]: !this.accordionOpen[section]
        };
    }

    handleDeployQuestionClick() {
        if (!this.builderPlan) {
            this.showToast('Preview the question metadata before deploying.', 'warning');
            return;
        }
        if (!this.isDeployReady) {
            this.showToast('Resolve question metadata issues before deploying.', 'error', false);
            return;
        }
        this.confirmModal = {
            action: 'question',
            title: 'Deploy question metadata?',
            body: 'This will queue a Salesforce metadata deployment for the question, options, file settings, and mapping records in the current preview plan.',
            confirmLabel: 'Deploy Question'
        };
    }

    handleDeployConfigClick() {
        if (!this.configPlan) {
            this.showToast('Preview the configuration metadata before deploying.', 'warning');
            return;
        }
        if (!this.isConfigDeployReady) {
            this.showToast('Resolve configuration metadata issues before deploying.', 'error', false);
            return;
        }
        this.confirmModal = {
            action: 'config',
            title: 'Deploy configuration metadata?',
            body: 'This will queue a Salesforce metadata deployment for the rule, action, channel, or routing configuration in the current preview plan.',
            confirmLabel: 'Deploy Config'
        };
    }

    handleDeployTemplateClick() {
        if (!this.setupPlan) {
            this.showToast('Preview the template metadata before deploying.', 'warning');
            return;
        }
        if (!this.isSetupDeployReady) {
            this.showToast('Resolve template metadata issues before deploying.', 'error', false);
            return;
        }
        this.confirmModal = {
            action: 'template',
            title: 'Deploy new template metadata?',
            body: 'This will queue the starter metadata needed for the new SmartIntake template. Messaging channel branding stays configured in Salesforce channel setup.',
            confirmLabel: 'Deploy Template'
        };
    }

    handleDeploySyncClick() {
        if (!this.registryPlan) {
            this.showToast('Preview the custom control registry before syncing.', 'warning');
            return;
        }
        if (!this.isRegistrySyncReady) {
            this.showToast('Resolve registry issues before syncing.', 'error', false);
            return;
        }
        this.confirmModal = {
            action: 'registry',
            title: 'Sync custom control registry?',
            body: 'This will update the generated static LWC registry metadata so active custom controls can render in fresh chat sessions.',
            confirmLabel: 'Sync Registry'
        };
    }

    handleModalCancel() {
        this.confirmModal = undefined;
    }

    async handleModalConfirm() {
        const modal = this.confirmModal;
        const action = modal?.action;
        this.confirmModal = undefined;
        if (action === 'question') {
            await this.handleDeployQuestionDraft();
        } else if (action === 'config') {
            await this.handleDeployAdminConfigDraft();
        } else if (action === 'template') {
            await this.handleDeployTemplateDraft();
        } else if (action === 'registry') {
            await this.handleSyncCustomControlRegistry();
        } else if (action === 'deactivate') {
            await this.handleDeactivateMetadataRecord(modal.record);
        }
    }

    showToast(text, type = 'info', autoDismiss = true) {
        const message = this.normalizeToastText(text);
        if (type === 'error' && this.isTransientClientCancellation(message)) {
            return;
        }
        if (this.toastTimer) {
            clearTimeout(this.toastTimer);
        }
        this.toastMessage = {
            text: message,
            type
        };
        if (autoDismiss) {
            this.toastTimer = setTimeout(() => {
                this.toastMessage = undefined;
                this.toastTimer = undefined;
            }, 4500);
        }
    }

    normalizeToastText(text) {
        return String(text || '').trim();
    }

    isTransientClientCancellation(message) {
        return this.normalizeToastText(message).toLowerCase() === 'disconnected or canceled';
    }

    handleToastDismiss() {
        if (this.toastTimer) {
            clearTimeout(this.toastTimer);
            this.toastTimer = undefined;
        }
        this.toastMessage = undefined;
    }

    fieldControlFromEvent(event) {
        const path = typeof event.composedPath === 'function' ? event.composedPath() : [];
        return [event.currentTarget, event.target, ...path].find((node) => node?.dataset?.field);
    }

    valueFromEvent(event, control) {
        if (control?.type === 'checkbox' || event.target?.type === 'checkbox') {
            return event.detail?.checked ?? event.target?.checked ?? control.checked;
        }
        if (event.detail?.value !== undefined) {
            return event.detail.value;
        }
        if (event.target?.value !== undefined) {
            return event.target.value;
        }
        if (control?.value !== undefined) {
            return control.value;
        }
        return undefined;
    }

    syncDraftFromControls(sectionSelector, draft) {
        const nextDraft = { ...draft };
        const scopedControls = Array.from(this.template.querySelectorAll(`${sectionSelector} [data-field]`));
        const controls = scopedControls.length
            ? scopedControls
            : Array.from(this.template.querySelectorAll('[data-field]')).filter((control) => control.getClientRects().length > 0);
        controls.forEach((control) => {
            const fieldName = control.dataset?.field;
            if (!fieldName) {
                return;
            }
            const value = this.valueFromControl(control);
            if (value !== undefined) {
                nextDraft[fieldName] = value;
            }
        });
        return nextDraft;
    }

    valueFromControl(control) {
        if (control?.type === 'checkbox') {
            return control.checked;
        }
        if (control?.value !== undefined) {
            return control.value;
        }
        return undefined;
    }

    uniqueOptions(options) {
        const seen = new Set();
        return (options || []).filter((option) => {
            if (!option?.value || seen.has(option.value)) {
                return false;
            }
            seen.add(option.value);
            return true;
        });
    }

    defaultFlowInputSource(apiName) {
        return DEFAULT_FLOW_INPUT_SOURCE_VALUES.has(apiName) ? apiName : '';
    }

    flowVariableTypeDetail(variable) {
        const direction = variable?.isInput && variable?.isOutput
            ? 'Input/Output'
            : (variable?.isInput ? 'Input' : (variable?.isOutput ? 'Output' : 'Variable'));
        const dataType = variable?.dataType || 'Unknown';
        const collection = variable?.isCollection ? ' collection' : '';
        const objectType = variable?.objectType ? ` - ${variable.objectType}` : '';
        return `${direction} - ${dataType}${collection}${objectType}`;
    }

    parseInputMappings(value) {
        return this.parseMappingText(value, ['<-', '=', ':']);
    }

    parseOutputMappings(value) {
        return this.parseMappingText(value, ['->', '=', ':']);
    }

    parseMappingText(value, delimiters) {
        const mappings = new Map();
        String(value || '')
            .replace(/\r\n/g, '\n')
            .replace(/\r/g, '\n')
            .replace(/;/g, '\n')
            .split('\n')
            .map((line) => line.trim())
            .filter((line) => line && !line.startsWith('#'))
            .forEach((line) => {
                const delimiter = delimiters.find((item) => line.includes(item));
                if (!delimiter) {
                    return;
                }
                const delimiterIndex = line.indexOf(delimiter);
                const left = line.slice(0, delimiterIndex).trim();
                const right = line.slice(delimiterIndex + delimiter.length).trim();
                if (left && right) {
                    mappings.set(left, right);
                }
            });
        return mappings;
    }

    serializeInputMappings(rows) {
        return (rows || [])
            .filter((row) => row?.apiName && row.sourceKey)
            .filter((row) => !DEFAULT_FLOW_INPUT_SOURCE_VALUES.has(row.apiName) || row.sourceKey !== row.apiName)
            .map((row) => `${row.apiName} <- ${row.sourceKey}`)
            .join('\n');
    }

    serializeOutputMappings(rows) {
        return (rows || [])
            .filter((row) => row?.apiName && row.answerKey)
            .filter((row) => !this.isHookControlOutput(row.apiName))
            .map((row) => `${row.apiName} -> ${row.answerKey}`)
            .join('\n');
    }

    applySuggestedFlowOutputMappings() {
        if (!this.isBasicHookOutputMode || !this.selectedFlowOutputVariables.length) {
            return;
        }
        const mappingsByVariable = this.parseOutputMappings(this.configDraft.flowOutputMappings);
        let changed = false;
        this.selectedFlowOutputVariables.forEach((variable) => {
            if (!variable?.apiName || this.isHookControlOutput(variable.apiName) || mappingsByVariable.has(variable.apiName)) {
                return;
            }
            const suggestedAnswerKey = this.suggestAnswerKeyForFlowOutput(variable.apiName);
            if (suggestedAnswerKey) {
                mappingsByVariable.set(variable.apiName, suggestedAnswerKey);
                changed = true;
            }
        });
        if (changed) {
            const rows = this.selectedFlowOutputVariables.map((variable) => ({
                apiName: variable.apiName,
                answerKey: mappingsByVariable.get(variable.apiName) || ''
            }));
            this.configDraft = {
                ...this.configDraft,
                flowOutputMappings: this.serializeOutputMappings(rows)
            };
        }
    }

    isHookControlOutput(apiName) {
        return HOOK_CONTROL_OUTPUT_VALUES.has(apiName);
    }

    suggestAnswerKeyForFlowOutput(apiName) {
        return String(apiName || '')
            .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
            .replace(/[^A-Za-z0-9]+/g, '_')
            .replace(/^_+|_+$/g, '')
            .toUpperCase();
    }

    decorateConfiguration(configuration) {
        return {
            ...configuration,
            sections: (configuration?.sections || []).map((section) => ({
                ...section,
                displayLabel: `${section.label} (${section.count || 0})`,
                hasRecords: Boolean(section.records?.length),
                records: (section.records || []).map((record, recordIndex) => {
                    const configKey = record.key || '';
                    const recordKey = `${section.key}-${configKey || recordIndex}`;
                    return {
                        ...record,
                        key: recordKey,
                        configKey,
                        isActive: record.status === 'Active',
                        isDeactivateDisabled: this.isDeleteDeploying || record.status !== 'Active' || !record.canDeactivate,
                        statusClass:
                            record.status === 'Active'
                                ? 'config-record__status config-record__status_active'
                                : 'config-record__status',
                        fields: (record.fields || []).map((field, fieldIndex) => ({
                            ...field,
                            key: `${recordKey}-${field.label || fieldIndex}`,
                            rawValue: field.value || '',
                            value: field.value || '-'
                        })),
                        ...this.decorateConfigRecord(section.key, record)
                    };
                })
            }))
        };
    }

    decorateConfigRecord(sectionKey, record) {
        if (sectionKey !== 'questions') {
            return {};
        }
        return {
            questionKey: this.configFieldValue(record, 'Question Key'),
            questionText: record.label || '',
            questionOrder: this.configFieldValue(record, 'Order'),
            isRequired: this.toBoolean(this.configFieldValue(record, 'Required')),
            confirmAiExtractedAnswer: this.toBoolean(this.configFieldValue(record, 'Confirm AI Extracted Answer')),
            inputType: this.configFieldValue(record, 'Input Type'),
            uiControl: this.configFieldValue(record, 'UI Control'),
            renderLightningInput: this.toBoolean(this.configFieldValue(record, 'Render Lightning Input')),
            dataSourceKey: this.configFieldValue(record, 'Data Source Key'),
            helpText: this.configFieldValue(record, 'Help Text'),
            placeholderText: this.configFieldValue(record, 'Placeholder')
        };
    }

    configSection(sectionKey) {
        return this.configurationSections.find((section) => section.key === sectionKey);
    }

    findConfigRecord(sectionKey, metadataFullName) {
        if (!sectionKey || !metadataFullName) {
            return undefined;
        }
        return (this.configSection(sectionKey)?.records || []).find(
            (record) => record.metadataFullName === metadataFullName
        );
    }

    configFieldValue(record, label) {
        const field = (record?.fields || []).find((item) => item.label === label);
        return field?.rawValue ?? field?.value ?? '';
    }

    relatedFileConfigValue(questionKey, label) {
        const record = (this.configSection('fileConfigs')?.records || []).find(
            (item) => this.configFieldValue(item, 'Question Key') === questionKey
        );
        return this.configFieldValue(record, label);
    }

    relatedOptionLines(questionKey) {
        return (this.configSection('options')?.records || [])
            .filter((record) => this.configFieldValue(record, 'Question Key') === questionKey)
            .map((record) => {
                const label = this.configFieldValue(record, 'Option Label');
                const value = this.configFieldValue(record, 'Option Value');
                return value && value !== label ? `${label}=${value}` : label;
            })
            .filter(Boolean)
            .join('\n');
    }

    questionConfigRecordsFor(questionKey) {
        if (!questionKey) {
            return [];
        }
        const records = [];
        (this.configSection('validationRules')?.records || [])
            .filter((record) => this.configFieldValue(record, 'Question Key') === questionKey)
            .forEach((record) => {
                const validationType = this.configFieldValue(record, 'Validation Type');
                records.push({
                    key: `validation-${record.configKey}`,
                    configType: 'VALIDATION_RULE',
                    configKey: record.configKey,
                    record,
                    questionKey,
                    typeLabel: 'Validation',
                    typeClass: 'configured-rule__type configured-rule__type_validation',
                    title: this.optionLabel(this.validationTypeOptions, validationType),
                    detail: this.configFieldValue(record, 'Error Message') || 'Answer must pass this validation before continuing.',
                    meta: record.status,
                    isDeactivateDisabled: record.isDeactivateDisabled
                });
            });

        (this.configSection('conditions')?.records || [])
            .filter((record) => {
                const sourceQuestion = this.configFieldValue(record, 'Source Question');
                const targetQuestion = this.configFieldValue(record, 'Target Question');
                return sourceQuestion === questionKey || targetQuestion === questionKey;
            })
            .forEach((record) => {
                const sourceQuestion = this.configFieldValue(record, 'Source Question');
                const targetQuestion = this.configFieldValue(record, 'Target Question');
                const action = this.configFieldValue(record, 'Action');
                const operator = this.configFieldValue(record, 'Operator');
                const compareValue = this.configFieldValue(record, 'Compare Value');
                const groupKey = this.configFieldValue(record, 'Condition Group');
                const logic = this.configFieldValue(record, 'Condition Logic') || 'ALL';
                records.push({
                    key: `condition-${record.configKey}`,
                    configType: 'CONDITION',
                    configKey: record.configKey,
                    record,
                    questionKey,
                    typeLabel: 'Condition',
                    typeClass: 'configured-rule__type configured-rule__type_condition',
                    title: `${this.optionLabel(this.conditionActionOptions, action)} ${targetQuestion}`,
                    detail: `When ${sourceQuestion} ${this.optionLabel(this.conditionOperatorOptions, operator)} ${compareValue || '(blank)'}${groupKey ? ` · ${groupKey} · ${logic}` : ''}`,
                    meta: record.status,
                    isDeactivateDisabled: record.isDeactivateDisabled
                });
            });

        (this.configSection('hooks')?.records || [])
            .filter((record) => this.configFieldValue(record, 'Question Key') === questionKey)
            .forEach((record) => {
                const eventName = this.configFieldValue(record, 'Event');
                const flowApiName = this.configFieldValue(record, 'Flow API Name');
                records.push({
                    key: `hook-${record.configKey}`,
                    configType: 'HOOK',
                    configKey: record.configKey,
                    record,
                    questionKey,
                    typeLabel: 'Flow Hook',
                    typeClass: 'configured-rule__type configured-rule__type_hook',
                    title: this.optionLabel(this.hookEventOptions, eventName),
                    detail: flowApiName ? `Runs ${flowApiName}` : 'Flow API name is not configured.',
                    meta: record.status,
                    isDeactivateDisabled: record.isDeactivateDisabled
                });
            });
        return records;
    }

    defaultQuestionConfigDraft(questionKey, configType = 'VALIDATION_RULE') {
        const resolvedQuestionKey = this.normalizeDraftKey(questionKey);
        return {
            ...this.configDraft,
            templateKey: this.selectedTemplateKey,
            configType,
            configKey: this.suggestConfigKey(configType, resolvedQuestionKey),
            label: '',
            questionKey: resolvedQuestionKey,
            isActive: true,
            validationType: 'MAX_LENGTH',
            regex: '',
            minLength: '',
            maxLength: '',
            minValue: '',
            maxValue: '',
            minDate: '',
            maxDate: '',
            errorMessage: '',
            sourceQuestionKey: resolvedQuestionKey,
            targetQuestionKey: resolvedQuestionKey,
            action: configType === 'CONDITION' ? 'BLOCK_WHEN' : 'SHOW_WHEN',
            operator: 'EQUALS',
            compareValue: '',
            conditionGroupKey: configType === 'CONDITION' && resolvedQuestionKey ? `${resolvedQuestionKey}_rules` : '',
            conditionLogic: 'ALL',
            conditionNumber: '',
            customLogic: '',
            userMessage: '',
            eventName: 'AFTER_ANSWER',
            handlerType: 'FLOW',
            flowApiName: '',
            outputMode: 'BASIC_OUTPUT_MAPPING',
            flowInputMappings: '',
            flowOutputMappings: '',
            successOutputVariable: 'success',
            userMessageOutputVariable: 'userMessage',
            nextQuestionOutputVariable: 'nextQuestionKey',
            answersJsonOutputVariable: 'updatedAnswersJson',
            blockContinueOutputVariable: 'blockContinue',
            sortOrder: 10
        };
    }

    configDraftFromQuestionConfig(item) {
        const record = item.record;
        const draft = this.defaultQuestionConfigDraft(item.questionKey, item.configType);
        const baseDraft = {
            ...draft,
            configKey: item.configKey,
            label: item.configKey,
            isActive: record.status === 'Active'
        };
        if (item.configType === 'VALIDATION_RULE') {
            return {
                ...baseDraft,
                questionKey: this.configFieldValue(record, 'Question Key'),
                validationType: this.configFieldValue(record, 'Validation Type') || 'MAX_LENGTH',
                regex: this.configFieldValue(record, 'Regex'),
                minLength: this.configFieldValue(record, 'Min Length'),
                maxLength: this.configFieldValue(record, 'Max Length'),
                minValue: this.configFieldValue(record, 'Min Value'),
                maxValue: this.configFieldValue(record, 'Max Value'),
                minDate: this.configFieldValue(record, 'Min Date'),
                maxDate: this.configFieldValue(record, 'Max Date'),
                errorMessage: this.configFieldValue(record, 'Error Message')
            };
        }
        if (item.configType === 'CONDITION') {
            return {
                ...baseDraft,
                questionKey: item.questionKey,
                sourceQuestionKey: this.configFieldValue(record, 'Source Question'),
                targetQuestionKey: this.configFieldValue(record, 'Target Question'),
                action: this.configFieldValue(record, 'Action') || 'SHOW_WHEN',
                operator: this.configFieldValue(record, 'Operator') || 'EQUALS',
                compareValue: this.configFieldValue(record, 'Compare Value'),
                conditionGroupKey: this.configFieldValue(record, 'Condition Group'),
                conditionLogic: this.configFieldValue(record, 'Condition Logic') || 'ALL',
                conditionNumber: this.configFieldValue(record, 'Condition Number'),
                customLogic: this.configFieldValue(record, 'Custom Logic'),
                userMessage: this.configFieldValue(record, 'User Message'),
                sortOrder: this.configFieldValue(record, 'Sort Order')
            };
        }
        return {
            ...baseDraft,
            questionKey: this.configFieldValue(record, 'Question Key'),
            eventName: this.configFieldValue(record, 'Event') || 'AFTER_ANSWER',
            handlerType: this.configFieldValue(record, 'Handler Type') || 'FLOW',
            flowApiName: this.configFieldValue(record, 'Flow API Name'),
            outputMode: this.configFieldValue(record, 'Output Mode') ||
                (this.configFieldValue(record, 'Flow Output Mappings') ? 'BASIC_OUTPUT_MAPPING' : 'ADVANCED_JSON_OVERRIDE'),
            flowInputMappings: this.configFieldValue(record, 'Flow Input Mappings'),
            flowOutputMappings: this.configFieldValue(record, 'Flow Output Mappings'),
            successOutputVariable: this.configFieldValue(record, 'Success Output Variable') || 'success',
            userMessageOutputVariable: this.configFieldValue(record, 'User Message Output Variable') || 'userMessage',
            nextQuestionOutputVariable: this.configFieldValue(record, 'Next Question Output Variable') || 'nextQuestionKey',
            answersJsonOutputVariable: this.configFieldValue(record, 'Answers JSON Output Variable') || 'updatedAnswersJson',
            blockContinueOutputVariable: this.configFieldValue(record, 'Block Continue Output Variable') || 'blockContinue',
            sortOrder: this.configFieldValue(record, 'Sort Order')
        };
    }

    optionLabel(options, value) {
        const option = (options || []).find((item) => item.value === value);
        return option?.label || value || '-';
    }

    toBoolean(value) {
        if (typeof value === 'boolean') {
            return value;
        }
        return String(value || '').toLowerCase() === 'true';
    }

    decorateControls(controls) {
        return (controls || []).map((control) => ({
            ...control,
            key: control.inputType,
            lightningLabel: control.lightningType
                ? `${control.lightningComponent} (${control.lightningType})`
                : control.lightningComponent,
            requiresOptionsLabel: control.requiresOptions ? 'Yes' : 'No',
            supportsMultipleLabel: control.supportsMultiple ? 'Yes' : 'No',
            requiresFileConfigLabel: control.requiresFileConfig ? 'Yes' : 'No'
        }));
    }

    decorateMetadataChoices(choices) {
        return (choices || []).map((choice) => ({
            ...choice,
            label: choice.label,
            value: choice.value
        }));
    }

    decorateReadiness(readiness) {
        return {
            ...readiness,
            items: (readiness?.items || []).map((item) => ({
                ...item,
                key: item.key || item.label,
                className: `readiness-item readiness-item_${(item.status || 'READY').toLowerCase()}`
            }))
        };
    }

    builderPlanStatusClass(plan, deploymentStatus) {
        if (deploymentStatus) {
            if (deploymentStatus.isComplete && deploymentStatus.isSuccess) {
                return 'builder-plan__status builder-plan__status_ready';
            }
            if (deploymentStatus.isComplete && !deploymentStatus.isSuccess) {
                return 'builder-plan__status builder-plan__status_error';
            }
            return 'builder-plan__status builder-plan__status_working';
        }
        return plan?.isValid ? 'builder-plan__status builder-plan__status_ready' : 'builder-plan__status builder-plan__status_error';
    }

    builderPlanStatusLabel(plan, deploymentStatus) {
        if (deploymentStatus) {
            return deploymentStatus.statusLabel;
        }
        return plan?.isValid ? 'Ready To Review' : 'Needs Changes';
    }

    decorateBuilderPlan(plan) {
        const deploymentStatus = this.decorateDeploymentStatus(plan?.deploymentStatus);
        return {
            ...plan,
            deploymentStatus,
            hasDeploymentStatus: Boolean(deploymentStatus),
            metadataWriteStatus: deploymentStatus?.metadataWriteStatus || plan?.metadataWriteStatus,
            metadataWriteNotice: deploymentStatus?.notice || plan?.metadataWriteNotice,
            statusClass: this.builderPlanStatusClass(plan, deploymentStatus),
            statusLabel: this.builderPlanStatusLabel(plan, deploymentStatus),
            issues: (plan?.issues || []).map((issue, index) => ({
                ...issue,
                key: `${issue.code}-${issue.componentKey}-${index}`,
                className: `issue issue_${(issue.severity || 'INFO').toLowerCase()}`
            })),
            records: (plan?.records || []).map((record, recordIndex) => {
                const recordKey = `${record.metadataType}-${record.fullName || recordIndex}`;
                return {
                    ...record,
                    key: recordKey,
                    fields: (record.fields || []).map((field, fieldIndex) => ({
                        ...field,
                        key: `${recordKey}-${field.label || fieldIndex}`,
                        value: field.value || '-'
                    }))
                };
            })
        };
    }

    createDefaultSetupDraft() {
        return {
            isActive: true,
            requiresConsent: true,
            requiresFinalConfirmation: true,
            createBranding: false,
            avatarIconName: 'standard:service_appointment',
            consentMessage: 'I agree that this intake can be saved and reviewed by the assigned team.',
            completionMessage: 'Thanks. Your intake has been saved.',
            welcomeMessage: 'Welcome. I will guide this intake one question at a time.'
        };
    }

    get setupPayload() {
        return {
            ...this.setupDraft
        };
    }

    get builderPayload() {
        const draft = { ...this.builderDraft };
        delete draft.questionType;
        delete draft.storedAnswerType;
        draft.inputType = this.effectiveBuilderInputType;
        draft.uiControl = this.isCustomRendererQuestion ? this.builderDraft.uiControl : '';
        draft.objectApiName = '';
        draft.fieldApiName = '';
        return {
            ...draft,
            templateKey: this.selectedTemplateKey,
            questionOrder: this.normalizeNumber(draft.questionOrder),
            maxFileCount: this.normalizeNumber(draft.maxFileCount)
        };
    }

    get configPayload() {
        const draft = this.configDraft.configType === 'VALIDATION_RULE'
            ? this.sanitizeValidationDraft(this.configDraft)
            : this.configDraft;
        return {
            ...draft,
            templateKey: draft.templateKey || this.selectedTemplateKey,
            maxRecords: this.normalizeNumber(draft.maxRecords),
            minLength: this.normalizeNumber(draft.minLength),
            maxLength: this.normalizeNumber(draft.maxLength),
            minValue: this.normalizeNumber(draft.minValue),
            maxValue: this.normalizeNumber(draft.maxValue),
            sortOrder: this.normalizeNumber(draft.sortOrder),
            conditionNumber: this.normalizeNumber(draft.conditionNumber),
            maxFileCount: this.normalizeNumber(draft.maxFileCount)
        };
    }

    sanitizeValidationDraft(draft) {
        const nextDraft = { ...draft };
        const validationType = nextDraft.validationType || 'MAX_LENGTH';
        if (validationType !== 'REGEX') {
            nextDraft.regex = '';
        }
        if (validationType !== 'MIN_LENGTH') {
            nextDraft.minLength = '';
        }
        if (validationType !== 'MAX_LENGTH') {
            nextDraft.maxLength = '';
        }
        if (validationType !== 'MIN_VALUE') {
            nextDraft.minValue = '';
        }
        if (validationType !== 'MAX_VALUE') {
            nextDraft.maxValue = '';
        }
        if (validationType !== 'MIN_DATE') {
            nextDraft.minDate = '';
        }
        if (validationType !== 'MAX_DATE') {
            nextDraft.maxDate = '';
        }
        return nextDraft;
    }

    normalizeNumber(value) {
        if (value === undefined || value === null || value === '') {
            return null;
        }
        return Number(value);
    }

    suggestTemplateKey(value) {
        if (!value) {
            return '';
        }
        return value
            .trim()
            .toUpperCase()
            .replace(/[^A-Z0-9]+/g, '_')
            .replace(/^_+|_+$/g, '');
    }

    normalizeDraftKey(value) {
        return (value || '').trim();
    }

    suggestConfigKey(configType, questionKey) {
        const suffixByType = {
            VALIDATION_RULE: 'validation',
            CONDITION: 'condition',
            HOOK: 'hook',
            FIELD_BINDING: 'binding',
            HANDOFF: 'handoff',
            MESSAGE: 'message',
            MATCHING_RULE: 'match',
            CONTEXT_CONFIG: 'context'
        };
        const base = this.normalizeDraftKey(questionKey) || this.normalizeDraftKey(this.selectedTemplateKey) || 'smartintake';
        const suffix = suffixByType[configType] || 'config';
        return `${base}_${suffix}`
            .replace(/[^A-Za-z0-9_]+/g, '_')
            .replace(/^_+|_+$/g, '');
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        return error?.body?.message || error?.message || 'Unexpected SmartIntake admin error.';
    }
}