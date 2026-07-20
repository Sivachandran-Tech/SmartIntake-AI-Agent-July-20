public without sharing class SmartIntakeApexDebugLogService {
    private static final String OBJECT_API_NAME = 'Apex_Debug_Log__c';
    private static final Integer LONG_TEXT_LIMIT = 32768;
    private static Boolean isLogging = false;

    public static void logSmartIntakeException(
        String className,
        String methodName,
        String templateKey,
        String intakeSessionId,
        SmartIntakeException ex,
        Map<String, Object> context
    ) {
        if (ex != null && ex.errorType == 'VALIDATION') {
            return;
        }
        logInternal(
            'ERROR',
            className,
            methodName,
            templateKey,
            intakeSessionId,
            ex == null ? null : ex.errorType,
            ex == null ? null : ex.errorCode,
            ex == null ? null : ex.userMessage,
            ex == null ? null : ex.adminMessage,
            ex,
            context
        );
    }

    public static void logException(
        String className,
        String methodName,
        String templateKey,
        String intakeSessionId,
        Exception ex,
        Map<String, Object> context
    ) {
        logInternal(
            'ERROR',
            className,
            methodName,
            templateKey,
            intakeSessionId,
            ex == null ? null : ex.getTypeName(),
            'UNEXPECTED_ERROR',
            ex == null ? null : ex.getMessage(),
            ex == null ? null : ex.getTypeName() + ': ' + ex.getMessage(),
            ex,
            context
        );
    }

    public static void logMessage(
        String severity,
        String className,
        String methodName,
        String templateKey,
        String intakeSessionId,
        String errorType,
        String errorCode,
        String message,
        String adminMessage,
        Map<String, Object> context
    ) {
        logInternal(severity, className, methodName, templateKey, intakeSessionId, errorType, errorCode, message, adminMessage, null, context);
    }

    private static void logInternal(
        String severity,
        String className,
        String methodName,
        String templateKey,
        String intakeSessionId,
        String errorType,
        String errorCode,
        String message,
        String adminMessage,
        Exception ex,
        Map<String, Object> context
    ) {
        if (isLogging || !Schema.getGlobalDescribe().containsKey(OBJECT_API_NAME)) {
            return;
        }

        isLogging = true;
        try {
            Map<String, Object> safeContext = context == null ? new Map<String, Object>() : new Map<String, Object>(context);
            String objectApiName = stringValue(safeContext.remove('objectApiName'));
            String fieldApiName = stringValue(safeContext.remove('fieldApiName'));
            String recordId = stringValue(safeContext.remove('recordId'));
            String questionKey = stringValue(safeContext.remove('questionKey'));
            String agentSessionKey = stringValue(safeContext.remove('agentSessionKey'));
            String status = stringValue(safeContext.remove('status'));

            Schema.SObjectType logType = Schema.getGlobalDescribe().get(OBJECT_API_NAME);
            SObject logRecord = logType.newSObject();
            putIfPresent(logRecord, 'Occurred_At__c', System.now());
            putIfPresent(logRecord, 'Severity__c', truncate(String.isBlank(severity) ? 'ERROR' : severity, 40));
            putIfPresent(logRecord, 'Status__c', truncate(status, 80));
            putIfPresent(logRecord, 'Class_Name__c', truncate(className, 255));
            putIfPresent(logRecord, 'Method_Name__c', truncate(methodName, 255));
            putIfPresent(logRecord, 'Source__c', truncate(source(className, methodName), 255));
            putIfPresent(logRecord, 'Error_Type__c', truncate(errorType, 80));
            putIfPresent(logRecord, 'Error_Code__c', truncate(errorCode, 120));
            putIfPresent(logRecord, 'Message__c', truncate(message, LONG_TEXT_LIMIT));
            putIfPresent(logRecord, 'Admin_Message__c', truncate(adminMessage, LONG_TEXT_LIMIT));
            putIfPresent(logRecord, 'Stack_Trace__c', truncate(ex == null ? null : ex.getStackTraceString(), LONG_TEXT_LIMIT));
            putIfPresent(logRecord, 'Context_JSON__c', truncate(serializeContext(safeContext), LONG_TEXT_LIMIT));
            putIfPresent(logRecord, 'Template_Key__c', truncate(templateKey, 255));
            putIfPresent(logRecord, 'Intake_Session_Id__c', truncate(intakeSessionId, 255));
            putIfPresent(logRecord, 'Agent_Session_Key__c', truncate(agentSessionKey, 255));
            putIfPresent(logRecord, 'Question_Key__c', truncate(questionKey, 255));
            putIfPresent(logRecord, 'Object_API_Name__c', truncate(objectApiName, 255));
            putIfPresent(logRecord, 'Field_API_Name__c', truncate(fieldApiName, 255));
            putIfPresent(logRecord, 'Record_Id__c', truncate(recordId, 18));
            putIfPresent(logRecord, 'User_Id__c', truncate(UserInfo.getUserId(), 18));
            putIfPresent(logRecord, 'Username__c', truncate(UserInfo.getUserName(), 255));
            Database.insert(logRecord, AccessLevel.SYSTEM_MODE);
        } catch (Exception loggingException) {
            System.debug(LoggingLevel.WARN, 'SmartIntake Apex debug log could not be recorded: ' + loggingException.getMessage());
        } finally {
            isLogging = false;
        }
    }

    private static void putIfPresent(SObject record, String fieldApiName, Object value) {
        if (record == null || String.isBlank(fieldApiName)) {
            return;
        }
        Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();
        if (fields.containsKey(fieldApiName)) {
            record.put(fieldApiName, value);
        }
    }

    private static String source(String className, String methodName) {
        if (String.isBlank(className)) {
            return methodName;
        }
        if (String.isBlank(methodName)) {
            return className;
        }
        return className + '.' + methodName;
    }

    private static String serializeContext(Map<String, Object> context) {
        if (context == null || context.isEmpty()) {
            return null;
        }
        try {
            return JSON.serialize(context);
        } catch (Exception ex) {
            return String.valueOf(context);
        }
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static String truncate(String value, Integer maxLength) {
        if (String.isBlank(value) || maxLength == null || maxLength <= 0 || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }
}