public with sharing class SmartIntakeWarrantyVerifyOtpAction {
    @InvocableMethod(
        label='SmartIntake Warranty - Verify Email OTP'
        description='Verifies an email OTP for a warranty claim and returns SmartIntake hook outputs.'
    )
    public static List<SmartIntakeWarrantyOtpService.VerifyOtpResponse> invoke(List<SmartIntakeWarrantyOtpService.VerifyOtpRequest> requests) {
        List<SmartIntakeWarrantyOtpService.VerifyOtpResponse> responses = new List<SmartIntakeWarrantyOtpService.VerifyOtpResponse>();
        for (SmartIntakeWarrantyOtpService.VerifyOtpRequest request : requests) {
            responses.add(SmartIntakeWarrantyOtpService.verifyOtp(request));
        }
        return responses;
    }
}