import { api, LightningElement } from 'lwc';

const DEFAULT_VISIBLE_COUNT = 2;

export default class SmartIntakeProductSelector extends LightningElement {
    @api readOnly = false;
    @api required = false;
    @api title = '';
    @api helpText = '';
    @api eyebrowText = 'Available products';
    @api productsJson = '';
    @api hidePrompt = false;

    _question = {};
    _value = '';
    _answers = {};
    pageIndex = 0;
    validationMessage = '';

    @api
    get question() {
        return this._question;
    }

    set question(value) {
        this._question = value || {};
        this._answers = this.parseAnswerPayload(this._question.answersJson);
        this.pageIndex = 0;
    }

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

    get titleText() {
        return this.title || this._question.questionText || 'Choose the product for this request';
    }

    get computedHelpText() {
        return this.helpText || this._question.helpText || '';
    }

    get showPrompt() {
        return !this.toBoolean(this.hidePrompt);
    }

    get computedAriaLabel() {
        return this.titleText || 'Product selector';
    }

    get products() {
        return this.readProducts().map((product, index) => this.normalizeProduct(product, index));
    }

    get hasProducts() {
        return this.products.length > 0;
    }

    get visibleCount() {
        return DEFAULT_VISIBLE_COUNT;
    }

    get visibleProducts() {
        return this.products.slice(this.pageIndex, this.pageIndex + this.visibleCount);
    }

    get selectedProduct() {
        return this.products.find((product) => product.value === this._value) || null;
    }

    get resultCountLabel() {
        const count = this.products.length;
        if (!count) {
            return 'No products';
        }
        const start = Math.min(this.pageIndex + 1, count);
        const end = Math.min(this.pageIndex + this.visibleCount, count);
        return `${start}-${end} of ${count}`;
    }

    get isPreviousDisabled() {
        return this.pageIndex <= 0;
    }

    get isNextDisabled() {
        return this.pageIndex + this.visibleCount >= this.products.length;
    }

    get trackStyle() {
        return '';
    }

    handlePrevious() {
        this.pageIndex = Math.max(0, this.pageIndex - this.visibleCount);
    }

    handleNext() {
        const maxStart = Math.max(0, this.products.length - this.visibleCount);
        this.pageIndex = Math.min(maxStart, this.pageIndex + this.visibleCount);
    }

