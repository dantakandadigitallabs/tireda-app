import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/app/modules/account_disabled_screen.dart';
import 'package:eSellify/app/modules/dashboard_screen/views/dashboard_screen_view.dart';
import 'package:eSellify/app/modules/signup_screen/views/enter_location_view.dart';
import 'package:eSellify/utils/notifications/notification_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/modules/signup_screen/views/signup_screen_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../constant/show_toast.dart';

class LoginScreenController extends GetxController {
  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;

  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> passwordController = TextEditingController().obs;
  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxString loginType = "".obs;
  Rx<String> otpCode = "".obs;
  RxBool isPasswordVisible = true.obs;

  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> emailSignIn() async {
    ShowToastDialog.showLoader("Please Wait..".tr);

    final String email = emailController.value.text;
    final String password = passwordController.value.text;

    try {
      final userCredential = await signInWithEmailAndPassword(email, password);

      if (userCredential == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showError("Invalid email or password.".tr);
        return;
      }

      UserModel? userProfile = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()!);
      String fcmToken = await NotificationService.getToken();
      if (userProfile != null) {
        Constant.userModel = userProfile;
        userProfile.fcmToken = fcmToken;
        await FireStoreUtils.updateUser(userProfile);
        if (userProfile.isActive == true) {
          await Constant.getAddress();
          ShowToastDialog.closeLoader();
          if (Constant.userModel!.addAddresses == null || Constant.userModel!.addAddresses!.isEmpty) {
            developer.log("No addresses found");

            Get.offAll(() => EnterLocationView(isRedirectDashboard: true));
            return;
          }

          /// ✅ NORMAL FLOW
          ShowToastDialog.showSuccess("Logged in successfully!".tr);
          Get.offAll(const DashboardScreenView());
        } else {
          ShowToastDialog.closeLoader();
          Get.offAll(const AccountDisabledScreen());
        }
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showError("Account not found. Please sign up.".tr);
      }
    } on FirebaseAuthException catch (e) {
      developer.log("Firebase code : ${e.code}");
      ShowToastDialog.closeLoader();
      switch (e.code) {
        case 'invalid-email':
          ShowToastDialog.showError("The email address is not valid.".tr);
          break;
        case 'invalid-credential':
        case 'wrong-password':
          ShowToastDialog.showError("Incorrect email or password. Please try again.".tr);
          break;
        case 'user-not-found':
          ShowToastDialog.showError("No account found with this email. Please sign up.".tr);
          break;
        default:
          ShowToastDialog.showError("${"Login failed:".tr} ${e.message}");
          break;
      }
    } catch (e) {
      developer.log("Login error", error: e);
      // Add this line to see the actual error
      developer.log("Error details: ${e.toString()}");
      ShowToastDialog.closeLoader();
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await googleSignIn.initialize();
      final GoogleSignInAccount account = await googleSignIn.authenticate();

      developer.log("🔵 Google account: ${account.email}, ID: ${account.id}");

      final GoogleSignInAuthentication googleAuth = account.authentication;

      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      developer.log("🔵 Firebase user from Google: ${userCredential.user?.uid}, Email: ${userCredential.user?.email}");

      return userCredential;
    } catch (e, stack) {
      developer.log("Error in signInWithGoogle", error: e, stackTrace: stack);
    }
    return null;
  }

  Future<void> loginWithGoogle() async {
    ShowToastDialog.showLoader("Please Wait..".tr);

    try {
      final value = await signInWithGoogle();
      if (value == null) {
        ShowToastDialog.closeLoader();
        return;
      }

      String fcmToken = await NotificationService.getToken();

      bool userExist = await FireStoreUtils.userExistOrNot(value.user!.uid);

      if (userExist) {
        UserModel? userModel = await FireStoreUtils.getUserProfile(value.user!.uid);

        if (userModel != null) {
          if (userModel.loginType != Constant.googleLoginType) {
            ShowToastDialog.closeLoader();
            await FirebaseAuth.instance.signOut();
            await googleSignIn.signOut();
            ShowToastDialog.showError("This email is already registered with Email/Password. Please use that method.".tr);
            return;
          }

          userModel.fcmToken = fcmToken;
          await FireStoreUtils.updateUser(userModel);
          ShowToastDialog.closeLoader();

          if (userModel.isActive == true) {
            Get.offAll(const DashboardScreenView());
          } else {
            Get.offAll(const AccountDisabledScreen());
          }
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showError("User profile not found.".tr);
        }
      } else {
        // New User Flow — split display name into first + last
        ShowToastDialog.closeLoader();
        final displayName = value.user?.displayName ?? '';
        final nameParts = displayName.trim().split(RegExp(r'\s+'));
        UserModel userModel = UserModel(
          id: value.user?.uid,
          email: value.user?.email,
          firstName: nameParts.isNotEmpty ? nameParts.first : '',
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          profilePic: value.user?.photoURL,
          loginType: Constant.googleLoginType,
          fcmToken: fcmToken,
        );
        Get.to(SignupScreenView(), arguments: {'userModel': userModel});
      }
    } catch (e, stackTrace) {
      ShowToastDialog.closeLoader();
      developer.log("Error in loginWithGoogle: $e", stackTrace: stackTrace);
    }
  }

  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName], nonce: nonce);

      final oauthCredential = OAuthProvider("apple.com").credential(idToken: appleCredential.identityToken, rawNonce: rawNonce, accessToken: appleCredential.authorizationCode);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      return {"appleCredential": appleCredential, "userCredential": userCredential};
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint("User cancelled Apple Sign-In");
      } else {
        debugPrint("Apple Sign-In failed: ${e.code} - ${e.message}");
      }
    } catch (e) {
      debugPrint("Unexpected error during Apple Sign-In: $e");
    }
    return null;
  }

  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<void> loginWithApple() async {
    ShowToastDialog.showLoader("Please Wait..".tr);

    try {
      final signIn = await signInWithApple();
      if (signIn == null) {
        ShowToastDialog.showError("Apple Sign-In failed.".tr);
        return;
      }

      Map<String, dynamic> map = signIn;

      AuthorizationCredentialAppleID appleCredential = map['appleCredential'];
      UserCredential userCredential = map['userCredential'];

      final fcmToken = await NotificationService.getToken();

      // ------------------ New User ------------------
      if (userCredential.additionalUserInfo!.isNewUser == true) {
        UserModel userModel = UserModel(
          id: userCredential.user!.uid,
          firstName: appleCredential.givenName ?? '',
          lastName: appleCredential.familyName ?? '',
          email: appleCredential.email ?? userCredential.user!.email ?? '',
          loginType: Constant.appleLoginType,
          fcmToken: fcmToken,
        );

        Get.to(SignupScreenView(), arguments: {'userModel': userModel});
        return;
      }

      // ------------------ Existing User ------------------
      final uid = userCredential.user!.uid;
      final userExists = await FireStoreUtils.userExistOrNot(uid);

      if (!userExists) {
        final userModel = UserModel(
          id: uid,
          firstName: appleCredential.givenName ?? '',
          lastName: appleCredential.familyName ?? '',
          email: appleCredential.email ?? userCredential.user!.email ?? '',
          loginType: Constant.appleLoginType,
          fcmToken: fcmToken,
        );
        Get.to(SignupScreenView(), arguments: {'userModel': userModel});
        return;
      }

      final userModel = await FireStoreUtils.getUserProfile(uid);
      if (userModel == null) {
        ShowToastDialog.showError("This account is not valid for this app.".tr);
        return;
      }
      // Update FCM
      userModel.fcmToken = fcmToken;
      await FireStoreUtils.updateUser(userModel);

      // Navigation based on status
      if (userModel.isActive == true) {
        Get.offAll(const DashboardScreenView());
      } else {
        Get.offAll(const AccountDisabledScreen());
      }
    } catch (e, stackTrace) {
      developer.log("Error in loginWithApple: $e", stackTrace: stackTrace);
    } finally {
      ShowToastDialog.closeLoader();
    }
  }

  String sha256ofString(String input) {
    try {
      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e, stackTrace) {
      developer.log("Error in sha256ofString: $e", stackTrace: stackTrace);
      return '';
    }
  }
}
