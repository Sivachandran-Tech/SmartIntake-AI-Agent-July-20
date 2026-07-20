import { LightningElement, api, track } from 'lwc';
import getNextQuestion from '@salesforce/apex/SmartIntakeRuntimeController.getNextQuestion';
import submitAnswer from '@salesforce/apex/SmartIntakeRuntimeController.submitAnswer';
import goBack from '@salesforce/apex/SmartIntakeRuntimeController.goBack';
import skipQuestion from '@salesforce/apex/SmartIntakeRuntimeController.skipQuestion';
import saveFinal from '@salesforce/apex/SmartIntakeRuntimeController.saveFinal';
import getExistingContext from '@salesforce/apex/SmartIntakeRuntimeController.getExistingContext';
import getHandoffPlan from '@salesforce/apex/SmartIntakeRuntimeController.getHandoffPlan';

export default class SmartIntakeRuntime extends LightningElement {
    @api templateKey = 'HOTEL_BOOKING_BASIC_V1';
    @api agentDisplayName = 'SmartIntake Agent';
    @api agentIconName = 'utility:einstein';

    @track question;
    @track progress;
    @track existingContext;

    avatarImageUrl;
    welcomeMessage;
    requiresConsent = false;
    consentMessage;
    requiresFinalConfirmation = true;
    consentAccepted = false;
    intakeSessionId;
    answersJson = '{}';
    answerValue = '';
    errorMessage;
    successMessage;
    handoffPlan;
    handoffPanelOpen = false;
    handoffBusy = false;
    handoffConsentAccepted = false;
    handoffDeclined = false;
    handoffErrorMessage;
    resumeRetryAttempted = false;
    isLoading = false;
    isComplete = false;

    connectedCallback() {
        this.intakeSessionId = this.storedSessionId;
        this.loadQuestion();
    }

    get hasQuestion() {
        return Boolean(this.question) && !this.isComplete;
    }

    get hasAvatarImage() {
        return Boolean(this.avatarImageUrl);
    }

    get hasWelcomeMessage() {
        return Boolean(this.welcomeMessage);
    }

    get hasExistingContext() {
        return Boolean(this.existingContext?.records?.length);
    }

    get existingContextRecords() {
        return this.existingContext?.records || [];
    }

    get hasHandoffAction() {
        return Boolean(this.handoffPlan?.handoffEnabled);
    }

    get showHandoffPanel() {
        return this.handoffPanelOpen && this.hasHandoffAction;
    }

    get handoffButtonDisabled() {
        return this.isLoading || this.handoffBusy;
    }

    get handoffMessage() {
        if (this.handoffDeclined) {
            return this.handoffPlan?.declinedMessage || 'No problem. I will continue helping here.';
        }
        return this.handoffPlan?.handoffMessage || this.handoffPlan?.triggerMessage;
    }

    get handoffRequiresConsent() {
        return this.handoffPlan?.availabilityStatus === 'CONSENT_REQUIRED';
    }

    get handoffIsReady() {
        return this.handoffPlan?.handoffReady === true;
    }

    get handoffIsUnavailable() {
        return Boolean(this.handoffPlan) &&
            !this.handoffRequiresConsent &&
            !this.handoffIsReady &&
            !this.handoffDeclined;
    }

    get showHandoffExternalUrl() {
        return this.handoffIsReady &&
            this.handoffPlan?.providerType === 'EXTERNAL_URL' &&
            Boolean(this.handoffPlan?.handoffUrl);
    }

    get showHandoffReadyActions() {
        return this.handoffIsReady && !this.showHandoffExternalUrl && !this.handoffDeclined;
    }

    get showHandoffConsentActions() {
        return this.handoffRequiresConsent && !this.handoffDeclined;
    }

    get showHandoffDeclineAction() {
        return !this.handoffDeclined && (this.handoffRequiresConsent || this.handoffIsReady);
    }

    get handoffReadinessWarnings() {
        const warnings = this.parseJson(this.handoffPlan?.readinessWarningsJson) || [];
        if (!Array.isArray(warnings)) {
            return [];
        }
        return warnings.map((warning, index) => ({
            key: `${index}-${warning}`,
            message: warning
        }));
    }

    get hasHandoffReadinessWarnings() {
        return this.handoffReadinessWarnings.length > 0;
    }

