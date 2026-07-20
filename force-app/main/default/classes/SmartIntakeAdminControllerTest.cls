@IsTest
private class SmartIntakeAdminControllerTest {
    @IsTest
    static void listTemplatesReturnsConfiguredTemplate() {
        List<SmartIntakeAdminController.TemplateSummary> templates = SmartIntakeAdminController.listTemplates();

        System.assert(!templates.isEmpty(), 'Expected at least one SmartIntake template.');
        Boolean foundHotelTemplate = false;
        for (SmartIntakeAdminController.TemplateSummary template : templates) {
            if (template.templateKey == SmartIntakeTestDataFactory.TEMPLATE_KEY) {
                foundHotelTemplate = true;
                System.assertEquals(true, template.isActive);
            }
        }
        System.assertEquals(true, foundHotelTemplate, 'Expected the packaged hotel template.');
    }

    @IsTest
    static void listSupportedControlsReturnsRuntimeCatalog() {
        List<SmartIntakeAdminController.ControlDefinition> controls =
            SmartIntakeAdminController.listSupportedControls();

        System.assertEquals(16, controls.size());

        Map<String, SmartIntakeAdminController.ControlDefinition> controlsByInputType =
            new Map<String, SmartIntakeAdminController.ControlDefinition>();
        for (SmartIntakeAdminController.ControlDefinition control : controls) {
            controlsByInputType.put(control.inputType, control);
        }

        System.assertEquals('lightning-input', controlsByInputType.get('DATE').lightningComponent);
        System.assertEquals('date', controlsByInputType.get('DATE').lightningType);
        System.assertEquals(true, controlsByInputType.get('PICKLIST').requiresOptions);
        System.assertEquals('lightning-checkbox-group', controlsByInputType.get('MULTI_SELECT').lightningComponent);
        System.assertEquals(true, controlsByInputType.get('FILE').requiresFileConfig);
        System.assertEquals('Salesforce Files only', controlsByInputType.get('PDF').supportedFieldTypes);
    }

    @IsTest
    static void getTemplateReadinessReturnsAdminChecklist() {
        SmartIntakeAdminController.ReadinessResult readiness =
            SmartIntakeAdminController.getTemplateReadiness(SmartIntakeTestDataFactory.TEMPLATE_KEY);

        System.assertEquals(SmartIntakeTestDataFactory.TEMPLATE_KEY, readiness.templateKey);
        System.assert(!String.isBlank(readiness.overallStatus), JSON.serialize(readiness));
        System.assert(readiness.items.size() >= 7, JSON.serialize(readiness.items));

        Set<String> itemKeys = new Set<String>();
        for (SmartIntakeAdminController.ReadinessItem item : readiness.items) {
            itemKeys.add(item.key);
            System.assert(!String.isBlank(item.label));
            System.assert(!String.isBlank(item.status));
            System.assert(!String.isBlank(item.message));
        }
        System.assert(itemKeys.contains('metadata'), JSON.serialize(readiness.items));
        System.assert(itemKeys.contains('submissionObject'), JSON.serialize(readiness.items));
        System.assert(itemKeys.contains('files'), JSON.serialize(readiness.items));
        System.assert(itemKeys.contains('handoff'), JSON.serialize(readiness.items));
        System.assert(itemKeys.contains('agentforce'), JSON.serialize(readiness.items));

        SmartIntakeAdminController.ReadinessResult missing =
            SmartIntakeAdminController.getTemplateReadiness(null);
        System.assertEquals('BLOCKED', missing.overallStatus);
        System.assertEquals(1, missing.blockingCount);
    }

    @IsTest
    static void previewQuestionDraftReturnsMetadataPlan() {
        SmartIntakeAdminController.BuilderQuestionDraft draft = new SmartIntakeAdminController.BuilderQuestionDraft();
        draft.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        draft.questionKey = 'meal_preference';
        draft.questionText = 'Do you have a meal preference?';
        draft.inputType = 'PICKLIST';
        draft.isRequired = true;
        draft.objectApiName = 'SmartIntake_Submission__c';
        draft.fieldApiName = 'Secondary_Text__c';
        draft.optionLines = 'Vegetarian=vegetarian\nVegan=vegan\nNo preference=no_preference';

        SmartIntakeAdminController.BuilderPlan plan = SmartIntakeAdminController.previewQuestionDraft(draft);

        System.assertEquals(true, plan.isValid, JSON.serialize(plan.issues));
        System.assertEquals(0, plan.errorCount, JSON.serialize(plan.issues));
        System.assertEquals(5, plan.recordCount, JSON.serialize(plan.records));
        System.assertEquals('PLANNED_ONLY', plan.metadataWriteStatus);

        Set<String> metadataTypes = new Set<String>();
        for (SmartIntakeAdminController.BuilderRecord record : plan.records) {
            metadataTypes.add(record.metadataType);
            System.assert(!String.isBlank(record.fullName));
            System.assert(!record.fields.isEmpty());
        }
        System.assert(metadataTypes.contains('SmartIntake_Question__mdt'), JSON.serialize(plan.records));
        System.assert(metadataTypes.contains('SmartIntake_Option__mdt'), JSON.serialize(plan.records));
        System.assert(metadataTypes.contains('SmartIntake_Field_Binding__mdt'), JSON.serialize(plan.records));
    }

    @IsTest
    static void previewQuestionDraftReportsConfigurationIssues() {
        SmartIntakeAdminController.BuilderQuestionDraft draft = new SmartIntakeAdminController.BuilderQuestionDraft();
        draft.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        draft.questionKey = 'room_type';
        draft.questionText = 'Duplicate room type?';
        draft.inputType = 'PICKLIST';

        SmartIntakeAdminController.BuilderPlan plan = SmartIntakeAdminController.previewQuestionDraft(draft);

        System.assertEquals(false, plan.isValid);
        Set<String> issueCodes = new Set<String>();
        for (SmartIntakeAdminController.ValidationIssue issue : plan.issues) {
            issueCodes.add(issue.code);
        }
        System.assert(issueCodes.contains('BUILDER_QUESTION_KEY_WILL_UPDATE'), JSON.serialize(plan.issues));
        System.assert(issueCodes.contains('BUILDER_OPTIONS_REQUIRED'), JSON.serialize(plan.issues));

        SmartIntakeAdminController.BuilderPlan missing = SmartIntakeAdminController.previewQuestionDraft(null);
        System.assertEquals(false, missing.isValid);
        System.assertEquals('DRAFT_MISSING', missing.issues[0].code);
    }

    @IsTest
    static void previewQuestionDraftAcceptsDirectCustomLwcControl() {
        SmartIntakeAdminController.BuilderQuestionDraft draft = new SmartIntakeAdminController.BuilderQuestionDraft();
        draft.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        draft.questionKey = 'custom_control_check';
        draft.questionText = 'Custom control check';
        draft.inputType = 'TEXT';
        draft.uiControl = 'c/smartIntakeProductSelector';

        SmartIntakeAdminController.BuilderPlan plan = SmartIntakeAdminController.previewQuestionDraft(draft);

        System.assertEquals(true, plan.isValid, JSON.serialize(plan.issues));
        for (SmartIntakeAdminController.ValidationIssue issue : plan.issues) {
            System.assertNotEquals('BUILDER_CUSTOM_UI_CONTROL_NOT_REGISTERED', issue.code, JSON.serialize(plan.issues));
            System.assertNotEquals('BUILDER_CUSTOM_UI_CONTROL_INVALID_NAME', issue.code, JSON.serialize(plan.issues));
        }
    }

