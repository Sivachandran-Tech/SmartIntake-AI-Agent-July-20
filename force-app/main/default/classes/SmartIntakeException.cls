public class SmartIntakeException extends Exception {
    public String errorType { get; private set; }
    public String errorCode { get; private set; }
    public String userMessage { get; private set; }
    public String adminMessage { get; private set; }

    public SmartIntakeException(String errorType, String errorCode, String userMessage, String adminMessage) {
        this.errorType = errorType;
        this.errorCode = errorCode;
        this.userMessage = userMessage;
        this.adminMessage = adminMessage;
    }
}