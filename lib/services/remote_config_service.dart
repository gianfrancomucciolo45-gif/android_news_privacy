import 'feature_flags.dart';

class RemoteConfigService {
  Future<FeatureFlags> fetchFlags() async {
    // Placeholder: return defaults. Integrate Firebase Remote Config o altro backend in seguito.
    return const FeatureFlags();
  }
}