    @IsTest
    static void previewQuestionDraftAcceptsRegisteredControlAlias() {
        SmartIntakeAdminController.BuilderQuestionDraft draft = new SmartIntakeAdminController.BuilderQuestionDraft();
        draft.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        draft.questionKey = 'star_control_check';
        draft.questionText = 'Star control check';
        draft.inputType = 'NUMBER';
        draft.uiControl = 'STAR_RATING';

        SmartIntakeAdminController.BuilderPlan plan = SmartIntakeAdminController.previewQuestionDraft(draft);

        System.assertEquals(true, plan.isValid, JSON.serialize(plan.issues));
        for (SmartIntakeAdminController.ValidationIssue issue : plan.issues) {
            System.assertNotEquals('BUILDER_CUSTOM_UI_CONTROL_NOT_REGISTERED', issue.code, JSON.serialize(plan.issues));
            System.assertNotEquals('BUILDER_CUSTOM_UI_CONTROL_INVALID_NAME', issue.code, JSON.serialize(plan.issues));
        }
    }

    @IsTest
    static void previewCustomControlRegistryBuildsStaticImportPlan() {
        SmartIntakeAdminController.BuilderPlan plan = SmartIntakeAdminController.previewCustomControlRegistry();

        System.assertEquals(true, plan.isValid, JSON.serialize(plan.issues));
        System.assert(plan.generatedControlCount >= 3, JSON.serialize(plan));
        System.assert(plan.recordCount >= plan.generatedControlCount, JSON.serialize(plan.records));
        System.assert(!String.isBlank(plan.generatedSource), 'Expected generated registry source.');
        System.assert(plan.generatedSource.contains('import("c/eventPulseRating")'), plan.generatedSource);
        System.assert(plan.generatedSource.contains('"event_pulse"'), plan.generatedSource);
        System.assert(plan.generatedSource.contains('active SmartIntake questions'), plan.generatedSource);
        System.assertEquals('PLANNED_ONLY', plan.metadataWriteStatus);
    }

    @IsTest
    static void syncCustomControlRegistryRequiresConfirmationAndSyncs() {
        SmartIntakeAdminController.BuilderPlan unconfirmed =
            SmartIntakeAdminController.syncCustomControlRegistry(false);
        System.assertEquals(false, unconfirmed.isValid);
        System.assertEquals('CONFIRMATION_REQUIRED', unconfirmed.metadataWriteStatus);
        System.assertEquals('CONTROL_REGISTRY_SYNC_CONFIRMATION_REQUIRED', unconfirmed.issues[0].code);

        SmartIntakeAdminController.BuilderPlan synced =
            SmartIntakeAdminController.syncCustomControlRegistry(true);
        System.assertEquals(true, synced.isValid, JSON.serialize(synced.issues));
        System.assertEquals('SYNCED', synced.metadataWriteStatus);
        System.assertEquals('0Rd000000000000AAA', synced.registryResourceId);
    }

    @IsTest
    static void deployQuestionDraftQueuesMetadataDeployment() {
        SmartIntakeAdminController.BuilderQuestionDraft draft = new SmartIntakeAdminController.BuilderQuestionDraft();
        draft.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        draft.questionKey = 'late_checkout_note';
        draft.questionText = 'Do you need a late checkout?';
        draft.inputType = 'TEXT';
        draft.isRequired = false;
        draft.objectApiName = 'SmartIntake_Submission__c';
        draft.fieldApiName = 'Secondary_Text__c';

        SmartIntakeAdminController.BuilderPlan preview = SmartIntakeAdminController.previewQuestionDraft(draft);
        Metadata.DeployContainer container = SmartIntakeAdminController.buildDeployContainer(preview);
        System.assertEquals(preview.recordCount, container.getMetadata().size());
        Metadata.CustomMetadata questionMetadata = (Metadata.CustomMetadata) container.getMetadata()[0];
        System.assert(!String.isBlank(questionMetadata.fullName));
        System.assert(!String.isBlank(questionMetadata.label));
        System.assert(!questionMetadata.values.isEmpty());

        SmartIntakeAdminController.BuilderPlan deployed =
            SmartIntakeAdminController.deployQuestionDraft(draft, true);

        System.assertEquals(true, deployed.isValid, JSON.serialize(deployed.issues));
        System.assertEquals('QUEUED', deployed.metadataWriteStatus);
        System.assertEquals('0Af000000000000AAA', deployed.deploymentJobId);
        SmartIntakeAdminController.DeploymentStatus queuedStatus =
            SmartIntakeAdminController.getMetadataDeploymentStatus(deployed.deploymentJobId);
        System.assertEquals('Pending', queuedStatus.status);
        System.assertEquals(false, queuedStatus.done);
        System.assertEquals(preview.recordCount, queuedStatus.numberComponentsTotal);

        new SmartIntakeMetadataDeployCallback().handleResult(null, null);
    }

    @IsTest
    static void metadataDeployCallbackStoresFinalDeploymentStatus() {
        SmartIntakeAdminController.BuilderPlan plan = new SmartIntakeAdminController.BuilderPlan();
        plan.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        plan.recordCount = 1;
        SmartIntakeMetadataDeployCallback.recordQueued(
            '0Af000000000001AAA',
            plan,
            'Question Builder',
            'arrival_date'
        );

        Metadata.DeployResult result = new Metadata.DeployResult();
        result.id = '0Af000000000001AAA';
        result.status = Metadata.DeployStatus.Succeeded;
        result.done = true;
        result.success = true;
        result.numberComponentsDeployed = 1;
        result.numberComponentsTotal = 1;
        result.numberComponentErrors = 0;
        result.stateDetail = 'Deployment complete.';

        new SmartIntakeMetadataDeployCallback().handleResult(result, null);

        SmartIntakeAdminController.DeploymentStatus status =
            SmartIntakeAdminController.getMetadataDeploymentStatus(result.id);
        System.assertEquals('Succeeded', status.status);
        System.assertEquals(true, status.done);
        System.assertEquals(true, status.success);
        System.assertEquals(1, status.numberComponentsDeployed);
        System.assertEquals(1, status.numberComponentsTotal);
        System.assertEquals('Deployment complete.', status.stateDetail);
    }

    @IsTest
    static void deployQuestionDraftUsesDeploySafeMetadataLabel() {
        SmartIntakeAdminController.BuilderQuestionDraft draft = new SmartIntakeAdminController.BuilderQuestionDraft();
        draft.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        draft.questionKey = 'suite_preference';
        draft.questionText = 'Any suite preference we should pass to the booking team?';
        draft.helpText = 'This question appears only when the selected room type is Suite.';
        draft.placeholderText = 'High floor, quiet room, ocean view...';
        draft.inputType = 'LONG_TEXT';
        draft.uiControl = 'lightning-textarea';
        draft.isRequired = false;

        SmartIntakeAdminController.BuilderPlan preview = SmartIntakeAdminController.previewQuestionDraft(draft);
        Metadata.DeployContainer container = SmartIntakeAdminController.buildDeployContainer(preview);
        System.assertEquals(true, preview.isValid, JSON.serialize(preview.issues));
        System.assertEquals(1, container.getMetadata().size(), JSON.serialize(preview.records));

        Metadata.CustomMetadata questionMetadata = (Metadata.CustomMetadata) container.getMetadata()[0];
        System.assert(questionMetadata.label.length() <= 40, questionMetadata.label);
    }

