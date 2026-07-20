import { api, LightningElement } from 'lwc';

export default class SmartIntakeOptionCardPicker extends LightningElement {
    @api question;
    @api value;
    @api required;

    get ariaLabel() {
        return this.question?.questionText || 'SmartIntake options';
    }

    get options() {
        if (Array.isArray(this.question?.options) && this.question.options.length) {
            return this.question.options;
        }
        if (!this.question?.optionsJson) {
            return [];
        }
        try {
            const parsed = JSON.parse(this.question.optionsJson);
            return Array.isArray(parsed) ? parsed : [];
        } catch (error) {
            return [];
        }
    }

    get hasOptions() {
        return this.options.length > 0;
    }

    get normalizedOptions() {
        const currentValue = String(this.value || '');
        return this.options.map((option) => {
            const value = String(option.value || option.label || '');
            const label = option.label || value;
            const selected = value === currentValue;
            return {
                label,
                value,
                selected,
                className: selected ? 'option-card option-card_selected' : 'option-card'
            };
        });
    }

    handleSelect(event) {
        const selectedValue = event.currentTarget?.dataset?.value;
        if (!selectedValue) {
            return;
        }
        this.value = selectedValue;
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: { value: selectedValue },
                bubbles: true,
                composed: true
            })
        );
    }
}