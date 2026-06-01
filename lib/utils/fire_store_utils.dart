import 'dart:async';
import 'dart:developer' as developer;
import 'dart:developer';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/utils/distance_utils.dart';
import 'package:eSellify/app/dependency/geoflutterfire/src/models/point.dart';
import 'package:eSellify/app/dependency/geoflutterfire/src/utils/math.dart';
import 'package:eSellify/app/models/ad_report_model.dart';
import 'package:eSellify/app/models/banner_model.dart';
import 'package:eSellify/app/models/report_reason_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/models/chat_message_model.dart';
import 'package:eSellify/app/models/chat_room_model.dart';
import 'package:eSellify/app/models/feature_section_model.dart';
import 'package:eSellify/app/models/contact_us_model.dart';
import 'package:eSellify/app/models/currency_model.dart';
import 'package:eSellify/app/models/custom_field_model.dart';
import 'package:eSellify/app/models/job_application_model.dart';
import 'package:eSellify/app/models/notification_model.dart';
import 'package:eSellify/app/models/review_model.dart';
import 'package:eSellify/app/models/payment_method_model.dart';
import 'package:eSellify/app/models/subscription_package_model.dart';
import 'package:eSellify/app/models/transaction_model.dart';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app/constant/collection_name.dart';
import '../app/models/advertisement_config_model.dart';
import '../app/models/openai_config_model.dart';
import '../app/constant/constants.dart';
import '../app/models/language_model.dart';
import '../app/models/verification_document_model.dart';
import 'notifications/send_notification.dart';

class FireStoreUtils {
  static final FirebaseFirestore fireStore = FirebaseFirestore.instance;

  static String? getCurrentUid() {
    if (FirebaseAuth.instance.currentUser == null) {
      return null;
    }
    return FirebaseAuth.instance.currentUser!.uid;
  }

  //  static String getCurrentFirebaseUid() => FirebaseAuth.instance.currentUser?.uid ?? '';

  static Future<bool> userExistOrNot(String uid) async {
    try {
      var value = await fireStore.collection(CollectionName.customers).doc(uid).get();
      return value.exists;
    } catch (e) {
      developer.log("Failed to check user exist: $e");
      return false;
    }
  }

