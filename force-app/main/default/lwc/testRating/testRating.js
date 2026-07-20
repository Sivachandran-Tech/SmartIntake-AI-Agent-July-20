import { api, LightningElement, track } from 'lwc';

/**
 * SmartIntake Star Rating Custom LWC
 *
 * Pluggable custom LWC for SmartIntake questions with UI_Control__c = 'c/testRating'.
 * Loaded dynamically by smartIntakeAnswerEditor via lwc:is + import('c/testRating').
 *
 * Contract:
 *   @api value      — receives the current answer string (e.g. "3") from smartIntakeAnswerEditor
 *   @api readOnly   — true when rendered as read-only (output/renderer mode)
 *   @api required   — true when the question is required
 *   Dispatches: CustomEvent('valuechange', { detail: { value: String } })
 */
export default class TestRating extends LightningElement {
    @api readOnly = false;
    @api required = false;

    @track _value = '';

    // Rating labels for user feedback
    RATING_LABELS = {
        '1': '⭐ Poor',
        '2': '⭐⭐ Fair',
        '3': '⭐⭐⭐ Good',
        '4': '⭐⭐⭐⭐ Very Good',
        '5': '⭐⭐⭐⭐⭐ Excellent'
    };

    @api
    get value() {
        return this._value;
    }

    set value(val) {
        // Accept both plain string ('3') and full question contract object
        if (val && typeof val === 'object') {
            // Called from smartIntakeAnswerEditor with answerValue field
            this._value = String(val.answerValue || val.value || '');
        } else {
            this._value = String(val || '');
        }
    }

    get stars() {
        const score = parseInt(this._value, 10) || 0;
        return Array.from({ length: 5 }, (_, index) => {
            const val = index + 1;
            const isSelected = val <= score;
            return {
                value: val,
                isSelected: isSelected,
                ariaLabel: `${val} star${val > 1 ? 's' : ''}`,
                buttonClass: isSelected
                    ? 'star-btn star-btn--selected'
                    : 'star-btn star-btn--empty',
                iconClass: isSelected ? 'star-icon star-icon--filled' : 'star-icon star-icon--empty'
            };
        });
    }

    get hasSelection() {
        return !!this._value && parseInt(this._value, 10) > 0;
    }

    get ratingFeedback() {
        return this.RATING_LABELS[this._value] || '';
    }

    handleStarClick(event) {
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