    @IsTest
    static void deployQuestionDraftRequiresConfirmationAndPermission() {
        SmartIntakeAdminController.BuilderQuestionDraft draft = new SmartIntakeAdminController.BuilderQuestionDraft();
        draft.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        draft.questionKey = 'airport_pickup';
        draft.questionText = 'Do you need airport pickup?';
        draft.inputType = 'BOOLEAN';

        SmartIntakeAdminController.BuilderPlan unconfirmed =
            SmartIntakeAdminController.deployQuestionDraft(draft, false);
        System.assertEquals(false, unconfirmed.isValid);
        System.assertEquals('CONFIRMATION_REQUIRED', unconfirmed.metadataWriteStatus);
        System.assertEquals('METADATA_DEPLOY_CONFIRMATION_REQUIRED', unconfirmed.issues[0].code);

        SmartIntakeAdminController.forceMetadataPermissionDeniedForTests = true;
        SmartIntakeAdminController.BuilderPlan denied =
            SmartIntakeAdminController.deployQuestionDraft(draft, true);
        SmartIntakeAdminController.forceMetadataPermissionDeniedForTests = false;

        System.assertEquals(false, denied.isValid);
        System.assertEquals('PERMISSION_REQUIRED', denied.metadataWriteStatus);
        System.assertEquals('METADATA_DEPLOY_PERMISSION_REQUIRED', denied.issues[0].code);
    }

    @IsTest
    static void previewTemplateDraftReturnsStarterPlan() {
        SmartIntakeAdminController.TemplateDraft draft = new SmartIntakeAdminController.TemplateDraft();
        draft.templateKey = 'spa booking starter';
        draft.templateName = 'Spa Booking Starter';
        draft.startQuestionKey = 'guest_name';
        draft.isActive = true;
        draft.requiresConsent = true;
        draft.requiresFinalConfirmation = true;
        draft.consentMessage = 'I agree that this spa intake can be saved.';
        draft.completionMessage = 'Thanks. Your spa intake has been saved.';
        draft.createBranding = true;
        draft.agentDisplayName = 'Spa Concierge';
        draft.avatarIconName = 'standard:event';
        draft.welcomeMessage = 'Welcome to spa booking.';

        SmartIntakeAdminController.BuilderPlan plan = SmartIntakeAdminController.previewTemplateDraft(draft);

        System.assertEquals(true, plan.isValid, JSON.serialize(plan.issues));
        System.assertEquals('SPA_BOOKING_STARTER', plan.templateKey);
        System.assertEquals(2, plan.recordCount, JSON.serialize(plan.records));
        System.assertEquals('PLANNED_ONLY', plan.metadataWriteStatus);

        Set<String> metadataTypes = new Set<String>();
        for (SmartIntakeAdminController.BuilderRecord record : plan.records) {
            metadataTypes.add(record.metadataType);
            System.assert(!String.isBlank(record.fullName));
            System.assert(!String.isBlank(record.metadataLabel));
            System.assert(!record.fields.isEmpty());
        }
        System.assert(metadataTypes.contains('SmartIntake_Template__mdt'), JSON.serialize(plan.records));
        System.assert(metadataTypes.contains('SmartIntake_Branding_Config__mdt'), JSON.serialize(plan.records));

        Metadata.DeployContainer container = SmartIntakeAdminController.buildDeployContainer(plan);
        System.assertEquals(plan.recordCount, container.getMetadata().size());
    }

    @IsTest
    static void deployTemplateDraftQueuesAndValidatesSetupIssues() {
        SmartIntakeAdminController.TemplateDraft draft = new SmartIntakeAdminController.TemplateDraft();
        draft.templateKey = 'guest_feedback';
        draft.templateName = 'Guest Feedback';
        draft.requiresConsent = false;
        draft.requiresFinalConfirmation = true;
        draft.createBranding = false;

        SmartIntakeAdminController.BuilderPlan deployed =
            SmartIntakeAdminController.deployTemplateDraft(draft, true);
        System.assertEquals(true, deployed.isValid, JSON.serialize(deployed.issues));
        System.assertEquals('QUEUED', deployed.metadataWriteStatus);
        System.assertEquals('0Af000000000000AAA', deployed.deploymentJobId);

        SmartIntakeAdminController.TemplateDraft invalid = new SmartIntakeAdminController.TemplateDraft();
        invalid.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        invalid.templateName = 'Duplicate';
        invalid.requiresConsent = true;
        invalid.createBranding = true;

        SmartIntakeAdminController.BuilderPlan invalidPlan =
            SmartIntakeAdminController.previewTemplateDraft(invalid);
        System.assertEquals(false, invalidPlan.isValid);

        Set<String> issueCodes = new Set<String>();
        for (SmartIntakeAdminController.ValidationIssue issue : invalidPlan.issues) {
            issueCodes.add(issue.code);
        }
        System.assert(issueCodes.contains('SETUP_TEMPLATE_KEY_EXISTS'), JSON.serialize(invalidPlan.issues));
        System.assert(issueCodes.contains('SETUP_CONSENT_MESSAGE_REQUIRED'), JSON.serialize(invalidPlan.issues));
        System.assert(issueCodes.contains('SETUP_AGENT_NAME_REQUIRED'), JSON.serialize(invalidPlan.issues));
    }

    @IsTest
    static void previewAdminConfigDraftReturnsPlansForSupportedTypes() {
        List<SmartIntakeAdminController.AdminConfigDraft> drafts =
            new List<SmartIntakeAdminController.AdminConfigDraft>{
                brandingDraft(),
                messageDraft(),
                handoffDraft(),
                matchingDraft(),
                contextDraft(),
                validationDraft(),
                conditionDraft(),
                hookDraft(),
                fileDraft(),
                fieldBindingDraft()
            };

        Set<String> metadataTypes = new Set<String>();
        for (SmartIntakeAdminController.AdminConfigDraft draft : drafts) {
            SmartIntakeAdminController.BuilderPlan plan =
                SmartIntakeAdminController.previewAdminConfigDraft(draft);

            System.assertEquals(true, plan.isValid, JSON.serialize(plan.issues));
            System.assertEquals(1, plan.recordCount, JSON.serialize(plan.records));
            System.assertEquals(draft.configType, plan.configType);
            System.assertEquals(draft.configKey, plan.configKey);
            System.assert(plan.metadataWriteNotice.contains('updates that record'), plan.metadataWriteNotice);
            metadataTypes.add(plan.records[0].metadataType);

            Metadata.DeployContainer container = SmartIntakeAdminController.buildDeployContainer(plan);
            System.assertEquals(1, container.getMetadata().size(), JSON.serialize(plan.records));
        }

        System.assert(metadataTypes.contains('SmartIntake_Branding_Config__mdt'), JSON.serialize(metadataTypes));
        System.assert(metadataTypes.contains('SmartIntake_Message__mdt'), JSON.serialize(metadataTypes));
        System.assert(metadataTypes.contains('SmartIntake_Handoff_Config__mdt'), JSON.serialize(metadataTypes));
        System.assert(metadataTypes.contains('SmartIntake_Matching_Rule__mdt'), JSON.serialize(metadataTypes));
        System.assert(metadataTypes.contains('SmartIntake_Context_Config__mdt'), JSON.serialize(metadataTypes));
        System.assert(metadataTypes.contains('SmartIntake_Validation_Rule__mdt'), JSON.serialize(metadataTypes));
        System.assert(metadataTypes.contains('SmartIntake_Condition__mdt'), JSON.serialize(metadataTypes));
        System.assert(metadataTypes.contains('SmartIntake_Hook__mdt'), JSON.serialize(metadataTypes));
        System.assert(metadataTypes.contains('SmartIntake_File_Config__mdt'), JSON.serialize(metadataTypes));
        System.assert(metadataTypes.contains('SmartIntake_Field_Binding__mdt'), JSON.serialize(metadataTypes));
    }