    get isTextarea() {
        return this.question?.inputType === 'LONG_TEXT' || this.question?.uiControl === 'lightning-textarea';
    }

    get isCombobox() {
        return this.question?.inputType === 'PICKLIST' || this.question?.uiControl === 'lightning-combobox';
    }

    get isRadioGroup() {
        return this.question?.inputType === 'RADIO' || this.question?.uiControl === 'lightning-radio-group';
    }

    get isCheckboxGroup() {
        return this.question?.inputType === 'MULTI_SELECT' || this.question?.uiControl === 'lightning-checkbox-group';
    }

    get isFileUpload() {
        return ['FILE', 'IMAGE', 'PDF'].includes(this.question?.inputType) || this.question?.uiControl === 'lightning-file-upload';
    }

    get isLightningInput() {
        return !this.isTextarea && !this.isCombobox && !this.isRadioGroup && !this.isCheckboxGroup && !this.isFileUpload;
    }

    get multiAnswerValue() {
        if (!this.answerValue) {
            return [];
        }
        return this.answerValue.split(';').filter((value) => value);
    }

    get booleanAnswerValue() {
        return this.answerValue === 'true';
    }

    get fileAcceptedFormats() {
        return this.question?.acceptedFormats || [];
    }

    get fileUploadMultiple() {
        return Boolean(this.question?.allowMultipleFiles);
    }

    get fileUploadLabel() {
        return this.question?.placeholderText || this.question?.questionText || 'Upload Files';
    }

    get uploadedFiles() {
        const files = this.parseJson(this.answerValue) || [];
        if (!Array.isArray(files)) {
            return [];
        }
        return files.map((file, index) => ({
            name: file.name || 'Uploaded file',
            documentId: file.documentId,
            contentVersionId: file.contentVersionId,
            key: file.documentId || file.contentVersionId || `${file.name || 'file'}-${index}`
        }));
    }

    get hasUploadedFiles() {
        return this.uploadedFiles.length > 0;
    }

    get lightningInputType() {
        const inputType = this.question?.inputType;
        if (inputType === 'EMAIL') {
            return 'email';
        }
        if (inputType === 'PHONE') {
            return 'tel';
        }
        if (inputType === 'NUMBER') {
            return 'number';
        }
        if (inputType === 'DATE') {
            return 'date';
        }
        if (inputType === 'DATETIME') {
            return 'datetime';
        }
        if (inputType === 'BOOLEAN') {
            return 'checkbox';
        }
        if (inputType === 'URL') {
            return 'url';
        }
        return 'text';
    }

    get currentStepValue() {
        return String(this.progress?.currentStep || 1);
    }

    get steps() {
        const total = this.progress?.totalSteps || 0;
        return Array.from({ length: total }, (_, index) => ({
            label: `Step ${index + 1}`,
            value: String(index + 1)
        }));
    }

    get reviewItems() {
        try {
            const answers = JSON.parse(this.answersJson || '{}');
            return Object.keys(answers).map((key) => ({
                key,
                value: this.reviewValue(answers[key])
            }));
        } catch (error) {
            return [];
        }
    }

    get displayConsentMessage() {
        return this.consentMessage || 'I agree that this intake can be saved.';
    }

    get saveDisabled() {
        return this.isLoading || (this.requiresConsent && !this.consentAccepted);
    }

    get canGoBack() {
        return this.hasQuestion && !this.isLoading && (this.progress?.currentStep || 1) > 1;
    }

    get backDisabled() {
        return !this.canGoBack;
    }

    get canSkip() {
        return this.hasQuestion && !this.isLoading && this.question?.required !== true;
    }

    get storageKey() {
        return `smartintake:${this.templateKey}:sessionId`;
    }

    get storedSessionId() {
        try {
            return window.sessionStorage.getItem(this.storageKey);
        } catch (error) {
            return null;
        }
    }

