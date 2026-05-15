import 'dart:developer' as developer;

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  AdWithView? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final cfg = Constant.advertisementConfig;
    if (cfg == null || !cfg.mobile.enabled || cfg.mobile.bannerId.isEmpty) return;

    if (AdService.isAdmob) {
      _ad = AdService.createAdmobBanner(
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _isLoaded = true),
          onAdFailedToLoad: (ad, err) {
            developer.log('Banner failed: $err');
            ad.dispose();
          },
        ),
      );
    } else {
      _ad = AdService.createAdxBanner(
        listener: AdManagerBannerAdListener(
          onAdLoaded: (_) => setState(() => _isLoaded = true),
          onAdFailedToLoad: (ad, err) {
            developer.log('AdX banner failed: $err');
            ad.dispose();
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _ad == null) return const SizedBox.shrink();

    return SizedBox(
      width: AdSize.banner.width.toDouble(),
      height: AdSize.banner.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