    @IsTest
    static void previewFieldBindingAcceptsMappedFlowOutputKey() {
        SmartIntakeAdminController.AdminConfigDraft draft =
            baseAdminDraft('FIELD_BINDING', 'admin_builder_asset_binding');
        draft.templateKey = 'LAPTOP_WARRANTY_CLAIM';
        draft.questionKey = 'ASSET_ID';
        draft.objectApiName = 'Warranty_Claim__c';
        draft.fieldApiName = 'Asset__c';

        SmartIntakeAdminController.BuilderPlan plan =
            SmartIntakeAdminController.previewAdminConfigDraft(draft);

        System.assertEquals(true, plan.isValid, JSON.serialize(plan.issues));
        System.assertEquals(1, plan.recordCount, JSON.serialize(plan.records));
        System.assertEquals('SmartIntake_Field_Binding__mdt', plan.records[0].metadataType);
    }

    @IsTest
    static void previewFieldBindingEditKeepsExistingMetadataFullName() {
        SmartIntakeAdminController.AdminConfigDraft draft =
            baseAdminDraft('FIELD_BINDING', 'LAPTOP_WARRANTY_PRODUCT_ID');
        draft.templateKey = 'LAPTOP_WARRANTY_CLAIM';
        draft.questionKey = 'PRODUCT_ID';
        draft.objectApiName = 'Warranty_Claim__c';
        draft.fieldApiName = 'Product__c';

        SmartIntakeAdminController.BuilderPlan plan =
            SmartIntakeAdminController.previewAdminConfigDraft(draft);

        System.assertEquals(true, plan.isValid, JSON.serialize(plan.issues));
        System.assertEquals(1, plan.recordCount, JSON.serialize(plan.records));
        System.assertEquals(
            'SmartIntake_Field_Binding.LAPTOP_WARRANTY_PRODUCT_ID',
            plan.records[0].fullName,
            'Editing an existing binding must update its DeveloperName instead of creating a prefixed duplicate.'
        );
    }

    @IsTest
    static void deployAdminConfigDraftQueuesAndRequiresConfirmation() {
        SmartIntakeAdminController.AdminConfigDraft draft = messageDraft();

        SmartIntakeAdminController.BuilderPlan unconfirmed =
            SmartIntakeAdminController.deployAdminConfigDraft(draft, false);
        System.assertEquals(false, unconfirmed.isValid);
        System.assertEquals('CONFIRMATION_REQUIRED', unconfirmed.metadataWriteStatus);
        System.assertEquals('METADATA_DEPLOY_CONFIRMATION_REQUIRED', unconfirmed.issues[0].code);

        SmartIntakeAdminController.BuilderPlan deployed =
            SmartIntakeAdminController.deployAdminConfigDraft(draft, true);
        System.assertEquals(true, deployed.isValid, JSON.serialize(deployed.issues));
        System.assertEquals('QUEUED', deployed.metadataWriteStatus);
        System.assertEquals('0Af000000000000AAA', deployed.deploymentJobId);

        SmartIntakeAdminController.forceMetadataPermissionDeniedForTests = true;
        SmartIntakeAdminController.BuilderPlan denied =
            SmartIntakeAdminController.deployAdminConfigDraft(draft, true);
        SmartIntakeAdminController.forceMetadataPermissionDeniedForTests = false;

        System.assertEquals(false, denied.isValid);
        System.assertEquals('PERMISSION_REQUIRED', denied.metadataWriteStatus);
        System.assertEquals('METADATA_DEPLOY_PERMISSION_REQUIRED', denied.issues[0].code);
    }

    @IsTest
    static void deactivateMetadataRecordQueuesActiveFlagUpdate() {
        SmartIntake_Condition__mdt conditionRecord = [
            SELECT DeveloperName, Condition_Key__c
            FROM SmartIntake_Condition__mdt
            WHERE Template_Key__c = :SmartIntakeTestDataFactory.TEMPLATE_KEY
            LIMIT 1
        ];
        String fullName = 'SmartIntake_Condition.' + conditionRecord.DeveloperName;

        SmartIntakeAdminController.BuilderPlan confirmationPlan =
            SmartIntakeAdminController.deactivateMetadataRecord(
                'SmartIntake_Condition__mdt',
                fullName,
                conditionRecord.Condition_Key__c,
                false
            );
        System.assertEquals('CONFIRMATION_REQUIRED', confirmationPlan.metadataWriteStatus);

        SmartIntakeAdminController.BuilderPlan queuedPlan =
            SmartIntakeAdminController.deactivateMetadataRecord(
                'SmartIntake_Condition__mdt',
                fullName,
                conditionRecord.Condition_Key__c,
                true
            );
        System.assertEquals(true, queuedPlan.isValid, JSON.serialize(queuedPlan.issues));
        System.assertEquals(1, queuedPlan.recordCount, JSON.serialize(queuedPlan.records));
        System.assertEquals('QUEUED', queuedPlan.metadataWriteStatus);
        System.assertEquals(fullName, queuedPlan.records[0].fullName);

        Metadata.DeployContainer container = SmartIntakeAdminController.buildDeployContainer(queuedPlan);
        System.assertEquals(1, container.getMetadata().size(), JSON.serialize(queuedPlan.records));
    }

    @IsTest
    static void jsonDraftEntryPointsSupportLwcCalls() {
        SmartIntakeAdminController.BuilderQuestionDraft questionDraft = new SmartIntakeAdminController.BuilderQuestionDraft();
        questionDraft.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        questionDraft.questionKey = 'json_preview_question';
        questionDraft.questionText = 'JSON preview question?';
        questionDraft.inputType = 'TEXT';
        questionDraft.objectApiName = 'SmartIntake_Submission__c';
        questionDraft.fieldApiName = 'Primary_Text__c';

        SmartIntakeAdminController.BuilderPlan questionPlan =
            SmartIntakeAdminController.previewQuestionDraftJson(JSON.serialize(questionDraft));
        System.assertEquals(true, questionPlan.isValid, JSON.serialize(questionPlan.issues));
        System.assertEquals('json_preview_question', questionPlan.questionKey);

        SmartIntakeAdminController.BuilderPlan unconfirmedQuestionDeploy =
            SmartIntakeAdminController.deployQuestionDraftJson(JSON.serialize(questionDraft), false);
        System.assertEquals(false, unconfirmedQuestionDeploy.isValid);
        System.assertEquals('CONFIRMATION_REQUIRED', unconfirmedQuestionDeploy.metadataWriteStatus);

        SmartIntakeAdminController.TemplateDraft templateDraft = new SmartIntakeAdminController.TemplateDraft();
        templateDraft.templateKey = 'json_template';
        templateDraft.templateName = 'JSON Template';
        templateDraft.requiresConsent = false;
        templateDraft.requiresFinalConfirmation = true;
        templateDraft.createBranding = false;

        SmartIntakeAdminController.BuilderPlan templatePlan =
            SmartIntakeAdminController.previewTemplateDraftJson(JSON.serialize(templateDraft));
        System.assertEquals(true, templatePlan.isValid, JSON.serialize(templatePlan.issues));
        System.assertEquals('JSON_TEMPLATE', templatePlan.templateKey);

        SmartIntakeAdminController.BuilderPlan templateDeploy =
            SmartIntakeAdminController.deployTemplateDraftJson(JSON.serialize(templateDraft), true);
        System.assertEquals('QUEUED', templateDeploy.metadataWriteStatus);

        SmartIntakeAdminController.AdminConfigDraft adminDraft = brandingDraft();
        SmartIntakeAdminController.BuilderPlan adminPlan =
            SmartIntakeAdminController.previewAdminConfigDraftJson(JSON.serialize(adminDraft));
        System.assertEquals(true, adminPlan.isValid, JSON.serialize(adminPlan.issues));
        System.assertEquals(adminDraft.configKey, adminPlan.configKey);

        SmartIntakeAdminController.BuilderPlan adminDeploy =
            SmartIntakeAdminController.deployAdminConfigDraftJson(JSON.serialize(messageDraft()), true);
        System.assertEquals('QUEUED', adminDeploy.metadataWriteStatus);

        SmartIntakeAdminController.BuilderPlan missing =
            SmartIntakeAdminController.previewQuestionDraftJson(null);
        System.assertEquals(false, missing.isValid);
        System.assertEquals('DRAFT_MISSING', missing.issues[0].code);
    }

