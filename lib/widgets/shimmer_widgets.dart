import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:flutter/material.dart';

class ShimmerWidgets {
  static Color _base(bool isDark) => isDark ? AppThemeData.grey9 : AppThemeData.grey3;
  static Color _highlight(bool isDark) => isDark ? AppThemeData.grey8 : AppThemeData.grey2;
  static Color _card(bool isDark) => isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;

  // ─── Home Page ────────────────────────────────────────────────────
  static Widget homeShimmer(bool isDark) {
    final base = _base(isDark);
    final card = _card(isDark);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: _highlight(isDark),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(height: 48, decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12))),
            spaceH(height: 16),
            // Banner
            Container(height: 160, decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14))),
            spaceH(height: 16),
            // Categories header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 16, width: 100, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                Container(height: 14, width: 50, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
              ],
            ),
            spaceH(height: 12),
            // Category chips
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (_, _) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(height: 56, width: 56, decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14))),
                      spaceH(height: 6),
                      Container(height: 10, width: 50, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ),
            ),
            spaceH(height: 20),
            // Section header
            Container(height: 16, width: 140, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
            spaceH(height: 12),
            // Ad cards row
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (_, _) => _adCardShimmer(base, card),
              ),
            ),
            spaceH(height: 20),
            // Another section
            Container(height: 16, width: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
            spaceH(height: 12),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (_, _) => _adCardShimmer(base, card),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _adCardShimmer(Color base, Color card) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 160,
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 120, decoration: BoxDecoration(color: base, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)))),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                  spaceH(height: 6),
                  Container(height: 10, width: 80, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                  spaceH(height: 8),
                  Container(height: 14, width: 60, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Ad List (Grid) ───────────────────────────────────────────────
  static Widget adListShimmer(bool isDark) {
    final base = _base(isDark);
    final card = _card(isDark);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: _highlight(isDark),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(color: base, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                      spaceH(height: 6),
                      Container(height: 10, width: 80, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                      const Spacer(),
                      Container(height: 14, width: 60, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── List Items (Favourites, My Ads, etc.) ────────────────────────
  static Widget listItemShimmer(bool isDark, {int count = 6}) {
    final base = _base(isDark);
    final card = _card(isDark);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: _highlight(isDark),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 110,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(height: 90, width: 90, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10))),
                spaceW(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                      spaceH(height: 8),
                      Container(height: 10, width: 100, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                      spaceH(height: 8),
                      Container(height: 12, width: 70, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
