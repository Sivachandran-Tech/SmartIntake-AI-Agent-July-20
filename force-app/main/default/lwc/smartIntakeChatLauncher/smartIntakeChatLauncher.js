import { LightningElement, api } from 'lwc';
import SMART_INTAKE_BOT_LOGO from '@salesforce/resourceUrl/smartIntakeBotLogo';

const MAX_HIDE_ATTEMPTS = 20;
const MAX_LAUNCH_ATTEMPTS = 80;
const MAX_FRAME_VISIBILITY_ATTEMPTS = 20;
const HIDE_RETRY_DELAY_MS = 250;
const LAUNCH_RETRY_DELAY_MS = 250;
const FRAME_VISIBILITY_RETRY_DELAY_MS = 150;
const PRECHAT_READY_EVENT = 'smartintakeprechatready';
const LAUNCH_CHAT_EVENT = 'smartintakelaunchchat';
const LAUNCH_CHAT_RESULT_EVENT = 'smartintakelaunchchatresult';
const BRIDGE_RESULT_TIMEOUT_MS = 10000;
const AGENT_USER_ID = '005g5000007D0gbAAC';
const ROUTE_BY_PATH = Object.freeze({
    '/': 'HOTEL_BOOKING_PAGE',
    '/booking': 'HOTEL_BOOKING_PAGE',
    '/feedback': 'feedback',
    '/warranty-claim': 'LAPTOP_WARRANTY_CLAIM',
    '/s': 'HOTEL_BOOKING_PAGE',
    '/s/': 'HOTEL_BOOKING_PAGE',
    '/s/booking': 'HOTEL_BOOKING_PAGE',
    '/s/feedback': 'feedback',
    '/s/warranty-claim': 'LAPTOP_WARRANTY_CLAIM'
});
const BOT_LOGO_VIEW_BOX = '470 420 390 390';
const BOT_EYE_TRACK_ORIGIN_X = 0.38;
const BOT_EYE_TRACK_ORIGIN_Y = 0.49;
const BOT_EYE_MAX_OFFSET_RATIO = 0.035;
const BOT_EYE_TRACK_DISTANCE_RATIO = 0.7;
const BOT_EYE_VERTICAL_RATIO = 0.72;
const STANDARD_LAUNCHER_STYLE_ID = 'smart-intake-hide-standard-chat-launcher';
const STANDARD_LAUNCHER_CSS = `
    #embeddedMessagingFrame.initial:not(.maximized),
    #embeddedMessagingFrame.minimized,
    iframe.embeddedMessagingFrame.initial:not(.maximized),
    iframe.embeddedMessagingFrame.minimized {
        display: none !important;
        visibility: hidden !important;
        pointer-events: none !important;
    }
`;

export default class SmartIntakeChatLauncher extends LightningElement {
    @api label = 'SmartIntake';
    @api eyebrow = 'Need help?';
    @api accessibilityLabel = 'Open SmartIntake chat';
    @api startNewConversation = false;

    isLaunching = false;
    isChatWindowOpen = false;
    errorMessage = '';
    hideAttempts = 0;
    launchAttempts = 0;
    pendingLaunch = false;
    isStandardButtonCreated = false;
    hideRetryTimer;
    launchRetryTimer;
    frameVisibilityTimer;
    bridgeResultTimer;
    botEyeFrame;
    lastPointerPosition;
    isEmbeddedMessagingReady = false;
    isPrechatConfigured = false;

    connectedCallback() {
        this.boundHandleStandardButtonCreated = this.handleStandardButtonCreated.bind(this);
        this.boundHandleMessagingReady = this.handleMessagingReady.bind(this);
        this.boundHandlePrechatReady = this.handlePrechatReady.bind(this);
        this.boundHandleLaunchResult = this.handleLaunchResult.bind(this);
        this.boundHideLauncher = this.hideLauncher.bind(this);
        this.boundShowLauncher = this.showLauncher.bind(this);
        this.boundTrackBotEyes = this.trackBotEyes.bind(this);
        this.boundResetBotEyes = this.resetBotEyes.bind(this);

        this.installStandardLauncherStyles();

        window.addEventListener('pointermove', this.boundTrackBotEyes);
        window.addEventListener('blur', this.boundResetBotEyes);
        window.addEventListener('onEmbeddedMessagingButtonCreated', this.boundHandleStandardButtonCreated);
        window.addEventListener('onEmbeddedMessagingReady', this.boundHandleMessagingReady);
        window.addEventListener(PRECHAT_READY_EVENT, this.boundHandlePrechatReady);
        window.addEventListener(LAUNCH_CHAT_RESULT_EVENT, this.boundHandleLaunchResult);
        window.addEventListener('onEmbeddedMessagingWindowMaximized', this.boundHideLauncher);
        window.addEventListener('onEmbeddedMessagingWindowMinimized', this.boundShowLauncher);
        window.addEventListener('onEmbeddedMessagingConversationClosed', this.boundShowLauncher);
        window.addEventListener('onEmbeddedMessagingWindowClosed', this.boundShowLauncher);

        this.queueHideStandardButton();
    }

