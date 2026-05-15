import 'dart:developer' as developer;

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _ad;
  bool _isLoaded = false;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) _loadAd();
  }

  void _loadAd() {
    final cfg = Constant.advertisementConfig;
    if (cfg == null || !cfg.mobile.enabled || cfg.mobile.nativeId.isEmpty) return;
    _loadStarted = true;

    final ad = NativeAd(
      adUnitId: cfg.mobile.nativeId,
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          developer.log('Native ad failed: $err');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
    )..load();

    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _ad == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 300,
            minHeight: 350,
            maxHeight: 400,
            maxWidth: double.infinity,
          ),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}