    handleSelect(event) {
        const value = this.normalizeValue(event.currentTarget.dataset.value);
        if (!value) {
            return;
        }
        this._value = value;
        this.validationMessage = '';
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value,
                product: this.products.find((product) => product.value === value) || null
            },
            bubbles: true,
            composed: true
        }));
    }

    @api
    reportValidity() {
        if (this.required && !this._value) {
            this.validationMessage = 'Please choose a product.';
            return false;
        }
        this.validationMessage = '';
        return true;
    }

    @api
    checkValidity() {
        return !(this.required && !this._value);
    }

    readProducts() {
        const directProducts = this.parseProductPayload(this.productsJson);
        if (directProducts.length) {
            return directProducts;
        }

        const dataSourceProducts = this.parseProductPayload(this._question.dataSourceJson);
        if (dataSourceProducts.length) {
            return dataSourceProducts;
        }

        const optionProducts = Array.isArray(this._question.options) && this._question.options.length
            ? this._question.options
            : this.parseProductPayload(this._question.optionsJson);
        if (optionProducts.length) {
            return optionProducts;
        }

        const answerProducts = this.productsFromAnswers();
        if (answerProducts.length) {
            return answerProducts;
        }

        const answerProduct = this.productFromAnswerIds();
        return answerProduct ? [answerProduct] : [];
    }

    parseProductPayload(payload) {
        if (!payload) {
            return [];
        }
        if (Array.isArray(payload)) {
            return payload;
        }
        if (typeof payload === 'object') {
            return this.extractProductArray(payload);
        }
        try {
            return this.extractProductArray(JSON.parse(payload));
        } catch (error) {
            return [];
        }
    }

    toBoolean(value) {
        if (typeof value === 'string') {
            return value.trim().toLowerCase() === 'true';
        }
        return value === true;
    }

    extractProductArray(parsed) {
        if (Array.isArray(parsed)) {
            return parsed;
        }
        if (!parsed || typeof parsed !== 'object') {
            return [];
        }

        const candidates = [
            parsed.products,
            parsed.items,
            parsed.records,
            parsed.results,
            parsed.options,
            parsed.data,
            parsed.availableProducts,
            parsed.AVAILABLE_PRODUCTS,
            parsed.registeredProducts,
            parsed.REGISTERED_PRODUCTS,
            parsed.productResults,
            parsed.PRODUCT_RESULTS
        ];
        for (const candidate of candidates) {
            const products = this.parseProductPayload(candidate);
            if (products.length) {
                return products;
            }
        }
        return [];
    }

    parseAnswerPayload(payload) {
        if (!payload) {
            return {};
        }
        if (typeof payload === 'object' && !Array.isArray(payload)) {
            return payload;
        }
        try {
            const parsed = JSON.parse(payload);
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : {};
        } catch (error) {
            return {};
        }
    }

    productsFromAnswers() {
        const answers = this._answers || {};
        const directProducts = this.parseProductPayload(
            this.firstAnswerValue(
                'products',
                'PRODUCTS',
                'productResults',
                'PRODUCT_RESULTS',
                'availableProducts',
                'AVAILABLE_PRODUCTS',
                'registeredProducts',
                'REGISTERED_PRODUCTS'
            )
        );
        if (directProducts.length) {
            return directProducts;
        }

        const answerProduct = this.productFromAnswerIds();
        return answerProduct ? [answerProduct] : [];
    }

    productFromAnswerIds() {
        const assetId = this.firstAnswerValue('assetId', 'asset_id', 'ASSET_ID');
        const productId = this.firstAnswerValue('productId', 'product_id', 'PRODUCT_ID');
        const serialNumber = this.firstAnswerValue('serialNumber', 'serial_number', 'SERIAL_NUMBER');
        const productCode = this.firstAnswerValue('productCode', 'product_code', 'PRODUCT_CODE');
        const warrantyStatus = this.firstAnswerValue('warrantyStatus', 'warranty_status', 'WARRANTY_STATUS');
        const label = this.firstAnswerValue('productName', 'product_name', 'PRODUCT_NAME', 'assetName', 'asset_name', 'ASSET_NAME');

        if (!assetId && !productId && !serialNumber && !productCode && !label) {
            return null;
        }

        return {
            value: this.firstValue(serialNumber, productCode, productId, assetId),
            label: this.firstValue(label, 'Registered product'),
            subtitle: this.firstAnswerValue('productDescription', 'product_description', 'PRODUCT_DESCRIPTION'),
            serialNumber,
            productId,
            warrantyLabel: warrantyStatus ? `Warranty: ${warrantyStatus}` : ''
        };
    }

    normalizeProduct(product, index) {
        const source = product || {};
        const label = this.firstValue(source.label, source.name, source.productName, source.title, `Product ${index + 1}`);
        const value = this.normalizeValue(
            this.firstValue(
                source.value,
                source.serialNumber,
                source.productId,
                source.productCode,
                source.assetId,
                source.id,
                label
            )
        );
        const isSelected = value === this._value;
        const identifier = this.firstValue(source.serialNumber, source.productId, source.productCode, source.sku, source.id, value);
        const priceLabel = this.firstValue(source.priceLabel, source.price, source.purchasePrice);
        const warrantyLabel = this.firstValue(source.warrantyLabel, source.warrantyStatus, source.status);

        return {
            value,
            label,
            subtitle: this.firstValue(source.subtitle, source.description, source.family, source.category, source.brand),
            imageUrl: this.firstValue(source.imageUrl, source.image, source.thumbnailUrl, source.thumbnail),
            imageAlt: `${label} product image`,
            initials: this.initialsFor(label),
            priceLabel: priceLabel ? String(priceLabel) : '',
            identifierLabel: identifier ? `ID: ${identifier}` : '',
            warrantyLabel: warrantyLabel ? String(warrantyLabel) : '',
            isSelected,
            ariaLabel: `${isSelected ? 'Selected product' : 'Choose product'} ${label}`,
            cardClass: isSelected ? 'product-card product-card_selected' : 'product-card'
        };
    }

    firstValue(...values) {
        return values.find((value) => value !== undefined && value !== null && String(value).trim() !== '');
    }

    firstAnswerValue(...keys) {
        const answers = this._answers || {};
        for (const key of keys) {
            if (answers[key] !== undefined && answers[key] !== null && String(answers[key]).trim() !== '') {
                return answers[key];
            }
        }
        const normalizedKeys = keys.map((key) => String(key).toLowerCase());
        const matchedKey = Object.keys(answers).find((key) => normalizedKeys.includes(key.toLowerCase()));
        return matchedKey ? answers[matchedKey] : '';
    }

    normalizeValue(value) {
        return String(value || '').trim();
    }

    formatCurrency(value) {
        const amount = Number(value);
        if (!Number.isFinite(amount)) {
            return String(value || '');
        }
        return new Intl.NumberFormat(undefined, {
            style: 'currency',
            currency: 'USD',
            maximumFractionDigits: 0
        }).format(amount);
    }

    formatDate(value) {
        if (!value) {
            return '';
        }
        try {
            return new Intl.DateTimeFormat(undefined, {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
            }).format(new Date(value));
        } catch (error) {
            return String(value);
        }
    }

    initialsFor(label) {
        return String(label || 'Product')
            .split(/\s+/)
            .filter(Boolean)
            .slice(0, 2)
            .map((part) => part.charAt(0).toUpperCase())
            .join('') || 'P';
    }
}