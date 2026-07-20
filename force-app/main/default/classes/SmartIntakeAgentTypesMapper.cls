public class SmartIntakeAgentTypesMapper {
    public static SmartIntakeQuestionContract toQuestionContract(SmartIntakeDTO.Question question) {
        if (question == null) {
            return null;
        }

        SmartIntakeQuestionContract contract = new SmartIntakeQuestionContract();
        contract.questionKey = question.questionKey;
        contract.questionText = question.questionText;
        contract.helpText = question.helpText;
        contract.placeholderText = question.placeholderText;
        contract.required = question.required;
        contract.inputType = question.inputType;
        contract.uiControl = question.uiControl;
        contract.renderLightningInput = question.renderLightningInput;
        contract.value = question.value;
        contract.dataSourceKey = question.dataSourceKey;
        contract.dataSourceJson = question.dataSourceJson;
        contract.answersJson = question.answersJson;
        contract.options = toOptionContracts(question.options);
        contract.optionsJson = JSON.serialize(contract.options);
        contract.acceptedFormats = question.acceptedFormats == null ? new List<String>() : question.acceptedFormats;
        contract.acceptedFormatsJson = JSON.serialize(contract.acceptedFormats);
        contract.allowMultipleFiles = question.allowMultipleFiles;
        contract.maxFileCount = question.maxFileCount;
        return contract;
    }

    public static SmartIntakeAnswerCapture toAnswerCapture(SmartIntakeDTO.Question question) {
        if (question == null) {
            return null;
        }

        SmartIntakeAnswerCapture capture = new SmartIntakeAnswerCapture();
        capture.questionKey = question.questionKey;
        capture.questionText = question.questionText;
        capture.helpText = question.helpText;
        capture.placeholderText = question.placeholderText;
        capture.required = question.required;
        capture.inputType = question.inputType;
        capture.uiControl = question.uiControl;
        capture.renderLightningInput = question.renderLightningInput;
        capture.answerValue = question.value;
        capture.dataSourceKey = question.dataSourceKey;
        capture.dataSourceJson = question.dataSourceJson;
        capture.answersJson = question.answersJson;
        capture.options = toOptionContracts(question.options);
        capture.optionsJson = JSON.serialize(capture.options);
        capture.acceptedFormats = question.acceptedFormats == null ? new List<String>() : question.acceptedFormats;
        capture.acceptedFormatsJson = JSON.serialize(capture.acceptedFormats);
        capture.allowMultipleFiles = question.allowMultipleFiles;
        capture.maxFileCount = question.maxFileCount;
        return capture;
    }

    public static String resolveAnswerValue(String answerValue, SmartIntakeAnswerCapture answerCapture) {
        if (answerCapture != null && !String.isBlank(answerCapture.answerValue)) {
            return answerCapture.answerValue;
        }
        return answerValue;
    }

    private static List<SmartIntakeOptionContract> toOptionContracts(List<SmartIntakeDTO.Option> options) {
        if (options == null || options.isEmpty()) {
            return new List<SmartIntakeOptionContract>();
        }

        List<SmartIntakeOptionContract> contracts = new List<SmartIntakeOptionContract>();
        for (SmartIntakeDTO.Option option : options) {
            if (option == null) {
                continue;
            }
            SmartIntakeOptionContract contract = new SmartIntakeOptionContract();
            contract.label = option.label;
            contract.value = option.value;
            contracts.add(contract);
        }
        return contracts;
    }
}