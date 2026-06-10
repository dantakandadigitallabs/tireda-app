import 'package:eSellify/app/models/onboarding_model.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eSellify/app/modules/dashboard_screen/views/dashboard_screen_view.dart';
class OnboardingScreenController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  final List<OnBoardingModel> pages = [
    OnBoardingModel(title: "Discover Great Deals", description: "Browse thousands of items from electronics to fashion — all in one place.", image: 'assets/images/intro_1.svg'),
    OnBoardingModel(title: "Sell in Minutes", description: "Snap a photo, add details, and sell instantly to local buyers.", image: 'assets/images/intro_2.svg'),
    OnBoardingModel(title: "Safe & Easy Transactions", description: "Chat securely, meet locally, and make payments with peace of mind.", image: 'assets/images/intro_3.svg'),
  ];



  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void skipToEnd() {
    Get.offAll(const DashboardScreenView());
  }
}
