import { api, LightningElement, track } from 'lwc';

/**
 * SmartIntake Smile Rating Custom LWC
 *
 * Pluggable custom LWC for SmartIntake questions with UI_Control__c = 'c/smileRating'.
 * Loaded dynamically by smartIntakeAnswerEditor via lwc:is + import('c/smileRating').
 *
 * Contract:
 *   @api value      — receives the current answer string (e.g. "3") from smartIntakeAnswerEditor
 *   @api readOnly   — true when rendered as read-only (output/renderer mode)
 *   @api required   — true when the question is required
 *   Dispatches: CustomEvent('valuechange', { detail: { value: String } })
 */
export default class SmileRating extends LightningElement {
    @api readOnly = false;
    @api required = false;

    @track _value = '';

    // Smile options: value 1–5 mapped to emoji faces and labels
    SMILE_OPTIONS = [
        { value: 1, emoji: '😞', label: 'Very Dissatisfied' },
        { value: 2, emoji: '😕', label: 'Dissatisfied' },
        { value: 3, emoji: '😐', label: 'Neutral' },
        { value: 4, emoji: '🙂', label: 'Satisfied' },
        { value: 5, emoji: '😄', label: 'Very Satisfied' }
    ];

    @api
    get value() {
        return this._value;
    }

    set value(val) {
        // Accept both plain string ('3') and full question contract object
        if (val && typeof val === 'object') {
            this._value = String(val.answerValue || val.value || '');
        } else {
            this._value = String(val || '');
        }
    }

    get smiles() {
        const selected = parseInt(this._value, 10) || 0;
        return this.SMILE_OPTIONS.map(option => {
            const isSelected = option.value === selected;
            return {
                value: option.value,
                emoji: option.emoji,
                label: option.label,
                isSelected,
                ariaLabel: `${option.label} (${option.value} of 5)`,
                buttonClass: isSelected
                    ? 'smile-btn smile-btn--selected'
                    : 'smile-btn smile-btn--empty'
            };
        });
    }

    get hasSelection() {
        return !!this._value && parseInt(this._value, 10) > 0;
    }

    get ratingFeedback() {
        const selected = parseInt(this._value, 10);
        const option = this.SMILE_OPTIONS.find(o => o.value === selected);
        return option ? `${option.emoji} ${option.label}` : '';
    }

    handleSmileClick(event) {
        if (this.readOnly) return;
        const selectedValue = event.currentTarget.dataset.value;
        this._value = String(selectedValue);

        // Dispatch valuechange — consumed by smartIntakeAnswerEditor
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: { value: this._value },
            bubbles: true,
            composed: true
        }));
    }
}