    @IsTest
    static void previewAdminConfigDraftReportsConfigurationIssues() {
        SmartIntakeAdminController.BuilderPlan missing =
            SmartIntakeAdminController.previewAdminConfigDraft(null);
        System.assertEquals(false, missing.isValid);
        System.assertEquals('ADMIN_CONFIG_DRAFT_MISSING', missing.issues[0].code);

        SmartIntakeAdminController.AdminConfigDraft unsupported = baseAdminDraft('NOT_REAL', 'bad_type');
        SmartIntakeAdminController.BuilderPlan unsupportedPlan =
            SmartIntakeAdminController.previewAdminConfigDraft(unsupported);
        System.assertEquals(false, unsupportedPlan.isValid);

        SmartIntakeAdminController.AdminConfigDraft globalBranding = brandingDraft();
        globalBranding.templateKey = 'GLOBAL';
        SmartIntakeAdminController.BuilderPlan globalPlan =
            SmartIntakeAdminController.previewAdminConfigDraft(globalBranding);
        System.assertEquals(false, globalPlan.isValid);

        SmartIntakeAdminController.AdminConfigDraft invalidValidation = validationDraft();
        invalidValidation.validationType = 'MIN_DATE';
        invalidValidation.minDate = 'bad-date';
        SmartIntakeAdminController.BuilderPlan invalidValidationPlan =
            SmartIntakeAdminController.previewAdminConfigDraft(invalidValidation);
        System.assertEquals(false, invalidValidationPlan.isValid);

        SmartIntakeAdminController.AdminConfigDraft invalidHook = hookDraft();
        invalidHook.flowApiName = null;
        SmartIntakeAdminController.BuilderPlan invalidHookPlan =
            SmartIntakeAdminController.previewAdminConfigDraft(invalidHook);
        System.assertEquals(false, invalidHookPlan.isValid);
        System.assertEquals('HOOK_FLOW_REQUIRED', invalidHookPlan.issues[0].code);
    }

    @IsTest
    static void validateTemplateReturnsValidResultForHotelTemplate() {
        SmartIntakeAdminController.ValidationResult result = SmartIntakeAdminController.validateTemplate(
            SmartIntakeTestDataFactory.TEMPLATE_KEY
        );

        System.assertEquals(SmartIntakeTestDataFactory.TEMPLATE_KEY, result.templateKey);
        System.assertNotEquals(null, result.isValid, JSON.serialize(result.issues));
        System.assertNotEquals(null, result.issues, 'Expected validation issues list to be initialized.');
        System.assert(result.questionCount >= 6, JSON.serialize(result.issues));
        System.assertEquals(1, result.brandingConfigCount);
        System.assert(result.bindingCount >= 4, JSON.serialize(result.issues));
        System.assert(result.optionCount >= 3, JSON.serialize(result.issues));
        System.assert(result.validationRuleCount >= 2, JSON.serialize(result.issues));
        System.assert(result.conditionCount >= 1, JSON.serialize(result.issues));
        System.assert(result.hookCount >= 0, JSON.serialize(result.issues));
        System.assert(result.matchingRuleCount >= 1, JSON.serialize(result.issues));
        System.assert(result.contextConfigCount >= 1, JSON.serialize(result.issues));
        System.assert(result.fileConfigCount >= 1, JSON.serialize(result.issues));
        System.assert(result.handoffConfigCount >= 1, JSON.serialize(result.issues));
        System.assert(result.errorCount >= 0, JSON.serialize(result.issues));
    }

    @IsTest
    static void getTemplateConfigurationReturnsTemplateGraph() {
        SmartIntakeAdminController.TemplateConfiguration config =
            SmartIntakeAdminController.getTemplateConfiguration(SmartIntakeTestDataFactory.TEMPLATE_KEY);

        System.assertEquals(SmartIntakeTestDataFactory.TEMPLATE_KEY, config.templateKey);
        System.assertEquals(13, config.sections.size(), JSON.serialize(config.sections));

        Map<String, SmartIntakeAdminController.ConfigSection> sectionsByKey =
            new Map<String, SmartIntakeAdminController.ConfigSection>();
        Integer countedRecords = 0;
        for (SmartIntakeAdminController.ConfigSection section : config.sections) {
            sectionsByKey.put(section.key, section);
            countedRecords += section.count;
        }
        System.assertEquals(countedRecords, config.totalRecordCount, JSON.serialize(config.sections));

        System.assertEquals(1, sectionsByKey.get('template').count);
        System.assertEquals(1, sectionsByKey.get('branding').count);
        System.assert(sectionsByKey.get('questions').count >= 6, JSON.serialize(sectionsByKey.get('questions')));
        System.assert(sectionsByKey.get('fieldBindings').count >= 4, JSON.serialize(sectionsByKey.get('fieldBindings')));
        System.assert(sectionsByKey.get('options').count >= 3, JSON.serialize(sectionsByKey.get('options')));
        System.assert(sectionsByKey.get('validationRules').count >= 2, JSON.serialize(sectionsByKey.get('validationRules')));
        System.assert(sectionsByKey.get('conditions').count >= 1, JSON.serialize(sectionsByKey.get('conditions')));
        System.assert(sectionsByKey.get('hooks').count >= 0, JSON.serialize(sectionsByKey.get('hooks')));
        System.assert(sectionsByKey.get('matchingRules').count >= 1, JSON.serialize(sectionsByKey.get('matchingRules')));
        System.assert(sectionsByKey.get('contextConfigs').count >= 1, JSON.serialize(sectionsByKey.get('contextConfigs')));
        System.assert(sectionsByKey.get('fileConfigs').count >= 1, JSON.serialize(sectionsByKey.get('fileConfigs')));
        System.assert(sectionsByKey.get('handoffConfigs').count >= 1, JSON.serialize(sectionsByKey.get('handoffConfigs')));
        System.assert(sectionsByKey.get('messages').count >= 3, JSON.serialize(sectionsByKey.get('messages')));

        SmartIntakeAdminController.ConfigRecord templateRecord = sectionsByKey.get('template').records[0];
        System.assertEquals('Active', templateRecord.status);
        System.assertEquals('SmartIntake_Template__mdt', templateRecord.metadataType);
        System.assert(!String.isBlank(templateRecord.metadataFullName));
        System.assertEquals(true, templateRecord.canDeactivate);
        System.assert(!templateRecord.fields.isEmpty(), 'Expected template fields for admin inspection.');
    }

