import 'security_entity.dart';

abstract class SecurityRepository {
  Future<MockSessionEntity> createSession({required bool trustedDevice});
  Future<MockSessionEntity?> getSession();
  Future<void> clearSession();
  Future<OtpChallengeEntity> requestOtp(String reason);
  Future<bool> validateOtp(String challengeId, String code);
  Future<bool> authenticateBiometrically();
  Future<void> setBiometricsEnabled(bool enabled);
  Future<bool> isBiometricsEnabled();
  Future<void> recordEvent(
    SecurityEventType type,
    String description, {
    bool successful = true,
  });
  Future<List<SecurityEventEntity>> getEvents();
}