    disconnectedCallback() {
        window.removeEventListener('pointermove', this.boundTrackBotEyes);
        window.removeEventListener('blur', this.boundResetBotEyes);
        window.removeEventListener('onEmbeddedMessagingButtonCreated', this.boundHandleStandardButtonCreated);
        window.removeEventListener('onEmbeddedMessagingReady', this.boundHandleMessagingReady);
        window.removeEventListener(PRECHAT_READY_EVENT, this.boundHandlePrechatReady);
        window.removeEventListener(LAUNCH_CHAT_RESULT_EVENT, this.boundHandleLaunchResult);
        window.removeEventListener('onEmbeddedMessagingWindowMaximized', this.boundHideLauncher);
        window.removeEventListener('onEmbeddedMessagingWindowMinimized', this.boundShowLauncher);
        window.removeEventListener('onEmbeddedMessagingConversationClosed', this.boundShowLauncher);
        window.removeEventListener('onEmbeddedMessagingWindowClosed', this.boundShowLauncher);
        window.clearTimeout(this.hideRetryTimer);
        window.clearTimeout(this.launchRetryTimer);
        window.clearTimeout(this.frameVisibilityTimer);
        window.clearTimeout(this.bridgeResultTimer);
        window.cancelAnimationFrame(this.botEyeFrame);
    }

    get computedAriaLabel() {
        return this.accessibilityLabel || this.label || 'Open chat';
    }

    get launcherShellClass() {
        return this.isChatWindowOpen ? 'launcher-shell launcher-shell_hidden' : 'launcher-shell';
    }

    get botLogoUrl() {
        return SMART_INTAKE_BOT_LOGO;
    }

    get botLogoViewBox() {
        return BOT_LOGO_VIEW_BOX;
    }

    handleLaunch() {
        this.errorMessage = '';
        const api = this.getUtilApi();

        if (!this.canLaunchChat(api)) {
            this.isLaunching = true;
            this.pendingLaunch = true;
            this.launchAttempts = 0;
            this.configurePrechatFields();
            this.queueLaunchWhenReady();
            this.queueHideStandardButton();
            return;
        }

        this.openChat(api);
    }

    queueHideStandardButton() {
        window.clearTimeout(this.hideRetryTimer);
        this.hideRetryTimer = window.setTimeout(() => this.hideStandardButton(), HIDE_RETRY_DELAY_MS);
    }

    installStandardLauncherStyles() {
        if (document.getElementById(STANDARD_LAUNCHER_STYLE_ID)) {
            return;
        }

        const style = document.createElement('style');
        style.id = STANDARD_LAUNCHER_STYLE_ID;
        style.textContent = STANDARD_LAUNCHER_CSS;
        document.head.appendChild(style);
    }

    hideStandardButton() {
        const api = this.getUtilApi();

        if (!this.isStandardButtonCreated) {
            if (this.hideAttempts < MAX_HIDE_ATTEMPTS) {
                this.hideAttempts += 1;
                this.queueHideStandardButton();
            }

            return;
        }

        if (api && typeof api.hideChatButton === 'function') {
            try {
                api.hideChatButton();
                this.hideAttempts = 0;
                return;
            } catch (error) {
                // The standard launcher can fail to hide while the chat window is open.
            }
        }

        if (this.hideAttempts < MAX_HIDE_ATTEMPTS) {
            this.hideAttempts += 1;
            this.queueHideStandardButton();
        }
    }

    getUtilApi() {
        return window.embeddedservice_bootstrap && window.embeddedservice_bootstrap.utilAPI;
    }

    getPrechatApi() {
        return window.embeddedservice_bootstrap && window.embeddedservice_bootstrap.prechatAPI;
    }

    resolveCurrentPage() {
        const currentPath = window.location && window.location.pathname ? window.location.pathname : '/';
        const normalizedPath = currentPath.replace(/\/+$/, '') || '/';

        return (
            ROUTE_BY_PATH[currentPath] ||
            ROUTE_BY_PATH[normalizedPath] ||
            (normalizedPath.endsWith('/booking') ? 'HOTEL_BOOKING_PAGE' : null) ||
            (normalizedPath.endsWith('/warranty-claim') ? 'LAPTOP_WARRANTY_CLAIM' : null) ||
            (normalizedPath.endsWith('/feedback') ? 'feedback' : null) ||
            (window.location && window.location.href)
        );
    }

