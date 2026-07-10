import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/constant_widgets/custom_dialog_box.dart';
import 'package:eSellify/app/modules/contact_us/views/contact_us_view.dart';
import 'package:eSellify/app/modules/favourites/views/favourites_view.dart';
import 'package:eSellify/app/modules/follow/views/follow_list_view.dart';
import 'package:eSellify/app/modules/language/views/language_view.dart';
import 'package:eSellify/app/modules/dashboard_screen/controllers/dashboard_screen_controller.dart';
import 'package:eSellify/app/modules/my_address/views/my_address_view.dart';
import 'package:eSellify/app/modules/my_ads/views/my_ads_view.dart';
import 'package:eSellify/app/modules/notifications/views/notifications_view.dart';
import 'package:eSellify/app/modules/payment_history/views/payment_history_view.dart';
import 'package:eSellify/app/modules/subscriptions/views/subscriptions_view.dart';
import 'package:eSellify/app/modules/dashboard_screen/views/dashboard_screen_view.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/verified_badge.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<ProfileController>(
      init: ProfileController(),
      builder: (controller) {
        final isDark = themeChange.isDarkTheme();
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(
            context,
            themeChange,
            "Profile",
            isBack: false,
            actions: [
              GestureDetector(
                onTap: () async {
                  var result = await Get.toNamed(Routes.EDIT_PROFILE);
                  if (result == true) controller.getData();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey1, borderRadius: BorderRadius.circular(10)),
                  child: SvgPicture.asset(
                    "assets/icons/ic_edit_2.svg",
                    height: 18,
                    colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey3 : AppThemeData.grey8, BlendMode.srcIn),
                  ),
                ),
              ).paddingOnly(right: 16),
            ],
          ),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),
              Expanded(
                child: controller.isLoading.value
                    ? Constant.loader(context: context)
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                              child: Column(children: [_buildProfileHeader(themeChange), spaceH(height: 16), _buildMenuSection(context, themeChange)]),
                            ),
                            spaceH(height: 24),
                          ],
                        ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Profile Header ───────────────────────────────────────────────
  Widget _buildProfileHeader(DarkThemeProvider theme) {
    final isDark = theme.isDarkTheme();
    final isVerified = controller.userModel.value.isVerified == true;
    final verificationStatus = controller.userModel.value.verificationStatus ?? 'unverified';

    return Container(
      decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          children: [
            // Avatar + Name
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                NetworkImageWidget(imageUrl: controller.userModel.value.profilePic.toString(), height: 72, width: 72, borderRadius: 200, fit: BoxFit.cover),
                if (isVerified)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, shape: BoxShape.circle),
                    child: const VerifiedBadge(size: 20),
                  ),
              ],
            ),
            spaceH(height: 12),
            TextCustom(title: controller.userModel.value.fullNameString(), fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
            spaceH(height: 2),
            TextCustom(title: controller.userModel.value.email.toString(), fontSize: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
            spaceH(height: 12),
            _buildFollowStats(isDark),
            spaceH(height: 14),
            // Verification banner
            GestureDetector(
              onTap: () async {
                await Get.toNamed(Routes.VERIFICATION);
                controller.getData();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppThemeData.success300.withValues(alpha: 0.08)
                      : (verificationStatus == 'pending' || verificationStatus == 'resubmitted')
                      ? Colors.orange.withValues(alpha: 0.08)
                      : AppThemeData.primary4.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isVerified
                            ? AppThemeData.success300.withValues(alpha: 0.15)
                            : (verificationStatus == 'pending' || verificationStatus == 'resubmitted')
                            ? Colors.orange.withValues(alpha: 0.15)
                            : AppThemeData.primary4.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          isVerified
                              ? "assets/icons/ic_crown.svg"
                              : (verificationStatus == 'pending' || verificationStatus == 'resubmitted')
                              ? "assets/icons/ic_bell_2.svg"
                              : "assets/icons/ic_info.svg",
                          height: 16,
                          colorFilter: ColorFilter.mode(
                            isVerified
                                ? AppThemeData.success300
                                : (verificationStatus == 'pending' || verificationStatus == 'resubmitted')
                                ? Colors.orange
                                : AppThemeData.primary4,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    spaceW(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextCustom(
                            title: isVerified
                                ? 'Verified Account'.tr
                                : (verificationStatus == 'pending' || verificationStatus == 'resubmitted')
                                ? 'Verification Under Review'.tr
                                : 'Get Verified'.tr,
                            fontSize: 13,
                            fontFamily: FontFamily.medium,
                            color: isVerified
                                ? AppThemeData.success300
                                : (verificationStatus == 'pending' || verificationStatus == 'resubmitted')
                                ? Colors.orange
                                : AppThemeData.primary4,
                          ),
                          if (!isVerified && verificationStatus != 'pending' && verificationStatus != 'resubmitted')
                            TextCustom(title: 'Tap to verify your identity'.tr, fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                        ],
                      ),
                    ),
                    SvgPicture.asset(
                      "assets/icons/ic_arrow_right.svg",
                      height: 14,
                      colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey5 : AppThemeData.grey6, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Followers / Following stats ─────────────────────────────────
  Widget _buildFollowStats(bool isDark) {
    final uid = controller.userModel.value.id ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<Map<String, int>>(
      stream: FireStoreUtils.followCountsStream(uid),
      builder: (context, snap) {
        final c = snap.data ?? const {'followers': 0, 'following': 0};
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statChip(
              isDark,
              count: c['followers']!,
              label: c['followers'] == 1 ? 'Follower'.tr : 'Followers'.tr,
              onTap: () => Get.to(() => FollowListView(uid: uid, mode: FollowListMode.followers)),
            ),
            Container(width: 1, height: 26, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
            _statChip(
              isDark,
              count: c['following']!,
              label: 'Following'.tr,
              onTap: () => Get.to(() => FollowListView(uid: uid, mode: FollowListMode.following)),
            ),
          ],
        );
      },
    );
  }

  Widget _statChip(bool isDark, {required int count, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              TextCustom(title: '$count', fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              spaceH(height: 2),
              TextCustom(title: label, fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Menu Sections ────────────────────────────────────────────────
  Widget _buildMenuSection(BuildContext context, DarkThemeProvider theme) {
    final isDark = theme.isDarkTheme();
    return Column(
      children: [
        // My Activity — things users check most often
        _buildSectionCard(isDark, 'My Activity'.tr, [
          _MenuItem(svg: "assets/icons/ic_bell_2.svg", title: "Notifications".tr, onTap: () => Get.to(NotificationsView())),
          _MenuItem(svg: "assets/icons/ic_heart.svg", title: "Favourites".tr, onTap: () => Get.to(FavouritesView())),
          _MenuItem(
            svg: "assets/icons/ic_crown.svg",
            title: "My Featured Ads".tr,
            onTap: () => Get.to(MyAdsView(), arguments: {"featured": true}),
          ),
          _MenuItem(svg: "assets/icons/ic_cart.svg", title: "My Purchases".tr, onTap: () => Get.toNamed(Routes.MY_PURCHASES)),
          _MenuItem(svg: "assets/icons/ic_order.svg", title: "Job Applications".tr, onTap: () => Get.toNamed(Routes.JOB_APPLICATIONS)),
          _MenuItem(
            svg: "assets/icons/ic_info.svg",
            title: "My Reviews".tr,
            onTap: () => Get.toNamed(Routes.SELLER_REVIEWS, arguments: {'sellerId': controller.userModel.value.id, 'sellerName': controller.userModel.value.fullNameString()}),
          ),
        ]),
        spaceH(height: 12),

        // Subscriptions & Payments
        _buildSectionCard(isDark, !Constant.freeAdListing || !Constant.freeAdFeaturing ? 'Subscriptions & Payments'.tr : 'Payments', [
          if (!Constant.freeAdListing || !Constant.freeAdFeaturing)
            _MenuItem(svg: "assets/icons/ic_subscription.svg", title: "Subscriptions".tr, onTap: () => Get.to(SubscriptionsView())),
          _MenuItem(svg: "assets/icons/ic_payment_history.svg", title: "Payment History".tr, onTap: () => Get.to(PaymentHistoryView())),
        ]),
        spaceH(height: 12),
        // Account & Verification
        _buildSectionCard(isDark, 'Account'.tr, [
          _MenuItem(svg: "assets/icons/ic_order.svg", title: "Verification".tr, onTap: () => Get.toNamed(Routes.VERIFICATION)),
          _MenuItem(svg: "assets/icons/ic_map_pin.svg", title: "My Address".tr, onTap: () => Get.to(MyAddressView(isFromProfile: true))),
          _MenuItem(svg: "assets/icons/ic_blocked_user.svg", title: "My Reports".tr, onTap: () => Get.toNamed(Routes.MY_REPORTS)),
        ]),
        spaceH(height: 12),
        // Help & Legal
        _buildSectionCard(isDark, 'Help & Legal'.tr, [
          _MenuItem(svg: "assets/icons/ic_phone_2.svg", title: "Contact us".tr, onTap: () => Get.to(ContactUsView())),
          _MenuItem(
            svg: "assets/icons/ic_privacy_policy.svg",
            title: "Privacy & Policy".tr,
            onTap: () => Get.toNamed(Routes.HTML_SCREEN, arguments: {'title': 'Privacy & Policy', 'type': 'privacy'}),
          ),
          _MenuItem(
            svg: "assets/icons/ic_terms.svg",
            title: "Terms & Condition".tr,
            onTap: () => Get.toNamed(Routes.HTML_SCREEN, arguments: {'title': 'Terms & Condition', 'type': 'terms'}),
          ),
          _MenuItem(
            svg: "assets/icons/ic_global.svg",
            title: "About us".tr,
            onTap: () => Get.toNamed(Routes.HTML_SCREEN, arguments: {'title': 'About us', 'type': 'about'}),
          ),
        ]),
        spaceH(height: 12),
        // App Settings
        _buildAppSettingsCard(context, theme),
        spaceH(height: 12),
        // Danger zone
        _buildDangerCard(context, theme),
      ],
    );
  }

  Widget _buildSectionCard(bool isDark, String title, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: TextCustom(title: title, fontSize: 13, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          ),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return Column(
              children: [
                InkWell(
                  onTap: item.onTap,
                  borderRadius: isLast ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)) : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: AppThemeData.primary4.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: SvgPicture.asset(item.svg, height: 18, colorFilter: ColorFilter.mode(AppThemeData.primary4, BlendMode.srcIn))),
                        ),
                        spaceW(width: 14),
                        Expanded(
                          child: TextCustom(title: item.title, fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                        ),
                        SvgPicture.asset(
                          "assets/icons/ic_arrow_right.svg",
                          height: 14,
                          colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey6 : AppThemeData.grey5, BlendMode.srcIn),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 66),
                    child: Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey2),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard(BuildContext context, DarkThemeProvider theme) {
    final isDark = theme.isDarkTheme();
    return Container(
      decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: TextCustom(title: 'App Settings'.tr, fontSize: 13, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          ),
          // Language
          InkWell(
            onTap: () => Get.to(LanguageView(isFirstTime: false)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppThemeData.primary4.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: SvgPicture.asset("assets/icons/ic_language.svg", height: 18, colorFilter: ColorFilter.mode(AppThemeData.primary4, BlendMode.srcIn))),
                  ),
                  spaceW(width: 14),
                  Expanded(
                    child: TextCustom(title: "Language".tr, fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                  ),
                  SvgPicture.asset("assets/icons/ic_arrow_right.svg", height: 14, colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey6 : AppThemeData.grey5, BlendMode.srcIn)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey2),
          ),
          // Dark Mode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppThemeData.primary4.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: SvgPicture.asset("assets/icons/ic_sun.svg", height: 18, colorFilter: ColorFilter.mode(AppThemeData.primary4, BlendMode.srcIn))),
                ),
                spaceW(width: 14),
                Expanded(
                  child: TextCustom(title: "Dark Mode".tr, fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                ),
                SizedBox(
                  height: 26,
                  child: FittedBox(
                    child: CupertinoSwitch(activeColor: AppThemeData.primary4, value: theme.isDarkTheme(), onChanged: (value) => theme.darkTheme = value ? 0 : 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard(BuildContext context, DarkThemeProvider theme) {
    final isDark = theme.isDarkTheme();
    return Container(
      decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showDeleteAccountDialog(context, controller),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppThemeData.danger300.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: SvgPicture.asset("assets/icons/ic_delete.svg", height: 18, colorFilter: ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn))),
                  ),
                  spaceW(width: 14),
                  Expanded(
                    child: TextCustom(title: "Delete Account".tr, fontSize: 14, fontFamily: FontFamily.medium, color: AppThemeData.danger300),
                  ),
                  SvgPicture.asset("assets/icons/ic_arrow_right.svg", height: 14, colorFilter: ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey2),
          ),
          InkWell(
            onTap: () => _showLogoutDialog(context, controller),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppThemeData.danger300.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: SvgPicture.asset("assets/icons/ic_logout.svg", height: 18, colorFilter: ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn))),
                  ),
                  spaceW(width: 14),
                  Expanded(
                    child: TextCustom(title: "Log out".tr, fontSize: 14, fontFamily: FontFamily.medium, color: AppThemeData.danger300),
                  ),
                  SvgPicture.asset("assets/icons/ic_arrow_right.svg", height: 14, colorFilter: ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context, ProfileController controller) {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialogBox(
          title: "Log out".tr,
          descriptions: "Are you sure you want to logout?".tr,
          img: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2, shape: BoxShape.circle),
            child: Center(child: SvgPicture.asset("assets/icons/ic_logout.svg", height: 30, colorFilter: ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn))),
          ),
          positiveButtonColor: AppThemeData.danger300,
          positiveButtonBorderColor: AppThemeData.danger300,
          positiveButtonTextColor: AppThemeData.primaryWhite,
          negativeButtonColor: Colors.transparent,
          negativeButtonTextColor: AppThemeData.danger300,
          negativeButtonBorderColor: AppThemeData.danger300,
          positiveClick: () async {
            Get.back();
            ShowToastDialog.showLoader("Logging out...".tr);
            try {
              // Clear FCM token before signing out
              await FireStoreUtils.clearFcmToken();
              await FirebaseAuth.instance.signOut();
              Constant.userModel = null;
              ShowToastDialog.closeLoader();
              Get.delete<DashboardScreenController>(); // ← clears stale state
              Get.offAll(const DashboardScreenView());
            } catch (e) {
              ShowToastDialog.closeLoader();
              ShowToastDialog.showError("Failed to logout. Please try again.".tr);
            }
          },
          negativeClick: () => Get.back(),
          positiveString: "Logout",
          negativeString: "Cancel",
          themeChange: themeChange,
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, ProfileController controller) {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialogBox(
          title: "Delete Account".tr,
          descriptions: "Are you sure you want to delete your account? This will permanently erase your data and listings.".tr,
          img: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2, shape: BoxShape.circle),
            child: Center(child: SvgPicture.asset("assets/icons/ic_delete.svg", height: 30, colorFilter: ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn))),
          ),
          positiveButtonColor: AppThemeData.danger300,
          positiveButtonBorderColor: AppThemeData.danger300,
          positiveButtonTextColor: AppThemeData.primaryWhite,
          negativeButtonColor: Colors.transparent,
          negativeButtonTextColor: AppThemeData.danger300,
          negativeButtonBorderColor: AppThemeData.danger300,
          positiveClick: () async {
            Get.back();
            ShowToastDialog.showLoader("Deleting account...".tr);
            try {
              await FireStoreUtils.deleteUserAccount();
              Constant.userModel = null;
              ShowToastDialog.closeLoader();
              Get.delete<DashboardScreenController>(); // ← clears stale state
              Get.offAll(const DashboardScreenView());
              ShowToastDialog.showSuccess("Account deleted successfully".tr);
            } on FirebaseAuthException catch (_) {
              // If Auth delete fails (requires recent login), sign out and redirect
              ShowToastDialog.closeLoader();
              await FirebaseAuth.instance.signOut();
              Constant.userModel = null;
              Get.offAllNamed(Routes.LOGIN_SCREEN);
              ShowToastDialog.showError("Please login again to delete your account".tr);
            } catch (e) {
              ShowToastDialog.closeLoader();
              ShowToastDialog.showError("Failed to delete account. Please try again.".tr);
            }
          },
          negativeClick: () => Get.back(),
          positiveString: "Delete",
          negativeString: "Cancel",
          themeChange: themeChange,
        );
      },
    );
  }
}

class _MenuItem {
  final String svg;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({required this.svg, required this.title, required this.onTap});
}
