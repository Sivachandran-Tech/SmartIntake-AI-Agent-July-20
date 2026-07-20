@JsonAccess(serializable='always' deserializable='always')
global class SmartIntakeOptionContract {
    @InvocableVariable(label='Label')
    @AuraEnabled
    global String label;

    @InvocableVariable(label='Value')
    @AuraEnabled
    global String value;
}