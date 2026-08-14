import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:eSellify/utils/navigation_helper.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:get/get.dart';

/// Listens for incoming universal / app links (e.g. from a shared
/// `https://<webAppURL>/ad-detail?id=<adId>` URL) and routes the user to
/// the ad detail screen once the app has finished booting.
///
/// This is the app-side of the deep-link contract described in
/// [AdListingDetailController.shareAd] — the share sheet builds the URL,
/// the OS opens it here (or in the browser if the app isn't installed),
/// and this service converts that URL into a Get.to() navigation.
///
/// The service handles both:
///   - Cold start: the app was launched from the link.
///   - Warm resume: the app was already running and got a new link.
///
/// Setup on the native side (per admin's actual domain) is documented in
/// `docs/deep-links.md`; without it the OS never routes the URL here and
/// the browser opens the customer web app instead — which is the graceful
/// fallback described in the requirements.
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Cold start — the URI that launched the app (if any).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        // Delay until after the first frame so the navigator is ready.
        WidgetsBinding.instance.addPostFrameCallback((_) => _handle(initial));
      }
    } catch (e) {
      debugPrint('DeepLinkService: getInitialLink failed: $e');
    }

    // 2. Warm resume — new URIs delivered while the app is running.
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (e) => debugPrint('DeepLinkService: uriLinkStream error: $e'),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  Future<void> _handle(Uri uri) async {
    // We only route ad-detail URLs — everything else is ignored so an
    // unrelated intent can't accidentally deep-link inside the app.
    if (!_isAdDetailUri(uri)) return;

    // Prefer the slug param (new share links: `/ad-detail?slug=<slug>`),
    // falling back to id for links shared before slugs existed.
    final slug = uri.queryParameters['slug']?.trim();
    final adId = uri.queryParameters['id']?.trim();
    final hasSlug = slug != null && slug.isNotEmpty;
    final hasId = adId != null && adId.isNotEmpty;
    if (!hasSlug && !hasId) return;

    // Fetch the ad, then open the detail view. We fetch in-service (rather
    // than passing the raw param in arguments) so the detail controller keeps
    // its existing "argument is an AdModel" contract.
    try {
      final ad = hasSlug ? await FireStoreUtils.getAdBySlug(slug) : await FireStoreUtils.getAdById(adId!);
      if (ad != null) {
        _openAdDetail(ad);
      }
    } catch (e) {
      debugPrint('DeepLinkService: failed to load ad (slug=$slug id=$adId): $e');
    }
  }

  bool _isAdDetailUri(Uri uri) {
    // Match by path so we don't have to hardcode the admin's domain
    // (which is only known at runtime via `Constant.webAppUrl`). Any
    // custom-scheme or https link that ends in `/ad-detail` counts.
    final segments = uri.pathSegments;
    if (segments.isEmpty) return false;
    return segments.last == 'ad-detail';
  }

  void _openAdDetail(AdModel ad) {
    goToAdDetail(ad);
  }
}
