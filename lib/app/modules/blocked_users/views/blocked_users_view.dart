import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/blocked_users_controller.dart';

class BlockedUsersView extends GetView<BlockedUsersController> {
  const BlockedUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: AppBar(
        backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
        ),
        title: TextCustom(
          title: "Blocked Users".tr,
          fontSize: 18,
          fontFamily: FontFamily.bold,
          color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmer(isDark);
        }

        if (controller.blockedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeData.grey8 : AppThemeData.grey2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.block, size: 36, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5),
                ),
                spaceH(height: 20),
                TextCustom(
                  title: "No blocked users".tr,
                  fontSize: 16,
                  fontFamily: FontFamily.medium,
                  color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                ),
                spaceH(height: 8),
                TextCustom(
                  title: "Users you block will appear here".tr,
                  fontSize: 13,
                  color: isDark ? AppThemeData.grey6 : AppThemeData.grey5,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: controller.blockedUsers.length,
          itemBuilder: (context, index) {
            final user = controller.blockedUsers[index];
            final name = user.fullNameString();
            final profile = user.profilePic ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                      backgroundImage: profile.isNotEmpty ? CachedNetworkImageProvider(profile) : null,
                      child: profile.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
                            )
                          : null,
                    ),
                    spaceW(width: 14),
                    // Name + email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextCustom(
                            title: name,
                            fontSize: 15,
                            fontFamily: FontFamily.semiBold,
                            color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                            maxLine: 1,
                          ),
                          if (user.email != null && user.email!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: TextCustom(
                                title: user.email!,
                                fontSize: 12,
                                color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                                maxLine: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                    spaceW(width: 8),
                    // Unblock button
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => _confirmUnblock(context, controller, user.id!, name, isDark),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppThemeData.primary4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: TextCustom(
                          title: "Unblock".tr,
                          fontSize: 13,
                          fontFamily: FontFamily.semiBold,
                          color: AppThemeData.primary4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: base),
                spaceW(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                      spaceH(height: 6),
                      Container(height: 10, width: 80, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
                Container(height: 34, width: 70, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmUnblock(BuildContext context, BlockedUsersController controller, String userId, String name, bool isDark) {
    final user = controller.blockedUsers.firstWhereOrNull((u) => u.id == userId);
    final profile = user?.profilePic ?? '';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                    backgroundImage: profile.isNotEmpty ? CachedNetworkImageProvider(profile) : null,
                    child: profile.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7))
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite, shape: BoxShape.circle),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppThemeData.primary4, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              spaceH(height: 16),
              TextCustom(title: "${'Unblock'.tr} $name?", fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, textAlign: TextAlign.center),
              spaceH(height: 8),
              TextCustom(title: "They will be able to\nmessage you again.".tr, fontSize: 13, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, textAlign: TextAlign.center),
              spaceH(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    Get.back();
                    await controller.unblockUser(userId);
                    ShowToastDialog.showSuccess("user_unblocked".trParams({"name": name}));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppThemeData.primary4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: Text("Unblock".tr, style: const TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white)),
                ),
              ),
              spaceH(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: TextCustom(title: "Cancel".tr, fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
