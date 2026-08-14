import 'dart:async';
import 'dart:developer' as developer;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/advertisement_config_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
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
  static const Duration _interstitialLoadTimeout = Duration(seconds: 6);

  /// Show the interstitial on every Nth eligible tap rather than on every
  /// tap. An ad in front of every single ad-detail open makes the app feel
  /// unusable (and trips AdMob's "excessive interstitials" policy).
  static const int interstitialFrequency = 3;

  /// Counts only taps that *could* have shown an ad — i.e. taps made while
  /// ads are configured and enabled. Taps that were skipped because the
  /// config was missing don't burn a slot, so the very first tap after the
  /// config arrives still counts as #1.
  ///
  /// In-memory by design: the count resets on app restart, matching the
  /// usual per-session frequency-cap behaviour.
  static int _interstitialTapCount = 0;

  /// Resets the frequency counter — useful after logout or from tests.
  static void resetInterstitialCounter() => _interstitialTapCount = 0;

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
    // Frequency cap. Taps 1 and 2 navigate straight through with no loader
    // and no ad request; tap 3 shows the ad, then the cycle repeats.
    _interstitialTapCount++;
    if (_interstitialTapCount % interstitialFrequency != 0) {
      developer.log('AdService: tap $_interstitialTapCount of $interstitialFrequency — skipping interstitial');
      onDismissed?.call();
      return;
    }

    developer.log('AdService: tap $_interstitialTapCount — loading interstitial id=${cfg.mobile.interstitialId}');

    // ── Slow path: ads enabled → show a loader so the user knows their tap
    //    registered and waits instead of double-tapping or backing out.
    //    The loader is dismissed at the same moment the interstitial appears
    //    (or as soon as load/show fails) so it never overlaps with the ad.
    var loaderActive = true;
    void dismissLoader() {
      if (!loaderActive) return;
      loaderActive = false;
      EasyLoading.dismiss();
    }

    // Defensive timeout: if the SDK never calls back, free the user.
    final timeout = Timer(_interstitialLoadTimeout, () {
      if (loaderActive) {
        developer.log('AdService: interstitial load timed out, proceeding');
        dismissLoader();
        onDismissed?.call();
      }
    });

    // Wrap callbacks once so each terminal event fires onDismissed exactly
    // once and we never leak the loader.
    var navigated = false;
    void finish() {
      if (navigated) return;
      navigated = true;
      timeout.cancel();
      dismissLoader();
      onDismissed?.call();
    }

    EasyLoading.show(status: 'Loading...'.tr, maskType: EasyLoadingMaskType.black);

    if (isAdmob) {
      await InterstitialAd.load(
        adUnitId: cfg.mobile.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            developer.log('AdService: interstitial loaded, showing');
            timeout.cancel();
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (_) => dismissLoader(),
              onAdDismissedFullScreenContent: (_) {
                ad.dispose();
                finish();
              },
              onAdFailedToShowFullScreenContent: (_, err) {
                developer.log('AdService: interstitial failed to show: $err');
                ad.dispose();
                finish();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (err) {
            developer.log('AdService: interstitial failed to load: $err');
            finish();
          },
        ),
      );
    } else {
      await AdManagerInterstitialAd.load(
        adUnitId: cfg.mobile.interstitialId,
        request: const AdManagerAdRequest(),
        adLoadCallback: AdManagerInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            timeout.cancel();
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (_) => dismissLoader(),
              onAdDismissedFullScreenContent: (_) {
                ad.dispose();
                finish();
              },
              onAdFailedToShowFullScreenContent: (_, __) {
                ad.dispose();
                finish();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (err) {
            developer.log('AdManager interstitial failed: $err');
            finish();
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
