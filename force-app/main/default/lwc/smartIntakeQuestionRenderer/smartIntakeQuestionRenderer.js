import { api, LightningElement } from 'lwc';
import {
    isSmartIntakeRegisteredControl,
    loadSmartIntakeControl
} from 'c/smartIntakeControlRegistry';

const FINAL_CONFIRMATION_QUESTION_KEY = '__FINAL_CONFIRMATION__';
const FINAL_REVIEW_DATA_SOURCE_KEY = '__SMARTINTAKE_FINAL_REVIEW__';
const REVIEW_TEXT_HEADER = 'Review your answers:';

export default class SmartIntakeQuestionRenderer extends LightningElement {
    _value;

    @api configuration;

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
    renderLightningInput = false;
    displayValue = '';
    picklistOptions = [];
    reviewItems = [];
    dynamicConstructor;
    dynamicLoadError;
    isLoadingCustomComponent = false;
    _currentUiControl;

    connectedCallback() {
        this.hydrateFromValue();
    }

    get hasRegisteredControl() {
        return isSmartIntakeRegisteredControl(this.uiControl);
    }

    get isConfiguredControl() {
        return this.shouldRenderInlineControl && (
            this.normalizedUiControl.startsWith('smartintake:') ||
            this.normalizedUiControl === 'c/eventopinionsurvey'
        );
    }

    get showStandardQuestionHeader() {
        return this.hasReviewItems;
    }

    get shouldRenderQuestionShell() {
        return this.shouldRenderInlineControl || this.hasReviewItems;
    }

    get suppressEmbeddedPrompt() {
        return this.shouldRenderInlineControl;
    }

    get isProductSelector() {
        return this.shouldRenderInlineControl &&
            [
                'c/smartintakeproductselector',
                'smartintake_product_selector',
                'product_selector'
            ].includes(this.normalizedUiControl);
    }

    get isCustomLwc() {
        return this.shouldRenderInlineControl &&
            !this.isConfiguredControl &&
            !this.isProductSelector &&
            !this.isStarRating &&
            !this.isSmileRating &&
            !this.isEventPulseRating &&
            (this.hasRegisteredControl || this.normalizedUiControl.startsWith('c/'));
    }

    get isCombobox() {
        return this.shouldRenderInlineControl && !this.hasRegisteredControl && !this.isCustomLwc && (this.inputType === 'PICKLIST' || this.uiControl === 'lightning-combobox');
    }

    get isRadioGroup() {
        return this.shouldRenderInlineControl && !this.hasRegisteredControl && !this.isCustomLwc && (this.inputType === 'RADIO' || this.uiControl === 'lightning-radio-group');
    }

    get isCheckboxGroup() {
        return this.shouldRenderInlineControl && !this.hasRegisteredControl && !this.isCustomLwc && (this.inputType === 'MULTI_SELECT' || this.uiControl === 'lightning-checkbox-group');
    }

    get isTextarea() {
        return this.shouldRenderInlineControl && !this.hasRegisteredControl && !this.isCustomLwc && (this.inputType === 'LONG_TEXT' || this.uiControl === 'lightning-textarea');
    }

    get isFileUpload() {
        return this.shouldRenderInlineControl && !this.hasRegisteredControl && !this.isCustomLwc && (['FILE', 'IMAGE', 'PDF'].includes(this.inputType) || this.uiControl === 'lightning-file-upload');
    }

    get normalizedUiControl() {
        return (this.uiControl || '').trim().toLowerCase();
    }

    get shouldRenderInlineControl() {
        return this.renderLightningInput === true;
    }

    get hasReviewItems() {
        return this.reviewItems.length > 0;
    }

    get isStarRating() {
        return this.shouldRenderInlineControl &&
            [
                'c/testrating',
                'star',
                'star_rating'
            ].includes(this.normalizedUiControl);
    }

    get isSmileRating() {
        return this.shouldRenderInlineControl &&
            [
                'c/smilerating',
                'smile',
                'smile_rating'
            ].includes(this.normalizedUiControl);
    }

    get isEventPulseRating() {
        return this.shouldRenderInlineControl &&
            [
                'c/eventpulserating',
                'event_pulse',
                'event_pulse_rating',
                'progress',
                'pulse',
                'pulse_rating'
            ].includes(this.normalizedUiControl);
    }

