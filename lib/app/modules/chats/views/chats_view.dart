import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/chat_room_model.dart';
import 'package:eSellify/app/modules/chats/views/chat_detail_view.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/chats_controller.dart';

class ChatsView extends GetView<ChatsController> {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetBuilder<ChatsController>(
      init: ChatsController(),
      builder: (controller) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
            appBar: AppBar(
              backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
              automaticallyImplyLeading: false,
              elevation: 0,
              centerTitle: false,
              title: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: TextCustom(title: "Chats".tr, fontSize: 20, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              ),
              actions: [
                // Blocked users
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () => Get.toNamed(Routes.BLOCKED_USERS),
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/icons/ic_blocked_user.svg",
                          colorFilter: ColorFilter.mode(Colors.red.shade400, BlendMode.srcIn),
                          height: 20,
                          width: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              bottom: TabBar(
                labelColor: AppThemeData.primary4,
                unselectedLabelColor: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                labelStyle: const TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold),
                unselectedLabelStyle: const TextStyle(fontSize: 15, fontFamily: FontFamily.regular),
                indicatorColor: AppThemeData.primary4,
                indicatorWeight: 3,
                dividerColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                tabs:  [
                  Tab(text: "Selling".tr),
                  Tab(text: "Buying".tr),
                ],
              ),
            ),
            body: Column(
              children: [
                const Center(child: AdBannerWidget()),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value || controller.isAdsLoading.value) {
                      return TabBarView(
                        children: [
                          _SellingShimmerList(isDark: isDark),
                          _BuyingShimmerList(isDark: isDark),
                        ],
                      );
                    }

                    if (controller.currentUserId == null) {
                      return TabBarView(
                        children: [
                          _buildEmptyState(isDark, "Please login to view your messages", Icons.login_rounded),
                          _buildEmptyState(isDark, "Please login to view your messages", Icons.login_rounded),
                        ],
                      );
                    }

                    return TabBarView(children: [_buildSellingTab(context, controller, isDark), _buildBuyingTab(controller, isDark)]);
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SELLING TAB — grouped by active ads
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSellingTab(BuildContext context, ChatsController controller, bool isDark) {
    final liveAds = controller.liveAds;
    final soldAds = controller.soldAdsWithChats;

    if (liveAds.isEmpty && soldAds.isEmpty) {
      return _buildEmptyState(isDark, "No active ads yet\nPost an ad to start selling", Icons.storefront_outlined);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        // Live ads
        ...liveAds.map((ad) {
          final chats = controller.chatsForAd(ad.id ?? '');
          final totalUnread = controller.totalUnreadForAd(ad.id ?? '');
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SellingAdCard(
              ad: ad,
              chats: chats,
              totalUnread: totalUnread,
              currentUserId: controller.currentUserId!,
              isDark: isDark,
              onTapAd: () => Get.to(() => AdBuyerChatsView(ad: ad)),
              onTapChat: (room) => Get.to(() => ChatDetailView(chatRoom: room)),
              onBlockUser: (room) => _showBlockDialog(context, controller, room, isDark),
            ),
          );
        }),

        // Sold ads section header
        if (soldAds.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeData.grey8 : AppThemeData.grey2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sell_outlined, size: 14, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
                      const SizedBox(width: 6),
                      TextCustom(title: "Sold Out".tr, fontSize: 12, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Divider(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3)),
              ],
            ),
          ),
          // Sold ad cards
          ...soldAds.map((ad) {
            final chats = controller.chatsForAd(ad.id ?? '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: 0.7,
                child: _SellingAdCard(
                  ad: ad,
                  chats: chats,
                  totalUnread: 0,
                  currentUserId: controller.currentUserId!,
                  isDark: isDark,
                  isSold: true,
                  onTapAd: () => Get.to(() => AdBuyerChatsView(ad: ad)),
                  onTapChat: (room) => Get.to(() => ChatDetailView(chatRoom: room)),
                  onBlockUser: (room) => _showBlockDialog(context, controller, room, isDark),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUYING TAB — flat list with product image + owner + category
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBuyingTab(ChatsController controller, bool isDark) {
    final rooms = controller.buyingChats;

    if (rooms.isEmpty) {
      return _buildEmptyState(isDark, "No conversations yet\nBrowse ads and start chatting", Icons.shopping_bag_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _BuyingChatCard(
            room: room,
            currentUserId: controller.currentUserId!,
            isDark: isDark,
            onTap: () => Get.to(() => ChatDetailView(chatRoom: room)),
            onBlock: () => _showBlockDialog(context, controller, room, isDark),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(bool isDark, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(color: (isDark ? AppThemeData.grey8 : AppThemeData.grey2), shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5),
          ),
          spaceH(height: 20),
          TextCustom(title: message, fontSize: 14, fontFamily: FontFamily.regular, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context, ChatsController controller, ChatRoomModel room, bool isDark) {
    final otherName = room.otherUserName(controller.currentUserId!);
    final otherUserId = room.otherUserId(controller.currentUserId!);
    final otherProfile = room.otherUserProfile(controller.currentUserId!);

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
                    backgroundImage: otherProfile.isNotEmpty ? CachedNetworkImageProvider(otherProfile) : null,
                    child: otherProfile.isEmpty
                        ? Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
                    )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite, shape: BoxShape.circle),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.block, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              spaceH(height: 16),
              TextCustom(
                title: "Block $otherName?",
                fontSize: 18,
                fontFamily: FontFamily.bold,
                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                textAlign: TextAlign.center,
              ),
              spaceH(height: 8),
              TextCustom(
                title: "They won't be able to message you\nand their chats will be hidden.",
                fontSize: 13,
                color: isDark ? AppThemeData.grey4 : AppThemeData.grey6,
                textAlign: TextAlign.center,
              ),
              spaceH(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    Get.back();
                    await controller.blockUser(otherUserId);
                    ShowToastDialog.showSuccess("$otherName has been blocked");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Block",
                    style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white),
                  ),
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

// ═══════════════════════════════════════════════════════════════════════════════
// SELLING AD CARD — attractive card with ad info + inline buyer preview
// ═══════════════════════════════════════════════════════════════════════════════
class _SellingAdCard extends StatelessWidget {
  final AdModel ad;
  final List<ChatRoomModel> chats;
  final int totalUnread;
  final String currentUserId;
  final bool isDark;
  final bool isSold;
  final VoidCallback onTapAd;
  final Function(ChatRoomModel) onTapChat;
  final Function(ChatRoomModel) onBlockUser;

  const _SellingAdCard({
    required this.ad,
    required this.chats,
    required this.totalUnread,
    required this.currentUserId,
    required this.isDark,
    this.isSold = false,
    required this.onTapAd,
    required this.onTapChat,
    required this.onBlockUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
      ),
      child: Column(
        children: [
          // Ad header — tap to see all buyer chats
          InkWell(
            onTap: chats.isNotEmpty ? onTapAd : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Ad image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (ad.mainImage != null && ad.mainImage!.isNotEmpty)
                        ? CachedNetworkImage(
                      imageUrl: ad.mainImage!,
                      height: 56,
                      width: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(height: 56, width: 56, color: isDark ? AppThemeData.grey9 : AppThemeData.grey2),
                    )
                        : Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.image_outlined, size: 22, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                    ),
                  ),
                  spaceW(width: 12),
                  // Ad info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextCustom(
                                title: ad.title ?? 'Untitled',
                                fontSize: 15,
                                fontFamily: FontFamily.semiBold,
                                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                                maxLine: 1,
                              ),
                            ),
                            if (isSold)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xff007AFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: TextCustom(title: "Sold".tr, fontSize: 10, fontFamily: FontFamily.bold, color: const Color(0xff007AFF)),
                              ),
                          ],
                        ),
                        spaceH(height: 3),
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                            spaceW(width: 4),
                            TextCustom(
                              title: "${chats.length} ${chats.length == 1 ? 'inquiry' : 'inquiries'}",
                              fontSize: 12,
                              color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Unread badge
                  if (totalUnread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppThemeData.primary4, borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        totalUnread > 99 ? '99+' : totalUnread.toString(),
                        style: const TextStyle(fontSize: 12, fontFamily: FontFamily.bold, color: Colors.white),
                      ),
                    ),
                  if (chats.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.chevron_right, size: 22, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                    ),
                ],
              ),
            ),
          ),

          // Preview of recent buyers (max 2)
          if (chats.isNotEmpty) ...[
            Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey2),
            ...chats.take(2).map((room) {
              final buyerName = room.otherUserName(currentUserId);
              final buyerProfile = room.otherUserProfile(currentUserId);
              final unread = room.myUnreadCount(currentUserId);
              final lastMsg = _formatLastMessage(room);
              final time = _formatTime(room);

              return InkWell(
                onTap: () => onTapChat(room),
                onLongPress: () => onBlockUser(room),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      spaceW(width: 4),
                      // Buyer avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                        backgroundImage: buyerProfile.isNotEmpty ? CachedNetworkImageProvider(buyerProfile) : null,
                        child: buyerProfile.isEmpty
                            ? Text(
                          buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 13, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
                        )
                            : null,
                      ),
                      spaceW(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextCustom(
                                    title: buyerName,
                                    fontSize: 13,
                                    fontFamily: unread > 0 ? FontFamily.bold : FontFamily.medium,
                                    color: isDark ? AppThemeData.grey2 : AppThemeData.grey9,
                                    maxLine: 1,
                                  ),
                                ),
                                if (time.isNotEmpty)
                                  TextCustom(title: time, fontSize: 11, color: unread > 0 ? AppThemeData.primary4 : (isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
                              ],
                            ),
                            if (lastMsg.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextCustom(
                                        title: lastMsg,
                                        fontSize: 12,
                                        fontFamily: unread > 0 ? FontFamily.medium : FontFamily.regular,
                                        color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                                        maxLine: 1,
                                      ),
                                    ),
                                    if (unread > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(color: AppThemeData.primary4, borderRadius: BorderRadius.circular(10)),
                                        child: Text(
                                          unread > 99 ? '99+' : unread.toString(),
                                          style: const TextStyle(fontSize: 10, fontFamily: FontFamily.bold, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // "View all" if more than 3
            if (chats.length > 3)
              InkWell(
                onTap: onTapAd,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: TextCustom(title: "View all ${chats.length} conversations", fontSize: 13, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _formatLastMessage(ChatRoomModel room) {
    if (room.lastMessage == null || room.lastMessage!.isEmpty) return '';
    if (room.lastMessageType == 'offer') return '\u{1F4B0} ${room.lastMessage}';
    if (room.lastMessageType == 'image') return '\u{1F4F7} Photo';
    return room.lastMessage!;
  }

  String _formatTime(ChatRoomModel room) {
    if (room.lastMessageTime == null) return '';
    final dt = room.lastMessageTime!.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $amPm';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BUYING CHAT CARD — product image + owner name + category + last msg + unread
// ═══════════════════════════════════════════════════════════════════════════════
class _BuyingChatCard extends StatelessWidget {
  final ChatRoomModel room;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onBlock;

  const _BuyingChatCard({required this.room, required this.currentUserId, required this.isDark, required this.onTap, required this.onBlock});

  @override
  Widget build(BuildContext context) {
    final sellerName = room.otherUserName(currentUserId);
    final unread = room.myUnreadCount(currentUserId);
    final lastMsg = _formatLastMessage();
    final time = _formatTime();
    final category = room.adCategory ?? '';

    return InkWell(
      onTap: onTap,
      onLongPress: onBlock,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (room.adImage != null && room.adImage!.isNotEmpty)
                  ? CachedNetworkImage(
                imageUrl: room.adImage!,
                height: 64,
                width: 64,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 64, width: 64, color: isDark ? AppThemeData.grey9 : AppThemeData.grey2),
                errorWidget: (_, __, ___) => _imagePlaceholder(),
              )
                  : _imagePlaceholder(),
            ),
            spaceW(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Owner name + time
                  Row(
                    children: [
                      Expanded(
                        child: TextCustom(
                          title: sellerName,
                          fontSize: 15,
                          fontFamily: unread > 0 ? FontFamily.bold : FontFamily.semiBold,
                          color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                          maxLine: 1,
                        ),
                      ),
                      if (time.isNotEmpty) TextCustom(title: time, fontSize: 11, color: unread > 0 ? AppThemeData.primary4 : (isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
                    ],
                  ),
                  spaceH(height: 3),
                  // Ad title + category
                  Row(
                    children: [
                      Expanded(
                        child: TextCustom(
                          title: room.adTitle ?? '',
                          fontSize: 13,
                          fontFamily: FontFamily.medium,
                          color: isDark ? AppThemeData.grey3 : AppThemeData.grey8,
                          maxLine: 1,
                        ),
                      ),
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey2, borderRadius: BorderRadius.circular(8)),
                          child: TextCustom(title: category, fontSize: 10, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
                        ),
                    ],
                  ),
                  spaceH(height: 4),
                  // Last message + unread
                  Row(
                    children: [
                      Expanded(
                        child: TextCustom(
                          title: lastMsg.isEmpty ? 'Start a conversation' : lastMsg,
                          fontSize: 12,
                          fontFamily: unread > 0 ? FontFamily.medium : FontFamily.regular,
                          color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                          maxLine: 1,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppThemeData.primary4, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            unread > 99 ? '99+' : unread.toString(),
                            style: const TextStyle(fontSize: 11, fontFamily: FontFamily.bold, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            spaceW(width: 6),
            Icon(Icons.chevron_right, size: 22, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Icon(Icons.image_outlined, size: 22, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
    );
  }

  String _formatLastMessage() {
    if (room.lastMessage == null || room.lastMessage!.isEmpty) return '';
    if (room.lastMessageType == 'offer') return '\u{1F4B0} ${room.lastMessage}';
    if (room.lastMessageType == 'image') return '\u{1F4F7} Photo';
    return room.lastMessage!;
  }

  String _formatTime() {
    if (room.lastMessageTime == null) return '';
    final dt = room.lastMessageTime!.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $amPm';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AD BUYER CHATS VIEW — full screen with all buyer chats for a specific ad
// ═══════════════════════════════════════════════════════════════════════════════
class AdBuyerChatsView extends StatelessWidget {
  final AdModel ad;

  const AdBuyerChatsView({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetBuilder<ChatsController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: AppBar(
            backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (ad.mainImage != null && ad.mainImage!.isNotEmpty)
                      ? CachedNetworkImage(imageUrl: ad.mainImage!, height: 34, width: 34, fit: BoxFit.cover)
                      : Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.image_outlined, size: 16, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                  ),
                ),
                spaceW(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(
                        title: ad.title ?? 'Ad Chats',
                        fontSize: 15,
                        fontFamily: FontFamily.semiBold,
                        color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                        maxLine: 1,
                      ),
                      if (ad.leafCategoryName != null) TextCustom(title: ad.leafCategoryName!, fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Obx(() {
            final chats = controller.chatsForAd(ad.id ?? '');

            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey2, shape: BoxShape.circle),
                      child: Icon(Icons.chat_bubble_outline_rounded, size: 32, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5),
                    ),
                    spaceH(height: 16),
                    TextCustom(title: "No inquiries yet".tr, fontSize: 14, fontFamily: FontFamily.regular, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final room = chats[index];
                final buyerName = room.otherUserName(controller.currentUserId!);
                final buyerProfile = room.otherUserProfile(controller.currentUserId!);
                final unread = room.myUnreadCount(controller.currentUserId!);
                final lastMsg = _formatLastMessage(room);
                final time = _formatTime(room);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => Get.to(() => ChatDetailView(chatRoom: room)),
                    onLongPress: () => _showBlockDialog(context, controller, room, isDark),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                            backgroundImage: buyerProfile.isNotEmpty ? CachedNetworkImageProvider(buyerProfile) : null,
                            child: buyerProfile.isEmpty
                                ? Text(
                              buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 15, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
                            )
                                : null,
                          ),
                          spaceW(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextCustom(
                                        title: buyerName,
                                        fontSize: 14,
                                        fontFamily: unread > 0 ? FontFamily.bold : FontFamily.medium,
                                        color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                                        maxLine: 1,
                                      ),
                                    ),
                                    if (time.isNotEmpty)
                                      TextCustom(title: time, fontSize: 11, color: unread > 0 ? AppThemeData.primary4 : (isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
                                  ],
                                ),
                                spaceH(height: 3),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextCustom(
                                        title: lastMsg.isEmpty ? 'Start a conversation' : lastMsg,
                                        fontSize: 12,
                                        fontFamily: unread > 0 ? FontFamily.medium : FontFamily.regular,
                                        color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                                        maxLine: 1,
                                      ),
                                    ),
                                    if (unread > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(color: AppThemeData.primary4, borderRadius: BorderRadius.circular(10)),
                                        child: Text(
                                          unread > 99 ? '99+' : unread.toString(),
                                          style: const TextStyle(fontSize: 10, fontFamily: FontFamily.bold, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          spaceW(width: 4),
                          Icon(Icons.chevron_right, size: 20, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }

  void _showBlockDialog(BuildContext context, ChatsController controller, ChatRoomModel room, bool isDark) {
    final otherName = room.otherUserName(controller.currentUserId!);
    final otherUserId = room.otherUserId(controller.currentUserId!);
    final otherProfile = room.otherUserProfile(controller.currentUserId!);

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
                    backgroundImage: otherProfile.isNotEmpty ? CachedNetworkImageProvider(otherProfile) : null,
                    child: otherProfile.isEmpty
                        ? Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7),
                    )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite, shape: BoxShape.circle),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.block, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              spaceH(height: 16),
              TextCustom(
                title: "Block $otherName?",
                fontSize: 18,
                fontFamily: FontFamily.bold,
                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                textAlign: TextAlign.center,
              ),
              spaceH(height: 8),
              TextCustom(
                title: "They won't be able to message you\nand their chats will be hidden.",
                fontSize: 13,
                color: isDark ? AppThemeData.grey4 : AppThemeData.grey6,
                textAlign: TextAlign.center,
              ),
              spaceH(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    Get.back();
                    await controller.blockUser(otherUserId);
                    ShowToastDialog.showSuccess("$otherName has been blocked");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Block",
                    style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white),
                  ),
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

  String _formatLastMessage(ChatRoomModel room) {
    if (room.lastMessage == null || room.lastMessage!.isEmpty) return '';
    if (room.lastMessageType == 'offer') return '\u{1F4B0} ${room.lastMessage}';
    if (room.lastMessageType == 'image') return '\u{1F4F7} Photo';
    return room.lastMessage!;
  }

  String _formatTime(ChatRoomModel room) {
    if (room.lastMessageTime == null) return '';
    final dt = room.lastMessageTime!.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $amPm';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHIMMER — Selling tab
// ═══════════════════════════════════════════════════════════════════════════════
class _SellingShimmerList extends StatelessWidget {
  final bool isDark;

  const _SellingShimmerList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10)),
                ),
                spaceW(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                      spaceH(height: 8),
                      Container(
                        height: 10,
                        width: 100,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
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

// ═══════════════════════════════════════════════════════════════════════════════
// SHIMMER — Buying tab
// ═══════════════════════════════════════════════════════════════════════════════
class _BuyingShimmerList extends StatelessWidget {
  final bool isDark;

  const _BuyingShimmerList({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10)),
                ),
                spaceW(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 130,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                      spaceH(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                      spaceH(height: 6),
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
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
