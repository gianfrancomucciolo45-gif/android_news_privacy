class FeatureFlags {
  final bool adsEnabled;
  final bool premiumEnabled;
  final int softPaywallDailyFreeArticles;

  const FeatureFlags({
    this.adsEnabled = false,
    this.premiumEnabled = false,
    this.softPaywallDailyFreeArticles = 10,
  });
}
