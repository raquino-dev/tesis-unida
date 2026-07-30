enum SecurityEventType {
  login,
  failedLogin,
  passwordChange,
  otp,
  biometric,
  criticalAction,
}

class SecurityEventEntity {
  final String id;
  final SecurityEventType type;
  final String description;
  final DateTime occurredAt;
  final bool successful;

  const SecurityEventEntity({
    required this.id,
    required this.type,
    required this.description,
    required this.occurredAt,
    required this.successful,
  });
}

class MockSessionEntity {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final bool trustedDevice;

  const MockSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.trustedDevice,
  });
}

class OtpChallengeEntity {
  final String id;
  final String maskedDestination;
  final String demoCode;
  final DateTime expiresAt;

  const OtpChallengeEntity({
    required this.id,
    required this.maskedDestination,
    required this.demoCode,
    required this.expiresAt,
  });
}