    configurePrechatFields() {
        if (typeof window.smartIntakeSetHiddenPrechatFields === 'function') {
            try {
                const result = window.smartIntakeSetHiddenPrechatFields();
                if (result !== false) {
                    this.isPrechatConfigured = true;
                    return true;
                }
            } catch (error) {
                // Fall back to direct pre-chat configuration below.
            }
        }

        const prechatApi = this.getPrechatApi();
        if (!prechatApi || typeof prechatApi.setHiddenPrechatFields !== 'function') {
            return false;
        }

        const currentPage = this.resolveCurrentPage();
        try {
            prechatApi.setHiddenPrechatFields({
                Current_Page: currentPage,
                Agent_User: AGENT_USER_ID
            });
            window.smartIntakeEmbeddedPrechatReady = true;
            this.isPrechatConfigured = true;
            window.dispatchEvent(new CustomEvent(PRECHAT_READY_EVENT, { detail: { currentPage, agentUserId: AGENT_USER_ID } }));
            return true;
        } catch (error) {
            window.smartIntakeEmbeddedPrechatReady = false;
            return false;
        }
    }

    handleStandardButtonCreated() {
        this.isStandardButtonCreated = true;
        window.smartIntakeEmbeddedButtonReady = true;
        this.hideAttempts = 0;
        this.hideStandardButton();

        if (this.pendingLaunch) {
            this.queueLaunchWhenReady();
        }
    }

    handleMessagingReady() {
        this.isEmbeddedMessagingReady = true;
        this.configurePrechatFields();
        this.hideStandardButton();

        if (this.pendingLaunch) {
            this.queueLaunchWhenReady();
        }
    }

    handlePrechatReady() {
        this.isPrechatConfigured = true;

        if (this.pendingLaunch) {
            this.queueLaunchWhenReady();
        }
    }

    handleLaunchResult(event) {
        window.clearTimeout(this.bridgeResultTimer);

        if (event && event.detail && event.detail.success) {
            this.verifyChatWindowVisible();
            return;
        }

        this.isLaunching = false;
        this.isChatWindowOpen = false;
        this.errorMessage = 'Chat could not open. Please try again.';
    }

    queueLaunchWhenReady() {
        window.clearTimeout(this.launchRetryTimer);
        this.launchRetryTimer = window.setTimeout(() => this.launchWhenReady(), LAUNCH_RETRY_DELAY_MS);
    }

    launchWhenReady() {
        const api = this.getUtilApi();

        if (this.canLaunchChat(api)) {
            this.openChat(api);
            return;
        }

        if (this.canRequestBridgeLaunch()) {
            this.pendingLaunch = false;
            this.requestLaunchThroughBridge();
            return;
        }

        if (this.launchAttempts < MAX_LAUNCH_ATTEMPTS) {
            this.launchAttempts += 1;
            this.queueLaunchWhenReady();
            return;
        }

        this.pendingLaunch = false;
        this.isLaunching = false;
        this.launchAttempts = 0;
        this.errorMessage = 'Chat is still loading. Please try again in a moment.';
    }

    openChat(api) {
        this.isLaunching = true;
        this.pendingLaunch = false;
        this.launchAttempts = 0;
        window.clearTimeout(this.bridgeResultTimer);
        this.logLaunchReadiness('launching');
        this.configurePrechatFields();

        Promise.resolve()
            .then(() => api.launchChat(this.shouldStartNewConversation()))
            .then(() => {
                this.verifyChatWindowVisible();
            })
            .catch(() => {
                this.isChatWindowOpen = false;
                this.errorMessage = 'Chat could not open. Please try again.';
            })
            .finally(() => {
                this.isLaunching = false;
                this.hideStandardButton();
            });
    }

    canLaunchChat(api = this.getUtilApi()) {
        return Boolean(this.isStandardButtonReady() && api && typeof api.launchChat === 'function');
    }

    canRequestBridgeLaunch() {
        return this.isStandardButtonReady();
    }

    isStandardButtonReady() {
        return this.isStandardButtonCreated || window.smartIntakeEmbeddedButtonReady === true;
    }

    requestLaunchThroughBridge() {
        this.logLaunchReadiness('bridge-requested');
        window.clearTimeout(this.bridgeResultTimer);
        this.configurePrechatFields();

        try {
            window.dispatchEvent(
                new CustomEvent(LAUNCH_CHAT_EVENT, {
                    detail: {
                        startNewConversation: this.shouldStartNewConversation()
                    }
                })
            );

            this.bridgeResultTimer = window.setTimeout(() => {
                this.isLaunching = false;
                this.verifyChatWindowVisible();
            }, BRIDGE_RESULT_TIMEOUT_MS);
        } catch (error) {
            this.isLaunching = false;
            this.errorMessage = 'Chat could not open. Please try again.';
        }
    }

