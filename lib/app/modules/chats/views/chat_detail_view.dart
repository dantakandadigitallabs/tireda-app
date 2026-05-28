import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/app/models/chat_message_model.dart';
import 'package:eSellify/app/models/chat_room_model.dart';
import 'package:eSellify/app/modules/chats/controllers/chat_detail_controller.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChatDetailView extends StatelessWidget {
  final ChatRoomModel chatRoom;

  const ChatDetailView({super.key, required this.chatRoom});

  @override
  Widget build(BuildContext context) {
    // Register controller with chatRoom data
    final controller = Get.put(ChatDetailController()..chatRoom = chatRoom);
    controller.initChat();

    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();
    final otherName = chatRoom.otherUserName(controller.currentUserId);
    final otherProfile = chatRoom.otherUserProfile(controller.currentUserId);

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: AppBar(
        backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            InkWell(
              onTap: () => Get.back(),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
              backgroundImage: otherProfile.isNotEmpty ? CachedNetworkImageProvider(otherProfile) : null,
              child: otherProfile.isEmpty
                  ? Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : '?', style: TextStyle(fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(title: otherName, fontSize: 15, fontFamily: FontFamily.medium, maxLine: 1),
                  TextCustom(title: chatRoom.adTitle ?? '', fontSize: 12, color: AppThemeData.grey5, maxLine: 1),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
            color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog(context, controller, isDark);
              } else if (value == 'unblock') {
                _showUnblockDialog(context, controller, isDark);
              }
            },
            itemBuilder: (_) => [
              if (controller.isOtherUserBlocked.value)
                PopupMenuItem<String>(
                  value: 'unblock',
                  child: Row(
                    children: [
                      Icon(Icons.lock_open_rounded, color: AppThemeData.primary4, size: 20),
                      const SizedBox(width: 10),
                      TextCustom(title: "Unblock User", fontSize: 14, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
                    ],
                  ),
                )
              else
                PopupMenuItem<String>(
                  value: 'block',
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      TextCustom(title: "Block User", fontSize: 14, fontFamily: FontFamily.medium, color: Colors.red),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _AdBanner(chatRoom: chatRoom, isDark: isDark),

          // Messages
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildMessageShimmer(isDark);
              }
              if (controller.messages.isEmpty) {
                return Center(child: TextCustom(title: "No messages yet.\nSay hello or make an offer!", fontSize: 14, color: AppThemeData.grey5, textAlign: TextAlign.center));
              }
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];
                  final isMe = msg.senderId == controller.currentUserId;

                  if (msg.messageType == 'offer') {
                    return _OfferBubble(
                      message: msg,
                      chatRoom: chatRoom,
                      isMe: isMe,
                      isDark: isDark,
                      canRespond: !isMe && msg.offerStatus == 'pending',
                      onAccept: () => controller.respondToOffer(msg, 'accepted'),
                      onReject: () => controller.respondToOffer(msg, 'rejected'),
                    );
                  }
                  if (msg.messageType == 'image' || msg.messageType == 'video') {
                    return _MediaBubble(message: msg, isMe: isMe, isDark: isDark);
                  }
                  return _MessageBubble(message: msg, isMe: isMe, isDark: isDark);
                },
              );
            }),
          ),

          // Bottom: sold/blocked banner or input
          Obx(() {
            if (controller.isAdSoldOut.value) {
              return _BlockedBanner(
                message: chatRoom.isJobAd ? "This position is closed" : "This ad has been sold out".tr,
                icon: Icons.sell_outlined,
                isDark: isDark,
              );
            }
            if (controller.isOtherUserBlocked.value) {
              return _BlockedBanner(message: "You have blocked this user", icon: Icons.block, isDark: isDark);
            }
            if (controller.amIBlockedByOther.value) {
              return _BlockedBanner(message: "You can't reply to this conversation", icon: Icons.info_outline, isDark: isDark);
            }
            return _MessageInput(
              controller: controller.messageController,
              isDark: isDark,
              onSend: controller.sendTextMessage,
              // No monetary offers on job-ad chats
              onOffer: chatRoom.isJobAd ? null : () => _showMakeOfferSheet(context, controller, isDark),
              onAttachment: () => _showAttachmentSheet(context, controller, isDark),
            );
          }),
        ],
      ),
    );
  }

  // ─── Offer Sheet ─────────────────────────────────────────────────────────────
  void _showMakeOfferSheet(BuildContext context, ChatDetailController controller, bool isDark) {
    if (controller.amIBlockedByOther.value) {
      ShowToastDialog.showError("You can't send offers to this user".tr);
      return;
    }

    final offerCtrl = TextEditingController();
    final currencySymbol = chatRoom.adCurrencySymbol ?? Constant.currencyModel?.symbol ?? '\$';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4, borderRadius: BorderRadius.circular(2)))),
                spaceH(height: 20),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: chatRoom.adImage != null && chatRoom.adImage!.isNotEmpty
                          ? CachedNetworkImage(imageUrl: chatRoom.adImage!, width: 50, height: 50, fit: BoxFit.cover)
                          : Container(width: 50, height: 50, decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.image, color: AppThemeData.grey5)),
                    ),
                    spaceW(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextCustom(title: chatRoom.adTitle ?? '', fontSize: 14, fontFamily: FontFamily.semiBold, maxLine: 1, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                          spaceH(height: 2),
                          TextCustom(title: "Listed: ${chatRoom.formattedPrice}", fontSize: 13, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
                        ],
                      ),
                    ),
                  ],
                ),
                spaceH(height: 24),
                TextCustom(title: "Make an Offer".tr, fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                spaceH(height: 4),
                TextCustom(title: "Enter your offer price below", fontSize: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                spaceH(height: 16),
                TextField(
                  controller: offerCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: TextStyle(fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                  decoration: InputDecoration(
                    prefixText: '$currencySymbol ',
                    prefixStyle: TextStyle(fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                    hintText: "0.00",
                    hintStyle: TextStyle(fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                    filled: true,
                    fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  ),
                ),
                spaceH(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(offerCtrl.text.trim());
                      if (amount == null || amount <= 0) {
                        ShowToastDialog.showError("Please enter a valid amount");
                        return;
                      }
                      Navigator.pop(ctx);
                      await controller.sendOfferMessage(amount);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppThemeData.primary4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                    child: Text("Send Offer".tr, style: TextStyle(fontSize: 16, fontFamily: FontFamily.semiBold, color: Colors.white)),
                  ),
                ),
                spaceH(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Attachment Sheet ────────────────────────────────────────────────────────
  void _showAttachmentSheet(BuildContext context, ChatDetailController controller, bool isDark) {
    if (controller.amIBlockedByOther.value) {
      ShowToastDialog.showError("You can't send media to this user".tr);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? AppThemeData.grey7 : AppThemeData.grey4, borderRadius: BorderRadius.circular(2))),
              spaceH(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachmentOption(Icons.camera_alt_rounded, "Camera", isDark, () { Get.back(); controller.pickAndSendCamera(); }),
                  _attachmentOption(Icons.photo_library_rounded, "Photos", isDark, () { Get.back(); controller.pickAndSendMultipleImages(); }),
                  _attachmentOption(Icons.videocam_rounded, "Video", isDark, () { Get.back(); controller.pickAndSendVideo(); }),
                ],
              ),
              spaceH(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentOption(IconData icon, String label, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(height: 56, width: 56, decoration: BoxDecoration(color: AppThemeData.primary4.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 26, color: AppThemeData.primary4)),
          spaceH(height: 8),
          TextCustom(title: label, fontSize: 12, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey3 : AppThemeData.grey8),
        ],
      ),
    );
  }

  // ─── Block / Unblock Dialogs ─────────────────────────────────────────────────
  void _showBlockDialog(BuildContext context, ChatDetailController controller, bool isDark) {
    final otherName = chatRoom.otherUserName(controller.currentUserId);
    final otherProfile = chatRoom.otherUserProfile(controller.currentUserId);

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
              Stack(alignment: Alignment.bottomRight, children: [
                CircleAvatar(radius: 32, backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3, backgroundImage: otherProfile.isNotEmpty ? CachedNetworkImageProvider(otherProfile) : null, child: otherProfile.isEmpty ? Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : '?', style: TextStyle(fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7)) : null),
                Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite, shape: BoxShape.circle), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.block, size: 12, color: Colors.white))),
              ]),
              spaceH(height: 16),
              TextCustom(title: "Block $otherName?", fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, textAlign: TextAlign.center),
              spaceH(height: 8),
              TextCustom(title: "They won't be able to message you\nand their chats will be hidden.", fontSize: 13, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, textAlign: TextAlign.center),
              spaceH(height: 24),
              SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: () { Get.back(); controller.blockUser(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Text("Block", style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white)))),
              spaceH(height: 10),
              SizedBox(width: double.infinity, height: 46, child: TextButton(onPressed: () => Get.back(), style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: TextCustom(title: "Cancel", fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6))),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnblockDialog(BuildContext context, ChatDetailController controller, bool isDark) {
    final otherName = chatRoom.otherUserName(controller.currentUserId);
    final otherProfile = chatRoom.otherUserProfile(controller.currentUserId);

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
              Stack(alignment: Alignment.bottomRight, children: [
                CircleAvatar(radius: 32, backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3, backgroundImage: otherProfile.isNotEmpty ? CachedNetworkImageProvider(otherProfile) : null, child: otherProfile.isEmpty ? Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : '?', style: TextStyle(fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey3 : AppThemeData.grey7)) : null),
                Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite, shape: BoxShape.circle), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppThemeData.primary4, shape: BoxShape.circle), child: const Icon(Icons.check, size: 12, color: Colors.white))),
              ]),
              spaceH(height: 16),
              TextCustom(title: "Unblock $otherName?", fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, textAlign: TextAlign.center),
              spaceH(height: 8),
              TextCustom(title: "They will be able to\nmessage you again.", fontSize: 13, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, textAlign: TextAlign.center),
              spaceH(height: 24),
              SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: () { Get.back(); controller.unblockUser(); }, style: ElevatedButton.styleFrom(backgroundColor: AppThemeData.primary4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Text("Unblock", style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white)))),
              spaceH(height: 10),
              SizedBox(width: double.infinity, height: 46, child: TextButton(onPressed: () => Get.back(), style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: TextCustom(title: "Cancel", fontSize: 15, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Left bubble
            Align(alignment: Alignment.centerLeft, child: Container(height: 44, width: 180, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)))),
            spaceH(height: 10),
            Align(alignment: Alignment.centerLeft, child: Container(height: 36, width: 140, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)))),
            spaceH(height: 14),
            // Right bubble
            Align(alignment: Alignment.centerRight, child: Container(height: 44, width: 160, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)))),
            spaceH(height: 10),
            Align(alignment: Alignment.centerRight, child: Container(height: 36, width: 120, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)))),
            spaceH(height: 14),
            // Left bubble
            Align(alignment: Alignment.centerLeft, child: Container(height: 56, width: 200, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)))),
            spaceH(height: 10),
            // Right bubble
            Align(alignment: Alignment.centerRight, child: Container(height: 44, width: 170, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOCKED BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _BlockedBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isDark;

  const _BlockedBanner({required this.message, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        border: Border(top: BorderSide(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.red.shade400),
            const SizedBox(width: 8),
            TextCustom(title: message, fontSize: 13, fontFamily: FontFamily.medium, color: Colors.red.shade400),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AD BANNER (top of chat) — uses ad's own currency
// ─────────────────────────────────────────────────────────────────────────────
class _AdBanner extends StatelessWidget {
  final ChatRoomModel chatRoom;
  final bool isDark;

  const _AdBanner({required this.chatRoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
        border: Border(bottom: BorderSide(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: chatRoom.adImage != null && chatRoom.adImage!.isNotEmpty
                ? CachedNetworkImage(imageUrl: chatRoom.adImage!, width: 44, height: 44, fit: BoxFit.cover)
                : Container(
                    width: 44,
                    height: 44,
                    color: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                    child: const Icon(Icons.image, size: 20, color: AppThemeData.grey5),
                  ),
          ),
          spaceW(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(title: chatRoom.adTitle ?? '', fontSize: 13, fontFamily: FontFamily.medium, maxLine: 1),
                TextCustom(title: chatRoom.priceOrSalaryLabel, fontSize: 14, fontFamily: FontFamily.bold, color: AppThemeData.primary4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEXT MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isMe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppThemeData.primary4 : (isDark ? AppThemeData.grey8 : AppThemeData.grey2),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text ?? '',
                style: TextStyle(fontSize: 14, fontFamily: FontFamily.regular, color: isMe ? Colors.white : (isDark ? AppThemeData.grey1 : AppThemeData.grey10)),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(fontSize: 10, fontFamily: FontFamily.regular, color: isMe ? Colors.white.withValues(alpha: 0.7) : AppThemeData.grey5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFER BUBBLE — uses ad's own currency
// ─────────────────────────────────────────────────────────────────────────────
class _OfferBubble extends StatelessWidget {
  final ChatMessageModel message;
  final ChatRoomModel chatRoom;
  final bool isMe;
  final bool isDark;
  final bool canRespond;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OfferBubble({
    required this.message,
    required this.chatRoom,
    required this.isMe,
    required this.isDark,
    required this.canRespond,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = message.offerStatus ?? 'pending';

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = AppThemeData.success300;
        statusText = 'Accepted';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'rejected':
        statusColor = AppThemeData.danger300;
        statusText = 'Declined';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppThemeData.pending300;
        statusText = 'Pending';
        statusIcon = Icons.access_time_rounded;
    }

    // Format offer amount with ad's own currency
    final formattedAmount = message.offerAmount != null ? chatRoom.formatAmount(message.offerAmount!) : '\$0.00';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppThemeData.grey7 : AppThemeData.grey3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppThemeData.primary4.withValues(alpha: 0.1) : (isDark ? AppThemeData.grey8 : AppThemeData.grey2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_rounded, size: 18, color: AppThemeData.primary4),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMe ? "You made an offer" : "${message.senderName} made an offer",
                        style: TextStyle(fontSize: 13, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey2 : AppThemeData.grey8),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedAmount,
                      style: TextStyle(fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                    ),
                    const SizedBox(height: 8),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(fontSize: 12, fontFamily: FontFamily.medium, color: statusColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Accept/Reject buttons
              if (canRespond) ...[
                Divider(height: 1, color: isDark ? AppThemeData.grey7 : AppThemeData.grey3),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onReject,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppThemeData.danger300),
                            ),
                            child: const Center(
                              child: Text(
                                "Decline",
                                style: TextStyle(fontSize: 14, fontFamily: FontFamily.semiBold, color: AppThemeData.danger300),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: onAccept,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.success300),
                            child: const Center(
                              child: Text(
                                "Accept",
                                style: TextStyle(fontSize: 14, fontFamily: FontFamily.semiBold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Timestamp
              Padding(
                padding: const EdgeInsets.only(right: 14, bottom: 8, left: 14),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatTime(message.createdAt),
                    style: const TextStyle(fontSize: 10, fontFamily: FontFamily.regular, color: AppThemeData.grey5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE INPUT BAR
// ─────────────────────────────────────────────────────────────────────────────
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback? onOffer;
  final VoidCallback onAttachment;

  const _MessageInput({required this.controller, required this.isDark, required this.onSend, this.onOffer, required this.onAttachment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        border: Border(top: BorderSide(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3)),
      ),
      child: Row(
        children: [
          // Attachment button (image/video)
          GestureDetector(
            onTap: onAttachment,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey8 : AppThemeData.grey2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.attach_file_rounded, size: 20, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
            ),
          ),
          const SizedBox(width: 6),
          // Make offer button — hidden for job ads (no monetary offers)
          if (onOffer != null) ...[
            GestureDetector(
              onTap: onOffer,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AppThemeData.primary4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.local_offer_outlined, size: 18, color: AppThemeData.primary4),
              ),
            ),
            const SizedBox(width: 6),
          ],
          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14, fontFamily: FontFamily.regular, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(fontSize: 14, fontFamily: FontFamily.regular, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
                filled: true,
                fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 6),
          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppThemeData.primary4, shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.send_rounded, size: 20, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE / VIDEO MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _MediaBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool isDark;

  const _MediaBubble({required this.message, required this.isMe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isVideo = message.messageType == 'video';
    final images = message.allImageUrls;
    final videoUrl = message.videoUrl ?? '';

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: isMe ? AppThemeData.primary4 : (isDark ? AppThemeData.grey8 : AppThemeData.grey2),
            borderRadius: bubbleRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Media content
              ClipRRect(
                borderRadius: bubbleRadius,
                child: isVideo
                    ? _buildVideoThumbnail(videoUrl)
                    : images.length == 1
                        ? _buildSingleImage(context, images.first)
                        : _buildImageGrid(context, images),
              ),
              // Timestamp
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(fontSize: 10, fontFamily: FontFamily.regular, color: isMe ? Colors.white.withValues(alpha: 0.7) : AppThemeData.grey5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _openFullScreen(context, [url], 0),
      child: CachedNetworkImage(
        imageUrl: url,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, _) => Shimmer.fromColors(
          baseColor: isDark ? AppThemeData.grey9 : AppThemeData.grey3,
          highlightColor: isDark ? AppThemeData.grey8 : AppThemeData.grey2,
          child: Container(height: 220, color: isDark ? AppThemeData.grey9 : AppThemeData.grey3),
        ),
        errorWidget: (_, _, _) => Container(height: 220, color: isDark ? AppThemeData.grey9 : AppThemeData.grey3, child: const Center(child: Icon(Icons.broken_image, size: 32, color: AppThemeData.grey5))),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<String> urls) {
    final count = urls.length;

    if (count == 2) {
      return SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(child: _gridImage(context, urls, 0)),
            const SizedBox(width: 2),
            Expanded(child: _gridImage(context, urls, 1)),
          ],
        ),
      );
    }

    if (count == 3) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(flex: 2, child: _gridImage(context, urls, 0)),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _gridImage(context, urls, 1)),
                  const SizedBox(height: 2),
                  Expanded(child: _gridImage(context, urls, 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ images: 2x2 grid with "+N" overlay on last
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _gridImage(context, urls, 0)),
                const SizedBox(width: 2),
                Expanded(child: _gridImage(context, urls, 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _gridImage(context, urls, 2)),
                const SizedBox(width: 2),
                Expanded(
                  child: count > 4
                      ? GestureDetector(
                          onTap: () => _openFullScreen(context, urls, 3),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(imageUrl: urls[3], fit: BoxFit.cover),
                              Container(
                                color: Colors.black.withValues(alpha: 0.5),
                                child: Center(
                                  child: Text('+${count - 4}', style: const TextStyle(fontSize: 22, fontFamily: FontFamily.bold, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _gridImage(context, urls, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridImage(BuildContext context, List<String> urls, int index) {
    if (index >= urls.length) return const SizedBox();
    return GestureDetector(
      onTap: () => _openFullScreen(context, urls, index),
      child: CachedNetworkImage(
        imageUrl: urls[index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, _) => Container(color: isDark ? AppThemeData.grey9 : AppThemeData.grey3),
        errorWidget: (_, _, _) => Container(color: isDark ? AppThemeData.grey9 : AppThemeData.grey3, child: const Center(child: Icon(Icons.broken_image, size: 20, color: AppThemeData.grey5))),
      ),
    );
  }

  Widget _buildVideoThumbnail(String url) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(height: 200, width: double.infinity, color: isDark ? AppThemeData.grey9 : AppThemeData.grey3, child: const Center(child: Icon(Icons.videocam, size: 40, color: AppThemeData.grey5))),
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, size: 32, color: Colors.white),
        ),
      ],
    );
  }

  void _openFullScreen(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FullScreenImageView(imageUrls: urls, initialIndex: initialIndex)));
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL SCREEN IMAGE VIEWER — swipe between images, pinch to zoom
// ─────────────────────────────────────────────────────────────────────────────
class _FullScreenImageView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageView({required this.imageUrls, required this.initialIndex});

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: widget.imageUrls.length > 1
            ? Text('${_currentIndex + 1} / ${widget.imageUrls.length}', style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: FontFamily.medium))
            : null,
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (_, _) => Shimmer.fromColors(
                  baseColor: Colors.white24,
                  highlightColor: Colors.white10,
                  child: Container(color: Colors.white24),
                ),
                errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.white38)),
              ),
            ),
          );
        },
      ),
    );
  }
}
