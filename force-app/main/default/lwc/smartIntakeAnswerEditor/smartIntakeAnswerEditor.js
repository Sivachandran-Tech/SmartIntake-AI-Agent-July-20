import { api, LightningElement } from 'lwc';
import {
    isSmartIntakeRegisteredControl,
    loadSmartIntakeControl
} from 'c/smartIntakeControlRegistry';

export default class SmartIntakeAnswerEditor extends LightningElement {
    _value;
    _readOnly = false;

    // Track dynamic import state
    dynamicConstructor;
    dynamicLoadError;
    isLoadingCustomComponent = false;
    _currentUiControl;

    @api
    get readOnly() {
        return this._readOnly;
    }

    set readOnly(value) {
        this._readOnly = Boolean(value);
    }

    @api
    get value() {
        return this._value;
    }

    set value(value) {
        this._value = value ? { ...value } : {};
        this.hydrateFromValue();
    }

    questionText;
    helpText;
    placeholderText;
    required = false;
    inputType = 'TEXT';
    uiControl;
    answerValue = '';
    picklistOptions = [];
    multiAnswerValue = [];
    booleanAnswerValue = false;
    fileUploadLabel = 'Upload file';

    connectedCallback() {
        this.hydrateFromValue();
    }

    get normalizedUiControl() {
        return (this.uiControl || '').trim().toLowerCase();
    }

    get hasRegisteredControl() {
        return isSmartIntakeRegisteredControl(this.uiControl);
    }

    get isConfiguredControl() {
        return this.normalizedUiControl.startsWith('smartintake:') ||
            this.normalizedUiControl === 'c/eventopinionsurvey';
    }

    get showStandardQuestionHeader() {
        return !this.isConfiguredControl;
    }

    get isProductSelector() {
        return [
            'c/smartintakeproductselector',
            'smartintake_product_selector',
            'product_selector'
        ].includes(this.normalizedUiControl);
    }

    get isCustomLwc() {
        return !this.isConfiguredControl &&
            !this.isProductSelector &&
            (this.hasRegisteredControl || this.normalizedUiControl.startsWith('c/'));
    }

    get isEventPulseRating() {
        return false;
    }

    get isSmileRating() {
        return false;
    }

    get isTestRating() {
        return false;
    }

    get isTextarea() {
        return !this.hasRegisteredControl && (this.inputType === 'LONG_TEXT' || this.uiControl === 'lightning-textarea') && !this.isCustomLwc;
    }

    get isCombobox() {
        return !this.hasRegisteredControl && (this.inputType === 'PICKLIST' || this.uiControl === 'lightning-combobox') && !this.isCustomLwc;
    }

    get isRadioGroup() {
        return !this.hasRegisteredControl && (this.inputType === 'RADIO' || this.uiControl === 'lightning-radio-group') && !this.isCustomLwc;
    }

    get isCheckboxGroup() {
        return !this.hasRegisteredControl && (this.inputType === 'MULTI_SELECT' || this.uiControl === 'lightning-checkbox-group') && !this.isCustomLwc;
    }

    get isFileUpload() {
        return !this.hasRegisteredControl && (['FILE', 'IMAGE', 'PDF'].includes(this.inputType) || this.uiControl === 'lightning-file-upload') && !this.isCustomLwc;
    }

    get isLightningInput() {
        return !this.isTextarea &&
            !this.isCombobox &&
            !this.isRadioGroup &&
            !this.isCheckboxGroup &&
            !this.isFileUpload &&
            !this.isProductSelector &&
            !this.isCustomLwc &&
            !this.isConfiguredControl &&
            !this.hasRegisteredControl;
    }

    get lightningInputType() {
        if (this.inputType === 'EMAIL') {
            return 'email';
        }
        if (this.inputType === 'PHONE') {
            return 'tel';
        }
        if (this.inputType === 'NUMBER' || this.inputType === 'CURRENCY') {
            return 'number';
        }
        if (this.inputType === 'DATE') {
            return 'date';
        }
        if (this.inputType === 'DATETIME') {
            return 'datetime';
        }
        if (this.inputType === 'BOOLEAN') {
            return 'checkbox';
        }
        if (this.inputType === 'URL') {
            return 'url';
        }
        return 'text';
    }

    get fileAcceptedFormats() {
        return this._value?.acceptedFormats || [];
    }

    get fileUploadMultiple() {
        return Boolean(this._value?.allowMultipleFiles);
    }

