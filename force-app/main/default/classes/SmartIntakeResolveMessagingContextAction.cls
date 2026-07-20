public with sharing class SmartIntakeResolveMessagingContextAction {
    private static final String DEFAULT_WELCOME = 'Hi, I am here to help with this intake.';

    public class Request {
        @InvocableVariable(label='Current Page' description='Page, channel, or route context key, usually MessagingSession.Current_Page__c.')
        public String currentPage;

        @InvocableVariable(label='Routable Id' description='Optional MessagingSession Id used to resolve Current Page when the flow input is blank.')
        public String routableId;
    }

    public class Response {
        @InvocableVariable(label='Context Key')
        public String contextKey;

        @InvocableVariable(label='Template Key')
        public String templateKey;

        @InvocableVariable(label='Welcome Message')
        public String welcomeMessage;
    }

    @InvocableMethod(
        label='SmartIntake - Resolve Messaging Context'
        description='Resolves the SmartIntake template and metadata-driven welcome message from MessagingSession page context.'
    )
    public static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request request : requests) {
            responses.add(resolve(request));
        }
        return responses;
    }

    private static Response resolve(Request request) {
        Response response = new Response();
        response.contextKey = resolveContextKey(request);
        response.templateKey = resolveTemplateKey(response.contextKey);
        response.welcomeMessage = resolveWelcomeMessage(response.templateKey, response.contextKey);
        logContextResolution(request, response);
        return response;
    }

    private static void logContextResolution(Request request, Response response) {
        Map<String, Object> context = new Map<String, Object>{
            'requestedCurrentPage' => request == null ? null : normalize(request.currentPage),
            'resolvedContextKey' => response == null ? null : response.contextKey,
            'resolvedTemplateKey' => response == null ? null : response.templateKey,
            'welcomeMessage' => response == null ? null : response.welcomeMessage,
            'routableId' => request == null ? null : normalize(request.routableId),
            'recordId' => request == null ? null : normalize(request.routableId),
            'status' => 'Context Resolved'
        };
        SmartIntakeApexDebugLogService.logMessage(
            'INFO',
            'SmartIntakeResolveMessagingContextAction',
            'resolve',
            response == null ? null : response.templateKey,
            null,
            null,
            'SMARTINTAKE_CONTEXT_RESOLVED',
            'Resolved SmartIntake messaging context before agent routing.',
            'Compare this record with SMARTINTAKE_ROUTE_DIAGNOSTIC to confirm Agentforce passed the same route context to Get Next.',
            context
        );
    }

    private static String resolveContextKey(Request request) {
        String currentPage = request == null ? null : normalize(request.currentPage);
        if (!String.isBlank(currentPage)) {
            return currentPage;
        }
        return request == null ? null : contextKeyForRoutableId(request.routableId);
    }

    private static String resolveTemplateKey(String contextKey) {
        List<SmartIntake_Template_Route__mdt> routes = [
            SELECT Route_Key__c, Template_Key__c, Is_Default__c
            FROM SmartIntake_Template_Route__mdt
            WHERE Is_Active__c = true
        ];

        if (!String.isBlank(contextKey)) {
            for (SmartIntake_Template_Route__mdt route : routes) {
                if (route.Route_Key__c != null && route.Route_Key__c.equalsIgnoreCase(contextKey)) {
                    return route.Template_Key__c;
                }
            }
            for (SmartIntake_Template_Route__mdt route : routes) {
                if (route.Route_Key__c != null && contextKey.toLowerCase().contains(route.Route_Key__c.toLowerCase())) {
                    return route.Template_Key__c;
                }
            }
        }

        for (SmartIntake_Template_Route__mdt route : routes) {
            if (route.Is_Default__c) {
                return route.Template_Key__c;
            }
        }
        return null;
    }

    private static String resolveWelcomeMessage(String templateKey, String contextKey) {
        if (!String.isBlank(templateKey)) {
            List<SmartIntake_Branding_Config__mdt> brandingConfigs = [
                SELECT Welcome_Message__c
                FROM SmartIntake_Branding_Config__mdt
                WHERE Is_Active__c = true AND Template_Key__c = :templateKey
                LIMIT 1
            ];
            if (!brandingConfigs.isEmpty() && !String.isBlank(brandingConfigs[0].Welcome_Message__c)) {
                return brandingConfigs[0].Welcome_Message__c.trim();
            }
        }

        String label = !String.isBlank(contextKey) ? contextKey : templateKey;
        if (String.isBlank(label)) {
            return DEFAULT_WELCOME;
        }
        return 'Hi, I am here to help with ' + humanize(label) + '.';
    }

    private static String normalize(String value) {
        return String.isBlank(value) ? null : value.trim();
    }

    private static String contextKeyForRoutableId(String routableId) {
        if (String.isBlank(routableId) || !String.valueOf(routableId).startsWith('0Mw')) {
            return null;
        }
        if (!Schema.sObjectType.MessagingSession.isAccessible() ||
            !Schema.sObjectType.MessagingSession.fields.Current_Page__c.isAccessible()
        ) {
            return null;
        }
        List<MessagingSession> sessions = [
            SELECT Current_Page__c
            FROM MessagingSession
            WHERE Id = :routableId
            WITH USER_MODE
            LIMIT 1
        ];
        return sessions.isEmpty() ? null : normalize(sessions[0].Current_Page__c);
    }

    private static String humanize(String value) {
        String normalized = value == null ? '' : value.toLowerCase().replace('_page', '').replace('_v1', '').replace('_', ' ');
        return normalized.replaceAll('\\s+', ' ').trim();
    }
}