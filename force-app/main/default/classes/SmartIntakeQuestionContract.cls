@JsonAccess(serializable='always' deserializable='always')
global class SmartIntakeQuestionContract {
    @InvocableVariable(label='Question Key')
    @AuraEnabled
    global String questionKey;

    @InvocableVariable(label='Question Text')
    @AuraEnabled
    global String questionText;

    @InvocableVariable(label='Help Text')
    @AuraEnabled
    global String helpText;

    @InvocableVariable(label='Placeholder Text')
    @AuraEnabled
    global String placeholderText;

    @InvocableVariable(label='Required')
    @AuraEnabled
    global Boolean required;

    @InvocableVariable(label='Input Type')
    @AuraEnabled
    global String inputType;

    @InvocableVariable(label='UI Control')
    @AuraEnabled
    global String uiControl;

    @InvocableVariable(label='Render Lightning Input')
    @AuraEnabled
    global Boolean renderLightningInput;

    @InvocableVariable(label='Value')
    @AuraEnabled
    global String value;

    @InvocableVariable(label='Data Source Key')
    @AuraEnabled
    global String dataSourceKey;

    @InvocableVariable(label='Data Source JSON')
    @AuraEnabled
    global String dataSourceJson;

    @InvocableVariable(label='Answers JSON')
    @AuraEnabled
    global String answersJson;

    @InvocableVariable(label='Options')
    @AuraEnabled
    global List<SmartIntakeOptionContract> options;

    @InvocableVariable(label='Options JSON')
    @AuraEnabled
    global String optionsJson;

    @InvocableVariable(label='Accepted Formats')
    @AuraEnabled
    global List<String> acceptedFormats;

    @InvocableVariable(label='Accepted Formats JSON')
    @AuraEnabled
    global String acceptedFormatsJson;

    @InvocableVariable(label='Allow Multiple Files')
    @AuraEnabled
    global Boolean allowMultipleFiles;

    @InvocableVariable(label='Max File Count')
    @AuraEnabled
    global Integer maxFileCount;
}