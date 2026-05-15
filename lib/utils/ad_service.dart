import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/advertisement_config_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static StreamSubscription<AdvertisementConfigModel?>? _configSubscription;

  static Future<void> init() async {
    await MobileAds.instance.initialize();
    _startListening();
  }

  static void _startListening() {
    _configSubscription?.cancel();
    _configSubscription = FireStoreUtils.advertisementConfigStream().listen((config) {
      Constant.advertisementConfig = config;
    }, onError: (e) => developer.log('AdService config stream error: $e'));
  }

  static void dispose() {
    _configSubscription?.cancel();
    _configSubscription = null;
  }

  static bool get _isActive {
    final cfg = Constant.advertisementConfig;
    return cfg != null && cfg.mobile.enabled && cfg.mobile.bannerId.isNotEmpty;
  }

  static bool get isAdmob => (Constant.advertisementConfig?.network ?? 'admob') == 'admob';

  // ── Banner ──────────────────────────────────────────────────────────────

  static BannerAd? createAdmobBanner({required BannerAdListener listener}) {
    if (!_isActive) return null;
    return BannerAd(
      adUnitId: Constant.advertisementConfig!.mobile.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    )..load();
  }

  static AdManagerBannerAd? createAdxBanner({required AdManagerBannerAdListener listener}) {
    if (!_isActive) return null;
    return AdManagerBannerAd(
      adUnitId: Constant.advertisementConfig!.mobile.bannerId,
      sizes: [AdSize.banner],
      request: const AdManagerAdRequest(),
      listener: listener,
    )..load();
  }

  // ── Interstitial ─────────────────────────────────────────────────────────

  static Future<void> showInterstitial({VoidCallback? onDismissed}) async {
    final cfg = Constant.advertisementConfig;
    if (cfg == null) {
      developer.log('AdService: config not loaded yet, skipping interstitial');
      onDismissed?.call();
      return;
    }
    if (!cfg.mobile.enabled) {
      developer.log('AdService: mobile ads disabled, skipping interstitial');
      onDismissed?.call();
      return;
    }
    if (cfg.mobile.interstitialId.isEmpty) {
      developer.log('AdService: interstitialId is empty, skipping interstitial');
      onDismissed?.call();
      return;
    }
    developer.log('AdService: loading interstitial id=${cfg.mobile.interstitialId}');

    if (isAdmob) {
      await InterstitialAd.load(
        adUnitId: cfg.mobile.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            developer.log('AdService: interstitial loaded, showing');
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (_) {
                ad.dispose();
                onDismissed?.call();
              },
              onAdFailedToShowFullScreenContent: (_, err) {
                developer.log('AdService: interstitial failed to show: $err');
                ad.dispose();
                onDismissed?.call();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (err) {
            developer.log('AdService: interstitial failed to load: $err');
            onDismissed?.call();
          },
        ),
      );
    } else {
      await AdManagerInterstitialAd.load(
        adUnitId: cfg.mobile.interstitialId,
        request: const AdManagerAdRequest(),
        adLoadCallback: AdManagerInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (_) {
                ad.dispose();
                onDismissed?.call();
              },
              onAdFailedToShowFullScreenContent: (_, __) {
                ad.dispose();
                onDismissed?.call();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (err) {
            developer.log('AdManager interstitial failed: $err');
            onDismissed?.call();
          },
        ),
      );
    }
  }

  // ── Native ───────────────────────────────────────────────────────────────

  static bool get _isNativeActive {
    final cfg = Constant.advertisementConfig;
    return cfg != null && cfg.mobile.enabled && cfg.mobile.nativeId.isNotEmpty;
  }

  static NativeAd? createNativeAd({required NativeAdListener listener}) {
    if (!_isNativeActive) return null;
    return NativeAd(
      adUnitId: Constant.advertisementConfig!.mobile.nativeId,
      listener: listener,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.medium),
    )..load();
  }

}
