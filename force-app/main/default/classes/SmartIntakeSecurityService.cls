public with sharing class SmartIntakeSecurityService {
    // Dynamically retrieve the current package namespace at runtime
    public static String getNamespace() {
        String className = SmartIntakeSecurityService.class.getName();
        return className.contains('.') ? className.substringBefore('.') : '';
    }

    // Resolves package custom object names at runtime (e.g. 'SmartIntake_Session__c')
    public static String resolveObjectName(String objectApiName) {
        String ns = getNamespace();
        if (String.isNotEmpty(ns) && objectApiName.startsWith('SmartIntake_') && !objectApiName.startsWith(ns + '__')) {
            return ns + '__' + objectApiName;
        }
        return objectApiName;
    }

    // Resolves package custom field names on namespaced objects at runtime (e.g. 'Session_Id__c')
    public static String resolveFieldName(String objectApiName, String fieldApiName) {
        String resolvedObjectName = resolveObjectName(objectApiName);
        // A namespaced custom object or metadata will have more than one "__" pair (e.g. "ns__Object__c")
        if (resolvedObjectName.indexOf('__') != resolvedObjectName.lastIndexOf('__')) {
            String ns = resolvedObjectName.substringBefore('__');
            if (!fieldApiName.startsWith(ns + '__')) {
                return ns + '__' + fieldApiName;
            }
        }
        return fieldApiName;
    }

    public static Schema.DescribeSObjectResult describeObjectForCreate(String objectApiName) {
        String resolvedObjectName = resolveObjectName(objectApiName);
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(resolvedObjectName);
        if (objectType == null) {
            throw configError('OBJECT_NOT_FOUND', 'Configured object was not found: ' + resolvedObjectName + '.');
        }

        Schema.DescribeSObjectResult describe = objectType.getDescribe();
        if (!describe.isCreateable()) {
            throw securityError('OBJECT_CREATE_DENIED', 'The running user cannot create records for configured object ' + resolvedObjectName + '.');
        }
        return describe;
    }

    public static Schema.DescribeSObjectResult describeObjectForRead(String objectApiName) {
        String resolvedObjectName = resolveObjectName(objectApiName);
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(resolvedObjectName);
        if (objectType == null) {
            throw configError('OBJECT_NOT_FOUND', 'Configured object was not found: ' + resolvedObjectName + '.');
        }

        Schema.DescribeSObjectResult describe = objectType.getDescribe();
        if (!describe.isAccessible()) {
            throw securityError('OBJECT_READ_DENIED', 'The running user cannot read records for configured object ' + resolvedObjectName + '.');
        }
        return describe;
    }

    public static Schema.DescribeSObjectResult describeObjectForUpdate(String objectApiName) {
        String resolvedObjectName = resolveObjectName(objectApiName);
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(resolvedObjectName);
        if (objectType == null) {
            throw configError('OBJECT_NOT_FOUND', 'Configured object was not found: ' + resolvedObjectName + '.');
        }

        Schema.DescribeSObjectResult describe = objectType.getDescribe();
        if (!describe.isUpdateable()) {
            throw securityError('OBJECT_UPDATE_DENIED', 'The running user cannot update records for configured object ' + resolvedObjectName + '.');
        }
        return describe;
    }

    public static Schema.DescribeFieldResult describeFieldForCreate(String objectApiName, String fieldApiName) {
        String resolvedObjectName = resolveObjectName(objectApiName);
        String resolvedFieldName = resolveFieldName(objectApiName, fieldApiName);
        Schema.DescribeSObjectResult objectDescribe = describeObjectForCreate(resolvedObjectName);
        Schema.SObjectField fieldToken = objectDescribe.fields.getMap().get(resolvedFieldName);
        if (fieldToken == null) {
            throw configError('FIELD_NOT_FOUND', 'Configured field ' + resolvedFieldName + ' was not found on object ' + resolvedObjectName + '.');
        }

        Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
        if (!fieldDescribe.isCreateable()) {
            throw securityError('FIELD_CREATE_DENIED', 'The running user cannot create field ' + resolvedFieldName + ' on configured object ' + resolvedObjectName + '.');
        }
        return fieldDescribe;
    }

    public static Schema.DescribeFieldResult describeFieldForUpdate(String objectApiName, String fieldApiName) {
        String resolvedObjectName = resolveObjectName(objectApiName);
        String resolvedFieldName = resolveFieldName(objectApiName, fieldApiName);
        Schema.DescribeSObjectResult objectDescribe = describeObjectForUpdate(resolvedObjectName);
        Schema.SObjectField fieldToken = objectDescribe.fields.getMap().get(resolvedFieldName);
        if (fieldToken == null) {
            throw configError('FIELD_NOT_FOUND', 'Configured field ' + resolvedFieldName + ' was not found on object ' + resolvedObjectName + '.');
        }

        Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
        if (!fieldDescribe.isUpdateable()) {
            throw securityError('FIELD_UPDATE_DENIED', 'The running user cannot update field ' + resolvedFieldName + ' on configured object ' + resolvedObjectName + '.');
        }
        return fieldDescribe;
    }

    public static Schema.DescribeFieldResult describeFieldForRead(String objectApiName, String fieldApiName) {
        String resolvedObjectName = resolveObjectName(objectApiName);
        String resolvedFieldName = resolveFieldName(objectApiName, fieldApiName);
        Schema.DescribeSObjectResult objectDescribe = describeObjectForRead(resolvedObjectName);
        Schema.SObjectField fieldToken = objectDescribe.fields.getMap().get(resolvedFieldName);
        if (fieldToken == null) {
            throw configError('FIELD_NOT_FOUND', 'Configured field ' + resolvedFieldName + ' was not found on object ' + resolvedObjectName + '.');
        }

        Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
        if (!fieldDescribe.isAccessible()) {
            throw securityError('FIELD_READ_DENIED', 'The running user cannot read field ' + resolvedFieldName + ' on configured object ' + resolvedObjectName + '.');
        }
        return fieldDescribe;
    }

    public static Object coerceForCreate(String objectApiName, String fieldApiName, String value) {
        Schema.DisplayType displayType = describeFieldForCreate(objectApiName, fieldApiName).getType();
        return coerceValue(objectApiName, fieldApiName, displayType, value);
    }

    public static Object coerceForReadFilter(String objectApiName, String fieldApiName, String value) {
        Schema.DisplayType displayType = describeFieldForRead(objectApiName, fieldApiName).getType();
        return coerceValue(objectApiName, fieldApiName, displayType, value);
    }

    private static Object coerceValue(String objectApiName, String fieldApiName, Schema.DisplayType displayType, String value) {
        if (String.isBlank(value)) {
            return null;
        }

        try {
            if (displayType == Schema.DisplayType.String ||
                displayType == Schema.DisplayType.TextArea ||
                displayType == Schema.DisplayType.Email ||
                displayType == Schema.DisplayType.Phone ||
                displayType == Schema.DisplayType.Url ||
                displayType == Schema.DisplayType.Picklist ||
                displayType == Schema.DisplayType.MultiPicklist) {
                return value;
            }
            if (displayType == Schema.DisplayType.Boolean) {
                return Boolean.valueOf(value);
            }
            if (displayType == Schema.DisplayType.Date) {
                return Date.valueOf(value);
            }
            if (displayType == Schema.DisplayType.DateTime) {
                return DateTime.valueOf(value.replace('T', ' '));
            }
            if (displayType == Schema.DisplayType.Integer) {
                return Integer.valueOf(value);
            }
            if (displayType == Schema.DisplayType.Double ||
                displayType == Schema.DisplayType.Currency ||
                displayType == Schema.DisplayType.Percent) {
                return Decimal.valueOf(value);
            }
            if (displayType == Schema.DisplayType.Reference ||
                displayType == Schema.DisplayType.Id) {
                return Id.valueOf(value);
            }
        } catch (Exception ex) {
            throw configError(
                'FIELD_VALUE_COERCION_FAILED',
                'Value for field ' + fieldApiName + ' on ' + objectApiName + ' could not be converted to ' + String.valueOf(displayType) + '. Check the question input type and field binding metadata.'
            );
        }

        throw configError('UNSUPPORTED_FIELD_TYPE', 'Field ' + fieldApiName + ' on ' + objectApiName + ' uses unsupported type ' + String.valueOf(displayType) + '.');
    }

    private static SmartIntakeException configError(String code, String adminMessage) {
        return new SmartIntakeException(
            'CONFIGURATION',
            code,
            SmartIntakeMetadataService.message(null, 'CONFIGURATION_ERROR', 'I can’t continue this intake safely because the template needs admin attention.'),
            adminMessage
        );
    }

    private static SmartIntakeException securityError(String code, String adminMessage) {
        return new SmartIntakeException(
            'SECURITY',
            code,
            SmartIntakeMetadataService.message(null, 'SECURITY_ERROR', 'I can’t access or save that part of the intake with the current permissions.'),
            adminMessage
        );
    }
}