import { api, LightningElement } from 'lwc';

const PULSE_OPTIONS = [
    { value: '1', label: 'Calm', angle: 225 },
    { value: '2', label: 'Warming up', angle: 270 },
    { value: '3', label: 'Good', angle: 315 },
    { value: '4', label: 'Vibrant', angle: 45 },
    { value: '5', label: 'Electric', angle: 90 }
];

export default class EventPulseRating extends LightningElement {
    @api readOnly = false;
    @api required = false;

    _value = '';
    isDragging = false;

    @api
    get value() {
        return this._value;
    }

    set value(value) {
        if (value && typeof value === 'object') {
            this._value = this.normalizeValue(value.answerValue || value.value);
            return;
        }
        this._value = this.normalizeValue(value);
    }

    get selectedOption() {
        return PULSE_OPTIONS.find((option) => option.value === this._value) || null;
    }

    get selectedIndex() {
        const index = PULSE_OPTIONS.findIndex((option) => option.value === this._value);
        return index < 0 ? 0 : index;
    }

    get displayValue() {
        return this._value || '0';
    }

    get selectedLabel() {
        return this.selectedOption?.label || 'Select';
    }

    get shellClass() {
        return this._value ? 'pulse pulse_selected' : 'pulse';
    }

    get dialStyle() {
        const progress = this._value ? ((this.selectedIndex + 1) / PULSE_OPTIONS.length) * 360 : 0;
        const midProgress = progress * 0.62;
        return `--pulse-progress:${progress}deg;--pulse-mid-progress:${midProgress}deg;`;
    }

    get options() {
        return PULSE_OPTIONS.map((option) => {
            const isSelected = option.value === this._value;
            return {
                ...option,
                isSelected,
                ariaLabel: `${option.label} event energy (${option.value} of 5)`,
                buttonClass: isSelected ? 'pulse__dot pulse__dot_selected' : 'pulse__dot',
                style: this.positionStyle(option.angle)
            };
        });
    }

    handleSelect(event) {
        event.stopPropagation();
        this.selectValue(event.currentTarget.dataset.value);
    }

    handleDialPointerDown(event) {
        if (this.readOnly) {
            return;
        }
        this.isDragging = true;
        event.currentTarget.setPointerCapture(event.pointerId);
        this.selectFromPointer(event);
    }

    handleDialPointerMove(event) {
        if (!this.isDragging || this.readOnly) {
            return;
        }
        this.selectFromPointer(event);
    }

    handleDialPointerUp(event) {
        if (!this.isDragging) {
            return;
        }
        this.isDragging = false;
        try {
            event.currentTarget.releasePointerCapture(event.pointerId);
        } catch (error) {
            // Pointer capture can already be released by the browser.
        }
    }

    selectFromPointer(event) {
        const rect = event.currentTarget.getBoundingClientRect();
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;
        const angle = this.normalizeAngle(Math.atan2(event.clientY - centerY, event.clientX - centerX) * 180 / Math.PI);
        const nearest = PULSE_OPTIONS.reduce((best, option) => {
            const distance = this.circularDistance(angle, option.angle);
            return distance < best.distance ? { option, distance } : best;
        }, { option: PULSE_OPTIONS[0], distance: 360 });
        this.selectValue(nearest.option.value);
    }

    selectValue(value) {
        const nextValue = this.normalizeValue(value);
        if (!nextValue || this._value === nextValue) {
            return;
        }
        this._value = nextValue;
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: { value: this._value },
            bubbles: true,
            composed: true
        }));
    }

    normalizeValue(value) {
        const normalized = String(value || '').trim();
        return PULSE_OPTIONS.some((option) => option.value === normalized) ? normalized : '';
    }

    normalizeAngle(angle) {
        return (angle + 360) % 360;
    }

    circularDistance(first, second) {
        const diff = Math.abs(first - second) % 360;
        return Math.min(diff, 360 - diff);
    }

    positionStyle(angle) {
        const radius = 46;
        const radians = angle * Math.PI / 180;
        const x = 50 + radius * Math.cos(radians);
        const y = 50 + radius * Math.sin(radians);
        return `left:${x}%;top:${y}%;`;
    }
}