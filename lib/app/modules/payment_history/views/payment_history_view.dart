import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/app/models/transaction_model.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/payment_history_controller.dart';

class PaymentHistoryView extends GetView<PaymentHistoryController> {
  const PaymentHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX(
      init: PaymentHistoryController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: AppBar(
            backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
            elevation: 0,
            leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10)),
            title: TextCustom(title: "Payment History".tr, fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          ),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),
              Expanded(
                child: controller.isLoading.value
                    ? _buildShimmer(isDark)
                    : Column(
                        children: [
                          // Tabs
                          Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, borderRadius: BorderRadius.circular(30)),
                        child: Row(
                          children: [
                            _tabButton("My Plans".tr, 0, controller, isDark),
                            _tabButton("Transactions".tr, 1, controller, isDark),
                          ],
                        ),
                      ),
                    ),
                    spaceH(height: 12),
                    // Content
                    Expanded(
                      child: controller.selectedTab.value == 0
                          ? _buildSubscriptionsList(controller, isDark)
                          : _buildTransactionsList(controller, isDark),
                    ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabButton(String title, int index, PaymentHistoryController controller, bool isDark) {
    final isActive = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: isActive ? AppThemeData.primary4 : Colors.transparent, borderRadius: BorderRadius.circular(30)),
          child: TextCustom(title: title, fontSize: isActive ? 15 : 14, fontFamily: isActive ? FontFamily.semiBold : FontFamily.regular, color: isActive ? Colors.white : (isDark ? AppThemeData.grey4 : AppThemeData.grey7)),
        ),
      ),
    );
  }

  // ─── Subscriptions Tab ─────────────────────────────────────────────────────
  Widget _buildSubscriptionsList(PaymentHistoryController controller, bool isDark) {
    if (controller.subscriptions.isEmpty) {
      return _emptyState("No subscriptions yet".tr, Icons.card_membership_outlined, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: controller.subscriptions.length,
      itemBuilder: (_, index) {
        final sub = controller.subscriptions[index];
        return _SubscriptionCard(sub: sub, isDark: isDark);
      },
    );
  }

  // ─── Transactions Tab ──────────────────────────────────────────────────────
  Widget _buildTransactionsList(PaymentHistoryController controller, bool isDark) {
    if (controller.transactions.isEmpty) {
      return _emptyState("No transactions yet".tr, Icons.receipt_long_outlined, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: controller.transactions.length,
      itemBuilder: (_, index) {
        final txn = controller.transactions[index];
        return _TransactionCard(txn: txn, isDark: isDark);
      },
    );
  }

  Widget _emptyState(String message, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(height: 72, width: 72, decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey2, shape: BoxShape.circle), child: Icon(icon, size: 32, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5)),
          spaceH(height: 16),
          TextCustom(title: message, fontSize: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30))),
            spaceH(height: 16),
            ...List.generate(4, (_) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(height: 140, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14))))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final UserSubscriptionModel sub;
  final bool isDark;

  const _SubscriptionCard({required this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currency = Constant.currencyModel?.symbol ?? '\$';
    final isActive = sub.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? AppThemeData.primary4.withValues(alpha: 0.3) : (isDark ? AppThemeData.grey8 : AppThemeData.grey3), width: isActive ? 1 : 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: (sub.packageType == 'featured_ads' ? const Color(0xffFF9500) : AppThemeData.primary4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        sub.packageType == 'featured_ads' ? Icons.star_rounded : Icons.inventory_2_outlined,
                        size: 20,
                        color: sub.packageType == 'featured_ads' ? const Color(0xffFF9500) : AppThemeData.primary4,
                      ),
                    ),
                    spaceW(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextCustom(title: () { final n = sub.packageNameFor(Get.locale?.languageCode); return n.isNotEmpty ? n : 'Package'.tr; }(), fontSize: 15, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                          TextCustom(
                            title: sub.packageType == 'featured_ads' ? 'Featured Ads'.tr : 'Ad Listing'.tr,
                            fontSize: 12,
                            color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(sub.status),
                  ],
                ),
                spaceH(height: 14),
                // Stats row
                Row(
                  children: [
                    _statItem("Price".tr, "$currency${(sub.price ?? 0).toStringAsFixed(2)}", isDark),
                    _statItem("Ads".tr, sub.isItemLimitUnlimited == true ? "${sub.adsPosted ?? 0}/\u221E" : "${sub.adsPosted ?? 0}/${sub.adLimit ?? 0}", isDark),
                    _statItem("Days".tr, sub.daysRemaining == -1 ? "\u221E" : "${sub.daysRemaining}", isDark),
                    _statItem("Via".tr, (sub.paymentMethod ?? '-').capitalizeFirst ?? '-', isDark),
                  ],
                ),
                // Progress bar
                if (isActive && sub.isItemLimitUnlimited != true && (sub.adLimit ?? 0) > 0) ...[
                  spaceH(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ((sub.adsPosted ?? 0) / (sub.adLimit ?? 1)).clamp(0.0, 1.0),
                      backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppThemeData.primary4),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Date footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey9 : AppThemeData.grey1,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                spaceW(width: 6),
                TextCustom(title: "${'Purchased:'.tr} ${_formatDate(sub.purchaseDate)}", fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                const Spacer(),
                if (sub.expiryDate != null) ...[
                  Icon(Icons.timer_outlined, size: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                  spaceW(width: 6),
                  TextCustom(title: "${'Expires:'.tr} ${_formatDate(sub.expiryDate)}", fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                ] else
                  TextCustom(title: "No Expiry".tr, fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          TextCustom(title: value, fontSize: 14, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 2),
          TextCustom(title: label, fontSize: 10, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) {
    Color color;
    switch ((status ?? 'active').toLowerCase()) {
      case 'active': color = const Color(0xff4CAF50); break;
      case 'expired': color = const Color(0xffFF9500); break;
      case 'cancelled': color = AppThemeData.danger300; break;
      default: color = AppThemeData.grey5;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text((status ?? 'active').capitalizeFirst ?? '', style: TextStyle(fontSize: 10, fontFamily: FontFamily.bold, color: color)),
    );
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSACTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final TransactionModel txn;
  final bool isDark;

  const _TransactionCard({required this.txn, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isSuccess = txn.paymentStatus == 'success';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: (isSuccess ? const Color(0xff4CAF50) : AppThemeData.danger300).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 22,
              color: isSuccess ? const Color(0xff4CAF50) : AppThemeData.danger300,
            ),
          ),
          spaceW(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(title: () { final n = txn.packageNameFor(Get.locale?.languageCode); return n.isNotEmpty ? n : 'Package'.tr; }(), fontSize: 14, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 1),
                spaceH(height: 3),
                Row(
                  children: [
                    TextCustom(title: (txn.paymentMethod ?? '-').capitalizeFirst ?? '-', fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                    TextCustom(title: "  \u2022  ", fontSize: 12, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                    TextCustom(title: _timeAgo(txn.createdAt), fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                  ],
                ),
              ],
            ),
          ),
          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${txn.currency ?? '\$'}${(txn.amount ?? 0).toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10)),
              spaceH(height: 2),
              Text(
                (txn.paymentStatus ?? 'pending').capitalizeFirst ?? '',
                style: TextStyle(fontSize: 11, fontFamily: FontFamily.medium, color: isSuccess ? const Color(0xff4CAF50) : AppThemeData.danger300),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Just now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${'m ago'.tr}';
    if (diff.inHours < 24) return '${diff.inHours}${'h ago'.tr}';
    if (diff.inDays == 1) return 'Yesterday'.tr;
    if (diff.inDays < 7) return '${diff.inDays}${'d ago'.tr}';
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
