enum AppConsentStatus { unknown, accepted, declined }

class ConsentService {
  AppConsentStatus status = AppConsentStatus.unknown;

  Future<void> initialize() async {
    // Placeholder: mostrare dialogo e salvare preferenza in seguito.
    status = AppConsentStatus.unknown;
  }
}