    hydrateFromValue() {
        const source = this._value || {};
        this.questionText = source.questionText || '';
        this.helpText = source.helpText || '';
        this.placeholderText = source.placeholderText || '';
        this.required = Boolean(source.required);
        this.inputType = (source.inputType || 'TEXT').toUpperCase();
        this.uiControl = source.uiControl;
        this.answerValue = source.answerValue || '';
        this.picklistOptions = this.resolveOptions(source);
        this.multiAnswerValue = this.answerValue ? this.answerValue.split(';').filter((entry) => entry) : [];
        this.booleanAnswerValue = this.answerValue === 'true';
        this.fileUploadLabel = this.placeholderText || this.questionText || 'Upload file';

        // Load custom component dynamically if name changed
        if (this.isCustomLwc) {
            if (this.uiControl !== this._currentUiControl) {
                this._currentUiControl = this.uiControl;
                this.loadCustomComponent(this.uiControl);
            }
        } else {
            this._currentUiControl = null;
            this.dynamicConstructor = null;
            this.dynamicLoadError = null;
        }
    }

    async loadCustomComponent(uiControlName) {
        this.isLoadingCustomComponent = true;
        this.dynamicLoadError = null;
        try {
            const ctor = await loadSmartIntakeControl(uiControlName);
            if (!ctor) {
                throw new Error(
                    `${uiControlName} is not in the generated SmartIntake control registry. Sync the custom control registry after deploying the question metadata.`
                );
            }
            this.dynamicConstructor = ctor;
        } catch (error) {
            console.error('Failed to load custom LWC component:', error);
            this.dynamicConstructor = null;
            this.dynamicLoadError = error.message || 'Failed to import component';
        } finally {
            this.isLoadingCustomComponent = false;
        }
    }

    resolveOptions(source) {
        if (Array.isArray(source.options) && source.options.length) {
            return source.options.map((option) => ({
                label: option.label,
                value: option.value
            }));
        }
        if (!source.optionsJson) {
            return [];
        }
        try {
            const parsed = JSON.parse(source.optionsJson);
            return Array.isArray(parsed)
                ? parsed.map((option) => ({ label: option.label, value: option.value }))
                : [];
        } catch (error) {
            return [];
        }
    }

    handleInputChange(event) {
        if (this.readOnly) {
            return;
        }
        if (this.inputType === 'BOOLEAN') {
            this.answerValue = String(event.target.checked);
        } else {
            this.answerValue = event.target.value;
        }
        this.emitValueChange();
    }

    handleCustomLwcValueChange(event) {
        if (this.readOnly) {
            return;
        }
        this.answerValue = event.detail.value;
        this.emitValueChange();
    }

    handleMultiAnswerChange(event) {
        if (this.readOnly) {
            return;
        }
        this.answerValue = (event.detail.value || []).join(';');
        this.multiAnswerValue = event.detail.value || [];
        this.emitValueChange();
    }

    handleFileUploadFinished(event) {
        if (this.readOnly) {
            return;
        }
        const uploadedFiles = (event.detail.files || []).map((file) => ({
            name: file.name,
            documentId: file.documentId || file.contentDocumentId,
            contentVersionId: file.contentVersionId || file.versionId
        }));
        const maxFileCount = this._value?.maxFileCount || 1;
        const existingFiles = this.parseUploadedFiles();
        const nextFiles = this.fileUploadMultiple ? [...existingFiles, ...uploadedFiles] : uploadedFiles.slice(-1);
        const trimmedFiles = nextFiles.slice(0, maxFileCount);
        this.answerValue = JSON.stringify(trimmedFiles);
        this.emitValueChange();
    }

    parseUploadedFiles() {
        if (!this.answerValue || !this.answerValue.trim().startsWith('[')) {
            return [];
        }
        try {
            const parsed = JSON.parse(this.answerValue);
            return Array.isArray(parsed) ? parsed : [];
        } catch (error) {
            return [];
        }
    }

    emitValueChange() {
        const nextValue = {
            ...(this._value || {}),
            questionKey: this._value?.questionKey,
            questionText: this.questionText,
            helpText: this.helpText,
            placeholderText: this.placeholderText,
            required: this.required,
            inputType: this.inputType,
            uiControl: this.uiControl,
            answerValue: this.answerValue,
            options: this.picklistOptions,
            optionsJson: this._value?.optionsJson,
            acceptedFormats: this._value?.acceptedFormats,
            acceptedFormatsJson: this._value?.acceptedFormatsJson,
            allowMultipleFiles: this._value?.allowMultipleFiles,
            maxFileCount: this._value?.maxFileCount
        };
        this._value = nextValue;
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: { value: nextValue },
                bubbles: true,
                composed: true
            })
        );
    }
}