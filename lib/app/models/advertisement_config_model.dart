class AdvertisementConfigModel {
  bool isEnabled;
  String network; // "admob" | "adx"
  MobileAdConfig mobile;
  WebAdConfig web;

  AdvertisementConfigModel({
    this.isEnabled = false,
    this.network = 'admob',
    MobileAdConfig? mobile,
    WebAdConfig? web,
  })  : mobile = mobile ?? MobileAdConfig(),
        web = web ?? WebAdConfig();

  factory AdvertisementConfigModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementConfigModel(
      isEnabled: json['isEnabled'] ?? false,
      network: json['network'] ?? 'admob',
      mobile: json['mobile'] != null ? MobileAdConfig.fromJson(Map<String, dynamic>.from(json['mobile'])) : MobileAdConfig(),
      web: json['web'] != null ? WebAdConfig.fromJson(Map<String, dynamic>.from(json['web'])) : WebAdConfig(),
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'network': network,
        'mobile': mobile.toJson(),
        'web': web.toJson(),
      };
}

class MobileAdConfig {
  /// Per-platform enable flag — admin can switch off mobile ads independently
  /// of web ads. Defaults to true so existing deployments stay enabled
  /// after the upgrade (the master [AdvertisementConfigModel.isEnabled] still
  /// overrides this to off).
  bool enabled;
  String admobAndroidAppId;
  String admobIosAppId;
  String bannerId;
  String interstitialId;
  String nativeId;

  MobileAdConfig({
    this.enabled = true,
    this.admobAndroidAppId = '',
    this.admobIosAppId = '',
    this.bannerId = '',
    this.interstitialId = '',
    this.nativeId = '',
  });

  factory MobileAdConfig.fromJson(Map<String, dynamic> json) => MobileAdConfig(
        enabled: json['enabled'] ?? true,
        admobAndroidAppId: json['admobAndroidAppId'] ?? '',
        admobIosAppId: json['admobIosAppId'] ?? '',
        bannerId: json['bannerId'] ?? '',
        interstitialId: json['interstitialId'] ?? '',
        nativeId: json['nativeId'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'admobAndroidAppId': admobAndroidAppId,
        'admobIosAppId': admobIosAppId,
        'bannerId': bannerId,
        'interstitialId': interstitialId,
        'nativeId': nativeId,
      };
}

class WebAdConfig {
  /// Per-platform enable flag — see [MobileAdConfig.enabled].
  bool enabled;
  String networkCode;
  String bannerSlotId;

  WebAdConfig({
    this.enabled = true,
    this.networkCode = '',
    this.bannerSlotId = '',
  });

  factory WebAdConfig.fromJson(Map<String, dynamic> json) => WebAdConfig(
        enabled: json['enabled'] ?? true,
        networkCode: json['networkCode'] ?? '',
        bannerSlotId: json['bannerSlotId'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'networkCode': networkCode,
        'bannerSlotId': bannerSlotId,
      };
}
