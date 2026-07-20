import { api, LightningElement } from 'lwc';

const DEFAULT_MOODS = [
    { value: '1', label: 'Not satisfied' },
    { value: '2', label: 'Could be better' },
    { value: '3', label: 'Neutral' },
    { value: '4', label: 'Satisfied' },
    { value: '5', label: 'Very satisfied' }
];

const FACE_TONES = ['sad', 'low', 'neutral', 'happy', 'delighted'];

export default class SmartIntakeConfiguredControl extends LightningElement {
    @api question;
    @api readOnly = false;
    @api required = false;

    _value = '';
    selectedMood = '';
    comment = '';
    validationMessage = '';

    @api
    get value() {
        return this._value;
    }

    set value(value) {
        this._value = typeof value === 'object' ? value?.answerValue || value?.value || '' : value || '';
        this.hydrateFromValue();
    }

    get normalizedControl() {
        return (this.question?.uiControl || '').trim().toLowerCase();
    }

    get isOpinionSurvey() {
        return [
            'smartintake:opinionsurvey',
            'smartintake:opinion-survey',
            'smartintake:facesnote',
            'smartintake:faces-note',
            'c/eventopinionsurvey'
        ].includes(this.normalizedControl);
    }

    get titleText() {
        return this.question?.questionText || 'We want your opinion!';
    }

    get eyebrowText() {
        return 'Quick pulse';
    }

    get ratingPrompt() {
        return this.question?.helpText || 'How satisfied are you?';
    }

    get notePrompt() {
        return 'What did you like or want improved?';
    }

    get placeholderText() {
        return this.question?.placeholderText || 'Please fill in your answer';
    }

    get configuredOptions() {
        const options = Array.isArray(this.question?.options) ? this.question.options : [];
        return options.length ? options : DEFAULT_MOODS;
    }

    get moodOptions() {
        return this.configuredOptions.map((option, index) => {
            const value = String(option.value || index + 1);
            const label = option.label || value;
            const isSelected = value === this.selectedMood;
            const tone = FACE_TONES[Math.min(index, FACE_TONES.length - 1)];
            return {
                value,
                label,
                isSelected,
                ariaLabel: `${label} (${index + 1} of ${this.configuredOptions.length})`,
                buttonClass: isSelected ? 'opinion__face-button opinion__face-button_selected' : 'opinion__face-button',
                faceClass: `face face_${tone}`
            };
        });
    }

    get selectedLabel() {
        const mood = this.moodOptions.find((entry) => entry.value === this.selectedMood);
        return mood ? `${mood.value} - ${mood.label}` : '';
    }

    handleMoodSelect(event) {
        this.selectedMood = event.currentTarget.dataset.value;
        this.validationMessage = '';
    }

    handleCommentInput(event) {
        this.comment = event.target.value;
        this.validationMessage = '';
    }

    handleContinue() {
        if (this.required && !this.selectedMood) {
            this.validationMessage = 'Please select a satisfaction level.';
            return;
        }

        if (this.required && !this.comment.trim()) {
            this.validationMessage = 'Please add a short note before continuing.';
            return;
        }

        const mood = this.moodOptions.find((entry) => entry.value === this.selectedMood);
        const answer = [
            mood ? `Satisfaction: ${mood.label} (${mood.value})` : '',
            this.comment.trim() ? `Feedback: ${this.comment.trim()}` : ''
        ].filter(Boolean).join('; ');

        this._value = answer;
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: { value: answer },
            bubbles: true,
            composed: true
        }));
    }

    hydrateFromValue() {
        const value = String(this._value || '');
        const moodMatch = value.match(/Satisfaction: .+ \(([^)]+)\)/);
        if (moodMatch) {
            this.selectedMood = moodMatch[1];
        }

        const feedbackPrefix = 'Feedback: ';
        const feedbackIndex = value.indexOf(feedbackPrefix);
        if (feedbackIndex >= 0) {
            this.comment = value.substring(feedbackIndex + feedbackPrefix.length);
        }
    }
}