    async loadQuestion() {
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            const response = await getNextQuestion({
                intakeSessionId: this.intakeSessionId,
                templateKey: this.templateKey,
                currentQuestionKey: this.question?.questionKey,
                answersJson: this.answersJson
            });
            await this.applyResponse(response);
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleAnswerChange(event) {
        if (this.question?.inputType === 'BOOLEAN') {
            this.answerValue = String(event.target.checked);
            return;
        }
        this.answerValue = event.target.value;
    }

    handleMultiAnswerChange(event) {
        this.answerValue = (event.detail.value || []).join(';');
    }

    handleFileUploadFinished(event) {
        const uploadedFiles = (event.detail.files || []).map((file) => ({
            name: file.name,
            documentId: file.documentId || file.contentDocumentId,
            contentVersionId: file.contentVersionId || file.versionId
        }));
        const maxFileCount = this.question?.maxFileCount || 1;
        const nextFiles = this.fileUploadMultiple ? [...this.uploadedFiles, ...uploadedFiles] : uploadedFiles.slice(-1);

        if (nextFiles.length > maxFileCount) {
            this.answerValue = JSON.stringify(nextFiles.slice(0, maxFileCount).map((file) => this.fileAnswerPayload(file)));
            this.errorMessage = `Please upload no more than ${maxFileCount} file${maxFileCount === 1 ? '' : 's'}.`;
            return;
        }

        this.answerValue = JSON.stringify(nextFiles.map((file) => this.fileAnswerPayload(file)));
        this.errorMessage = undefined;
    }

    handleRemoveUploadedFile(event) {
        const key = event.detail?.name || event.target.name;
        this.answerValue = JSON.stringify(
            this.uploadedFiles
                .filter((file) => file.key !== key)
                .map((file) => this.fileAnswerPayload(file))
        );
    }

    handleConsentChange(event) {
        this.consentAccepted = event.detail.checked;
    }

    async handleHandoffStart() {
        this.handoffPanelOpen = true;
        this.handoffDeclined = false;
        await this.refreshHandoffPlan(this.handoffConsentAccepted, true);
    }

    async handleHandoffConsentAccepted() {
        this.handoffConsentAccepted = true;
        this.handoffDeclined = false;
        await this.refreshHandoffPlan(true, true);
    }

    handleHandoffDeclined() {
        this.handoffConsentAccepted = false;
        this.handoffDeclined = true;
        this.handoffErrorMessage = undefined;
    }

    async handleNext() {
        if (!this.question) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;
        this.successMessage = undefined;
        try {
            const response = await submitAnswer({
                intakeSessionId: this.intakeSessionId,
                templateKey: this.templateKey,
                questionKey: this.question.questionKey,
                answerValue: this.answerValue,
                answersJson: this.answersJson
            });
            await this.applyResponse(response);
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async handleBack() {
        if (!this.question) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;
        this.successMessage = undefined;
        try {
            const response = await goBack({
                intakeSessionId: this.intakeSessionId,
                templateKey: this.templateKey,
                questionKey: this.question.questionKey,
                answersJson: this.answersJson
            });
            await this.applyResponse(response);
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async handleSkip() {
        if (!this.question) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;
        this.successMessage = undefined;
        try {
            const response = await skipQuestion({
                intakeSessionId: this.intakeSessionId,
                templateKey: this.templateKey,
                questionKey: this.question.questionKey,
                answersJson: this.answersJson
            });
            await this.applyResponse(response);
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async handleSave() {
        this.isLoading = true;
        this.errorMessage = undefined;
        this.successMessage = undefined;
        try {
            const response = await saveFinal({
                intakeSessionId: this.intakeSessionId,
                templateKey: this.templateKey,
                answersJson: this.answersJson,
                confirmed: true,
                consentAccepted: this.consentAccepted
            });
            await this.applyResponse(response);
            if (response.success) {
                this.successMessage = response.userMessage || 'Your intake was saved.';
            }
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async applyResponse(response) {
        this.intakeSessionId = response?.intakeSessionId || this.intakeSessionId;
        this.storeSessionId(this.intakeSessionId);

        if (!response?.success) {
            if (['SESSION_NOT_FOUND', 'INVALID_SESSION_ID'].includes(response?.errorCode) && !this.resumeRetryAttempted) {
                this.resumeRetryAttempted = true;
                this.clearStoredSessionId();
                this.intakeSessionId = null;
                this.answersJson = '{}';
                await this.loadQuestion();
                return;
            }
            this.errorMessage = response?.userMessage || 'SmartIntake could not continue.';
            return;
        }

        this.resumeRetryAttempted = false;
        this.answersJson = response.answersJson || this.answersJson || '{}';
        this.applyBranding(response.branding || this.parseJson(response.brandingJson));
        this.requiresConsent = Boolean(response.requiresConsent);
        this.consentMessage = response.consentMessage;
        this.requiresFinalConfirmation = response.requiresFinalConfirmation !== false;
        this.progress = response.progress || this.parseJson(response.progressJson);
        this.question = response.question || this.parseJson(response.questionJson);
        this.isComplete = Boolean(response.isComplete);
        this.answerValue = this.question?.value || '';
        this.existingContext = undefined;
        this.errorMessage = undefined;
        this.successMessage = response.userMessage;
        if (this.hasQuestion) {
            await this.loadExistingContext();
        }
        await this.refreshHandoffPlan(this.handoffConsentAccepted, false);
    }

    storeSessionId(sessionId) {
        if (!sessionId) {
            return;
        }
        try {
            window.sessionStorage.setItem(this.storageKey, sessionId);
        } catch (error) {
            // Storage can be unavailable in some embedded contexts. The server response remains authoritative.
        }
    }

    clearStoredSessionId() {
        try {
            window.sessionStorage.removeItem(this.storageKey);
        } catch (error) {
            // Ignore storage failures; Apex will issue a new server-authoritative session id.
        }
    }

    async loadExistingContext() {
        try {
            const response = await getExistingContext({
                intakeSessionId: this.intakeSessionId,
                templateKey: this.templateKey,
                questionKey: this.question.questionKey,
                recordId: null,
                answersJson: this.answersJson
            });

            if (!response?.success) {
                this.errorMessage = response?.userMessage || 'SmartIntake could not load existing context.';
                return;
            }

            const records = response.contextRecords || this.parseJson(response.contextRecordsJson) || [];
            if (response.hasContext && records.length) {
                this.existingContext = {
                    ...response,
                    records: records.map((record) => ({
                        ...record,
                        allowedActionsLabel: (record.allowedActions || '').split(';').filter((action) => action).join(', ')
                    }))
                };
            }
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        }
    }

    async refreshHandoffPlan(consentAccepted, showErrors) {
        this.handoffBusy = true;
        this.handoffErrorMessage = undefined;
        try {
            const response = await getHandoffPlan({
                intakeSessionId: this.intakeSessionId,
                templateKey: this.templateKey,
                reason: 'User requested human handoff from SmartIntake runtime.',
                consentAccepted,
                contextSummaryJson: consentAccepted ? this.buildHandoffContextCandidateJson() : '{}'
            });

            if (!response?.success) {
                this.handoffPlan = undefined;
                if (showErrors) {
                    this.handoffErrorMessage = response?.userMessage || 'SmartIntake could not check handoff readiness.';
                }
                return;
            }

            this.handoffPlan = response;
            if (!response.handoffEnabled) {
                this.handoffPanelOpen = false;
            }
        } catch (error) {
            if (showErrors) {
                this.handoffErrorMessage = this.reduceError(error);
            }
        } finally {
            this.handoffBusy = false;
        }
    }

    buildHandoffContextCandidateJson() {
        const answers = this.parseJson(this.answersJson) || {};
        if (!answers || typeof answers !== 'object' || Array.isArray(answers)) {
            return '{}';
        }
        return JSON.stringify(answers);
    }

    applyBranding(branding) {
        if (!branding) {
            return;
        }
        this.agentDisplayName = branding.agentDisplayName || this.agentDisplayName;
        this.agentIconName = branding.avatarIconName || this.agentIconName;
        this.avatarImageUrl = branding.avatarImageUrl;
        this.welcomeMessage = branding.welcomeMessage;
    }

    parseJson(value) {
        if (!value) {
            return undefined;
        }
        try {
            return JSON.parse(value);
        } catch (error) {
            return undefined;
        }
    }

    fileAnswerPayload(file) {
        return {
            name: file.name,
            documentId: file.documentId,
            contentVersionId: file.contentVersionId
        };
    }

    reviewValue(value) {
        if (typeof value !== 'string' || !value.trim().startsWith('[')) {
            return value || '';
        }
        const parsed = this.parseJson(value);
        if (!Array.isArray(parsed)) {
            return value || '';
        }
        return parsed.map((file) => file.name).filter((name) => name).join(', ');
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        return error?.body?.message || error?.message || 'Unexpected SmartIntake runtime error.';
    }
}