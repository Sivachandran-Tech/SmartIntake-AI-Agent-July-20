public with sharing class SmartIntakeWarrantyEmailOtpAction {
    @InvocableMethod(
        label='SmartIntake Warranty - Check Email and Send OTP'
        description='Checks whether the warranty claim email belongs to a registered contact, sends an email OTP, and returns SmartIntake hook outputs.'
    )
    public static List<SmartIntakeWarrantyOtpService.SendOtpResponse> invoke(List<SmartIntakeWarrantyOtpService.SendOtpRequest> requests) {
        List<SmartIntakeWarrantyOtpService.SendOtpResponse> responses = new List<SmartIntakeWarrantyOtpService.SendOtpResponse>();
        for (SmartIntakeWarrantyOtpService.SendOtpRequest request : requests) {
            responses.add(SmartIntakeWarrantyOtpService.checkRegisteredEmailAndSendOtp(request));
        }
        return responses;
    }
}