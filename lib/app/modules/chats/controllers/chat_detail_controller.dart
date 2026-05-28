import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/chat_message_model.dart';
import 'package:eSellify/app/models/chat_room_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChatDetailController extends GetxController {
  late ChatRoomModel chatRoom;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  StreamSubscription? _messageSubscription;

  RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  RxBool isLoading = true.obs;
  RxBool isOtherUserBlocked = false.obs;
  RxBool amIBlockedByOther = false.obs;
  RxBool isAdSoldOut = false.obs;

  String get currentUserId => FireStoreUtils.getCurrentUid() ?? '';

  bool _initialized = false;

  /// Called from the view after chatRoom is set
  void initChat() {
    if (_initialized) return;
    _initialized = true;
    _listenToMessages();
    _checkBlockedStatus();
    _checkAdStatus();
    FireStoreUtils.markMessagesAsRead(chatRoom.id!, currentUserId);
  }

  /// Check if the ad is sold out
  Future<void> _checkAdStatus() async {
    if (chatRoom.adId == null) return;
    try {
      final doc = await FireStoreUtils.fireStore.collection('ads').doc(chatRoom.adId).get();
      if (doc.exists) {
        final status = doc.data()?['status']?.toString().toLowerCase() ?? '';
        isAdSoldOut.value = (status == 'sold' || status == 'sold_out');
      }
    } catch (_) {}
  }

  Future<void> _checkBlockedStatus() async {
    if (currentUserId.isEmpty) return;
    final otherUserId = chatRoom.otherUserId(currentUserId);
    final results = await Future.wait([FireStoreUtils.getBlockedUsers(currentUserId), FireStoreUtils.getBlockedUsers(otherUserId)]);
    isOtherUserBlocked.value = results[0].contains(otherUserId);
    amIBlockedByOther.value = results[1].contains(currentUserId);
  }

  void _listenToMessages() {
    _messageSubscription = FireStoreUtils.getMessagesStream(chatRoom.id!).listen((msgs) {
      messages.value = msgs;
      isLoading.value = false;
      scrollToBottom();
      FireStoreUtils.markMessagesAsRead(chatRoom.id!, currentUserId);
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Guard against the controller being transiently attached to more than
      // one scroll view (e.g. during a route transition). Accessing `.position`
      // when `positions.length != 1` throws, so only scroll when exactly one
      // list view is attached.
      if (scrollController.hasClients && scrollController.positions.length == 1) {
        scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  // ─── Send Text Message ─────────────────────────────────────────────────────
  Future<void> sendTextMessage() async {
    if (isAdSoldOut.value) {
      ShowToastDialog.showError("This ad has been sold out. You can no longer send messages.".tr);
      return;
    }

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final otherUserId = chatRoom.otherUserId(currentUserId);
    final otherBlocked = await FireStoreUtils.getBlockedUsers(otherUserId);
    if (otherBlocked.contains(currentUserId)) {
      amIBlockedByOther.value = true;
      ShowToastDialog.showError("You can't send messages to this user".tr);
      return;
    }

    messageController.clear();

    final msgId = Constant.getUuid();
    final message = ChatMessageModel(
      id: msgId,
      chatRoomId: chatRoom.id,
      senderId: currentUserId,
      senderName: Constant.userModel?.fullNameString() ?? '',
      senderProfile: Constant.userModel?.profilePic ?? '',
      messageType: 'text',
      text: text,
      createdAt: Timestamp.now(),
      isRead: false,
    );

    final success = await FireStoreUtils.sendMessage(chatRoomId: chatRoom.id!, message: message, receiverId: otherUserId);

    if (!success) {
      ShowToastDialog.showError("Failed to send message".tr);
    }
  }

  // ─── Send Offer ────────────────────────────────────────────────────────────
  Future<void> sendOfferMessage(double amount) async {
    if (isAdSoldOut.value) {
      ShowToastDialog.showError("This ad has been sold out. You can no longer send offers.".tr);
      return;
    }

    final otherUserId = chatRoom.otherUserId(currentUserId);
    final otherBlocked = await FireStoreUtils.getBlockedUsers(otherUserId);
    if (otherBlocked.contains(currentUserId)) {
      amIBlockedByOther.value = true;
      ShowToastDialog.showError("You can't send offers to this user".tr);
      return;
    }

    final msgId = Constant.getUuid();
    final message = ChatMessageModel(
      id: msgId,
      chatRoomId: chatRoom.id,
      senderId: currentUserId,
      senderName: Constant.userModel?.fullNameString() ?? '',
      senderProfile: Constant.userModel?.profilePic ?? '',
      messageType: 'offer',
      text: 'Made an offer',
      offerAmount: amount,
      offerStatus: 'pending',
      createdAt: Timestamp.now(),
      isRead: false,
    );

    final success = await FireStoreUtils.sendMessage(chatRoomId: chatRoom.id!, message: message, receiverId: otherUserId);

    if (success) {
      ShowToastDialog.showSuccess("Offer sent!".tr);
    } else {
      ShowToastDialog.showError("Failed to send offer".tr);
    }
  }

  Future<void> respondToOffer(ChatMessageModel msg, String status) async {
    await FireStoreUtils.updateOfferStatus(chatRoomId: chatRoom.id!, messageId: msg.id!, status: status);
    ShowToastDialog.showSuccess(status == 'accepted' ? "Offer accepted".tr : "Offer declined".tr);
  }

  // ─── Media (Image / Video) ─────────────────────────────────────────────────
  Future<void> pickAndSendCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1200);
      if (picked == null) return;
      await _uploadAndSendImages([picked]);
    } catch (e) {
      ShowToastDialog.showError("Failed to capture photo".tr);
    }
  }

  Future<void> pickAndSendMultipleImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> picked = await picker.pickMultiImage(imageQuality: 70, maxWidth: 1200);
      if (picked.isEmpty) return;
      await _uploadAndSendImages(picked);
    } catch (e) {
      ShowToastDialog.showError("Failed to pick images".tr);
    }
  }

  Future<void> pickAndSendVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
      if (picked == null) return;

      final otherUserId = chatRoom.otherUserId(currentUserId);
      final otherBlocked = await FireStoreUtils.getBlockedUsers(otherUserId);
      if (otherBlocked.contains(currentUserId)) {
        amIBlockedByOther.value = true;
        ShowToastDialog.showError("You can't send media to this user".tr);
        return;
      }

      ShowToastDialog.showLoader("Sending video...".tr);

      final msgId = Constant.getUuid();
      final url = await Constant.uploadImageToFireStorage(File(picked.path), 'chat_media/${chatRoom.id}', 'video_$msgId');

      final message = ChatMessageModel(
        id: msgId,
        chatRoomId: chatRoom.id,
        senderId: currentUserId,
        senderName: Constant.userModel?.fullNameString() ?? '',
        senderProfile: Constant.userModel?.profilePic ?? '',
        messageType: 'video',
        text: 'Sent a video',
        videoUrl: url,
        createdAt: Timestamp.now(),
        isRead: false,
      );

      await FireStoreUtils.sendMessage(chatRoomId: chatRoom.id!, message: message, receiverId: otherUserId);
      ShowToastDialog.closeLoader();
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Failed to send video".tr);
    }
  }

  Future<void> _uploadAndSendImages(List<XFile> files) async {
    final otherUserId = chatRoom.otherUserId(currentUserId);
    final otherBlocked = await FireStoreUtils.getBlockedUsers(otherUserId);
    if (otherBlocked.contains(currentUserId)) {
      amIBlockedByOther.value = true;
      ShowToastDialog.showError("You can't send media to this user".tr);
      return;
    }

    ShowToastDialog.showLoader("sending_photos".trParams({"count": files.length.toString(), "type": files.length == 1 ? "photo".tr : "photos".tr}));

    try {
      final msgId = Constant.getUuid();
      final List<String> uploadedUrls = [];

      for (int i = 0; i < files.length; i++) {
        final url = await Constant.uploadImageToFireStorage(File(files[i].path), 'chat_media/${chatRoom.id}', 'img_${msgId}_$i');
        uploadedUrls.add(url);
      }

      final message = ChatMessageModel(
        id: msgId,
        chatRoomId: chatRoom.id,
        senderId: currentUserId,
        senderName: Constant.userModel?.fullNameString() ?? '',
        senderProfile: Constant.userModel?.profilePic ?? '',
        messageType: 'image',
        text: files.length == 1 ? 'Sent a photo' : 'Sent ${files.length} photos',
        imageUrls: uploadedUrls,
        createdAt: Timestamp.now(),
        isRead: false,
      );

      await FireStoreUtils.sendMessage(chatRoomId: chatRoom.id!, message: message, receiverId: otherUserId);
      ShowToastDialog.closeLoader();
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Failed to send images".tr);
    }
  }

  // ─── Block / Unblock ───────────────────────────────────────────────────────
  Future<void> blockUser() async {
    final otherUserId = chatRoom.otherUserId(currentUserId);
    await FireStoreUtils.blockUser(currentUserId, otherUserId);
    isOtherUserBlocked.value = true;
    ShowToastDialog.showSuccess("user_blocked".trParams({"name": chatRoom.otherUserName(currentUserId)}));
  }

  Future<void> unblockUser() async {
    final otherUserId = chatRoom.otherUserId(currentUserId);
    await FireStoreUtils.unblockUser(currentUserId, otherUserId);
    isOtherUserBlocked.value = false;
    ShowToastDialog.showSuccess("user_unblocked".trParams({"name": chatRoom.otherUserName(currentUserId)}));
  }

  @override
  void onClose() {
    _messageSubscription?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
