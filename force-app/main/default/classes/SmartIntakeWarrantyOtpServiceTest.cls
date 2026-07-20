@IsTest
private class SmartIntakeWarrantyOtpServiceTest {
    @IsTest
    static void sendsOtpForRegisteredContactAndVerifiesCode() {
        Account account = new Account(Name = 'Warranty Customer');
        insert account;

        Contact contact = new Contact(
            LastName = 'Customer',
            Email = 'customer@example.com',
            AccountId = account.Id
        );
        insert contact;

        Product2 product = new Product2(Name = 'Laptop Pro 15', ProductCode = 'LT-PRO15', IsActive = true);
        insert product;

        Asset asset = new Asset(
            Name = 'Laptop Pro 15',
            AccountId = account.Id,
            ContactId = contact.Id,
            Product2Id = product.Id,
            SerialNumber = 'LT-PRO15-TEST-001'
        );
        insert asset;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Asset__c = asset.Id,
            Status__c = 'Active',
            Start_Date__c = Date.today().addMonths(-1),
            End_Date__c = Date.today().addYears(1)
        );
        insert warranty;

        SmartIntakeWarrantyOtpService.SendOtpRequest sendRequest = new SmartIntakeWarrantyOtpService.SendOtpRequest();
        sendRequest.customerEmail = 'Customer@Example.com';
        sendRequest.intakeSessionId = 'session-001';
        sendRequest.otpQuestionKey = 'VERIFY_EMAIL_OTP';

        SmartIntakeWarrantyOtpService.SendOtpResponse sendResponse;
        Test.startTest();
        sendResponse = SmartIntakeWarrantyEmailOtpAction.invoke(new List<SmartIntakeWarrantyOtpService.SendOtpRequest>{ sendRequest })[0];
        Test.stopTest();

        System.assertEquals(true, sendResponse.emailRegistered);
        System.assertEquals(true, sendResponse.otpSent);
        System.assertEquals(false, sendResponse.blockContinue);
        System.assertEquals(contact.Id, sendResponse.contactId);
        System.assertEquals(asset.Id, sendResponse.assetId);
        System.assertEquals(warranty.Id, sendResponse.assetWarrantyId);
        System.assertEquals(product.Id, sendResponse.productId);
        System.assertEquals('Laptop Pro 15', sendResponse.productName);
        System.assertEquals('Laptop Pro 15', sendResponse.assetName);
        System.assertEquals('LT-PRO15-TEST-001', sendResponse.serialNumber);
        System.assertEquals('LT-PRO15', sendResponse.productCode);
        System.assertNotEquals(null, sendResponse.availableProductsJson);
        List<Object> availableProducts = (List<Object>) JSON.deserializeUntyped(sendResponse.availableProductsJson);
        System.assertEquals(1, availableProducts.size());
        Map<String, Object> availableProduct = (Map<String, Object>) availableProducts[0];
        System.assertEquals('Laptop Pro 15', availableProduct.get('label'));
        System.assertEquals('LT-PRO15-TEST-001', availableProduct.get('value'));
        System.assertEquals('Warranty: Active', availableProduct.get('warrantyLabel'));
        System.assertEquals('VERIFY_EMAIL_OTP', sendResponse.nextQuestionKey);
        System.assertNotEquals(null, sendResponse.otpVerificationId);
        System.assert(!sendResponse.userMessage.contains(SmartIntakeWarrantyOtpService.lastGeneratedOtp), sendResponse.userMessage);
        System.assert(!sendResponse.userMessage.contains('000000'), sendResponse.userMessage);

        SmartIntake_Email_OTP__c otpRecord = [
            SELECT Id, Status__c, Otp_Hash__c, Email__c, Normalized_Email__c, Masked_Email__c
            FROM SmartIntake_Email_OTP__c
            WHERE Id = :sendResponse.otpVerificationId
        ];
        System.assertEquals('Pending', otpRecord.Status__c);
        System.assertEquals('customer@example.com', otpRecord.Normalized_Email__c);
        System.assertNotEquals(SmartIntakeWarrantyOtpService.lastGeneratedOtp, otpRecord.Otp_Hash__c);

