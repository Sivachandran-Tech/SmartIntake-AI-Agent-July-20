@IsTest
private class SmartIntakeResolveCtxActionTest {
    @IsTest
    static void resolvesHotelBookingWelcomeFromMetadata() {
        SmartIntakeResolveMessagingContextAction.Request request =
            new SmartIntakeResolveMessagingContextAction.Request();
        request.currentPage = 'HOTEL_BOOKING_PAGE';

        List<SmartIntakeResolveMessagingContextAction.Response> responses =
            SmartIntakeResolveMessagingContextAction.invoke(
                new List<SmartIntakeResolveMessagingContextAction.Request>{ request }
            );

        System.assertEquals(1, responses.size());
        System.assertEquals('HOTEL_BOOKING_BASIC_V1', responses[0].templateKey);
        System.assert(responses[0].welcomeMessage.toLowerCase().contains('booking'), responses[0].welcomeMessage);
    }

    @IsTest
    static void resolvesFeedbackWelcomeFromMetadata() {
        SmartIntakeResolveMessagingContextAction.Request request =
            new SmartIntakeResolveMessagingContextAction.Request();
        request.currentPage = 'feedback';

        List<SmartIntakeResolveMessagingContextAction.Response> responses =
            SmartIntakeResolveMessagingContextAction.invoke(
                new List<SmartIntakeResolveMessagingContextAction.Request>{ request }
            );

        System.assertEquals(1, responses.size());
        System.assertEquals('EVENT_FEEDBACK_FORM', responses[0].templateKey);
        System.assert(responses[0].welcomeMessage.toLowerCase().contains('feedback'), responses[0].welcomeMessage);

        Apex_Debug_Log__c contextLog = [
            SELECT Severity__c, Error_Code__c, Template_Key__c, Context_JSON__c
            FROM Apex_Debug_Log__c
            WHERE Error_Code__c = 'SMARTINTAKE_CONTEXT_RESOLVED'
              AND Template_Key__c = 'EVENT_FEEDBACK_FORM'
            LIMIT 1
        ];
        System.assertEquals('INFO', contextLog.Severity__c);
        System.assert(contextLog.Context_JSON__c.contains('"resolvedContextKey":"feedback"'), contextLog.Context_JSON__c);
    }

    @IsTest
    static void fallsBackToDefaultRouteWhenContextIsBlank() {
        SmartIntakeResolveMessagingContextAction.Request request =
            new SmartIntakeResolveMessagingContextAction.Request();

        List<SmartIntakeResolveMessagingContextAction.Response> responses =
            SmartIntakeResolveMessagingContextAction.invoke(
                new List<SmartIntakeResolveMessagingContextAction.Request>{ request }
            );

        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].welcomeMessage);
    }

    @IsTest
    static void fallsBackToDefaultRouteWhenRequestIsNull() {
        List<SmartIntakeResolveMessagingContextAction.Response> responses =
            SmartIntakeResolveMessagingContextAction.invoke(
                new List<SmartIntakeResolveMessagingContextAction.Request>{ null }
            );

        System.assertEquals(1, responses.size());
        System.assertEquals(null, responses[0].contextKey);
        System.assertNotEquals(null, responses[0].welcomeMessage);
    }

    @IsTest
    static void fallsBackToDefaultRouteWhenContextIsUnknown() {
        SmartIntakeResolveMessagingContextAction.Request request =
            new SmartIntakeResolveMessagingContextAction.Request();
        request.currentPage = 'NOT_A_CONFIGURED_ROUTE';

        List<SmartIntakeResolveMessagingContextAction.Response> responses =
            SmartIntakeResolveMessagingContextAction.invoke(
                new List<SmartIntakeResolveMessagingContextAction.Request>{ request }
            );

        System.assertEquals(1, responses.size());
        System.assertEquals('NOT_A_CONFIGURED_ROUTE', responses[0].contextKey);
        System.assertNotEquals(null, responses[0].welcomeMessage);
    }

    @IsTest
    static void ignoresNonMessagingRoutableIds() {
        SmartIntakeResolveMessagingContextAction.Request request =
            new SmartIntakeResolveMessagingContextAction.Request();
        request.currentPage = '   ';
        request.routableId = '500000000000000AAA';

        List<SmartIntakeResolveMessagingContextAction.Response> responses =
            SmartIntakeResolveMessagingContextAction.invoke(
                new List<SmartIntakeResolveMessagingContextAction.Request>{ request }
            );

        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].welcomeMessage);
    }

    @IsTest
    static void fallsBackWhenMessagingRoutableIdHasNoSession() {
        SmartIntakeResolveMessagingContextAction.Request request =
            new SmartIntakeResolveMessagingContextAction.Request();
        request.routableId = '0Mw000000000000AAA';

        List<SmartIntakeResolveMessagingContextAction.Response> responses =
            SmartIntakeResolveMessagingContextAction.invoke(
                new List<SmartIntakeResolveMessagingContextAction.Request>{ request }
            );

        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].welcomeMessage);
    }

    @IsTest
    static void supportsContextContainingRouteKey() {
        SmartIntakeResolveMessagingContextAction.Request request =
            new SmartIntakeResolveMessagingContextAction.Request();
        request.currentPage = '/experience/smartintake/feedback/form';

        List<SmartIntakeResolveMessagingContextAction.Response> responses =
            SmartIntakeResolveMessagingContextAction.invoke(
                new List<SmartIntakeResolveMessagingContextAction.Request>{ request }
            );

        System.assertEquals(1, responses.size());
        System.assertEquals('EVENT_FEEDBACK_FORM', responses[0].templateKey);
    }
}