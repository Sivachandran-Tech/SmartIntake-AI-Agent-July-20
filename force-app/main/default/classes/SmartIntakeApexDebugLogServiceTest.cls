@IsTest
private class SmartIntakeApexDebugLogServiceTest {
    @IsTest
    static void logSmartIntakeExceptionCreatesDebugRecord() {
        SmartIntakeException ex = new SmartIntakeException(
            'SAVE',
            'FINAL_SAVE_FAILED',
            'Could not save.',
            'Warranty_Claim__c.Asset__c was not writable.'
        );

        Test.startTest();
        SmartIntakeApexDebugLogService.logSmartIntakeException(
            'SmartIntakeService',
            'saveFinal',
            'LAPTOP_WARRANTY_CLAIM',
            'SI-123',
            ex,
            new Map<String, Object>{
                'objectApiName' => 'Warranty_Claim__c',
                'fieldApiName' => 'Asset__c',
                'questionKey' => 'CLAIM_SERIAL_NUMBER',
                'status' => 'Failed'
            }
        );
        Test.stopTest();

        Apex_Debug_Log__c logRecord = [
            SELECT Severity__c, Source__c, Error_Type__c, Error_Code__c, Template_Key__c,
                Intake_Session_Id__c, Object_API_Name__c, Field_API_Name__c, Question_Key__c
            FROM Apex_Debug_Log__c
            LIMIT 1
        ];
        System.assertEquals('ERROR', logRecord.Severity__c);
        System.assertEquals('SmartIntakeService.saveFinal', logRecord.Source__c);
        System.assertEquals('SAVE', logRecord.Error_Type__c);
        System.assertEquals('FINAL_SAVE_FAILED', logRecord.Error_Code__c);
        System.assertEquals('LAPTOP_WARRANTY_CLAIM', logRecord.Template_Key__c);
        System.assertEquals('SI-123', logRecord.Intake_Session_Id__c);
        System.assertEquals('Warranty_Claim__c', logRecord.Object_API_Name__c);
        System.assertEquals('Asset__c', logRecord.Field_API_Name__c);
        System.assertEquals('CLAIM_SERIAL_NUMBER', logRecord.Question_Key__c);
    }

    @IsTest
    static void logExceptionCreatesDebugRecord() {
        try {
            Integer divisor = 0;
            Integer ignored = 1 / divisor;
            System.assertEquals(0, ignored);
        } catch (Exception ex) {
            SmartIntakeApexDebugLogService.logException(
                'SmartIntakeHookService',
                'executeFlow',
                'TEST_TEMPLATE',
                'SI-456',
                ex,
                new Map<String, Object>{ 'flowApiName' => 'Broken_Flow' }
            );
        }

        Apex_Debug_Log__c logRecord = [
            SELECT Source__c, Error_Code__c, Context_JSON__c, Stack_Trace__c
            FROM Apex_Debug_Log__c
            WHERE Source__c = 'SmartIntakeHookService.executeFlow'
            LIMIT 1
        ];
        System.assertEquals('UNEXPECTED_ERROR', logRecord.Error_Code__c);
        System.assert(logRecord.Context_JSON__c.contains('Broken_Flow'));
        System.assertNotEquals(null, logRecord.Stack_Trace__c);
    }
}