        List<Task> otpTasks = [
            SELECT Id, WhoId, Subject, Status, Priority, ActivityDate, Description
            FROM Task
            WHERE WhoId = :contact.Id AND Subject = 'Warranty OTP email sent'
        ];
        System.assertEquals(1, otpTasks.size());
        System.assertEquals('Completed', otpTasks[0].Status);
        System.assertEquals('Normal', otpTasks[0].Priority);
        System.assertEquals(Date.today(), otpTasks[0].ActivityDate);
        System.assert(otpTasks[0].Description.contains(String.valueOf(otpRecord.Id)), otpTasks[0].Description);
        System.assert(otpTasks[0].Description.contains('cu***@example.com'), otpTasks[0].Description);
        System.assert(!otpTasks[0].Description.contains(SmartIntakeWarrantyOtpService.lastGeneratedOtp), otpTasks[0].Description);

        SmartIntakeWarrantyOtpService.VerifyOtpRequest verifyRequest = new SmartIntakeWarrantyOtpService.VerifyOtpRequest();
        verifyRequest.enteredOtp = SmartIntakeWarrantyOtpService.lastGeneratedOtp;
        verifyRequest.contactId = contact.Id;
        verifyRequest.intakeSessionId = 'session-001';
        verifyRequest.verifiedNextQuestionKey = 'CLAIM_SERIAL_NUMBER';

        SmartIntakeWarrantyOtpService.VerifyOtpResponse verifyResponse =
            SmartIntakeWarrantyVerifyOtpAction.invoke(new List<SmartIntakeWarrantyOtpService.VerifyOtpRequest>{ verifyRequest })[0];

        System.assertEquals(true, verifyResponse.otpVerified);
        System.assertEquals(false, verifyResponse.blockContinue);
        System.assertEquals('CLAIM_SERIAL_NUMBER', verifyResponse.nextQuestionKey);