    @IsTest
    static void validateTemplateHandlesMissingInput() {
        SmartIntakeAdminController.ValidationResult blankResult = SmartIntakeAdminController.validateTemplate(null);
        System.assertEquals(false, blankResult.isValid);
        System.assertEquals('MISSING_TEMPLATE_KEY', blankResult.issues[0].code);

        SmartIntakeAdminController.ValidationResult missingResult = SmartIntakeAdminController.validateTemplate('NOT_REAL');
        System.assertEquals(false, missingResult.isValid);
        System.assertEquals('TEMPLATE_NOT_FOUND', missingResult.issues[0].code);
    }

    @IsTest
    static void validateValidationRulesReportsAdminConfigurationIssues() {
        SmartIntakeAdminController.ValidationResult result = new SmartIntakeAdminController.ValidationResult();
        result.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        result.issues = new List<SmartIntakeAdminController.ValidationIssue>();

        List<SmartIntake_Question__mdt> questions = new List<SmartIntake_Question__mdt>{
            question('text_q', 'TEXT'),
            question('number_q', 'NUMBER'),
            question('date_q', 'DATE'),
            question('inactive_q', 'TEXT', false)
        };
        List<SmartIntake_Validation_Rule__mdt> rules = new List<SmartIntake_Validation_Rule__mdt>{
            validationRule(null, 'text_q', 'REGEX'),
            validationRule('dup_rule', 'text_q', 'REGEX'),
            validationRule('dup_rule', 'text_q', 'REGEX'),
            validationRule('missing_question', 'not_real', 'MIN_LENGTH'),
            validationRule('inactive_question', 'inactive_q', 'MIN_LENGTH'),
            validationRule('unsupported', 'text_q', 'NOT_REAL'),
            validationRule('regex_missing', 'text_q', 'REGEX'),
            validationRule('regex_invalid', 'text_q', 'REGEX', '[', null, null, null, null, null, null),
            validationRule('length_wrong_input', 'date_q', 'MIN_LENGTH', null, 2, null, null, null, null, null),
            validationRule('length_missing', 'text_q', 'MIN_LENGTH'),
            validationRule('length_negative', 'text_q', 'MIN_LENGTH', null, -1, null, null, null, null, null),
            validationRule('length_range_min', 'text_q', 'MIN_LENGTH', null, 10, null, null, null, null, null),
            validationRule('length_range_max', 'text_q', 'MAX_LENGTH', null, null, 5, null, null, null, null),
            validationRule('number_wrong_input', 'text_q', 'MIN_VALUE', null, null, null, 1, null, null, null),
            validationRule('number_missing', 'number_q', 'MIN_VALUE'),
            validationRule('number_range_min', 'number_q', 'MIN_VALUE', null, null, null, 10, null, null, null),
            validationRule('number_range_max', 'number_q', 'MAX_VALUE', null, null, null, null, 5, null, null),
            validationRule('date_wrong_input', 'text_q', 'MIN_DATE', null, null, null, null, null, Date.newInstance(2026, 1, 1), null),
            validationRule('date_today_or_future', 'date_q', 'MIN_TODAY'),
            validationRule('date_missing', 'date_q', 'MIN_DATE'),
            validationRule('date_range_min', 'date_q', 'MIN_DATE', null, null, null, null, null, Date.newInstance(2026, 2, 1), null),
            validationRule('date_range_max', 'date_q', 'MAX_DATE', null, null, null, null, null, null, Date.newInstance(2026, 1, 1))
        };

        SmartIntakeAdminController.validateValidationRules(result, questions, rules);

        Set<String> issueCodes = new Set<String>();
        for (SmartIntakeAdminController.ValidationIssue issue : result.issues) {
            issueCodes.add(issue.code);
        }
        System.assertEquals(22, result.validationRuleCount);
        System.assert(issueCodes.contains('VALIDATION_RULE_KEY_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('DUPLICATE_VALIDATION_RULE_KEY'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_RULE_WITHOUT_ACTIVE_QUESTION'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('UNSUPPORTED_VALIDATION_TYPE'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_REGEX_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_REGEX_INVALID'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_TYPE_INCOMPATIBLE_WITH_INPUT'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_MIN_LENGTH_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_MIN_LENGTH_NEGATIVE'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_LENGTH_RANGE_INVALID'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_MIN_VALUE_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_VALUE_RANGE_INVALID'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_MIN_DATE_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('VALIDATION_DATE_RANGE_INVALID'), JSON.serialize(result.issues));
    }

    @IsTest
    static void validateConditionsReportsAdminConfigurationIssues() {
        SmartIntakeAdminController.ValidationResult result = new SmartIntakeAdminController.ValidationResult();
        result.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        result.issues = new List<SmartIntakeAdminController.ValidationIssue>();

        List<SmartIntake_Question__mdt> questions = new List<SmartIntake_Question__mdt>{
            question('source_q', 'TEXT'),
            question('target_q', 'TEXT'),
            question('inactive_q', 'TEXT', false)
        };
        List<SmartIntake_Condition__mdt> conditions = new List<SmartIntake_Condition__mdt>{
            condition(null, 'source_q', 'target_q', 'SHOW_WHEN', 'EQUALS', 'x'),
            condition('dup_condition', 'source_q', 'target_q', 'SHOW_WHEN', 'EQUALS', 'x'),
            condition('dup_condition', 'source_q', 'target_q', 'SHOW_WHEN', 'EQUALS', 'x'),
            condition('missing_source', 'not_real', 'target_q', 'SHOW_WHEN', 'EQUALS', 'x'),
            condition('missing_target', 'source_q', 'not_real', 'SHOW_WHEN', 'EQUALS', 'x'),
            condition('inactive_source', 'inactive_q', 'target_q', 'SHOW_WHEN', 'EQUALS', 'x'),
            condition('self_reference', 'source_q', 'source_q', 'SHOW_WHEN', 'EQUALS', 'x'),
            condition('bad_action', 'source_q', 'target_q', 'NOT_REAL', 'EQUALS', 'x'),
            condition('bad_operator', 'source_q', 'target_q', 'SHOW_WHEN', 'NOT_REAL', 'x'),
            condition('missing_compare', 'source_q', 'target_q', 'SHOW_WHEN', 'EQUALS', null),
            condition('blank_operator_no_compare', 'source_q', 'target_q', 'HIDE_WHEN', 'IS_BLANK', null)
        };

        SmartIntakeAdminController.validateConditions(result, questions, conditions, new Set<String>());

        Set<String> issueCodes = new Set<String>();
        for (SmartIntakeAdminController.ValidationIssue issue : result.issues) {
            issueCodes.add(issue.code);
        }
        System.assertEquals(11, result.conditionCount);
        System.assert(issueCodes.contains('CONDITION_KEY_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('DUPLICATE_CONDITION_KEY'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('CONDITION_SOURCE_KEY_NOT_FOUND'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('CONDITION_TARGET_QUESTION_NOT_FOUND'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('CONDITION_SELF_REFERENCE'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('UNSUPPORTED_CONDITION_ACTION'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('UNSUPPORTED_CONDITION_OPERATOR'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('CONDITION_COMPARE_VALUE_REQUIRED'), JSON.serialize(result.issues));
    }

    @IsTest
    static void validateFileConfigsReportsAdminConfigurationIssues() {
        SmartIntakeAdminController.ValidationResult result = new SmartIntakeAdminController.ValidationResult();
        result.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        result.issues = new List<SmartIntakeAdminController.ValidationIssue>();

        List<SmartIntake_Question__mdt> questions = new List<SmartIntake_Question__mdt>{
            question('file_q', 'FILE'),
            question('text_q', 'TEXT'),
            question('image_q', 'IMAGE'),
            question('inactive_file_q', 'FILE', false)
        };
        List<SmartIntake_File_Config__mdt> fileConfigs = new List<SmartIntake_File_Config__mdt>{
            fileConfig(null, 'file_q', '.pdf', true, 2, 'V', 'AllUsers'),
            fileConfig('dup_file', 'file_q', '.pdf', true, 2, 'V', 'AllUsers'),
            fileConfig('dup_file', 'image_q', '.png', false, 1, 'V', 'AllUsers'),
            fileConfig('missing_question', 'not_real', '.pdf', true, 2, 'V', 'AllUsers'),
            fileConfig('inactive_question', 'inactive_file_q', '.pdf', true, 2, 'V', 'AllUsers'),
            fileConfig('non_file_question', 'text_q', '.pdf', true, 2, 'V', 'AllUsers'),
            fileConfig('bad_accept', 'image_q', 'bad accept', true, 2, 'V', 'AllUsers'),
            fileConfig('bad_count', 'image_q', '.png', true, 30, 'V', 'AllUsers'),
            fileConfig('single_with_many', 'image_q', '.png', false, 2, 'V', 'AllUsers'),
            fileConfig('bad_share', 'image_q', '.png', true, 2, 'BAD', 'AllUsers'),
            fileConfig('bad_visibility', 'image_q', '.png', true, 2, 'V', 'Nobody')
        };

        SmartIntakeAdminController.validateFileConfigs(result, questions, fileConfigs);

        Set<String> issueCodes = new Set<String>();
        for (SmartIntakeAdminController.ValidationIssue issue : result.issues) {
            issueCodes.add(issue.code);
        }
        System.assertEquals(11, result.fileConfigCount);
        System.assert(issueCodes.contains('FILE_CONFIG_KEY_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('DUPLICATE_FILE_CONFIG_KEY'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('DUPLICATE_FILE_CONFIG_QUESTION'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('FILE_CONFIG_WITHOUT_ACTIVE_QUESTION'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('FILE_CONFIG_FOR_NON_FILE_QUESTION'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('FILE_ACCEPT_TYPE_INVALID'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('FILE_MAX_COUNT_OUT_OF_RANGE'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('FILE_MAX_COUNT_IGNORED_FOR_SINGLE_UPLOAD'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('UNSUPPORTED_FILE_SHARE_TYPE'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('UNSUPPORTED_FILE_VISIBILITY'), JSON.serialize(result.issues));
    }

    @IsTest
    static void validateHandoffConfigsReportsAdminConfigurationIssues() {
        SmartIntakeAdminController.ValidationResult result = new SmartIntakeAdminController.ValidationResult();
        result.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        result.issues = new List<SmartIntakeAdminController.ValidationIssue>();

        List<SmartIntake_Handoff_Config__mdt> handoffConfigs = new List<SmartIntake_Handoff_Config__mdt>{
            handoffConfig(null, 'ENHANCED_OMNI', 'CONFIGURED', true, null, null, null, null, null, true, null),
            handoffConfig('dup_handoff', 'ENHANCED_CHAT_V2', 'BAD_MODE', true, null, null, null, null, null, true, null),
            handoffConfig('dup_handoff', 'EXTERNAL_URL', 'CONFIGURED', false, null, null, null, null, null, false, null),
            handoffConfig('bad_provider', 'NOT_REAL', 'CONFIGURED', false, null, null, null, null, null, false, null),
            handoffConfig('missing_provider', null, 'CONFIGURED', false, null, null, null, null, null, false, null)
        };

        SmartIntakeAdminController.validateHandoffConfigs(result, handoffConfigs);

        Set<String> issueCodes = new Set<String>();
        for (SmartIntakeAdminController.ValidationIssue issue : result.issues) {
            issueCodes.add(issue.code);
        }
        System.assertEquals(5, result.handoffConfigCount);
        System.assert(issueCodes.contains('HANDOFF_CONFIG_KEY_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('DUPLICATE_HANDOFF_CONFIG_KEY'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('MULTIPLE_ACTIVE_HANDOFF_CONFIGS'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('UNSUPPORTED_HANDOFF_PROVIDER'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('HANDOFF_PROVIDER_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('UNSUPPORTED_HANDOFF_AVAILABILITY_MODE'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('HANDOFF_CONSENT_MESSAGE_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('HANDOFF_QUEUE_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('HANDOFF_CHAT_DEPLOYMENT_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('HANDOFF_URL_MISSING'), JSON.serialize(result.issues));
        System.assert(issueCodes.contains('HANDOFF_CONTEXT_FIELDS_MISSING'), JSON.serialize(result.issues));
    }

    private static SmartIntakeAdminController.AdminConfigDraft baseAdminDraft(String configType, String configKey) {
        SmartIntakeAdminController.AdminConfigDraft draft = new SmartIntakeAdminController.AdminConfigDraft();
        draft.templateKey = SmartIntakeTestDataFactory.TEMPLATE_KEY;
        draft.configType = configType;
        draft.configKey = configKey;
        draft.label = configKey;
        draft.isActive = true;
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft brandingDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('BRANDING', 'admin_builder_branding');
        draft.agentDisplayName = 'Admin Builder Concierge';
        draft.avatarIconName = 'standard:event';
        draft.avatarImageUrl = 'https://example.com/avatar.png';
        draft.welcomeMessage = 'Welcome from the admin builder.';
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft messageDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('MESSAGE', 'admin_builder_message');
        draft.messageType = 'VALIDATION_ERROR';
        draft.messageText = 'Please review this intake answer.';
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft handoffDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('HANDOFF', 'admin_builder_handoff');
        draft.providerType = 'EXTERNAL_URL';
        draft.availabilityMode = 'CONFIGURED';
        draft.triggerMessage = 'I can connect you with a hotel specialist.';
        draft.availableMessage = 'A specialist is available now.';
        draft.offlineMessage = 'The team is offline right now.';
        draft.declinedMessage = 'No problem. We can continue here.';
        draft.requiresConsent = true;
        draft.consentMessage = 'I agree to share my intake context with the specialist.';
        draft.handoffUrl = 'https://example.com/support';
        draft.isContextSharingEnabled = true;
        draft.contextFieldsToShare = 'guest_name;room_type';
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft matchingDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('MATCHING_RULE', 'admin_builder_match');
        draft.questionKey = 'guest_name';
        draft.objectApiName = 'SmartIntake_Submission__c';
        draft.fieldApiName = 'Primary_Text__c';
        draft.displayFieldApiName = 'Primary_Text__c';
        draft.matchType = 'EXACT';
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft contextDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('CONTEXT_CONFIG', 'admin_builder_context');
        draft.questionKey = 'guest_name';
        draft.contextType = 'MATCHED_RECORDS';
        draft.contextMessage = 'We found matching intake records.';
        draft.objectApiName = 'SmartIntake_Submission__c';
        draft.filterFieldApiName = 'Primary_Text__c';
        draft.filterSourceQuestionKey = 'guest_name';
        draft.displayFieldApiName = 'Primary_Text__c';
        draft.allowedActions = 'select;update';
        draft.maxRecords = 3;
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft validationDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('VALIDATION_RULE', 'admin_builder_validation');
        draft.questionKey = 'guest_name';
        draft.validationType = 'MIN_LENGTH';
        draft.minLength = 2;
        draft.sortOrder = 10;
        draft.errorMessage = 'Enter at least two characters.';
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft conditionDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('CONDITION', 'admin_builder_condition');
        draft.sourceQuestionKey = 'room_type';
        draft.targetQuestionKey = 'suite_preference';
        draft.action = 'SHOW_WHEN';
        draft.operator = 'EQUALS';
        draft.compareValue = 'suite';
        draft.sortOrder = 10;
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft hookDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('HOOK', 'admin_builder_hook');
        draft.questionKey = 'room_type';
        draft.eventName = 'AFTER_ANSWER';
        draft.handlerType = 'FLOW';
        draft.flowApiName = 'Check_Room_Availability';
        draft.outputMode = 'BASIC_OUTPUT_MAPPING';
        draft.flowInputMappings = 'roomType <- answerValue';
        draft.flowOutputMappings = 'availabilityStatus -> ROOM_AVAILABILITY';
        draft.successOutputVariable = 'success';
        draft.userMessageOutputVariable = 'userMessage';
        draft.nextQuestionOutputVariable = 'nextQuestionKey';
        draft.answersJsonOutputVariable = 'updatedAnswersJson';
        draft.blockContinueOutputVariable = 'blockContinue';
        draft.sortOrder = 10;
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft fileDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('FILE_CONFIG', 'admin_builder_file');
        draft.questionKey = 'booking_attachment';
        draft.acceptedFileTypes = '.pdf,.png';
        draft.allowMultipleFiles = true;
        draft.maxFileCount = 2;
        draft.linkToFinalRecord = true;
        draft.shareType = 'V';
        draft.visibility = 'AllUsers';
        return draft;
    }

    private static SmartIntakeAdminController.AdminConfigDraft fieldBindingDraft() {
        SmartIntakeAdminController.AdminConfigDraft draft = baseAdminDraft('FIELD_BINDING', 'admin_builder_binding');
        draft.questionKey = 'booking_note';
        draft.objectApiName = 'SmartIntake_Submission__c';
        draft.fieldApiName = 'Secondary_Text__c';
        return draft;
    }

    private static SmartIntake_Question__mdt question(String questionKey, String inputType) {
        return question(questionKey, inputType, true);
    }

    private static SmartIntake_Question__mdt question(String questionKey, String inputType, Boolean isActive) {
        SmartIntake_Question__mdt question = new SmartIntake_Question__mdt();
        question.Question_Key__c = questionKey;
        question.Input_Type__c = inputType;
        question.Is_Active__c = isActive;
        return question;
    }

    private static SmartIntake_Validation_Rule__mdt validationRule(
        String ruleKey,
        String questionKey,
        String validationType
    ) {
        return validationRule(ruleKey, questionKey, validationType, null, null, null, null, null, null, null);
    }

    private static SmartIntake_Validation_Rule__mdt validationRule(
        String ruleKey,
        String questionKey,
        String validationType,
        String regex,
        Decimal minLength,
        Decimal maxLength,
        Decimal minValue,
        Decimal maxValue,
        Date minDate,
        Date maxDate
    ) {
        SmartIntake_Validation_Rule__mdt validationRule = new SmartIntake_Validation_Rule__mdt();
        validationRule.Validation_Rule_Key__c = ruleKey;
        validationRule.Question_Key__c = questionKey;
        validationRule.Validation_Type__c = validationType;
        validationRule.Regex__c = regex;
        validationRule.Min_Length__c = minLength;
        validationRule.Max_Length__c = maxLength;
        validationRule.Min_Value__c = minValue;
        validationRule.Max_Value__c = maxValue;
        validationRule.Min_Date__c = minDate;
        validationRule.Max_Date__c = maxDate;
        validationRule.Is_Active__c = true;
        return validationRule;
    }

    private static SmartIntake_Condition__mdt condition(
        String conditionKey,
        String sourceQuestionKey,
        String targetQuestionKey,
        String action,
        String operator,
        String compareValue
    ) {
        SmartIntake_Condition__mdt condition = new SmartIntake_Condition__mdt();
        condition.Condition_Key__c = conditionKey;
        condition.Source_Question_Key__c = sourceQuestionKey;
        condition.Target_Question_Key__c = targetQuestionKey;
        condition.Action__c = action;
        condition.Operator__c = operator;
        condition.Compare_Value__c = compareValue;
        condition.Is_Active__c = true;
        return condition;
    }

    private static SmartIntake_File_Config__mdt fileConfig(
        String fileConfigKey,
        String questionKey,
        String acceptedFileTypes,
        Boolean allowMultiple,
        Decimal maxFileCount,
        String shareType,
        String visibility
    ) {
        SmartIntake_File_Config__mdt fileConfig = new SmartIntake_File_Config__mdt();
        fileConfig.File_Config_Key__c = fileConfigKey;
        fileConfig.Question_Key__c = questionKey;
        fileConfig.Accepted_File_Types__c = acceptedFileTypes;
        fileConfig.Allow_Multiple__c = allowMultiple;
        fileConfig.Max_File_Count__c = maxFileCount;
        fileConfig.Share_Type__c = shareType;
        fileConfig.Visibility__c = visibility;
        fileConfig.Is_Active__c = true;
        return fileConfig;
    }

    private static SmartIntake_Handoff_Config__mdt handoffConfig(
        String handoffConfigKey,
        String providerType,
        String availabilityMode,
        Boolean requiresConsent,
        String consentMessage,
        String queueDeveloperName,
        String messagingChannelDeveloperName,
        String embeddedServiceDeploymentName,
        String handoffUrl,
        Boolean contextSharingEnabled,
        String contextFieldsToShare
    ) {
        SmartIntake_Handoff_Config__mdt handoffConfig = new SmartIntake_Handoff_Config__mdt();
        handoffConfig.Handoff_Config_Key__c = handoffConfigKey;
        handoffConfig.Provider_Type__c = providerType;
        handoffConfig.Availability_Mode__c = availabilityMode;
        handoffConfig.Requires_Consent__c = requiresConsent;
        handoffConfig.Consent_Message__c = consentMessage;
        handoffConfig.Queue_Developer_Name__c = queueDeveloperName;
        handoffConfig.Messaging_Channel_Developer_Name__c = messagingChannelDeveloperName;
        handoffConfig.Embedded_Service_Deployment_Name__c = embeddedServiceDeploymentName;
        handoffConfig.Handoff_URL__c = handoffUrl;
        handoffConfig.Is_Context_Sharing_Enabled__c = contextSharingEnabled;
        handoffConfig.Context_Fields_To_Share__c = contextFieldsToShare;
        handoffConfig.Is_Active__c = true;
        return handoffConfig;
    }
}