    logLaunchReadiness(stage) {
        const api = this.getUtilApi();

        // Keep this visible during Experience Cloud testing without changing runtime behavior.
        // eslint-disable-next-line no-console
        console.debug('[SmartIntakeChatLauncher]', stage, {
            hasBootstrap: Boolean(window.embeddedservice_bootstrap),
            hasUtilApi: Boolean(api),
            hasLaunchChat: Boolean(api && typeof api.launchChat === 'function'),
            embeddedMessagingReady: this.isEmbeddedMessagingReady,
            prechatConfigured: this.isPrechatConfigured || window.smartIntakeEmbeddedPrechatReady === true
        });
    }

    shouldStartNewConversation() {
        return this.startNewConversation === true || this.startNewConversation === 'true';
    }

    hideLauncher() {
        this.verifyChatWindowVisible();
        this.hideStandardButton();
    }

    showLauncher() {
        window.clearTimeout(this.frameVisibilityTimer);
        this.isChatWindowOpen = false;
        this.configurePrechatFields();
        this.hideStandardButton();
    }

    verifyChatWindowVisible(attempt = 0) {
        window.clearTimeout(this.frameVisibilityTimer);

        if (this.ensureEmbeddedFrameVisible()) {
            this.isChatWindowOpen = true;
            this.errorMessage = '';
            this.hideStandardButton();
            return;
        }

        if (attempt < MAX_FRAME_VISIBILITY_ATTEMPTS) {
            this.frameVisibilityTimer = window.setTimeout(
                () => this.verifyChatWindowVisible(attempt + 1),
                FRAME_VISIBILITY_RETRY_DELAY_MS
            );
            return;
        }

        this.isChatWindowOpen = false;
        this.isLaunching = false;
        this.errorMessage = 'Chat is still opening. Please try again.';
    }

    ensureEmbeddedFrameVisible() {
        const frame = this.getEmbeddedMessagingFrame();

        if (!frame || !frame.classList.contains('maximized')) {
            return false;
        }

        const refreshedStyle = window.getComputedStyle(frame);
        const rect = frame.getBoundingClientRect();

        return (
            refreshedStyle.display !== 'none' &&
            refreshedStyle.visibility !== 'hidden' &&
            rect.width > 100 &&
            rect.height > 100
        );
    }

    getEmbeddedMessagingFrame() {
        return document.querySelector('#embeddedMessagingFrame, iframe.embeddedMessagingFrame');
    }

    trackBotEyes(event) {
        if (!event || !Number.isFinite(event.clientX) || !Number.isFinite(event.clientY)) {
            return;
        }

        this.lastPointerPosition = {
            x: event.clientX,
            y: event.clientY
        };

        if (this.botEyeFrame) {
            return;
        }

        this.botEyeFrame = window.requestAnimationFrame(() => this.updateBotEyes());
    }

    updateBotEyes() {
        this.botEyeFrame = undefined;

        if (this.prefersReducedMotion()) {
            this.resetBotEyes();
            return;
        }

        const botLogo = this.template.querySelector('.bot-logo');

        if (!botLogo || !this.lastPointerPosition) {
            return;
        }

        const rect = botLogo.getBoundingClientRect();

        if (!rect.width || !rect.height) {
            return;
        }

        const originX = rect.left + rect.width * BOT_EYE_TRACK_ORIGIN_X;
        const originY = rect.top + rect.height * BOT_EYE_TRACK_ORIGIN_Y;
        const deltaX = this.lastPointerPosition.x - originX;
        const deltaY = this.lastPointerPosition.y - originY;
        const distance = Math.hypot(deltaX, deltaY);

        if (!distance) {
            this.setBotEyeOffset(botLogo, 0, 0);
            return;
        }

        const maxOffset = rect.width * BOT_EYE_MAX_OFFSET_RATIO;
        const strength = Math.min(distance / (rect.width * BOT_EYE_TRACK_DISTANCE_RATIO), 1);
        const offsetX = (deltaX / distance) * maxOffset * strength;
        const offsetY = (deltaY / distance) * maxOffset * BOT_EYE_VERTICAL_RATIO * strength;

        this.setBotEyeOffset(botLogo, offsetX, offsetY);
    }

    resetBotEyes() {
        window.cancelAnimationFrame(this.botEyeFrame);
        this.botEyeFrame = undefined;
        this.lastPointerPosition = undefined;

        const botLogo = this.template.querySelector('.bot-logo');

        if (botLogo) {
            this.setBotEyeOffset(botLogo, 0, 0);
        }
    }

    setBotEyeOffset(botLogo, offsetX, offsetY) {
        botLogo.style.setProperty('--bot-eye-x', `${offsetX.toFixed(2)}px`);
        botLogo.style.setProperty('--bot-eye-y', `${offsetY.toFixed(2)}px`);
    }

    prefersReducedMotion() {
        return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    }
}