        otpRecord = [SELECT Status__c, Verified_At__c FROM SmartIntake_Email_OTP__c WHERE Id = :otpRecord.Id];
        System.assertEquals('Verified', otpRecord.Status__c);
        System.assertNotEquals(null, otpRecord.Verified_At__c);
    }

    @IsTest
    static void blocksWhenEmailIsNotRegistered() {
        SmartIntakeWarrantyOtpService.SendOtpRequest request = new SmartIntakeWarrantyOtpService.SendOtpRequest();
        request.customerEmail = 'missing@example.com';

        SmartIntakeWarrantyOtpService.SendOtpResponse response =
            SmartIntakeWarrantyOtpService.checkRegisteredEmailAndSendOtp(request);

        System.assertEquals(false, response.emailRegistered);
        System.assertEquals(false, response.otpSent);
        System.assertEquals(true, response.blockContinue);
        System.assert(response.userMessage.contains('registered product or warranty'), response.userMessage);
    }

    @IsTest
    static void asksForEmailWhenBlank() {
        SmartIntakeWarrantyOtpService.SendOtpResponse response =
            SmartIntakeWarrantyOtpService.checkRegisteredEmailAndSendOtp(new SmartIntakeWarrantyOtpService.SendOtpRequest());

        System.assertEquals(false, response.emailRegistered);
        System.assertEquals(false, response.otpSent);
        System.assertEquals(true, response.blockContinue);
        System.assert(response.userMessage.contains('Please enter'), response.userMessage);
    }

    @IsTest
    static void sendsOtpWhenRegisteredContactHasAssetOnly() {
        Account account = new Account(Name = 'Asset Only Customer');
        insert account;

        Contact contact = new Contact(
            LastName = 'Asset Only',
            Email = 'assetonly@example.com',
            AccountId = account.Id
        );
        insert contact;

        Product2 product = new Product2(Name = 'Laptop Air 13', IsActive = true);
        insert product;

        Asset asset = new Asset(
            Name = 'Laptop Air 13',
            AccountId = account.Id,
            ContactId = contact.Id,
            Product2Id = product.Id,
            SerialNumber = 'LT-AIR13-TEST-001'
        );
        insert asset;

        SmartIntakeWarrantyOtpService.SendOtpRequest request = new SmartIntakeWarrantyOtpService.SendOtpRequest();
        request.customerEmail = 'assetonly@example.com';
        request.intakeSessionId = 'asset-only-session';

        SmartIntakeWarrantyOtpService.SendOtpResponse response =
            SmartIntakeWarrantyOtpService.checkRegisteredEmailAndSendOtp(request);

        System.assertEquals(true, response.emailRegistered);
        System.assertEquals(false, response.warrantyFound);
        System.assertEquals(true, response.otpSent);
        System.assertEquals(asset.Id, response.assetId);
        System.assertEquals(product.Id, response.productId);
        System.assertEquals('Laptop Air 13', response.productName);
        System.assertEquals('LT-AIR13-TEST-001', response.serialNumber);
        System.assert(response.availableProductsJson.contains('Laptop Air 13'), response.availableProductsJson);
        System.assertEquals('VERIFY_EMAIL_OTP', response.nextQuestionKey);

        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhoId = :contact.Id AND Subject = 'Warranty OTP email sent'
        ];
        System.assertEquals(1, taskCount);
    }

    @IsTest
    static void blocksWhenEmailSendFails() {
        Contact contact = new Contact(LastName = 'Email Failure', Email = 'failure@example.com');
        insert contact;

        SmartIntakeWarrantyOtpService.SendOtpRequest request = new SmartIntakeWarrantyOtpService.SendOtpRequest();
        request.customerEmail = 'failure@example.com';
        request.intakeSessionId = 'send-failure-session';

        SmartIntakeWarrantyOtpService.simulateEmailSendFailure = true;
        SmartIntakeWarrantyOtpService.SendOtpResponse response;
        try {
            response = SmartIntakeWarrantyOtpService.checkRegisteredEmailAndSendOtp(request);
        } finally {
            SmartIntakeWarrantyOtpService.simulateEmailSendFailure = false;
        }

        System.assertEquals(false, response.success);
        System.assertEquals(true, response.emailRegistered);
        System.assertEquals(false, response.otpSent);
        System.assertEquals(true, response.blockContinue);
        System.assert(response.userMessage.contains('could not send'), response.userMessage);

        SmartIntake_Email_OTP__c otpRecord = [
            SELECT Status__c
            FROM SmartIntake_Email_OTP__c
            WHERE Id = :response.otpVerificationId
        ];
        System.assertEquals('Expired', otpRecord.Status__c);

        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhoId = :contact.Id AND Subject = 'Warranty OTP email sent'
        ];
        System.assertEquals(0, taskCount);
    }

    @IsTest
    static void keepsOtpActiveForDeveloperOrgEmailLimitFallback() {
        Contact contact = new Contact(LastName = 'Email Limit', Email = 'limit@example.com');
        insert contact;

        SmartIntakeWarrantyOtpService.SendOtpRequest request = new SmartIntakeWarrantyOtpService.SendOtpRequest();
        request.customerEmail = 'limit@example.com';
        request.intakeSessionId = 'email-limit-session';
        request.otpQuestionKey = 'VERIFY_EMAIL_OTP';

        SmartIntakeWarrantyOtpService.simulateEmailSendFailure = true;
        SmartIntakeWarrantyOtpService.simulateEmailSendFailureMessage = 'SINGLE_EMAIL_LIMIT_EXCEEDED: Email limit exceeded.';
        SmartIntakeWarrantyOtpService.simulateDeveloperOrgOtpReveal = true;

        SmartIntakeWarrantyOtpService.SendOtpResponse response;
        try {
            response = SmartIntakeWarrantyOtpService.checkRegisteredEmailAndSendOtp(request);
        } finally {
            SmartIntakeWarrantyOtpService.simulateEmailSendFailure = false;
            SmartIntakeWarrantyOtpService.simulateEmailSendFailureMessage = null;
            SmartIntakeWarrantyOtpService.simulateDeveloperOrgOtpReveal = false;
        }

        System.assertEquals(true, response.success);
        System.assertEquals(true, response.emailRegistered);
        System.assertEquals(true, response.otpSent);
        System.assertEquals(false, response.blockContinue);
        System.assertEquals('VERIFY_EMAIL_OTP', response.nextQuestionKey);
        System.assert(response.userMessage.contains('verification code'), response.userMessage);
        System.assert(!response.userMessage.contains('000000'), response.userMessage);
        System.assert(!response.userMessage.contains('test verification code'), response.userMessage);
        System.assertEquals('000000', SmartIntakeWarrantyOtpService.lastGeneratedOtp);

        SmartIntake_Email_OTP__c otpRecord = [
            SELECT Status__c
            FROM SmartIntake_Email_OTP__c
            WHERE Id = :response.otpVerificationId
        ];
        System.assertEquals('Pending', otpRecord.Status__c);

        SmartIntakeWarrantyOtpService.VerifyOtpRequest verifyRequest = new SmartIntakeWarrantyOtpService.VerifyOtpRequest();
        verifyRequest.enteredOtp = '000000';
        verifyRequest.contactId = contact.Id;
        verifyRequest.intakeSessionId = 'email-limit-session';
        SmartIntakeWarrantyOtpService.VerifyOtpResponse verifyResponse = SmartIntakeWarrantyOtpService.verifyOtp(verifyRequest);
        System.assertEquals(true, verifyResponse.otpVerified);

        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhoId = :contact.Id AND Subject = 'Warranty OTP email sent'
        ];
        System.assertEquals(0, taskCount);
    }

    @IsTest
    static void verifyOtpHandlesBlankMissingAndExpiredCodes() {
        SmartIntakeWarrantyOtpService.VerifyOtpResponse blankResponse =
            SmartIntakeWarrantyOtpService.verifyOtp(new SmartIntakeWarrantyOtpService.VerifyOtpRequest());
        System.assertEquals(false, blankResponse.otpVerified);
        System.assert(blankResponse.userMessage.contains('Please enter'), blankResponse.userMessage);

        Contact contact = new Contact(LastName = 'Expired Code', Email = 'expired@example.com');
        insert contact;

        SmartIntakeWarrantyOtpService.VerifyOtpRequest missingRequest = new SmartIntakeWarrantyOtpService.VerifyOtpRequest();
        missingRequest.enteredOtp = '123456';
        missingRequest.contactId = contact.Id;

        SmartIntakeWarrantyOtpService.VerifyOtpResponse missingResponse =
            SmartIntakeWarrantyOtpService.verifyOtp(missingRequest);
        System.assertEquals(false, missingResponse.otpVerified);
        System.assert(missingResponse.userMessage.contains('active verification code'), missingResponse.userMessage);

        SmartIntake_Email_OTP__c otpRecord = new SmartIntake_Email_OTP__c(
            External_Key__c = 'expired-code-test',
            Contact__c = contact.Id,
            Email__c = 'expired@example.com',
            Normalized_Email__c = 'expired@example.com',
            Masked_Email__c = 'ex***@example.com',
            Salt__c = 'expired-salt',
            Otp_Hash__c = 'expired-hash',
            Expires_At__c = System.now().addMinutes(-1),
            Attempt_Count__c = 0,
            Status__c = 'Pending'
        );
        insert otpRecord;

        SmartIntakeWarrantyOtpService.VerifyOtpResponse expiredResponse =
            SmartIntakeWarrantyOtpService.verifyOtp(missingRequest);
        System.assertEquals(false, expiredResponse.otpVerified);
        System.assert(expiredResponse.userMessage.contains('expired'), expiredResponse.userMessage);

        otpRecord = [SELECT Status__c FROM SmartIntake_Email_OTP__c WHERE Id = :otpRecord.Id];
        System.assertEquals('Expired', otpRecord.Status__c);
    }

    @IsTest
    static void locksAfterThreeWrongOtpAttempts() {
        Contact contact = new Contact(LastName = 'Wrong Code', Email = 'wrong@example.com');
        insert contact;

        SmartIntake_Email_OTP__c otpRecord = new SmartIntake_Email_OTP__c(
            External_Key__c = 'wrong-code-test',
            Contact__c = contact.Id,
            Email__c = 'wrong@example.com',
            Normalized_Email__c = 'wrong@example.com',
            Masked_Email__c = 'wr***@example.com',
            Salt__c = 'test-salt',
            Otp_Hash__c = 'not-the-hash',
            Expires_At__c = System.now().addMinutes(10),
            Attempt_Count__c = 0,
            Status__c = 'Pending'
        );
        insert otpRecord;

        SmartIntakeWarrantyOtpService.VerifyOtpRequest request = new SmartIntakeWarrantyOtpService.VerifyOtpRequest();
        request.enteredOtp = '000000';
        request.contactId = contact.Id;

        SmartIntakeWarrantyOtpService.verifyOtp(request);
        SmartIntakeWarrantyOtpService.verifyOtp(request);
        SmartIntakeWarrantyOtpService.VerifyOtpResponse thirdResponse =
            SmartIntakeWarrantyOtpService.verifyOtp(request);

        System.assertEquals(false, thirdResponse.otpVerified);
        System.assertEquals(true, thirdResponse.blockContinue);

        otpRecord = [SELECT Status__c, Attempt_Count__c FROM SmartIntake_Email_OTP__c WHERE Id = :otpRecord.Id];
        System.assertEquals('Locked', otpRecord.Status__c);
        System.assertEquals(3, Integer.valueOf(otpRecord.Attempt_Count__c));
    }
}