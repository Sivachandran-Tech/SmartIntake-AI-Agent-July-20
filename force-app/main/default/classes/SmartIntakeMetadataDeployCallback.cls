public class SmartIntakeMetadataDeployCallback implements Metadata.DeployCallback {
    private static final Integer NAME_MAX_LENGTH = 80;
    private static final Integer LONG_TEXT_MAX_LENGTH = 32768;

    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result == null) {
            return;
        }
        recordCompleted(result, context);
    }

    public static void recordCompleted(Metadata.DeployResult result) {
        if (result == null) {
            return;
        }
        recordCompleted(result, null);
    }

    public static void recordQueued(
        String deploymentJobId,
        SmartIntakeAdminController.BuilderPlan plan,
        String componentType,
        String componentKey
    ) {
        if (String.isBlank(deploymentJobId)) {
            return;
        }

        String templateKey = plan == null ? null : plan.templateKey;
        Integer recordCount = plan == null ? null : plan.recordCount;
        if (Test.isRunningTest() || System.isFuture() || System.isBatch() || System.isQueueable()) {
            recordQueuedSynchronously(deploymentJobId, templateKey, recordCount, componentType, componentKey);
            return;
        }

        recordQueuedAsync(deploymentJobId, templateKey, recordCount, componentType, componentKey);
    }

    @future
    public static void recordQueuedAsync(
        String deploymentJobId,
        String templateKey,
        Integer recordCount,
        String componentType,
        String componentKey
    ) {
        recordQueuedSynchronously(deploymentJobId, templateKey, recordCount, componentType, componentKey);
    }

    @TestVisible
    private static void recordQueuedSynchronously(
        String deploymentJobId,
        String templateKey,
        Integer recordCount,
        String componentType,
        String componentKey
    ) {
        SmartIntake_Metadata_Deployment__c statusRecord = new SmartIntake_Metadata_Deployment__c();
        statusRecord.Name = truncate('SmartIntake ' + deploymentJobId, NAME_MAX_LENGTH);
        statusRecord.Deployment_Job_Id__c = deploymentJobId;
        statusRecord.Template_Key__c = templateKey;
        statusRecord.Component_Type__c = componentType;
        statusRecord.Component_Key__c = componentKey;
        statusRecord.Record_Count__c = recordCount;
        statusRecord.Status__c = 'Pending';
        statusRecord.Done__c = false;
        statusRecord.Success__c = false;
        statusRecord.Components_Deployed__c = 0;
        statusRecord.Components_Total__c = recordCount;
        statusRecord.Component_Errors__c = 0;
        statusRecord.Tests_Completed__c = 0;
        statusRecord.Tests_Total__c = 0;
        statusRecord.Test_Errors__c = 0;
        statusRecord.State_Detail__c = 'Salesforce queued the metadata deployment.';
        upsertStatusRecord(statusRecord);
    }

    public static SmartIntakeAdminController.DeploymentStatus getStatus(String deploymentJobId) {
        SmartIntakeAdminController.DeploymentStatus status = new SmartIntakeAdminController.DeploymentStatus();
        status.deploymentJobId = deploymentJobId;
        status.status = 'Pending';
        status.done = false;
        status.success = false;
        status.numberComponentsDeployed = 0;
        status.numberComponentsTotal = 0;
        status.numberComponentErrors = 0;
        status.numberTestsCompleted = 0;
        status.numberTestsTotal = 0;
        status.numberTestErrors = 0;
        status.stateDetail = 'Waiting for the metadata deployment callback.';

        if (String.isBlank(deploymentJobId)) {
            status.status = 'StatusUnavailable';
            status.errorMessage = 'A deployment job id is required.';
            return status;
        }

        List<SmartIntake_Metadata_Deployment__c> records = [
            SELECT Deployment_Job_Id__c, Status__c, Done__c, Success__c,
                   Components_Deployed__c, Components_Total__c, Component_Errors__c,
                   Tests_Completed__c, Tests_Total__c, Test_Errors__c,
                   State_Detail__c, Error_Message__c, Error_Status_Code__c,
                   Completed_Date__c, Deploy_Created_Date__c, Start_Date__c
            FROM SmartIntake_Metadata_Deployment__c
            WHERE Deployment_Job_Id__c = :deploymentJobId
            LIMIT 1
        ];
        if (records.isEmpty()) {
            return status;
        }
        return toStatus(records[0]);
    }

    private static void recordCompleted(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        String deploymentJobId = String.isBlank(result.id)
            ? (context == null ? null : String.valueOf(context.getCallbackJobId()))
            : result.id;
        if (String.isBlank(deploymentJobId)) {
            return;
        }

        SmartIntake_Metadata_Deployment__c statusRecord = new SmartIntake_Metadata_Deployment__c();
        statusRecord.Name = truncate('SmartIntake ' + deploymentJobId, NAME_MAX_LENGTH);
        statusRecord.Deployment_Job_Id__c = deploymentJobId;
        statusRecord.Callback_Job_Id__c = context == null ? null : String.valueOf(context.getCallbackJobId());
        statusRecord.Status__c = result.status == null ? 'Pending' : String.valueOf(result.status);
        statusRecord.Done__c = result.done == true;
        statusRecord.Success__c = result.success == true;
        statusRecord.Components_Deployed__c = result.numberComponentsDeployed;
        statusRecord.Components_Total__c = result.numberComponentsTotal;
        statusRecord.Component_Errors__c = result.numberComponentErrors;
        statusRecord.Tests_Completed__c = 0;
        statusRecord.Tests_Total__c = 0;
        statusRecord.Test_Errors__c = 0;
        statusRecord.State_Detail__c = truncate(result.stateDetail, LONG_TEXT_MAX_LENGTH);
        statusRecord.Error_Message__c = truncate(result.errorMessage, LONG_TEXT_MAX_LENGTH);
        statusRecord.Error_Status_Code__c = result.errorStatusCode == null ? null : String.valueOf(result.errorStatusCode);
        statusRecord.Completed_Date__c = result.completedDate;
        statusRecord.Deploy_Created_Date__c = result.createdDate;
        statusRecord.Start_Date__c = result.startDate;
        statusRecord.Result_JSON__c = truncate(JSON.serialize(result), LONG_TEXT_MAX_LENGTH);
        upsertStatusRecord(statusRecord);
    }

    private static void upsertStatusRecord(SmartIntake_Metadata_Deployment__c statusRecord) {
        try {
            upsert statusRecord SmartIntake_Metadata_Deployment__c.Deployment_Job_Id__c;
        } catch (DmlException ex) {
            SmartIntakeApexDebugLogService.logException(
                'SmartIntakeMetadataDeployCallback',
                'upsertStatusRecord',
                null,
                null,
                ex,
                new Map<String, Object>{
                    'recordId' => statusRecord == null ? null : statusRecord.Id,
                    'deploymentJobId' => statusRecord == null ? null : statusRecord.Deployment_Job_Id__c,
                    'status' => statusRecord == null ? null : statusRecord.Status__c
                }
            );
            System.debug(LoggingLevel.WARN, 'SmartIntake metadata deployment status could not be recorded: ' + ex.getMessage());
        }
    }

    private static SmartIntakeAdminController.DeploymentStatus toStatus(SmartIntake_Metadata_Deployment__c record) {
        SmartIntakeAdminController.DeploymentStatus status = new SmartIntakeAdminController.DeploymentStatus();
        status.deploymentJobId = record.Deployment_Job_Id__c;
        status.status = String.isBlank(record.Status__c) ? 'Pending' : record.Status__c;
        status.done = record.Done__c;
        status.success = record.Success__c;
        status.numberComponentsDeployed = toInteger(record.Components_Deployed__c);
        status.numberComponentsTotal = toInteger(record.Components_Total__c);
        status.numberComponentErrors = toInteger(record.Component_Errors__c);
        status.numberTestsCompleted = toInteger(record.Tests_Completed__c);
        status.numberTestsTotal = toInteger(record.Tests_Total__c);
        status.numberTestErrors = toInteger(record.Test_Errors__c);
        status.stateDetail = record.State_Detail__c;
        status.errorMessage = record.Error_Message__c;
        status.errorStatusCode = record.Error_Status_Code__c;
        status.completedDate = record.Completed_Date__c;
        status.createdDate = record.Deploy_Created_Date__c;
        status.startDate = record.Start_Date__c;
        return status;
    }

    private static Integer toInteger(Decimal value) {
        return value == null ? 0 : value.intValue();
    }

    private static String truncate(String value, Integer maxLength) {
        if (String.isBlank(value) || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }
}