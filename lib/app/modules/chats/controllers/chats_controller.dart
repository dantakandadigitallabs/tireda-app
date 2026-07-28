import 'dart:async';

import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/chat_room_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class ChatsController extends GetxController {
  RxList<ChatRoomModel> chatRooms = <ChatRoomModel>[].obs;
  RxList<AdModel> myAds = <AdModel>[].obs;
  RxBool isLoading = true.obs;
  RxBool isAdsLoading = true.obs;
  RxList<String> blockedUserIds = <String>[].obs;
  StreamSubscription? _chatSubscription;
  StreamSubscription? _adsSubscription;

  String? get currentUserId => FireStoreUtils.getCurrentUid();

  /// All selling chats (where current user is the ad owner/receiver)
  List<ChatRoomModel> get sellingChats {
    final uid = currentUserId;
    if (uid == null) return [];
    return chatRooms
        .where((room) => room.receiverId == uid)
        .where((room) => !blockedUserIds.contains(room.otherUserId(uid)))
        .toList();
  }

  /// User's live/active ads, sorted by most recent chat activity first
  List<AdModel> get liveAds {
    final activeAds = myAds
        .where((ad) => ad.status == 'active' && ad.isActive == true)
        .where((ad) => chatsForAd(ad.id ?? '').isNotEmpty)
        .toList();
    _sortAdsByChat(activeAds);
    return activeAds;
  }

  /// Sold ads that have chats (so seller can view old conversations)
  List<AdModel> get soldAdsWithChats {
    final soldAds = myAds
        .where((ad) => ad.status == 'sold' || ad.status == 'sold_out')
        .where((ad) => chatsForAd(ad.id ?? '').isNotEmpty)
        .toList();
    _sortAdsByChat(soldAds);
    return soldAds;
  }

  void _sortAdsByChat(List<AdModel> ads) {
    ads.sort((a, b) {
      final aChats = chatsForAd(a.id ?? '');
      final bChats = chatsForAd(b.id ?? '');
      final aLatest = _latestMessageTime(aChats);
      final bLatest = _latestMessageTime(bChats);
      if (aLatest == 0 && bLatest == 0) return 0;
      if (aLatest == 0) return 1;
      if (bLatest == 0) return -1;
      return bLatest.compareTo(aLatest);
    });
  }

  /// Get all chats for a specific ad
  List<ChatRoomModel> chatsForAd(String adId) {
    final uid = currentUserId;
    if (uid == null) return [];
    return sellingChats.where((room) => room.adId == adId).toList();
  }

  /// Total unread count across all chats for a specific ad
  int totalUnreadForAd(String adId) {
    final uid = currentUserId;
    if (uid == null) return 0;
    return chatsForAd(adId).fold(0, (sum, room) => sum + room.myUnreadCount(uid));
  }

  /// Latest message timestamp across all chats for an ad (for sorting)
  int _latestMessageTime(List<ChatRoomModel> chats) {
    if (chats.isEmpty) return 0;
    return chats.map((r) => r.lastMessageTime?.millisecondsSinceEpoch ?? 0).reduce((a, b) => a > b ? a : b);
  }

  /// Chats where the current user is the buyer (sender = buyer)
  List<ChatRoomModel> get buyingChats {
    final uid = currentUserId;
    if (uid == null) return [];
    return chatRooms
        .where((room) => room.senderId == uid)
        .where((room) => !blockedUserIds.contains(room.otherUserId(uid)))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    _loadBlockedUsers();
    _listenToChatRooms();
    _listenToMyAds();
  }

  Future<void> _loadBlockedUsers() async {
    final uid = currentUserId;
    if (uid == null) return;
    final blocked = await FireStoreUtils.getBlockedUsers(uid);
    blockedUserIds.value = blocked;
  }

  void _listenToChatRooms() {
    final uid = currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    _chatSubscription = FireStoreUtils.getChatRoomsStream(uid).listen((rooms) {
      chatRooms.value = rooms;
      isLoading.value = false;
    }, onError: (e) {
      isLoading.value = false;
    });
  }

  void _listenToMyAds() {
    final uid = currentUserId;
    if (uid == null) {
      isAdsLoading.value = false;
      return;
    }

    _adsSubscription = FireStoreUtils.getMyAdsStream(uid).listen((ads) {
      myAds.value = ads;
      isAdsLoading.value = false;
    }, onError: (e) {
      isAdsLoading.value = false;
    });
  }

  /// Block a user and refresh the blocked list
  Future<bool> blockUser(String blockedUserId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    final success = await FireStoreUtils.blockUser(uid, blockedUserId);
    if (success) {
      blockedUserIds.add(blockedUserId);
    }
    return success;
  }

  /// Unblock a user and refresh the blocked list
  Future<bool> unblockUser(String unblockedUserId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    final success = await FireStoreUtils.unblockUser(uid, unblockedUserId);
    if (success) {
      blockedUserIds.remove(unblockedUserId);
    }
    return success;
  }

  /// Check if a user is blocked
  bool isBlocked(String userId) {
    return blockedUserIds.contains(userId);
  }

  @override
  void onClose() {
    _chatSubscription?.cancel();
    _adsSubscription?.cancel();
    super.onClose();
  }
}