  static Future<bool> isLogin() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        return await userExistOrNot(FirebaseAuth.instance.currentUser!.uid);
      }
    } catch (e) {
      developer.log("Failed to check login status: $e");
    }
    return false;
  }

  Future<void> getSettings() async {
    // Load all settings documents in parallel
    try {
      final results = await Future.wait([
        fireStore.collection(CollectionName.settings).doc("constant").get(),
        fireStore.collection(CollectionName.settings).doc("notification_settings").get(),
        fireStore.collection(CollectionName.settings).doc("ad_settings").get(),
        fireStore.collection(CollectionName.settings).doc("advertisement_config").get(),
        fireStore.collection(CollectionName.settings).doc("openai_config").get(),
      ]);

      // 1. General settings (constant)
      final constantDoc = results[0];
      if (constantDoc.exists) {
        final data = constantDoc.data()!;
        Constant.appName.value = data["appName"] ?? "Tireda";
        Constant.appIconLight = data["appIconLight"];
        Constant.appIconDark = data["appIconDark"];
        Constant.termsAndConditions = data["termsAndConditions"];
        Constant.aboutApp = data["aboutApp"];
        Constant.privacyPolicy = data["privacyPolicy"];
        Constant.customerAppColor = data["customerAppColor"];
        Constant.countryCode = data["countryCode"];
        final mapSettings = data["mapSettings"] as Map<String, dynamic>?;
        if (mapSettings != null) {
          Constant.googleMapKey = mapSettings["googleMapKey"] ?? "";
          Constant.selectedMap = mapSettings["mapType"] ?? "Google Map";
        }
      }

      // 2. Notification settings (overrides constant if present)
      final notifDoc = results[1];
      if (notifDoc.exists && notifDoc.data() != null) {
        final data = notifDoc.data()!;
        if (data["notification_senderId"] != null && data["notification_senderId"].toString().isNotEmpty) {
          Constant.senderId = data["notification_senderId"];
        }
        if (data["jsonFileURL"] != null && data["jsonFileURL"].toString().isNotEmpty) {
          Constant.jsonFileURL = data["jsonFileURL"];
        }
      }

      // 3. Ad settings
      final adDoc = results[2];
      if (adDoc.exists && adDoc.data() != null) {
        final data = adDoc.data()!;
        Constant.autoApproveAds = data["autoApproveAds"] ?? false;
        Constant.autoApproveEditedAds = data["autoApproveEditedAds"] ?? false;
        Constant.freeAdListing = data["freeAdListing"] ?? false;
        Constant.minRange = data["minRange"] ?? 50;
        Constant.maxRange = data["maxRange"] ?? 200;
        Constant.unlimitedAdDuration = data["unlimitedAdDuration"] ?? false;
        Constant.freeAdListingDays = data["freeAdListingDays"] ?? 30;
      }
      // 4. Advertisement config
      final advDoc = results[3];
      if (advDoc.exists && advDoc.data() != null) {
        Constant.advertisementConfig = AdvertisementConfigModel.fromJson(advDoc.data()!);
      }

      // 5. OpenAI config
      final openAiDoc = results[4];
      if (openAiDoc.exists && openAiDoc.data() != null) {
        Constant.openAiConfig = OpenAiConfigModel.fromJson(openAiDoc.data()!);
      }

      // 6. Safety Tips (separate collection, dynamic from admin)
      await loadSafetyTips();
    } catch (e) {
      developer.log('Error in getSettings: $e');
    }
  }

  Future<void> loadSafetyTips() async {
    try {
      final snap = await fireStore.collection(CollectionName.safetyTips).orderBy('sortOrder').get();
      Constant.safetyTips = snap.docs
          .where((d) => (d.data()['active'] ?? true) == true)
          .map((d) => (d.data()['tip'] ?? '').toString())
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (e) {
      developer.log('loadSafetyTips Error: $e');
    }
  }

  static Stream<AdvertisementConfigModel?> advertisementConfigStream() {
    return FirebaseFirestore.instance
        .collection(CollectionName.settings)
        .doc("advertisement_config")
        .snapshots()
        .map((snap) => snap.exists && snap.data() != null ? AdvertisementConfigModel.fromJson(snap.data()!) : null);
  }

  Future<CurrencyModel?> getCurrency() async {
    try {
      var value = await fireStore.collection(CollectionName.currencies).where("active", isEqualTo: true).limit(1).get();

      if (value.docs.isNotEmpty) {
        return CurrencyModel.fromJson(value.docs.first.data());
      }
    } catch (e) {
      developer.log("Error fetching currency: $e");
    }
    return null;
  }

  Future<List<CurrencyModel>> getAllCurrencies() async {
    List<CurrencyModel> list = [];
    try {
      var snap = await fireStore.collection(CollectionName.currencies).where("active", isEqualTo: true).get();
      for (var doc in snap.docs) {
        list.add(CurrencyModel.fromJson(doc.data()));
      }
    } catch (e) {
      developer.log("Error fetching currencies: $e");
    }
    return list;
  }

  Future<PaymentModel?> getPayment() async {
    PaymentModel? paymentModel;
    try {
      var doc = await fireStore.collection(CollectionName.settings).doc("payment").get();
      if (doc.exists) {
        paymentModel = PaymentModel.fromJson(doc.data()!);
        Constant.paymentModel = paymentModel;
      }
    } catch (e) {
      developer.log("Error fetching payment details: $e");
    }
    return paymentModel;
  }

  static Future<List<LanguageModel>> getLanguage() async {
    List<LanguageModel> languageModelList = [];
    try {
      QuerySnapshot snap = await fireStore.collection(CollectionName.languages).where("active", isEqualTo: true).get();

      for (var document in snap.docs) {
        Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;
        if (data != null) {
          languageModelList.add(LanguageModel.fromJson(data));
        } else {
          developer.log("getLanguage: data is null for a document");
        }
      }
    } catch (e) {
      developer.log("Error fetching languages: $e");
    }
    return languageModelList;
  }

  static Future<UserModel?> getUserProfile(String uuid) async {
    try {
      var doc = await fireStore.collection(CollectionName.customers).doc(uuid).get();
      if (doc.exists) {
        UserModel user = UserModel.fromJson(doc.data()!);
        if (uuid == getCurrentUid()) {
          Constant.userModel = user;
          _prevUserName = user.fullNameString();
          _prevUserPic = user.profilePic ?? '';
        }
        return user;
      }
      return null;
    } catch (e) {
      developer.log("Failed to get user profile: $e");
    }
    return null;
  }

  static Future<bool> addUser(UserModel userModel) async {
    try {
      await fireStore.collection(CollectionName.customers).doc(userModel.id).set(userModel.toJson(), SetOptions(merge: true));
      Constant.userModel = userModel;

      // Send welcome notification to user + notify admin
      if (userModel.fcmToken != null && userModel.fcmToken!.isNotEmpty) {
        SendNotification.sendOneNotification(
          token: userModel.fcmToken!,
          title: 'Welcome to ${Constant.appName.value}!',
          body: 'Start exploring and posting ads on ${Constant.appName.value}',
          isPayment: false,
          isSaveNotification: true,
          payload: {'type': 'welcome', 'receiverId': userModel.id ?? '', 'senderId': '', 'userType': 'customer'},
        );
      }
      SendNotification.sendToTopic(
        topic: 'esellify-admin',
        title: 'New User',
        body: '${userModel.fullNameString()} just joined ${Constant.appName.value}',
        payload: {'type': 'new_user'},
      );

      return true;
    } catch (e) {
      developer.log("Failed to add user: $e");
      return false;
    }
  }

  // Track previous name/pic to detect changes
  static String? _prevUserName;
  static String? _prevUserPic;

  static Future<bool> updateUser(UserModel userModel) async {
    try {
      // Capture old values before update
      final oldName = _prevUserName;
      final oldPic = _prevUserPic;
      final newName = userModel.fullNameString();
      final newPic = userModel.profilePic ?? '';

      await fireStore.collection(CollectionName.customers).doc(userModel.id).set(userModel.toJson());
      Constant.userModel = userModel;

      // Save current values for next comparison
      _prevUserName = newName;
      _prevUserPic = newPic;

      // Only sync if name or profile pic actually changed
      if (oldName != null && (oldName != newName || oldPic != newPic)) {
        _syncUserDataInRelatedCollections(userModel);
      }

      return true;
    } catch (e) {
      developer.log("Failed to update user: $e");
      return false;
    }
  }

  /// Update denormalized user name/profile in ads and chat rooms.
  /// Only called when name or profile pic actually changes.
  static Future<void> _syncUserDataInRelatedCollections(UserModel user) async {
    if (user.id == null) return;
    final uid = user.id!;
    final name = user.fullNameString();
    final pic = user.profilePic ?? '';

    try {
      // Run all 3 queries in parallel
      final results = await Future.wait([
        fireStore.collection(CollectionName.ads).where('sellerId', isEqualTo: uid).get(),
        fireStore.collection(CollectionName.chatRooms).where('senderId', isEqualTo: uid).get(),
        fireStore.collection(CollectionName.chatRooms).where('receiverId', isEqualTo: uid).get(),
      ]);

      final allDocs = <DocumentReference, Map<String, dynamic>>{};

      // Ads: update sellerName/sellerProfile
      for (var doc in results[0].docs) {
        final data = doc.data();
        if (data['sellerName'] != name || data['sellerProfile'] != pic) {
          allDocs[doc.reference] = {'sellerName': name, 'sellerProfile': pic};
        }
      }

      // Chat rooms (sender)
      for (var doc in results[1].docs) {
        final data = doc.data();
        if (data['senderName'] != name || data['senderProfile'] != pic) {
          allDocs[doc.reference] = {'senderName': name, 'senderProfile': pic};
        }
      }

      // Chat rooms (receiver)
      for (var doc in results[2].docs) {
        final data = doc.data();
        if (data['receiverName'] != name || data['receiverProfile'] != pic) {
          allDocs[doc.reference] = {'receiverName': name, 'receiverProfile': pic};
        }
      }

      // Batch update only docs that actually need changes
      if (allDocs.isEmpty) return;

      final entries = allDocs.entries.toList();
      for (var i = 0; i < entries.length; i += 400) {
        final batch = fireStore.batch();
        final chunk = entries.sublist(i, i + 400 > entries.length ? entries.length : i + 400);
        for (var entry in chunk) {
          batch.update(entry.key, entry.value);
        }
        await batch.commit();
      }

      developer.log('Synced user data in ${allDocs.length} documents');
    } catch (e) {
      developer.log('_syncUserDataInRelatedCollections Error: $e');
    }
  }

  static Future<void> clearFcmToken() async {
    try {
      final uid = getCurrentUid();
      if (uid != null) {
        await fireStore.collection(CollectionName.customers).doc(uid).update({'fcmToken': ''});
      }
    } catch (e) {
      developer.log("Failed to clear FCM token: $e");
    }
  }

  static Future<void> deleteUserAccount() async {
    try {
      final uid = getCurrentUid();
      if (uid == null) return;

      // 1. Clear FCM token first
      await clearFcmToken();

      // 2. Delete user's ads + notifications in batches (max 500 per batch)
      final adsSnapshot = await fireStore.collection(CollectionName.ads).where('sellerId', isEqualTo: uid).get();
      final notifSnapshot = await fireStore.collection(CollectionName.notification).where('receiverId', isEqualTo: uid).get();

      final allDocs = [...adsSnapshot.docs, ...notifSnapshot.docs];
      for (var i = 0; i < allDocs.length; i += 400) {
        final batch = fireStore.batch();
        final chunk = allDocs.sublist(i, i + 400 > allDocs.length ? allDocs.length : i + 400);
        for (var doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 3. Delete customer document from Firestore
      await fireStore.collection(CollectionName.customers).doc(uid).delete();

      // 5. Delete from Firebase Auth
      await FirebaseAuth.instance.currentUser!.delete();
    } on FirebaseAuthException catch (error) {
      developer.log("Firebase Auth Exception : $error");
      rethrow;
    } catch (error) {
      developer.log("Error deleting account: $error");
      rethrow;
    }
  }

  static Future<List<CategoryModel>> getAllCategory() async {
    final snapshot = await fireStore.collection(CollectionName.category).get();

    return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data())).toList();
  }

  static Future<List<CategoryModel>> getParentCategory() async {
    // Fetch only root categories (no parentCategoryId or empty)
    final snapshot = await fireStore.collection(CollectionName.category).where('parentCategoryId', isEqualTo: '').get();
    final snapshot2 = await fireStore.collection(CollectionName.category).where('parentCategoryId', isNull: true).get();

    final list = <CategoryModel>[];
    for (var doc in [...snapshot.docs, ...snapshot2.docs]) {
      list.add(CategoryModel.fromJson(doc.data()));
    }
    return list;
  }
  static Future<List<CategoryModel>> getSubCategories(String parentId) async {
    try {
      final snapshot = await fireStore
          .collection(CollectionName.category)
          .where('parentCategoryId', isEqualTo: parentId)
          .where('active', isEqualTo: true)
          .get();
      final list = snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (a.categoryName ?? '').compareTo(b.categoryName ?? ''));
      return list;
    } catch (e) {
      developer.log('getSubCategories Error: $e');
      return [];
    }
  }
  static Future<ContactUsModel?> getContactUsInformation() async {
    ContactUsModel? contactUsModel;
    await fireStore
        .collection(CollectionName.settings)
        .doc('contact_us')
        .get()
        .then((value) {
          if (value.data() != null) {
            contactUsModel = ContactUsModel.fromJson(value.data()!);
            // Mirror admin-configured URLs into Constants so features
            // (Share, store-download CTAs, etc.) can reach them without
            // a new fetch.
            Constant.androidAppUrl.value = contactUsModel?.androidURL ?? '';
            Constant.iosAppUrl.value = contactUsModel?.iosURL ?? '';
            Constant.webAppUrl.value = contactUsModel?.webAppURL ?? '';
          }
        })
        .catchError((error) {
          log("Failed to get data: $error");
          return null;
        });
    return contactUsModel;
  }

  static Future<List<SubscriptionPackageModel>> getAdsListingSubscription() async {
    try {
      final snap = await fireStore.collection(CollectionName.subscriptionPackage).where("type", isEqualTo: "ad_listing").where('status', isEqualTo: true).get();
      final list = snap.docs.map((doc) => SubscriptionPackageModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (a.createdAt?.toDate() ?? DateTime(2000)).compareTo(b.createdAt?.toDate() ?? DateTime(2000)));
      return list;
    } catch (error) {
      log('Error fetching Ads Listing subscriptions Plans: $error');
      return [];
    }
  }

  static Future<List<SubscriptionPackageModel>> getFeaturedAdsSubscription() async {
    try {
      final snap = await fireStore.collection(CollectionName.subscriptionPackage).where("type", isEqualTo: "featured_ads").where('status', isEqualTo: true).get();
      final list = snap.docs.map((doc) => SubscriptionPackageModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (a.createdAt?.toDate() ?? DateTime(2000)).compareTo(b.createdAt?.toDate() ?? DateTime(2000)));
      return list;
    } catch (error) {
      log('Error fetching Featured Ads subscriptions Plans: $error');
      return [];
    }
  }

  // ── JOB APPLICATIONS ────────────────────────────────────────────────
  /// Saves a job application document. Returns true on success.
  static Future<bool> saveJobApplication(JobApplicationModel application) async {
    try {
      await fireStore.collection(CollectionName.jobApplications).doc(application.id).set(application.toJson());

      // Notify the employer (ad owner) about the new application.
      await _notifyEmployerOfApplication(application);
      return true;
    } catch (e) {
      developer.log('saveJobApplication Error: $e');
      return false;
    }
  }

  /// Sends the employer an FCM push + saved in-app notification for a new
  /// job application. Failures here never block the application save.
  static Future<void> _notifyEmployerOfApplication(JobApplicationModel application) async {
    try {
      final employerId = application.employerId;
      if (employerId == null || employerId.isEmpty) return;

      final employerDoc = await fireStore.collection(CollectionName.customers).doc(employerId).get();
      final token = employerDoc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;

      final applicantName = (application.applicantName ?? '').trim().isEmpty ? 'Someone' : application.applicantName!.trim();
      final jobTitle = application.adTitle ?? 'your job';

      await SendNotification.sendOneNotification(
        token: token,
        title: 'New job application',
        body: '$applicantName applied for "$jobTitle"',
        isPayment: false,
        isSaveNotification: true,
        payload: {'type': 'job_application', 'adId': application.adId ?? '', 'receiverId': employerId, 'senderId': application.applicantId ?? '', 'userType': 'customer'},
      );
    } catch (e) {
      developer.log('_notifyEmployerOfApplication Error: $e');
    }
  }

  /// Applications submitted BY the given applicant (for the "Job Applications" screen).
  /// Sorted newest-first client-side to avoid needing a composite index.
  static Future<List<JobApplicationModel>> getMyJobApplications(String applicantId) async {
    try {
      final snapshot = await fireStore.collection(CollectionName.jobApplications).where('applicantId', isEqualTo: applicantId).get();
      final list = snapshot.docs.map((doc) => JobApplicationModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (b.createdAt ?? Timestamp(0, 0)).compareTo(a.createdAt ?? Timestamp(0, 0)));
      return list;
    } catch (e) {
      developer.log('getMyJobApplications Error: $e');
      return [];
    }
  }

  /// Applications received FOR a given job ad (for the employer's "Applicants" screen).
  static Future<List<JobApplicationModel>> getApplicationsForAd(String adId) async {
    try {
      final snapshot = await fireStore.collection(CollectionName.jobApplications).where('adId', isEqualTo: adId).get();
      final list = snapshot.docs.map((doc) => JobApplicationModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (b.createdAt ?? Timestamp(0, 0)).compareTo(a.createdAt ?? Timestamp(0, 0)));
      return list;
    } catch (e) {
      developer.log('getApplicationsForAd Error: $e');
      return [];
    }
  }

  /// Updates an application's status (pending | reviewed | shortlisted | rejected).
  static Future<bool> updateJobApplicationStatus(String applicationId, String status) async {
    try {
      await fireStore.collection(CollectionName.jobApplications).doc(applicationId).update({'status': status, 'updatedAt': Timestamp.now()});

      // Notify the applicant about meaningful decisions.
      if (status == 'shortlisted' || status == 'rejected' || status == 'hired') {
        final doc = await fireStore.collection(CollectionName.jobApplications).doc(applicationId).get();
        if (doc.exists) {
          await _notifyApplicantOfStatus(JobApplicationModel.fromJson(doc.data()!), status);
        }
      }
      return true;
    } catch (e) {
      developer.log('updateJobApplicationStatus Error: $e');
      return false;
    }
  }

  /// Sends the applicant an FCM push + saved in-app notification when their
  /// application is shortlisted or rejected. Never blocks the status update.
  static Future<void> _notifyApplicantOfStatus(JobApplicationModel application, String status) async {
    try {
      final applicantId = application.applicantId;
      if (applicantId == null || applicantId.isEmpty) return;

      final applicantDoc = await fireStore.collection(CollectionName.customers).doc(applicantId).get();
      final token = applicantDoc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;

      final jobTitle = application.adTitle ?? 'a job';
      late final String title;
      late final String body;
      switch (status) {
        case 'hired':
          title = "Congratulations! You're hired";
          body = 'You have been hired for "$jobTitle". The employer may reach out with next steps.';
          break;
        case 'shortlisted':
          title = "You've been shortlisted!";
          body = 'Your application for "$jobTitle" has been shortlisted.';
          break;
        default: // rejected
          title = "Application update";
          body = 'Your application for "$jobTitle" was not selected this time.';
      }

      await SendNotification.sendOneNotification(
        token: token,
        title: title,
        body: body,
        isPayment: false,
        isSaveNotification: true,
        payload: {'type': 'job_application_status', 'adId': application.adId ?? '', 'receiverId': applicantId, 'senderId': application.employerId ?? '', 'userType': 'customer'},
      );
    } catch (e) {
      developer.log('_notifyApplicantOfStatus Error: $e');
    }
  }

  /// Returns true if [applicantId] already submitted an application for [adId].
  static Future<bool> hasAppliedToJob({required String adId, required String applicantId}) async {
    try {
      final snapshot = await fireStore.collection(CollectionName.jobApplications).where('adId', isEqualTo: adId).where('applicantId', isEqualTo: applicantId).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      developer.log('hasAppliedToJob Error: $e');
      return false;
    }
  }

  static Future<List<CustomFieldModel>> getCustomFields({required String categoryId, required String parentCategoryId}) async {
    final snapshot = await fireStore.collection(CollectionName.customFields).where('selectedCategories', arrayContainsAny: [categoryId, parentCategoryId]).get();

    return snapshot.docs.map((doc) => CustomFieldModel.fromJson(doc.data())).where((f) => f.active == true).toList();
  }

  // AD METHODS ==========

  static Future<bool> saveAd(AdModel ad) async {
    try {
      await fireStore.collection(CollectionName.ads).doc(ad.id).set(ad.toJson());

      // Notify admin about new ad
      SendNotification.sendToTopic(
        topic: 'esellify-admin',
        title: 'New Ad Posted',
        body: '${ad.sellerName ?? "A user"} posted "${ad.title}"',
        payload: {'type': 'new_ad', 'adId': ad.id ?? ''},
      );

      return true;
    } catch (e) {
      developer.log('saveAd Error: $e');
      return false;
    }
  }

  static Future<List<AdModel>> getMyAds(String sellerId) async {
    try {
      final snap = await fireStore.collection(CollectionName.ads).where('sellerId', isEqualTo: sellerId).orderBy('createdAt', descending: true).get();
      return snap.docs.map((doc) => AdModel.fromJson(doc.data())).toList();
    } catch (e) {
      developer.log('getMyAds Error: $e');
      return [];
    }
  }

  /// Real-time stream of logged-in user's ads
  static Stream<List<AdModel>> getMyAdsStream(String sellerId) {
    return fireStore
        .collection(CollectionName.ads)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => AdModel.fromJson(doc.data())).toList());
  }

  /// Delete a single ad document
  static Future<bool> deleteAd(String adId) async {
    try {
      await fireStore.collection(CollectionName.ads).doc(adId).delete();
      return true;
    } catch (e) {
      developer.log('deleteAd Error: $e');
      return false;
    }
  }

  /// Full update of an ad document
  static Future<bool> updateAd(AdModel ad) async {
    try {
      await fireStore.collection(CollectionName.ads).doc(ad.id).update(ad.toJson());
      return true;
    } catch (e) {
      developer.log('updateAd Error: $e');
      return false;
    }
  }

  /// Update ad status (active / inactive / pending / sold)
  static Future<bool> updateAdStatus(String adId, String status, bool isActive, {String? soldToUserId, String? soldToUserName}) async {
    try {
      final Map<String, dynamic> data = {'status': status, 'isActive': isActive, 'updatedAt': FieldValue.serverTimestamp()};
      if (soldToUserId != null) data['soldToUserId'] = soldToUserId;
      if (soldToUserName != null) data['soldToUserName'] = soldToUserName;

      await fireStore.collection(CollectionName.ads).doc(adId).update(data);
      return true;
    } catch (e) {
      developer.log('updateAdStatus Error: $e');
      return false;
    }
  }

  // ─── Feature Sections ─────────────────────────────────────

  // ─── Favourites / Likes (stored in ad's likedUser array) ──

  /// Toggle like: adds/removes userId from ad's likedUser array.
  /// Returns true if liked, false if unliked.
  static Future<bool> toggleLike(String adId, String userId) async {
    try {
      final docRef = fireStore.collection(CollectionName.ads).doc(adId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final List<dynamic> likedUser = List<dynamic>.from(data['likedUser'] ?? []);

      if (likedUser.contains(userId)) {
        // Unlike
        likedUser.remove(userId);
        await docRef.update({'likedUser': likedUser, 'likes': FieldValue.increment(-1)});
        return false;
      } else {
        // Like
        likedUser.add(userId);
        await docRef.update({'likedUser': likedUser, 'likes': FieldValue.increment(1)});

        // Notify ad owner about the like
        final sellerId = data['sellerId'] as String?;
        if (sellerId != null && sellerId.isNotEmpty && sellerId != userId) {
          final sellerDoc = await fireStore.collection(CollectionName.customers).doc(sellerId).get();
          final sellerToken = sellerDoc.data()?['fcmToken'] as String?;
          if (sellerToken != null && sellerToken.isNotEmpty) {
            final adTitle = data['title'] as String? ?? 'your ad';
            final userName = Constant.userModel?.fullNameString() ?? 'Someone';
            SendNotification.sendOneNotification(
              token: sellerToken,
              title: 'Someone liked your ad',
              body: '$userName liked "$adTitle"',
              isPayment: false,
              isSaveNotification: true,
              payload: {'type': 'ad_liked', 'adId': adId, 'receiverId': sellerId, 'senderId': userId, 'userType': 'customer'},
            );
          }
        }

        return true;
      }
    } catch (e) {
      developer.log('toggleLike Error: $e');
      return false;
    }
  }

  /// Check if the user liked this ad (from model data, no extra query)
  static bool isAdLikedByUser(AdModel ad, String userId) {
    return ad.likedUser?.contains(userId) ?? false;
  }

  /// Get all ads liked by user
  static Future<List<AdModel>> getUserFavouriteAds(String userId) async {
    List<AdModel> list = [];
    try {
      final snap = await fireStore.collection(CollectionName.ads).where('likedUser', arrayContains: userId).get();
      for (var doc in snap.docs) {
        final data = doc.data();
        list.add(AdModel.fromJson(data));
      }
      list.sort((a, b) => (b.createdAt?.toDate() ?? DateTime(2000)).compareTo(a.createdAt?.toDate() ?? DateTime(2000)));
    } catch (e) {
      developer.log('getUserFavouriteAds Error: $e');
    }
    return list;
  }

  /// Track ad view: ads/{adId}/viewers/{userId}
  /// Doc ID = userId. If doc already exists, Firestore skips the create.
  /// Also updates the `views` counter on the ad document.
  static Future<void> incrementAdViews(String adId) async {
    try {
      final uid = getCurrentUid();
      if (uid == null) return;

      final viewerRef = fireStore.collection(CollectionName.ads).doc(adId).collection('viewers').doc(uid);

      final doc = await viewerRef.get();
      if (!doc.exists) {
        await viewerRef.set({'viewedAt': Timestamp.now()});
        // Keep views counter in sync for fast reads in list screens
        await fireStore.collection(CollectionName.ads).doc(adId).update({'views': FieldValue.increment(1)});
      }
    } catch (_) {}
  }

  /// Get the viewer count from the subcollection.
  static Future<int> getAdViewerCount(String adId) async {
    try {
      final snap = await fireStore.collection(CollectionName.ads).doc(adId).collection('viewers').count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ── PAGINATED AD QUERIES ──────────────────────────────────────────

  /// Fetch ads using geohash bounding box queries for distance filtering at Firestore level.
  /// Location is required — returns empty if user has no location set.
  /// Cursor-based pagination over active ads. Keeps fetching batches from
  /// Firestore (ordered by createdAt DESC) until we have `limit` ads that
  /// pass all filters, or Firestore runs out.
  ///
  /// All filters (category, search, price, posted-since, distance) are
  /// applied inside the collection loop so a page consistently returns up
  /// to `limit` items. The cursor advances per-consumed-doc so breaking
  /// mid-batch still resumes correctly on the next call.
  ///
  /// For fairness: within each page, featured ads are pinned on top and
  /// the rest are shuffled — so older sellers aren't strictly buried by
  /// chronological order within a given page.
  static Future<PaginatedResult<AdModel>> getActiveAdsPaginated({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? categoryId,
    String? searchQuery,
    FeatureSectionModel? section,
    double? minPrice,
    double? maxPrice,
    DateTime? postedSinceCutoff,
    bool? verifiedOnly,
    bool? featuredOnly,
    Map<String, String>? customFilters,
  }) async {
    try {
      final isSectioned = section != null;
      if (isSectioned) {
        return _fetchForSection(limit: limit, section: section, categoryId: categoryId, searchQuery: searchQuery);
      }

      final effectiveCategoryId = (categoryId != null && categoryId.isNotEmpty) ? categoryId : null;
      final userLocation = Constant.currentLocation.value;
      final hasLocation = userLocation?.location?.latitude != null && userLocation?.location?.longitude != null;
      final maxRange = Constant.maxRange.toDouble();
      final isUnlimitedRange = maxRange == 0;
      final needsDistanceFilter = hasLocation && !isUnlimitedRange;

      Query baseQuery;
      if (effectiveCategoryId != null) {
        baseQuery = fireStore
            .collection(CollectionName.ads)
            .where('status', isEqualTo: 'active')
            .where('categoryPath', arrayContains: effectiveCategoryId)
            .orderBy('createdAt', descending: true);
      } else {
        baseQuery = fireStore.collection(CollectionName.ads).where('status', isEqualTo: 'active').orderBy('createdAt', descending: true);
      }

      final now = DateTime.now();
      final List<AdModel> collected = [];
      DocumentSnapshot? consumedCursor = lastDocument;
      bool firestoreHasMore = true;

      outer:
      while (collected.length < limit && firestoreHasMore) {
        Query q = baseQuery;
        if (consumedCursor != null) q = q.startAfterDocument(consumedCursor);

        final batchSize = needsDistanceFilter ? (limit * 3) : limit * 2;
        final snap = await q.limit(batchSize).get();

        if (snap.docs.isEmpty) {
          firestoreHasMore = false;
          break;
        }
        if (snap.docs.length < batchSize) firestoreHasMore = false;

        for (final doc in snap.docs) {
          consumedCursor = doc;

          final ad = AdModel.fromJson(doc.data() as Map<String, dynamic>);
          if (ad.expiryDate != null && ad.expiryDate!.toDate().isBefore(now)) continue;
          if (ad.isFeatured == true && ad.featuredUntil != null && ad.featuredUntil!.toDate().isBefore(now)) {
            ad.isFeatured = false;
          }

          // Distance filter
          if (needsDistanceFilter && ad.location?.latitude != null && ad.location?.longitude != null) {
            final dist = DistanceUtils.haversineDistanceKm(userLocation!.location!.latitude!, userLocation.location!.longitude!, ad.location!.latitude!, ad.location!.longitude!);
            if (dist > maxRange) continue;
          }

          // Search filter
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final sq = searchQuery.toLowerCase();
            if (!((ad.title ?? '').toLowerCase().contains(sq) || (ad.description ?? '').toLowerCase().contains(sq))) continue;
          }

          // Price filter
          if (minPrice != null && (ad.price ?? 0) < minPrice) continue;
          if (maxPrice != null && (ad.price ?? 0) > maxPrice) continue;

          // Posted-since filter
          if (postedSinceCutoff != null) {
            final created = ad.createdAt?.toDate();
            if (created == null || created.isBefore(postedSinceCutoff)) continue;
          }

          // Verified seller filter
          if (verifiedOnly == true && ad.isSellerVerified != true) continue;

          // Promoted ads filter
          if (featuredOnly == true && ad.isFeatured != true) continue;

          // Dynamic custom field filters
          // Each entry in customFilters is { fieldName: selectedValue }
          // The ad must have a matching customField entry for every active filter
          if (customFilters != null && customFilters.isNotEmpty) {
            bool passesAll = true;
            for (final entry in customFilters.entries) {
              if (entry.value.isEmpty) continue;
              bool fieldMatched = false;
              if (ad.customFields != null) {
                for (final field in ad.customFields!) {
                  final name = field['name']?.toString().toLowerCase() ?? '';
                  final value = field['value']?.toString() ?? '';
                  if (name == entry.key.toLowerCase() && value.toLowerCase() == entry.value.toLowerCase()) {
                    fieldMatched = true;
                    break;
                  }
                }
              }
              if (!fieldMatched) {
                passesAll = false;
                break;
              }
            }
            if (!passesAll) continue;
          }

          collected.add(ad);
          if (collected.length >= limit) break outer;
        }
      }

      // Fairness: featured first, then shuffle the rest so older sellers
      // in the same page aren't buried by strict chronological order.
      final featured = collected.where((a) => a.isFeatured == true).toList();
      final others = collected.where((a) => a.isFeatured != true).toList()..shuffle();
      collected
        ..clear()
        ..addAll(featured)
        ..addAll(others);

      // hasMore: if we hit the limit, there may be more data (unconsumed
      // docs in snap OR more in Firestore). If we exited the while without
      // hitting limit, we've drained everything.
      final hasMore = collected.length >= limit;
      return PaginatedResult(items: collected, lastDocument: consumedCursor, hasMore: hasMore);
    } catch (e) {
      developer.log('getActiveAdsPaginated Error: $e');
      return PaginatedResult(items: [], lastDocument: null, hasMore: false);
    }
  }

  /// Home-page feature section fetch — large pool, client-side filter, no
  /// cursor pagination (sections have their own ranking like most_liked,
  /// most_viewed, price_criteria which don't compose with cursor).
  static Future<PaginatedResult<AdModel>> _fetchForSection({required int limit, required FeatureSectionModel section, String? categoryId, String? searchQuery}) async {
    try {
      final poolLimit = (limit * 20).clamp(50, 300);
      final effectiveCategoryId = (categoryId != null && categoryId.isNotEmpty)
          ? categoryId
          : (section.filterType == 'category_criteria' && (section.categoryId?.isNotEmpty ?? false))
          ? section.categoryId
          : null;

      Query query;
      if (effectiveCategoryId != null && effectiveCategoryId.isNotEmpty) {
        query = fireStore
            .collection(CollectionName.ads)
            .where('status', isEqualTo: 'active')
            .where('categoryPath', arrayContains: effectiveCategoryId)
            .orderBy('createdAt', descending: true);
      } else if (section.filterType == 'featured_ads') {
        query = fireStore.collection(CollectionName.ads).where('status', isEqualTo: 'active').where('isFeatured', isEqualTo: true).orderBy('createdAt', descending: true);
      } else {
        query = fireStore.collection(CollectionName.ads).where('status', isEqualTo: 'active').orderBy('createdAt', descending: true);
      }

      final snap = await query.limit(poolLimit).get();
      final now = DateTime.now();
      List<AdModel> ads = [];
      for (final doc in snap.docs) {
        final ad = AdModel.fromJson(doc.data() as Map<String, dynamic>);
        if (ad.expiryDate != null && ad.expiryDate!.toDate().isBefore(now)) continue;
        if (ad.isFeatured == true && ad.featuredUntil != null && ad.featuredUntil!.toDate().isBefore(now)) ad.isFeatured = false;
        ads.add(ad);
      }

      switch (section.filterType) {
        case 'most_liked':
          ads = ads.where((ad) => (ad.likes ?? 0) > 0).toList()..sort((a, b) => (b.likes ?? 0).compareTo(a.likes ?? 0));
          break;
        case 'most_viewed':
          ads = ads.where((ad) => (ad.views ?? 0) > 0).toList()..sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));
          break;
        case 'price_criteria':
          if (section.minPrice != null) ads = ads.where((ad) => (ad.price ?? 0) >= section.minPrice!).toList();
          if (section.maxPrice != null) ads = ads.where((ad) => (ad.price ?? 0) <= section.maxPrice!).toList();
          ads.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
          break;
        case 'featured_ads':
          ads = ads.where((ad) => ad.isFeatured == true).toList();
          break;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        ads = ads.where((ad) => (ad.title ?? '').toLowerCase().contains(q) || (ad.description ?? '').toLowerCase().contains(q)).toList();
      }

      // Distance filter + featured-first within admin range
      final userLoc = Constant.currentLocation.value;
      final hasLoc = userLoc?.location?.latitude != null && userLoc?.location?.longitude != null;
      final maxRange = Constant.maxRange.toDouble();
      final isUnlimited = maxRange == 0;
      if (hasLoc && !isUnlimited) {
        final uLat = userLoc!.location!.latitude!;
        final uLng = userLoc.location!.longitude!;
        ads = ads.where((ad) {
          if (ad.location?.latitude == null || ad.location?.longitude == null) return true;
          return DistanceUtils.haversineDistanceKm(uLat, uLng, ad.location!.latitude!, ad.location!.longitude!) <= maxRange;
        }).toList();
      }

      if (ads.length > limit) ads = ads.sublist(0, limit);
      return PaginatedResult(items: ads, lastDocument: null, hasMore: false);
    } catch (e) {
      developer.log('_fetchForSection Error: $e');
      return PaginatedResult(items: [], lastDocument: null, hasMore: false);
    }
  }

  /// Fetches per-category ad counts from the full DB (respecting user's
  /// location + admin maxRange). Used by filter UI to show accurate counts
  /// independent of pagination state.
  static Future<Map<String, int>> getCategoryCounts() async {
    try {
      final userLocation = Constant.currentLocation.value;
      final hasLocation = userLocation?.location?.latitude != null && userLocation?.location?.longitude != null;
      final maxRange = Constant.maxRange.toDouble();
      final isUnlimitedRange = maxRange == 0;
      final needsDistanceFilter = hasLocation && !isUnlimitedRange;

      final snap = await fireStore.collection(CollectionName.ads).where('status', isEqualTo: 'active').get();

      final now = DateTime.now();
      final Map<String, int> counts = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        final expiryTs = data['expiryDate'];
        if (expiryTs is Timestamp && expiryTs.toDate().isBefore(now)) continue;

        if (needsDistanceFilter) {
          final loc = data['location'];
          if (loc is Map && loc['latitude'] is num && loc['longitude'] is num) {
            final dist = DistanceUtils.haversineDistanceKm(
              userLocation!.location!.latitude!,
              userLocation.location!.longitude!,
              (loc['latitude'] as num).toDouble(),
              (loc['longitude'] as num).toDouble(),
            );
            if (dist > maxRange) continue;
          }
        }

        final path = data['categoryPath'];
        if (path is List) {
          for (final id in path) {
            if (id is String && id.isNotEmpty) {
              counts[id] = (counts[id] ?? 0) + 1;
            }
          }
        }
      }
      return counts;
    } catch (e) {
      developer.log('getCategoryCounts Error: $e');
      return {};
    }
  }

  static Future<List<FeatureSectionModel>> getActiveFeatureSections() async {
    List<FeatureSectionModel> list = [];
    try {
      QuerySnapshot snap = await fireStore.collection(CollectionName.featureSections).where('active', isEqualTo: true).get();
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) list.add(FeatureSectionModel.fromJson(data));
      }
      list.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    } catch (e) {
      developer.log('getActiveFeatureSections Error: $e');
    }
    return list;
  }

  // ─── CHAT METHODS ──────────────────────────────────────────

  /// Find an existing chat room between two users for a specific ad
  static Future<ChatRoomModel?> findChatRoom({required String adId, required String senderId, required String receiverId}) async {
    try {
      // Check if current user is the sender
      var snap = await fireStore
          .collection(CollectionName.chatRooms)
          .where('adId', isEqualTo: adId)
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return ChatRoomModel.fromJson(snap.docs.first.data());
      }

      // Check if current user is the receiver
      snap = await fireStore
          .collection(CollectionName.chatRooms)
          .where('adId', isEqualTo: adId)
          .where('senderId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: senderId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return ChatRoomModel.fromJson(snap.docs.first.data());
      }
    } catch (e) {
      developer.log('findChatRoom Error: $e');
    }
    return null;
  }

  /// Get all chat rooms for a specific ad (all buyers who chatted about this ad)
  static Future<List<ChatRoomModel>> getChatRoomsForAd(String adId) async {
    try {
      final snap = await fireStore.collection(CollectionName.chatRooms).where('adId', isEqualTo: adId).orderBy('lastMessageTime', descending: true).get();
      return snap.docs.map((doc) => ChatRoomModel.fromJson(doc.data())).toList();
    } catch (e) {
      developer.log('getChatRoomsForAd Error: $e');
      return [];
    }
  }

  /// Create or get existing chat room
  static Future<ChatRoomModel> getOrCreateChatRoom({required AdModel ad, required UserModel currentUser}) async {
    final existing = await findChatRoom(adId: ad.id!, senderId: currentUser.id!, receiverId: ad.sellerId!);
    if (existing != null) return existing;

    final docRef = fireStore.collection(CollectionName.chatRooms).doc();
    final chatRoom = ChatRoomModel(
      id: docRef.id,
      adId: ad.id,
      adTitle: ad.title,
      adImage: ad.mainImage,
      adPrice: ad.price,
      isJobCategory: ad.isJobCategory,
      minSalary: ad.minSalary,
      maxSalary: ad.maxSalary,
      adCategory: ad.leafCategoryName,
      adCurrencySymbol: ad.currency?.symbol,
      adCurrencySymbolAtRight: ad.currency?.symbolAtRight,
      adCurrencyDecimalDigits: ad.currency?.decimalDigits,
      senderId: currentUser.id,
      senderName: currentUser.fullNameString(),
      senderProfile: currentUser.profilePic,
      receiverId: ad.sellerId,
      receiverName: ad.sellerName,
      receiverProfile: ad.sellerProfile,
      lastMessage: '',
      lastMessageType: 'text',
      lastMessageTime: Timestamp.now(),
      senderUnreadCount: 0,
      receiverUnreadCount: 0,
      createdAt: Timestamp.now(),
    );
    await docRef.set(chatRoom.toJson());
    return chatRoom;
  }

  /// Like [getOrCreateChatRoom] but lets the caller specify the OTHER participant
  /// explicitly (used when the employer starts a chat with a specific applicant,
  /// where the other user is the applicant, not the ad's seller).
  static Future<ChatRoomModel> getOrCreateChatRoomWith({required AdModel ad, required UserModel currentUser, required UserModel otherUser}) async {
    final existing = await findChatRoom(adId: ad.id!, senderId: currentUser.id!, receiverId: otherUser.id!);
    if (existing != null) return existing;

    final docRef = fireStore.collection(CollectionName.chatRooms).doc();
    final chatRoom = ChatRoomModel(
      id: docRef.id,
      adId: ad.id,
      adTitle: ad.title,
      adImage: ad.mainImage,
      adPrice: ad.price,
      isJobCategory: ad.isJobCategory,
      minSalary: ad.minSalary,
      maxSalary: ad.maxSalary,
      adCategory: ad.leafCategoryName,
      adCurrencySymbol: ad.currency?.symbol,
      adCurrencySymbolAtRight: ad.currency?.symbolAtRight,
      adCurrencyDecimalDigits: ad.currency?.decimalDigits,
      senderId: currentUser.id,
      senderName: currentUser.fullNameString(),
      senderProfile: currentUser.profilePic,
      receiverId: otherUser.id,
      receiverName: otherUser.fullNameString(),
      receiverProfile: otherUser.profilePic,
      lastMessage: '',
      lastMessageType: 'text',
      lastMessageTime: Timestamp.now(),
      senderUnreadCount: 0,
      receiverUnreadCount: 0,
      createdAt: Timestamp.now(),
    );
    await docRef.set(chatRoom.toJson());
    return chatRoom;
  }

  /// Stream of chat rooms for the current user.
  ///
  /// Optimizations:
  /// - Uses `includeMetadataChanges: true` to deliver cached data instantly on
  ///   app launch, then seamlessly merge server updates.
  /// - Proper dual-stream merge via StreamController so both sender and
  ///   receiver side updates are reflected in real-time without re-subscribing.
  static Stream<List<ChatRoomModel>> getChatRoomsStream(String userId) {
    final controller = StreamController<List<ChatRoomModel>>();
    List<ChatRoomModel> senderRooms = [];
    List<ChatRoomModel> receiverRooms = [];
    bool senderReady = false;
    bool receiverReady = false;

    void emitCombined() {
      // Only emit once both streams have delivered at least one snapshot
      // to avoid a flicker where one side is empty momentarily.
      if (!senderReady || !receiverReady) return;

      final all = [...senderRooms, ...receiverRooms];
      all.sort((a, b) {
        final aTime = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
        final bTime = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      controller.add(all);
    }

    final sub1 = fireStore
        .collection(CollectionName.chatRooms)
        .where('senderId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => ChatRoomModel.fromJson(doc.data())).toList())
        .listen(
          (rooms) {
            senderRooms = rooms;
            senderReady = true;
            emitCombined();
          },
          onError: (e) {
            developer.log('getChatRoomsStream senderStream error: $e');
            senderReady = true; // mark ready even on error so UI can still load
            emitCombined();
          },
        );

    final sub2 = fireStore
        .collection(CollectionName.chatRooms)
        .where('receiverId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => ChatRoomModel.fromJson(doc.data())).toList())
        .listen(
          (rooms) {
            receiverRooms = rooms;
            receiverReady = true;
            emitCombined();
          },
          onError: (e) {
            developer.log('getChatRoomsStream receiverStream error: $e');
            receiverReady = true;
            emitCombined();
          },
        );

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  /// Stream of messages for a chat room.
  /// Uses includeMetadataChanges for instant cache-first delivery.
  static Stream<List<ChatMessageModel>> getMessagesStream(String chatRoomId) {
    return fireStore
        .collection(CollectionName.chatRooms)
        .doc(chatRoomId)
        .collection(CollectionName.chatMessages)
        .orderBy('createdAt', descending: false)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => ChatMessageModel.fromJson(doc.data())).toList());
  }

  /// Send a text message.
  /// Optimized: accepts senderId to determine unread counter without an
  /// extra Firestore read. Writes message and updates chat room in parallel.
  static Future<bool> sendMessage({required String chatRoomId, required ChatMessageModel message, required String receiverId}) async {
    try {
      final chatRoomRef = fireStore.collection(CollectionName.chatRooms).doc(chatRoomId);
      final msgRef = chatRoomRef.collection(CollectionName.chatMessages).doc(message.id);

      // Use a Firestore batch to write both in a single round-trip
      final batch = fireStore.batch();

      // 1. Write the message
      batch.set(msgRef, message.toJson());

      // 2. Determine which counter to bump using the cached chatRoom data.
      //    We read from cache first to avoid a network round-trip.
      final chatDoc = await chatRoomRef.get(const GetOptions(source: Source.cache)).catchError((_) => chatRoomRef.get());
      final chatRoom = ChatRoomModel.fromJson(chatDoc.data()!);
      final isCurrentUserSender = chatRoom.senderId == message.senderId;

      batch.update(chatRoomRef, {
        'lastMessage': message.messageType == 'offer' ? 'Made an offer: ${message.offerAmount}' : message.text,
        'lastMessageType': message.messageType,
        'lastMessageTime': Timestamp.now(),
        if (isCurrentUserSender) 'receiverUnreadCount': FieldValue.increment(1),
        if (!isCurrentUserSender) 'senderUnreadCount': FieldValue.increment(1),
      });

      await batch.commit();

      // Send push notification to the receiver (fire-and-forget, don't block the return)
      _sendChatNotification(receiverId: receiverId, chatRoom: chatRoom, message: message);

      return true;
    } catch (e) {
      developer.log('sendMessage Error: $e');
      return false;
    }
  }

  /// Sends a push notification when a chat message is sent.
  /// Runs fire-and-forget so it doesn't slow down the message flow.
  static Future<void> _sendChatNotification({required String receiverId, required ChatRoomModel chatRoom, required ChatMessageModel message}) async {
    try {
      // Fetch receiver's FCM token
      final receiverDoc = await fireStore.collection(CollectionName.customers).doc(receiverId).get();
      if (!receiverDoc.exists) return;
      final receiverUser = UserModel.fromJson(receiverDoc.data()!);
      final token = receiverUser.fcmToken;
      if (token == null || token.isEmpty) return;

      // Build notification content
      final senderName = message.senderName ?? 'Someone';
      String title;
      String body;

      switch (message.messageType) {
        case 'offer':
          title = '$senderName made an offer';
          body = '${chatRoom.formatAmount(message.offerAmount ?? 0)} on ${chatRoom.adTitle ?? 'your ad'}';
          break;
        case 'image':
          title = senderName;
          body = '\u{1F4F7} Sent a photo';
          break;
        default:
          title = senderName;
          body = message.text ?? '';
      }

      await SendNotification.sendOneNotification(
        token: token,
        title: title,
        body: body,
        isPayment: false,
        isSaveNotification: message.messageType == "offer" ? true : false,
        payload: {
          'type': 'chat',
          'chatRoomId': chatRoom.id ?? '',
          'adId': chatRoom.adId ?? '',
          'receiverId': receiverId,
          'senderId': message.senderId ?? '',
          'userType': 'customer',
        },
      );
    } catch (e) {
      developer.log('_sendChatNotification Error: $e');
    }
  }

  /// Mark messages as read.
  /// Optimized: reads from cache first to determine sender/receiver role,
  /// then updates the counter in a single write.
  static Future<void> markMessagesAsRead(String chatRoomId, String currentUserId) async {
    try {
      final chatRoomRef = fireStore.collection(CollectionName.chatRooms).doc(chatRoomId);
      final chatDoc = await chatRoomRef.get(const GetOptions(source: Source.cache)).catchError((_) => chatRoomRef.get());
      if (!chatDoc.exists) return;
      final chatRoom = ChatRoomModel.fromJson(chatDoc.data()!);
      final isCurrentUserSender = chatRoom.senderId == currentUserId;

      // Skip update if already zero to avoid unnecessary writes
      final myUnread = isCurrentUserSender ? (chatRoom.senderUnreadCount ?? 0) : (chatRoom.receiverUnreadCount ?? 0);
      if (myUnread == 0) return;

      await chatRoomRef.update({if (isCurrentUserSender) 'senderUnreadCount': 0, if (!isCurrentUserSender) 'receiverUnreadCount': 0});
    } catch (e) {
      developer.log('markMessagesAsRead Error: $e');
    }
  }

  /// Update offer status (accept/reject) and notify the offer sender
  static Future<bool> updateOfferStatus({required String chatRoomId, required String messageId, required String status}) async {
    try {
      await fireStore.collection(CollectionName.chatRooms).doc(chatRoomId).collection(CollectionName.chatMessages).doc(messageId).update({'offerStatus': status});

      // Send notification to the offer sender
      _sendOfferResponseNotification(chatRoomId: chatRoomId, messageId: messageId, status: status);

      return true;
    } catch (e) {
      developer.log('updateOfferStatus Error: $e');
      return false;
    }
  }

  /// Sends a push notification when an offer is accepted/declined.
  static Future<void> _sendOfferResponseNotification({required String chatRoomId, required String messageId, required String status}) async {
    try {
      // Get the offer message to find the sender
      final msgDoc = await fireStore.collection(CollectionName.chatRooms).doc(chatRoomId).collection(CollectionName.chatMessages).doc(messageId).get();
      if (!msgDoc.exists) return;
      final msg = ChatMessageModel.fromJson(msgDoc.data()!);

      // Get the chat room for ad info
      final chatDoc = await fireStore.collection(CollectionName.chatRooms).doc(chatRoomId).get();
      if (!chatDoc.exists) return;
      final chatRoom = ChatRoomModel.fromJson(chatDoc.data()!);

      // Get the offer sender's FCM token (to notify them)
      final offerSenderId = msg.senderId;
      if (offerSenderId == null) return;
      final senderDoc = await fireStore.collection(CollectionName.customers).doc(offerSenderId).get();
      if (!senderDoc.exists) return;
      final senderUser = UserModel.fromJson(senderDoc.data()!);
      final token = senderUser.fcmToken;
      if (token == null || token.isEmpty) return;

      // Who responded (the other person in the chat)
      final responderName = chatRoom.otherUserName(offerSenderId);
      final statusText = status == 'accepted' ? 'accepted' : 'declined';
      final formattedAmount = chatRoom.formatAmount(msg.offerAmount ?? 0);

      await SendNotification.sendOneNotification(
        token: token,
        title: 'Offer $statusText',
        body: '$responderName $statusText your offer of $formattedAmount on ${chatRoom.adTitle ?? 'an ad'}',
        isPayment: false,
        isSaveNotification: true,
        payload: {
          'type': 'offer_response',
          'chatRoomId': chatRoomId,
          'adId': chatRoom.adId ?? '',
          'receiverId': offerSenderId,
          'senderId': getCurrentUid() ?? '',
          'userType': 'customer',
        },
      );
    } catch (e) {
      developer.log('_sendOfferResponseNotification Error: $e');
    }
  }

  // ─── Block / Unblock User ───────────────────────────────────────────────────

  /// Block a user — adds the blocked user's ID to the current user's blockedUsers array
  static Future<bool> blockUser(String currentUserId, String blockedUserId) async {
    try {
      await fireStore.collection(CollectionName.customers).doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });
      return true;
    } catch (e) {
      developer.log('blockUser Error: $e');
      return false;
    }
  }

  /// Unblock a user — removes the user's ID from the blockedUsers array
  static Future<bool> unblockUser(String currentUserId, String unblockedUserId) async {
    try {
      await fireStore.collection(CollectionName.customers).doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([unblockedUserId]),
      });
      return true;
    } catch (e) {
      developer.log('unblockUser Error: $e');
      return false;
    }
  }

  /// Fetch full UserModel profiles for a list of user IDs
  static Future<List<UserModel>> getUserProfiles(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      final List<UserModel> profiles = [];
      // Firestore whereIn supports max 30 items per query
      for (var i = 0; i < userIds.length; i += 30) {
        final chunk = userIds.sublist(i, i + 30 > userIds.length ? userIds.length : i + 30);
        final snap = await fireStore.collection(CollectionName.customers).where('id', whereIn: chunk).get();
        profiles.addAll(snap.docs.map((doc) => UserModel.fromJson(doc.data())));
      }
      return profiles;
    } catch (e) {
      developer.log('getUserProfiles Error: $e');
      return [];
    }
  }

  /// Get the current user's blocked users list
  static Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final doc = await fireStore.collection(CollectionName.customers).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return List<String>.from(doc.data()!['blockedUsers'] ?? []);
      }
      return [];
    } catch (e) {
      developer.log('getBlockedUsers Error: $e');
      return [];
    }
  }

  /// Fetch ads for a feature section on Home Screen.
  static Future<List<AdModel>> getAdsForSection(FeatureSectionModel section) async {
    try {
      final maxRecords = section.maxRecords ?? 10;

      // Featured ads section — fetch globally (not limited by location)
      if (section.filterType == 'featured_ads') {
        final ads = await _fetchFeaturedAdsForSection(section);
        return ads;
      }

      // Fetch more ads than needed so enough survive after filtering
      final fetchLimit = maxRecords * 20;

      final result = await getActiveAdsPaginated(limit: fetchLimit, section: section);

      // Trim to maxRecords
      final ads = result.items.length > maxRecords ? result.items.sublist(0, maxRecords) : result.items;
      return ads;
    } catch (e) {
      developer.log('❌ [${section.title}] getAdsForSection Error: $e');
      return [];
    }
  }

  /// Fetch featured ads globally — not limited by user's location
  static Future<List<AdModel>> _fetchFeaturedAdsForSection(FeatureSectionModel section) async {
    try {
      final snap = await fireStore
          .collection(CollectionName.ads)
          .where('status', isEqualTo: 'active')
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(section.maxRecords ?? 10)
          .get();

      final now = DateTime.now();
      final ads = <AdModel>[];
      for (final doc in snap.docs) {
        final ad = AdModel.fromJson(doc.data());
        // Skip expired ads
        if (ad.expiryDate != null && ad.expiryDate!.toDate().isBefore(now)) continue;
        // Skip expired featured
        if (ad.featuredUntil != null && ad.featuredUntil!.toDate().isBefore(now)) continue;
        ads.add(ad);
      }

      // Sort by distance if user location available
      final userLocation = Constant.currentLocation.value;
      if (userLocation?.location?.latitude != null && userLocation?.location?.longitude != null) {
        final userLat = userLocation!.location!.latitude!;
        final userLng = userLocation.location!.longitude!;
        ads.sort((a, b) {
          final distA = (a.location?.latitude != null) ? DistanceUtils.haversineDistanceKm(userLat, userLng, a.location!.latitude!, a.location!.longitude!) : double.maxFinite;
          final distB = (b.location?.latitude != null) ? DistanceUtils.haversineDistanceKm(userLat, userLng, b.location!.latitude!, b.location!.longitude!) : double.maxFinite;
          return distA.compareTo(distB);
        });
      }

      return ads;
    } catch (e) {
      developer.log('_fetchFeaturedAdsForSection Error: $e');
      return [];
    }
  }

  static Future<bool> setNotification(NotificationModel notificationModel) async {
    try {
      await fireStore.collection(CollectionName.notification).doc(notificationModel.id).set(notificationModel.toJson(), SetOptions(merge: false));
      return true;
    } catch (e) {
      developer.log("Failed to update user notification: $e");
      return false;
    }
  }

  /// Stream of notifications for the current user, ordered by newest first
  static Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return fireStore
        .collection(CollectionName.notification)
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => NotificationModel.fromJson(doc.data())).toList());
  }

  /// Mark a notification as read
  static Future<void> markNotificationRead(String notificationId) async {
    try {
      await fireStore.collection(CollectionName.notification).doc(notificationId).update({'isRead': true});
    } catch (e) {
      developer.log("markNotificationRead Error: $e");
    }
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllNotificationsRead(String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.notification).where('receiverId', isEqualTo: userId).where('isRead', isEqualTo: false).get();
      final batch = fireStore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      developer.log("markAllNotificationsRead Error: $e");
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await fireStore.collection(CollectionName.notification).doc(notificationId).delete();
    } catch (e) {
      developer.log("deleteNotification Error: $e");
    }
  }

  // ── BANNERS ─────────────────────────────────────────────────────────

  static Future<List<BannerModel>> getActiveBanners() async {
    List<BannerModel> list = [];
    try {
      QuerySnapshot snap = await fireStore.collection(CollectionName.banners).where('active', isEqualTo: true).get();
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) list.add(BannerModel.fromJson(data));
      }
      list.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    } catch (e) {
      developer.log('getActiveBanners Error: $e');
    }
    return list;
  }

  static Future<AdModel?> getAdById(String adId) async {
    try {
      final doc = await fireStore.collection(CollectionName.ads).doc(adId).get();
      if (doc.exists && doc.data() != null) return AdModel.fromJson(doc.data()!);
    } catch (e) {
      developer.log('getAdById Error: $e');
    }
    return null;
  }

  static Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final doc = await fireStore.collection(CollectionName.category).doc(categoryId).get();
      if (doc.exists && doc.data() != null) return CategoryModel.fromJson(doc.data()!);
    } catch (e) {
      developer.log('getCategoryById Error: $e');
    }
    return null;
  }

  // ── REPORTS ─────────────────────────────────────────────────────────

  static Future<List<ReportReasonModel>> getActiveReportReasons() async {
    try {
      final snap = await fireStore.collection(CollectionName.reportReasons).where('active', isEqualTo: true).get();
      final list = snap.docs.map((doc) => ReportReasonModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
      return list;
    } catch (e) {
      developer.log('getActiveReportReasons Error: $e');
      return [];
    }
  }

  static Future<bool> hasUserReportedAd(String adId, String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.adReports).where('adId', isEqualTo: adId).where('reporterId', isEqualTo: userId).limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      developer.log('hasUserReportedAd Error: $e');
      return false;
    }
  }

  static Future<bool> submitAdReport(AdReportModel report) async {
    try {
      await fireStore.collection(CollectionName.adReports).doc(report.id).set(report.toJson());

      // Notify admin about new report
      SendNotification.sendToTopic(
        topic: 'esellify-admin',
        title: 'New Ad Report',
        body: 'A report was submitted for "${report.adTitle ?? "an ad"}"',
        payload: {'type': 'new_report', 'adId': report.adId ?? ''},
      );

      return true;
    } catch (e) {
      developer.log('submitAdReport Error: $e');
      return false;
    }
  }

  /// Get all reports submitted by the current user
  static Future<List<AdReportModel>> getMyReports(String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.adReports).where('reporterId', isEqualTo: userId).get();
      final list = snap.docs.map((doc) => AdReportModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (b.createdAt?.toDate() ?? DateTime(2000)).compareTo(a.createdAt?.toDate() ?? DateTime(2000)));
      return list;
    } catch (e) {
      developer.log('getMyReports Error: $e');
      return [];
    }
  }

  /// Get report count for a specific ad
  static Future<int> getAdReportCount(String adId) async {
    try {
      final snap = await fireStore.collection(CollectionName.adReports).where('adId', isEqualTo: adId).count().get();
      return snap.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── SUBSCRIPTIONS & TRANSACTIONS ─────────────────────────────────────────

  /// Get user's active subscription for a specific package type
  static Future<UserSubscriptionModel?> getActiveSubscription(String userId, String packageType) async {
    try {
      final snap = await fireStore
          .collection(CollectionName.userSubscriptions)
          .where('userId', isEqualTo: userId)
          .where('packageType', isEqualTo: packageType)
          .where('status', isEqualTo: 'active')
          .get();
      if (snap.docs.isEmpty) return null;
      final subs = snap.docs.map((doc) => UserSubscriptionModel.fromJson(doc.data())).toList();
      subs.sort((a, b) => (b.purchaseDate?.toDate() ?? DateTime(2000)).compareTo(a.purchaseDate?.toDate() ?? DateTime(2000)));
      final sub = subs.first;
      // Auto-expire if past expiryDate
      if (sub.expiryDate != null && sub.expiryDate!.toDate().isBefore(DateTime.now())) {
        await fireStore.collection(CollectionName.userSubscriptions).doc(sub.id).update({'status': 'expired'});
        return null;
      }
      return sub;
    } catch (e) {
      developer.log('getActiveSubscription Error: $e');
      return null;
    }
  }

  /// Get all subscriptions for a user
  static Future<List<UserSubscriptionModel>> getUserSubscriptions(String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.userSubscriptions).where('userId', isEqualTo: userId).get();
      final list = snap.docs.map((doc) => UserSubscriptionModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (b.purchaseDate?.toDate() ?? DateTime(2000)).compareTo(a.purchaseDate?.toDate() ?? DateTime(2000)));
      return list;
    } catch (e) {
      developer.log('getUserSubscriptions Error: $e');
      return [];
    }
  }

  /// Create a new user subscription
  static Future<bool> createUserSubscription(UserSubscriptionModel sub) async {
    try {
      await fireStore.collection(CollectionName.userSubscriptions).doc(sub.id).set(sub.toJson());
      return true;
    } catch (e) {
      developer.log('createUserSubscription Error: $e');
      return false;
    }
  }

  /// Update a user subscription
  static Future<bool> updateUserSubscription(UserSubscriptionModel sub) async {
    try {
      await fireStore.collection(CollectionName.userSubscriptions).doc(sub.id).update(sub.toJson());
      return true;
    } catch (e) {
      developer.log('updateUserSubscription Error: $e');
      return false;
    }
  }

  /// Cancel all active subscriptions of a specific type for a user
  static Future<void> cancelActiveSubscriptions(String userId, String packageType) async {
    try {
      final snap = await fireStore
          .collection(CollectionName.userSubscriptions)
          .where('userId', isEqualTo: userId)
          .where('packageType', isEqualTo: packageType)
          .where('status', isEqualTo: 'active')
          .get();
      final batch = fireStore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'status': 'cancelled'});
      }
      await batch.commit();
    } catch (e) {
      developer.log('cancelActiveSubscriptions Error: $e');
    }
  }

  /// Increment adsPosted count on a subscription
  /// Count user's current active ads (status: active, pending, resubmitted)
  static Future<int> countUserActiveAds(String sellerId) async {
    try {
      final snap = await fireStore
          .collection(CollectionName.ads)
          .where('sellerId', isEqualTo: sellerId)
          .where('status', whereIn: ['active', 'pending', 'resubmitted'])
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      developer.log('countUserActiveAds Error: $e');
      return 0;
    }
  }

  /// Sync adsPosted on a subscription to match actual active ad count
  static Future<void> syncAdsPosted(String subscriptionId, String sellerId) async {
    try {
      final count = await countUserActiveAds(sellerId);
      await fireStore.collection(CollectionName.userSubscriptions).doc(subscriptionId).update({'adsPosted': count});
    } catch (e) {
      developer.log('syncAdsPosted Error: $e');
    }
  }

  /// Count user's current featured ads
  static Future<int> countUserFeaturedAds(String sellerId) async {
    try {
      final snap = await fireStore.collection(CollectionName.ads).where('sellerId', isEqualTo: sellerId).where('isFeatured', isEqualTo: true).count().get();
      return snap.count ?? 0;
    } catch (e) {
      developer.log('countUserFeaturedAds Error: $e');
      return 0;
    }
  }

  /// Sync featured adsPosted on subscription
  static Future<void> syncFeaturedAdsPosted(String subscriptionId, String sellerId) async {
    try {
      final count = await countUserFeaturedAds(sellerId);
      await fireStore.collection(CollectionName.userSubscriptions).doc(subscriptionId).update({'adsPosted': count});
    } catch (e) {
      developer.log('syncFeaturedAdsPosted Error: $e');
    }
  }

  /// Create a transaction record
  static Future<bool> createTransaction(TransactionModel txn) async {
    try {
      await fireStore.collection(CollectionName.transactions).doc(txn.id).set(txn.toJson());
      return true;
    } catch (e) {
      developer.log('createTransaction Error: $e');
      return false;
    }
  }

  /// Get all transactions for a user
  static Future<List<TransactionModel>> getUserTransactions(String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.transactions).where('userId', isEqualTo: userId).get();
      final list = snap.docs.map((doc) => TransactionModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (b.createdAt?.toDate() ?? DateTime(2000)).compareTo(a.createdAt?.toDate() ?? DateTime(2000)));
      return list;
    } catch (e) {
      developer.log('getUserTransactions Error: $e');
      return [];
    }
  }

  /// Mark an ad as featured
  static Future<bool> markAdAsFeatured(String adId, Timestamp? featuredUntil) async {
    try {
      await fireStore.collection(CollectionName.ads).doc(adId).update({'isFeatured': true, 'featuredUntil': featuredUntil});
      return true;
    } catch (e) {
      developer.log('markAdAsFeatured Error: $e');
      return false;
    }
  }

  /// Remove featured status from an ad
  static Future<bool> removeAdFeatured(String adId) async {
    try {
      await fireStore.collection(CollectionName.ads).doc(adId).update({'isFeatured': false, 'featuredUntil': null});
      return true;
    } catch (e) {
      developer.log('removeAdFeatured Error: $e');
      return false;
    }
  }

  /// Get featured ads for current user
  static Future<List<AdModel>> getMyFeaturedAds(String sellerId) async {
    try {
      final snap = await fireStore.collection(CollectionName.ads).where('sellerId', isEqualTo: sellerId).where('isFeatured', isEqualTo: true).get();
      final list = snap.docs.map((doc) => AdModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (b.createdAt?.toDate() ?? DateTime(2000)).compareTo(a.createdAt?.toDate() ?? DateTime(2000)));
      return list;
    } catch (e) {
      developer.log('getMyFeaturedAds Error: $e');
      return [];
    }
  }

  // ── VERIFICATION ──────────────────────────────────────────────────

  static Future<List<VerificationDocumentModel>> getActiveVerificationDocuments() async {
    try {
      final snap = await fireStore.collection(CollectionName.verificationDocuments).where('active', isEqualTo: true).get();
      return snap.docs.map((doc) => VerificationDocumentModel.fromJson(doc.data())).toList();
    } catch (e) {
      developer.log('getActiveVerificationDocuments Error: $e');
      return [];
    }
  }

  static Future<bool> submitVerificationData(String userId, String status, Map<String, dynamic> verificationData) async {
    try {
      await fireStore.collection(CollectionName.customers).doc(userId).set({'verificationStatus': status, 'verificationData': verificationData}, SetOptions(merge: true));
      return true;
    } catch (e) {
      developer.log('submitVerificationData Error: $e');
      return false;
    }
  }

  // ── AUTO-EXPIRY (runs on app launch) ──────────────────────────────

  /// Run all expiry checks for the current user
  static Future<void> runExpiryChecks(String userId) async {
    try {
      await Future.wait([_expireSubscriptions(userId), _expireAds(userId), _expireFeaturedAds(userId)]);
    } catch (e) {
      developer.log('runExpiryChecks Error: $e');
    }
  }

  /// Expire active subscriptions past their expiryDate
  static Future<void> _expireSubscriptions(String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.userSubscriptions).where('userId', isEqualTo: userId).where('status', isEqualTo: 'active').get();

      final batch = fireStore.batch();
      bool hasUpdates = false;

      for (final doc in snap.docs) {
        final sub = UserSubscriptionModel.fromJson(doc.data());
        if (sub.expiryDate != null && sub.expiryDate!.toDate().isBefore(DateTime.now())) {
          batch.update(doc.reference, {'status': 'expired'});
          hasUpdates = true;

          // If ad_listing package expired with listingDurationType = 'package'
          // → all user's active ads should be deactivated
          if (sub.packageType == 'ad_listing' && sub.listingDurationType == 'package') {
            await _deactivateAllUserAds(userId);
          }

          // If featured_ads package expired with listingDurationType = 'package'
          // → remove featured from all user's ads
          if (sub.packageType == 'featured_ads' && sub.listingDurationType == 'package') {
            await _removeAllUserFeatured(userId);
          }
        }
      }

      if (hasUpdates) await batch.commit();
    } catch (e) {
      developer.log('_expireSubscriptions Error: $e');
    }
  }

  /// Expire individual ads past their expiryDate
  static Future<void> _expireAds(String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.ads).where('sellerId', isEqualTo: userId).where('status', isEqualTo: 'active').get();

      final batch = fireStore.batch();
      bool hasUpdates = false;
      final now = DateTime.now();

      for (final doc in snap.docs) {
        final data = doc.data();
        final expiryDate = data['expiryDate'] as Timestamp?;
        if (expiryDate != null && expiryDate.toDate().isBefore(now)) {
          batch.update(doc.reference, {'status': 'inactive', 'isActive': false});
          hasUpdates = true;
        }
      }

      if (hasUpdates) await batch.commit();
    } catch (e) {
      developer.log('_expireAds Error: $e');
    }
  }

  /// Remove featured status from ads past their featuredUntil date
  static Future<void> _expireFeaturedAds(String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.ads).where('sellerId', isEqualTo: userId).where('isFeatured', isEqualTo: true).get();

      final batch = fireStore.batch();
      bool hasUpdates = false;
      final now = DateTime.now();

      for (final doc in snap.docs) {
        final data = doc.data();
        final featuredUntil = data['featuredUntil'] as Timestamp?;
        if (featuredUntil != null && featuredUntil.toDate().isBefore(now)) {
          batch.update(doc.reference, {'isFeatured': false, 'featuredUntil': null});
          hasUpdates = true;
        }
      }

      if (hasUpdates) await batch.commit();
    } catch (e) {
      developer.log('_expireFeaturedAds Error: $e');
    }
  }

  /// Deactivate all active ads for a user (when package with 'package' duration expires)
  static Future<void> _deactivateAllUserAds(String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.ads).where('sellerId', isEqualTo: userId).where('status', isEqualTo: 'active').get();

      final batch = fireStore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'status': 'inactive', 'isActive': false});
      }
      if (snap.docs.isNotEmpty) await batch.commit();
    } catch (e) {
      developer.log('_deactivateAllUserAds Error: $e');
    }
  }

  /// Remove featured from all user's ads (when featured package with 'package' duration expires)
  static Future<void> _removeAllUserFeatured(String userId) async {
    try {
      final snap = await fireStore.collection(CollectionName.ads).where('sellerId', isEqualTo: userId).where('isFeatured', isEqualTo: true).get();

      final batch = fireStore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isFeatured': false, 'featuredUntil': null});
      }
      if (snap.docs.isNotEmpty) await batch.commit();
    } catch (e) {
      developer.log('_removeAllUserFeatured Error: $e');
    }
  }

  // ── REVIEWS & PURCHASES ──────────────────────────────────────────────────

  /// Get ads purchased by a buyer (where soldToUserId == buyerId)
  static Future<List<AdModel>> getMyPurchases(String buyerId) async {
    try {
      final snap = await fireStore.collection(CollectionName.ads).where('soldToUserId', isEqualTo: buyerId).get();
      final list = snap.docs.map((doc) => AdModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (b.createdAt?.toDate() ?? DateTime(2000)).compareTo(a.createdAt?.toDate() ?? DateTime(2000)));
      return list;
    } catch (e) {
      developer.log('getMyPurchases Error: $e');
      return [];
    }
  }

  /// Submit a review for a seller
  static Future<bool> submitReview(ReviewModel review) async {
    try {
      await fireStore.collection(CollectionName.reviews).doc(review.id).set(review.toJson());
      return true;
    } catch (e) {
      developer.log('submitReview Error: $e');
      return false;
    }
  }

  /// Check if buyer already reviewed a seller for a specific ad
  static Future<bool> hasReviewedForAd(String buyerId, String adId) async {
    try {
      final snap = await fireStore.collection(CollectionName.reviews).where('buyerId', isEqualTo: buyerId).where('adId', isEqualTo: adId).limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all reviews for a seller
  static Future<List<ReviewModel>> getSellerReviews(String sellerId) async {
    try {
      final snap = await fireStore.collection(CollectionName.reviews).where('sellerId', isEqualTo: sellerId).get();
      final list = snap.docs.map((doc) => ReviewModel.fromJson(doc.data())).toList();
      list.sort((a, b) => (b.createdAt?.toDate() ?? DateTime(2000)).compareTo(a.createdAt?.toDate() ?? DateTime(2000)));
      return list;
    } catch (e) {
      developer.log('getSellerReviews Error: $e');
      return [];
    }
  }

  /// Get seller's average rating and review count
  static Future<Map<String, dynamic>> getSellerRating(String sellerId) async {
    try {
      final reviews = await getSellerReviews(sellerId);
      if (reviews.isEmpty) return {'average': 0.0, 'count': 0};
      final total = reviews.fold<double>(0, (sum, r) => sum + (r.rating ?? 0));
      return {'average': total / reviews.length, 'count': reviews.length};
    } catch (e) {
      return {'average': 0.0, 'count': 0};
    }
  }
}

class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedResult({required this.items, this.lastDocument, required this.hasMore});
}
