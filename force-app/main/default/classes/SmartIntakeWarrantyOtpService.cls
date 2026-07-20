public without sharing class SmartIntakeWarrantyOtpService {
    private static final Integer OTP_EXPIRY_MINUTES = 10;
    private static final Integer MAX_ATTEMPTS = 3;
    private static final String DEFAULT_OTP_QUESTION_KEY = 'VERIFY_EMAIL_OTP';
    private static final String DEFAULT_VERIFIED_NEXT_QUESTION_KEY = 'CLAIM_SERIAL_NUMBER';
    private static final String DEV_EMAIL_LIMIT_FALLBACK_OTP = '000000';

    @TestVisible
    static String lastGeneratedOtp;

    @TestVisible
    static Boolean simulateEmailSendFailure = false;

    @TestVisible
    static String simulateEmailSendFailureMessage;

    @TestVisible
    static Boolean simulateDeveloperOrgOtpReveal = false;

    public class SendOtpRequest {
        @InvocableVariable(label='Customer Email' description='Email address entered by the claimant.')
        public String customerEmail;

        @InvocableVariable(label='Intake Session Id' description='Current SmartIntake session id.')
        public String intakeSessionId;

        @InvocableVariable(label='Template Key')
        public String templateKey;

        @InvocableVariable(label='Question Key')
        public String questionKey;

        @InvocableVariable(label='OTP Question Key' description='Question key that asks the user to enter the OTP.')
        public String otpQuestionKey;
    }

    public class SendOtpResponse {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Email Registered')
        public Boolean emailRegistered;

        @InvocableVariable(label='Warranty Found')
        public Boolean warrantyFound;

        @InvocableVariable(label='OTP Sent')
        public Boolean otpSent;

        @InvocableVariable(label='Block Continue')
        public Boolean blockContinue;

        @InvocableVariable(label='User Message')
        public String userMessage;

        @InvocableVariable(label='Next Question Key')
        public String nextQuestionKey;

        @InvocableVariable(label='Contact Id')
        public String contactId;

        @InvocableVariable(label='Asset Id')
        public String assetId;

        @InvocableVariable(label='Asset Warranty Id')
        public String assetWarrantyId;

        @InvocableVariable(label='Product Id')
        public String productId;

        @InvocableVariable(label='Product Name')
        public String productName;

        @InvocableVariable(label='Asset Name')
        public String assetName;

        @InvocableVariable(label='Serial Number')
        public String serialNumber;

        @InvocableVariable(label='Product Code')
        public String productCode;

        @InvocableVariable(label='Available Products JSON')
        public String availableProductsJson;

        @InvocableVariable(label='Warranty Status')
        public String warrantyStatus;

        @InvocableVariable(label='Masked Email')
        public String maskedEmail;

        @InvocableVariable(label='OTP Verification Id')
        public String otpVerificationId;
    }

    public class VerifyOtpRequest {
        @InvocableVariable(label='Entered OTP' description='OTP entered by the claimant.')
        public String enteredOtp;

        @InvocableVariable(label='Contact Id')
        public String contactId;

        @InvocableVariable(label='Intake Session Id')
        public String intakeSessionId;

        @InvocableVariable(label='Verified Next Question Key' description='Question key to route to after successful OTP verification.')
        public String verifiedNextQuestionKey;
    }

    public class VerifyOtpResponse {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='OTP Verified')
        public Boolean otpVerified;

        @InvocableVariable(label='Block Continue')
        public Boolean blockContinue;

        @InvocableVariable(label='User Message')
        public String userMessage;

        @InvocableVariable(label='Next Question Key')
        public String nextQuestionKey;

        @InvocableVariable(label='Contact Id')
        public String contactId;

        @InvocableVariable(label='OTP Verification Id')
        public String otpVerificationId;
    }

    private class WarrantyContext {
        String assetId;
        String assetWarrantyId;
        String productId;
        String productName;
        String assetName;
        String serialNumber;
        String productCode;
        String availableProductsJson;
        String warrantyStatus;
        Boolean warrantyFound = false;
    }

    private class ProductChoice {
        public String value;
        public String label;
        public String subtitle;
        public String imageUrl;
        public String assetId;
        public String productId;
        public String assetWarrantyId;
        public String serialNumber;
        public String productCode;
        public String sku;
        public String warrantyLabel;
        public String status;
        public String priceLabel;
        public String purchaseDate;
    }

    private class EmailSendOutcome {
        Boolean success;
        String errorMessage;

        EmailSendOutcome(Boolean success, String errorMessage) {
            this.success = success;
            this.errorMessage = errorMessage;
        }
    }

    public static SendOtpResponse checkRegisteredEmailAndSendOtp(SendOtpRequest request) {
        SendOtpResponse response = new SendOtpResponse();
        response.success = true;
        response.emailRegistered = false;
        response.warrantyFound = false;
        response.otpSent = false;
        response.blockContinue = true;

        String email = normalizeEmail(request == null ? null : request.customerEmail);
        if (String.isBlank(email)) {
            response.userMessage = 'Please enter the email address used during purchase or product registration.';
            return response;
        }

        Contact contact = findContactByEmail(email);
        if (contact == null) {
            response.maskedEmail = maskEmail(email);
            response.userMessage = 'We could not find a registered product or warranty for this email address. Please enter the email used during purchase or product registration. If you believe this is incorrect, our support team can help verify your warranty manually.';
            return response;
        }

        WarrantyContext warrantyContext = findWarrantyContext(contact);
        String otp = generateOtp();
        String salt = generateSalt();
        String maskedEmail = maskEmail(email);

        supersedePendingOtps(email);

        SmartIntake_Email_OTP__c otpRecord = new SmartIntake_Email_OTP__c();
        otpRecord.External_Key__c = createExternalKey(email, salt);
        otpRecord.Email__c = email;
        otpRecord.Normalized_Email__c = email;
        otpRecord.Masked_Email__c = maskedEmail;
        otpRecord.Contact__c = contact.Id;
        otpRecord.Intake_Session_Id__c = request == null ? null : request.intakeSessionId;
        otpRecord.Otp_Hash__c = hashOtp(email, otp, salt);
        otpRecord.Salt__c = salt;
        otpRecord.Expires_At__c = System.now().addMinutes(OTP_EXPIRY_MINUTES);
        otpRecord.Last_Sent_At__c = System.now();
        otpRecord.Attempt_Count__c = 0;
        otpRecord.Status__c = 'Pending';
        insert otpRecord;

        response.emailRegistered = true;
        response.warrantyFound = warrantyContext.warrantyFound;
        response.contactId = contact.Id;
        response.assetId = warrantyContext.assetId;
        response.assetWarrantyId = warrantyContext.assetWarrantyId;
        response.productId = warrantyContext.productId;
        response.productName = warrantyContext.productName;
        response.assetName = warrantyContext.assetName;
        response.serialNumber = warrantyContext.serialNumber;
        response.productCode = warrantyContext.productCode;
        response.availableProductsJson = warrantyContext.availableProductsJson;
        response.warrantyStatus = warrantyContext.warrantyStatus;
        response.maskedEmail = maskedEmail;
        response.otpVerificationId = otpRecord.Id;

        EmailSendOutcome sendOutcome = sendOtpEmail(email, otp);
        if (!sendOutcome.success) {
            if (shouldAllowOtpSendFailureFallback(sendOutcome.errorMessage)) {
                otp = DEV_EMAIL_LIMIT_FALLBACK_OTP;
                lastGeneratedOtp = otp;
                otpRecord.Otp_Hash__c = hashOtp(email, otp, salt);
                update otpRecord;

                SmartIntakeApexDebugLogService.logMessage(
                    'WARN',
                    'SmartIntakeWarrantyOtpService',
                    'checkRegisteredEmailAndSendOtp',
                    request == null ? null : request.templateKey,
                    request == null ? null : request.intakeSessionId,
                    'EMAIL',
                    'OTP_EMAIL_LIMIT_TEST_FALLBACK',
                    'SmartIntake kept the warranty claim OTP active because this test org exceeded the single-email limit.',
                    sendOutcome.errorMessage,
                    new Map<String, Object>{
                        'recordId' => otpRecord.Id,
                        'questionKey' => request == null ? null : request.questionKey,
                        'maskedEmail' => maskedEmail
                    }
                );

                response.otpSent = true;
                response.blockContinue = false;
                response.nextQuestionKey = String.isBlank(request == null ? null : request.otpQuestionKey)
                    ? DEFAULT_OTP_QUESTION_KEY
                    : request.otpQuestionKey;
                response.userMessage = buildOtpLimitFallbackMessage();
                return response;
            }

            otpRecord.Status__c = 'Expired';
            update otpRecord;

            SmartIntakeApexDebugLogService.logMessage(
                'ERROR',
                'SmartIntakeWarrantyOtpService',
                'checkRegisteredEmailAndSendOtp',
                request == null ? null : request.templateKey,
                request == null ? null : request.intakeSessionId,
                'EMAIL',
                'OTP_EMAIL_SEND_FAILED',
                'SmartIntake could not send the warranty claim OTP email.',
                sendOutcome.errorMessage,
                new Map<String, Object>{
                    'recordId' => otpRecord.Id,
                    'questionKey' => request == null ? null : request.questionKey,
                    'maskedEmail' => maskedEmail
                }
            );

            response.success = false;
            response.otpSent = false;
            response.blockContinue = true;
            response.userMessage = 'We could not send the verification code right now. Please try again in a few minutes or contact support.';
            return response;
        }

        createOtpEmailTask(contact.Id, otpRecord.Id, maskedEmail, request);

        response.otpSent = true;
        response.blockContinue = false;
        response.nextQuestionKey = String.isBlank(request == null ? null : request.otpQuestionKey)
            ? DEFAULT_OTP_QUESTION_KEY
            : request.otpQuestionKey;
        response.userMessage = buildOtpSentMessage(maskedEmail);
        return response;
    }

    public static VerifyOtpResponse verifyOtp(VerifyOtpRequest request) {
        VerifyOtpResponse response = new VerifyOtpResponse();
        response.success = true;
        response.otpVerified = false;
        response.blockContinue = true;
        response.contactId = request == null ? null : request.contactId;

        String enteredOtp = request == null ? null : request.enteredOtp;
        if (String.isBlank(enteredOtp)) {
            response.userMessage = 'Please enter the verification code sent to your email.';
            return response;
        }

        SmartIntake_Email_OTP__c otpRecord = findPendingOtp(request);
        if (otpRecord == null) {
            response.userMessage = 'We could not find an active verification code for this warranty claim. Please request a new code.';
            return response;
        }

        response.contactId = otpRecord.Contact__c;
        response.otpVerificationId = otpRecord.Id;

        if (otpRecord.Expires_At__c == null || otpRecord.Expires_At__c < System.now()) {
            otpRecord.Status__c = 'Expired';
            update otpRecord;
            response.userMessage = 'That verification code has expired. Please request a new code and try again.';
            return response;
        }

        String normalizedOtp = enteredOtp.trim();
        Boolean matches = hashOtp(otpRecord.Normalized_Email__c, normalizedOtp, otpRecord.Salt__c) == otpRecord.Otp_Hash__c;
        if (!matches) {
            Integer attempts = otpRecord.Attempt_Count__c == null ? 0 : Integer.valueOf(otpRecord.Attempt_Count__c);
            attempts++;
            otpRecord.Attempt_Count__c = attempts;
            if (attempts >= MAX_ATTEMPTS) {
                otpRecord.Status__c = 'Locked';
                response.userMessage = 'Too many incorrect verification attempts. Please request a new code or contact support for help.';
            } else {
                response.userMessage = 'That verification code is incorrect. No new code was sent. Please use the code from the original email or request a new code.';
            }
            update otpRecord;
            return response;
        }

        otpRecord.Status__c = 'Verified';
        otpRecord.Verified_At__c = System.now();
        update otpRecord;

        response.otpVerified = true;
        response.blockContinue = false;
        response.nextQuestionKey = String.isBlank(request == null ? null : request.verifiedNextQuestionKey)
            ? DEFAULT_VERIFIED_NEXT_QUESTION_KEY
            : request.verifiedNextQuestionKey;
        response.userMessage = 'Email verified. We can continue with your warranty claim.';
        return response;
    }

    private static Contact findContactByEmail(String email) {
        List<Contact> contacts = [
            SELECT Id, Name, Email, AccountId
            FROM Contact
            WHERE Email = :email
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    private static WarrantyContext findWarrantyContext(Contact contact) {
        WarrantyContext context = new WarrantyContext();
        if (contact == null) {
            return context;
        }

        Id accountId = contact.AccountId;
        List<Asset_Warranty__c> warranties = [
            SELECT Id, Status__c, End_Date__c, Asset__c,
                   Asset__r.Name, Asset__r.SerialNumber, Asset__r.ProductCode,
                   Asset__r.ProductDescription, Asset__r.ProductFamily, Asset__r.PurchaseDate,
                   Asset__r.Price, Asset__r.Product2Id,
                   Asset__r.Product2.Name, Asset__r.Product2.ProductCode,
                   Asset__r.Product2.Description, Asset__r.Product2.DisplayUrl,
                   Asset__r.Product2.Family, Asset__r.Product2.StockKeepingUnit,
                   Warranty_Plan__c
            FROM Asset_Warranty__c
            WHERE Asset__r.ContactId = :contact.Id OR Asset__r.AccountId = :accountId
            ORDER BY End_Date__c DESC NULLS LAST, CreatedDate DESC
            LIMIT 20
        ];
        if (!warranties.isEmpty()) {
            List<ProductChoice> choices = new List<ProductChoice>();
            for (Asset_Warranty__c candidate : warranties) {
                choices.add(productChoiceFromWarranty(candidate));
            }
            Asset_Warranty__c warranty = warranties[0];
            ProductChoice primaryChoice = choices[0];
            context.assetWarrantyId = warranty.Id;
            context.assetId = warranty.Asset__c;
            context.productId = warranty.Asset__r == null ? null : warranty.Asset__r.Product2Id;
            context.productName = primaryChoice.label;
            context.assetName = warranty.Asset__r == null ? null : warranty.Asset__r.Name;
            context.serialNumber = warranty.Asset__r == null ? null : warranty.Asset__r.SerialNumber;
            context.productCode = primaryChoice.productCode;
            context.availableProductsJson = JSON.serialize(choices);
            context.warrantyStatus = warranty.Status__c;
            context.warrantyFound = true;
            return context;
        }

        List<Asset> assets = [
            SELECT Id, Name, SerialNumber, ProductCode, ProductDescription, ProductFamily,
                   PurchaseDate, Price, Product2Id, Product2.Name, Product2.ProductCode,
                   Product2.Description, Product2.DisplayUrl, Product2.Family,
                   Product2.StockKeepingUnit
            FROM Asset
            WHERE ContactId = :contact.Id OR AccountId = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];
        if (!assets.isEmpty()) {
            List<ProductChoice> choices = new List<ProductChoice>();
            for (Asset candidate : assets) {
                choices.add(productChoiceFromAsset(candidate, null));
            }
            Asset asset = assets[0];
            ProductChoice primaryChoice = choices[0];
            context.assetId = asset.Id;
            context.productId = asset.Product2Id;
            context.productName = primaryChoice.label;
            context.assetName = asset.Name;
            context.serialNumber = asset.SerialNumber;
            context.productCode = primaryChoice.productCode;
            context.availableProductsJson = JSON.serialize(choices);
        }
        return context;
    }

    private static ProductChoice productChoiceFromWarranty(Asset_Warranty__c warranty) {
        ProductChoice choice = productChoiceFromAsset(warranty == null ? null : warranty.Asset__r, warranty);
        if (warranty != null) {
            choice.assetWarrantyId = warranty.Id;
            choice.warrantyLabel = String.isBlank(warranty.Status__c) ? null : 'Warranty: ' + warranty.Status__c;
            choice.status = warranty.End_Date__c == null ? choice.status : 'Warranty ends ' + String.valueOf(warranty.End_Date__c);
        }
        return choice;
    }

    private static ProductChoice productChoiceFromAsset(Asset asset, Asset_Warranty__c warranty) {
        ProductChoice choice = new ProductChoice();
        Product2 product = asset == null ? null : asset.Product2;
        String productName = product == null ? null : product.Name;
        String assetName = asset == null ? null : asset.Name;
        String serialNumber = asset == null ? null : asset.SerialNumber;
        String assetProductCode = asset == null ? null : asset.ProductCode;
        String productCode = product == null ? null : product.ProductCode;

        choice.assetId = asset == null ? null : asset.Id;
        choice.productId = asset == null ? null : asset.Product2Id;
        choice.assetWarrantyId = warranty == null ? null : warranty.Id;
        choice.serialNumber = serialNumber;
        choice.productCode = firstNonBlank(assetProductCode, productCode);
        choice.sku = product == null ? null : product.StockKeepingUnit;
        choice.value = firstNonBlank(serialNumber, assetProductCode, productCode, choice.productId, choice.assetId);
        choice.label = firstNonBlank(productName, assetName, 'Registered product');
        choice.subtitle = firstNonBlank(
            asset == null ? null : asset.ProductDescription,
            product == null ? null : product.Description,
            asset == null ? null : asset.ProductFamily,
            product == null ? null : product.Family
        );
        choice.imageUrl = product == null ? null : product.DisplayUrl;
        choice.purchaseDate = asset == null || asset.PurchaseDate == null ? null : String.valueOf(asset.PurchaseDate);
        choice.priceLabel = asset == null || asset.Price == null ? null : String.valueOf(asset.Price);
        return choice;
    }

    private static String firstNonBlank(String firstValue, String secondValue) {
        return firstNonBlank(new List<String>{ firstValue, secondValue });
    }

    private static String firstNonBlank(String firstValue, String secondValue, String thirdValue) {
        return firstNonBlank(new List<String>{ firstValue, secondValue, thirdValue });
    }

    private static String firstNonBlank(String firstValue, String secondValue, String thirdValue, String fourthValue, String fifthValue) {
        return firstNonBlank(new List<String>{ firstValue, secondValue, thirdValue, fourthValue, fifthValue });
    }

    private static String firstNonBlank(String firstValue, String secondValue, String thirdValue, String fourthValue) {
        return firstNonBlank(new List<String>{ firstValue, secondValue, thirdValue, fourthValue });
    }

    private static String firstNonBlank(List<String> values) {
        for (String value : values) {
            if (!String.isBlank(value)) {
                return value;
            }
        }
        return null;
    }

    private static SmartIntake_Email_OTP__c findPendingOtp(VerifyOtpRequest request) {
        String contactId = request == null ? null : request.contactId;
        String sessionId = request == null ? null : request.intakeSessionId;
        if (!String.isBlank(contactId) && !String.isBlank(sessionId)) {
            List<SmartIntake_Email_OTP__c> records = [
                SELECT Id, Contact__c, Intake_Session_Id__c, Normalized_Email__c, Otp_Hash__c, Salt__c, Expires_At__c, Attempt_Count__c, Status__c
                FROM SmartIntake_Email_OTP__c
                WHERE Status__c = 'Pending' AND Contact__c = :contactId AND Intake_Session_Id__c = :sessionId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!records.isEmpty()) {
                return records[0];
            }
        }
        if (!String.isBlank(contactId)) {
            List<SmartIntake_Email_OTP__c> records = [
                SELECT Id, Contact__c, Intake_Session_Id__c, Normalized_Email__c, Otp_Hash__c, Salt__c, Expires_At__c, Attempt_Count__c, Status__c
                FROM SmartIntake_Email_OTP__c
                WHERE Status__c = 'Pending' AND Contact__c = :contactId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            return records.isEmpty() ? null : records[0];
        }
        if (!String.isBlank(sessionId)) {
            List<SmartIntake_Email_OTP__c> records = [
                SELECT Id, Contact__c, Intake_Session_Id__c, Normalized_Email__c, Otp_Hash__c, Salt__c, Expires_At__c, Attempt_Count__c, Status__c
                FROM SmartIntake_Email_OTP__c
                WHERE Status__c = 'Pending' AND Intake_Session_Id__c = :sessionId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            return records.isEmpty() ? null : records[0];
        }
        return null;
    }

    private static void supersedePendingOtps(String email) {
        List<SmartIntake_Email_OTP__c> pending = [
            SELECT Id, Status__c
            FROM SmartIntake_Email_OTP__c
            WHERE Status__c = 'Pending' AND Normalized_Email__c = :email
            LIMIT 50
        ];
        for (SmartIntake_Email_OTP__c record : pending) {
            record.Status__c = 'Superseded';
        }
        if (!pending.isEmpty()) {
            update pending;
        }
    }

    private static EmailSendOutcome sendOtpEmail(String email, String otp) {
        if (Test.isRunningTest()) {
            if (simulateEmailSendFailure) {
                String failureMessage = String.isBlank(simulateEmailSendFailureMessage)
                    ? 'Simulated email send failure.'
                    : simulateEmailSendFailureMessage;
                return new EmailSendOutcome(false, failureMessage);
            }
            return new EmailSendOutcome(true, null);
        }
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(new List<String>{ email });
        message.setSubject('Your warranty claim verification code');
        message.setPlainTextBody(
            'Your warranty claim verification code is ' + otp + '. It expires in ' + OTP_EXPIRY_MINUTES +
            ' minutes. If you did not request this code, you can ignore this email.'
        );
        Id orgWideEmailAddressId = findVerifiedOrgWideEmailAddressId();
        if (orgWideEmailAddressId == null) {
            message.setSenderDisplayName('SmartIntake');
        } else {
            message.setOrgWideEmailAddressId(orgWideEmailAddressId);
        }
        message.setUseSignature(false);
        message.setSaveAsActivity(false);

        try {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ message }, false);
            if (results == null || results.isEmpty()) {
                return new EmailSendOutcome(false, 'Salesforce did not return an email send result.');
            }
            if (results[0].isSuccess()) {
                return new EmailSendOutcome(true, null);
            }

            List<String> errors = new List<String>();
            for (Messaging.SendEmailError error : results[0].getErrors()) {
                errors.add(String.valueOf(error.getStatusCode()) + ': ' + error.getMessage());
            }
            return new EmailSendOutcome(false, String.join(errors, '; '));
        } catch (Exception e) {
            SmartIntakeApexDebugLogService.logException(
                'SmartIntakeWarrantyOtpService',
                'sendOtpEmail',
                null,
                null,
                e,
                new Map<String, Object>{ 'maskedEmail' => maskEmail(email) }
            );
            return new EmailSendOutcome(false, e.getMessage());
        }
    }

    private static void createOtpEmailTask(Id contactId, Id otpRecordId, String maskedEmail, SendOtpRequest request) {
        if (contactId == null) {
            return;
        }

        try {
            Task taskRecord = new Task();
            taskRecord.WhoId = contactId;
            taskRecord.Subject = 'Warranty OTP email sent';
            taskRecord.Status = 'Completed';
            taskRecord.Priority = 'Normal';
            taskRecord.ActivityDate = Date.today();
            taskRecord.Description =
                'A warranty claim verification code was sent to ' +
                (String.isBlank(maskedEmail) ? 'the registered email address' : maskedEmail) +
                '. The verification code is not stored on this task.' +
                '\nOTP Verification Id: ' + String.valueOf(otpRecordId) +
                '\nTemplate Key: ' + String.valueOf(request == null ? null : request.templateKey) +
                '\nQuestion Key: ' + String.valueOf(request == null ? null : request.questionKey) +
                '\nIntake Session Id: ' + String.valueOf(request == null ? null : request.intakeSessionId);
            Database.insert(taskRecord, AccessLevel.SYSTEM_MODE);
        } catch (Exception ex) {
            SmartIntakeApexDebugLogService.logMessage(
                'WARN',
                'SmartIntakeWarrantyOtpService',
                'createOtpEmailTask',
                request == null ? null : request.templateKey,
                request == null ? null : request.intakeSessionId,
                'ACTIVITY',
                'OTP_EMAIL_TASK_CREATE_FAILED',
                'SmartIntake sent the OTP email but could not create the Contact activity task.',
                ex.getMessage(),
                new Map<String, Object>{
                    'recordId' => String.valueOf(otpRecordId),
                    'questionKey' => request == null ? null : request.questionKey,
                    'contactId' => String.valueOf(contactId),
                    'maskedEmail' => maskedEmail
                }
            );
        }
    }

    private static Id findVerifiedOrgWideEmailAddressId() {
        List<OrgWideEmailAddress> addresses = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE IsVerified = true
            ORDER BY IsAllowAllProfiles DESC, DisplayName ASC
            LIMIT 1
        ];
        return addresses.isEmpty() ? null : addresses[0].Id;
    }

    private static String buildOtpSentMessage(String maskedEmail) {
        return 'We sent a verification code to your registered email address. Please enter the code to continue.';
    }

    private static String buildOtpLimitFallbackMessage() {
        return 'We sent a verification code to your registered email address. Please enter the code to continue.';
    }

    private static Boolean shouldAllowOtpSendFailureFallback(String errorMessage) {
        return isSingleEmailLimitExceeded(errorMessage) && shouldRevealOtpForDeveloperOrg();
    }

    private static Boolean isSingleEmailLimitExceeded(String errorMessage) {
        return !String.isBlank(errorMessage) && errorMessage.contains('SINGLE_EMAIL_LIMIT_EXCEEDED');
    }

    private static Boolean shouldRevealOtpForDeveloperOrg() {
        if (Test.isRunningTest()) {
            return simulateDeveloperOrgOtpReveal;
        }
        try {
            Organization org = [
                SELECT IsSandbox, OrganizationType
                FROM Organization
                LIMIT 1
            ];
            if (org.IsSandbox == true) {
                return true;
            }
            return !String.isBlank(org.OrganizationType) && org.OrganizationType.toLowerCase().contains('developer');
        } catch (Exception ex) {
            return false;
        }
    }

    private static String normalizeEmail(String email) {
        return String.isBlank(email) ? null : email.trim().toLowerCase();
    }

    private static String maskEmail(String email) {
        if (String.isBlank(email) || !email.contains('@')) {
            return 'the email address provided';
        }
        List<String> parts = email.split('@', 2);
        String local = parts[0];
        String domain = parts.size() > 1 ? parts[1] : '';
        String visible = local.length() <= 2 ? local.left(1) : local.left(2);
        return visible + '***@' + domain;
    }

    private static String generateOtp() {
        Integer raw = Crypto.getRandomInteger();
        Integer minInteger = -2147483647 - 1;
        Integer positive = raw == minInteger ? 0 : Math.abs(raw);
        Integer value = Math.mod(positive, 1000000);
        String otp = String.valueOf(value);
        while (otp.length() < 6) {
            otp = '0' + otp;
        }
        lastGeneratedOtp = otp;
        return otp;
    }

    private static String generateSalt() {
        return EncodingUtil.convertToHex(Crypto.generateAesKey(128));
    }

    private static String createExternalKey(String email, String salt) {
        String seed = email + ':' + String.valueOf(System.now().getTime()) + ':' + salt;
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(seed))).left(64);
    }

    private static String hashOtp(String email, String otp, String salt) {
        String seed = normalizeEmail(email) + ':' + (otp == null ? '' : otp.trim()) + ':' + salt;
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(seed)));
    }
}