    get isLightningInput() {
        return this.shouldRenderInlineControl &&
            !this.isTextarea &&
            !this.isCombobox &&
            !this.isRadioGroup &&
            !this.isCheckboxGroup &&
            !this.isFileUpload &&
            !this.isProductSelector &&
            !this.isCustomLwc &&
            !this.isConfiguredControl &&
            !this.isStarRating &&
            !this.isSmileRating &&
            !this.isEventPulseRating;
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

    get booleanAnswerValue() {
        return this.displayValue === 'true';
    }

    get multiAnswerValue() {
        return this.displayValue ? this.displayValue.split(';').filter((entry) => entry) : [];
    }

    get shouldAutoSendInputValue() {
        return ['DATE', 'DATETIME', 'BOOLEAN'].includes(this.inputType);
    }

    get ratingStars() {
        const score = Number.parseInt(this.displayValue, 10) || 0;
        return Array.from({ length: 5 }, (_, index) => {
            const value = index + 1;
            const isSelected = value <= score;
            return {
                value,
                isSelected,
                ariaLabel: `${value} star${value > 1 ? 's' : ''}`,
                buttonClass: isSelected ? 'star-button star-button--selected' : 'star-button',
                iconClass: isSelected ? 'star-icon star-icon--selected' : 'star-icon'
            };
        });
    }

    get ratingFeedback() {
        const labels = {
            1: '1 star',
            2: '2 stars',
            3: '3 stars',
            4: '4 stars',
            5: '5 stars'
        };
        return labels[Number.parseInt(this.displayValue, 10)] || '';
    }

    get smileOptions() {
        const selected = Number.parseInt(this.displayValue, 10) || 0;
        const options = [
            { value: 1, emoji: '😞', label: 'Very dissatisfied' },
            { value: 2, emoji: '😕', label: 'Dissatisfied' },
            { value: 3, emoji: '😐', label: 'Neutral' },
            { value: 4, emoji: '🙂', label: 'Satisfied' },
            { value: 5, emoji: '😄', label: 'Very satisfied' }
        ];
        return options.map((option) => {
            const isSelected = option.value === selected;
            return {
                ...option,
                ariaLabel: `${option.label} (${option.value} of 5)`,
                buttonClass: isSelected ? 'smile-button smile-button--selected' : 'smile-button'
            };
        });
    }

    get smileFeedback() {
        const selected = this.smileOptions.find((option) => option.value === Number.parseInt(this.displayValue, 10));
        return selected ? `${selected.emoji} ${selected.label}` : '';
    }

    handleInputChange(event) {
        if (this.inputType === 'BOOLEAN') {
            this.displayValue = String(event.target.checked);
        } else {
            this.displayValue = event.target.value;
        }
        this.emitValueChange();
        if (this.shouldAutoSendInputValue) {
            this.sendSelectedValueToAgent();
        }
    }

    handleChoiceChange(event) {
        this.displayValue = event.target.value;
        this.emitValueChange();
        this.sendSelectedValueToAgent();
    }

    handleMultiAnswerChange(event) {
        this.displayValue = (event.detail.value || []).join(';');
        this.emitValueChange();
    }

    handleStarClick(event) {
        this.displayValue = event.currentTarget.dataset.value;
        this.emitValueChange();
        this.sendSelectedValueToAgent();
    }

    handleSmileClick(event) {
        this.displayValue = event.currentTarget.dataset.value;
        this.emitValueChange();
        this.sendSelectedValueToAgent();
    }

    handleCustomLwcValueChange(event) {
        this.displayValue = event.detail?.value;
        this.emitValueChange();
        this.sendSelectedValueToAgent();
    }

    hydrateFromValue() {
        const source = this._value || {};
        const embeddedReview = this.embeddedReviewText(source.helpText);
        this.questionText = source.questionText || '';
        this.helpText = embeddedReview ? embeddedReview.cleanedHelpText : (source.helpText || '');
        this.placeholderText = source.placeholderText || '';
        this.required = this.toBoolean(source.required);
        this.inputType = (source.inputType || 'TEXT').toUpperCase();
        this.uiControl = source.uiControl;
        this.renderLightningInput = this.toBoolean(source.renderLightningInput);
        this.displayValue = source.value || source.answerValue || '';
        this.picklistOptions = this.resolveOptions(source);
        this.reviewItems = this.resolveReviewItems(source, embeddedReview);
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

    toBoolean(value) {
        if (typeof value === 'string') {
            return value.trim().toLowerCase() === 'true';
        }
        return value === true;
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
            this.dynamicConstructor = null;
            this.dynamicLoadError = error.message || 'Failed to import component';
        } finally {
            this.isLoadingCustomComponent = false;
        }
    }

    isDirectCustomLwcName(uiControlName) {
        return /^c\/[A-Za-z][A-Za-z0-9_]*$/.test((uiControlName || '').trim());
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

    resolveReviewItems(source, embeddedReview) {
        if (!this.isFinalReviewQuestion(source) && !embeddedReview) {
            return [];
        }
        const parsed = this.parseJson(source.dataSourceJson);
        const items = Array.isArray(parsed) ? parsed : parsed?.items;
        const resolvedItems = Array.isArray(items) ? items : embeddedReview?.items;
        if (!Array.isArray(resolvedItems)) {
            return [];
        }
        return resolvedItems
            .map((item, index) => ({
                key: item.questionKey || item.key || `review-${index}`,
                label: item.label || item.questionText || item.questionKey || 'Question',
                value: this.formatReviewValue(item.value)
            }))
            .filter((item) => item.value);
    }

    isFinalReviewQuestion(source) {
        return source?.questionKey === FINAL_CONFIRMATION_QUESTION_KEY ||
            source?.dataSourceKey === FINAL_REVIEW_DATA_SOURCE_KEY;
    }

    parseJson(payload) {
        if (!payload) {
            return null;
        }
        if (typeof payload === 'object') {
            return payload;
        }
        try {
            return JSON.parse(payload);
        } catch (error) {
            return null;
        }
    }

    formatReviewValue(value) {
        if (Array.isArray(value)) {
            return value
                .filter((entry) => entry !== null && entry !== undefined && String(entry).trim())
                .join(', ');
        }
        if (value && typeof value === 'object') {
            return value.label || value.name || value.displayValue || value.value || JSON.stringify(value);
        }
        return value === null || value === undefined ? '' : String(value);
    }

    embeddedReviewText(helpText) {
        if (!helpText || !helpText.includes(REVIEW_TEXT_HEADER)) {
            return null;
        }

        const start = helpText.indexOf(REVIEW_TEXT_HEADER);
        const before = helpText.slice(0, start).trim();
        const afterHeader = helpText.slice(start + REVIEW_TEXT_HEADER.length);
        const separator = afterHeader.indexOf('\n\n');
        const reviewBlock = (separator >= 0 ? afterHeader.slice(0, separator) : afterHeader).trim();
        const after = (separator >= 0 ? afterHeader.slice(separator + 2) : '').trim();
        const lines = reviewBlock
            .split(/\r?\n/)
            .map((line) => line.trim())
            .filter((line) => line);
        const items = [];

        for (let index = 0; index < lines.length; index += 1) {
            const questionLine = lines[index];
            const answerLine = lines[index + 1];
            if (!questionLine.startsWith('Q: ') || !answerLine || !answerLine.startsWith('A: ')) {
                continue;
            }
            items.push({
                key: `review-text-${items.length}`,
                label: questionLine.slice(3).trim(),
                value: answerLine.slice(3).trim()
            });
            index += 1;
        }

        return {
            items,
            cleanedHelpText: [before, after].filter((part) => part).join('\n\n')
        };
    }

    emitValueChange() {
        const nextValue = {
            ...(this._value || {}),
            questionText: this.questionText,
            helpText: this.helpText,
            placeholderText: this.placeholderText,
            required: this.required,
            inputType: this.inputType,
            uiControl: this.uiControl,
            renderLightningInput: this.renderLightningInput,
            value: this.displayValue,
            answerValue: this.displayValue,
            options: this.picklistOptions,
            optionsJson: this._value?.optionsJson,
            dataSourceKey: this._value?.dataSourceKey,
            dataSourceJson: this._value?.dataSourceJson,
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

    getTextMessageForSelectedValue() {
        if (!this.isInternalSmartIntakeValue(this.displayValue)) {
            return this.displayValue;
        }
        const selectedOption = this.picklistOptions.find(
            (option) => String(option.value) === String(this.displayValue)
        );
        return selectedOption?.label || this.displayValue;
    }

    isInternalSmartIntakeValue(value) {
        return /^__SMARTINTAKE_[A-Z0-9_]+__$/.test(String(value || ''));
    }

    sendSelectedValueToAgent() {
        const messageText = this.getTextMessageForSelectedValue();
        if (!messageText || !this.configuration?.util?.sendTextMessage) {
            return;
        }
        this.configuration.util.sendTextMessage(messageText).catch(() => {
            // Enhanced Chat owns user-visible send failures; keep the renderer non-blocking.
        });
    }
}