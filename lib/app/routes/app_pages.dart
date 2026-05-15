import 'package:get/get.dart';

import '../modules/ad_listing_detail/bindings/ad_listing_detail_binding.dart';
import '../modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import '../modules/add_products/bindings/add_products_binding.dart';
import '../modules/add_products/views/add_products_view.dart';
import '../modules/ads_listing/bindings/ads_listing_binding.dart';
import '../modules/ads_listing/views/ads_listing_view.dart';
import '../modules/blocked_users/bindings/blocked_users_binding.dart';
import '../modules/blocked_users/views/blocked_users_view.dart';
import '../modules/my_reports/bindings/my_reports_binding.dart';
import '../modules/my_reports/views/my_reports_view.dart';
import '../modules/payment_method/bindings/payment_method_binding.dart';
import '../modules/payment_method/views/payment_method_view.dart';
import '../modules/categories/bindings/categories_binding.dart';
import '../modules/categories/views/categories_view.dart';
import '../modules/chats/bindings/chats_binding.dart';
import '../modules/chats/views/chats_view.dart';
import '../modules/contact_us/bindings/contact_us_binding.dart';
import '../modules/contact_us/views/contact_us_view.dart';
import '../modules/dashboard_screen/bindings/dashboard_screen_binding.dart';
import '../modules/dashboard_screen/views/dashboard_screen_view.dart';
import '../modules/edit_profile/bindings/edit_profile_binding.dart';
import '../modules/edit_profile/views/edit_profile_view.dart';
import '../modules/favourites/bindings/favourites_binding.dart';
import '../modules/favourites/views/favourites_view.dart';
import '../modules/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/forgot_password/views/forgot_password_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/html_screen/bindings/html_screen_binding.dart';
import '../modules/html_screen/views/html_screen_view.dart';
import '../modules/language/bindings/language_binding.dart';
import '../modules/language/views/language_view.dart';
import '../modules/login_screen/bindings/login_screen_binding.dart';
import '../modules/login_screen/views/login_screen_view.dart';
import '../modules/my_address/bindings/my_address_binding.dart';
import '../modules/my_address/views/my_address_view.dart';
import '../modules/my_ads/bindings/my_ads_binding.dart';
import '../modules/my_ads/views/my_ads_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/onboarding_screen/bindings/onboarding_screen_binding.dart';
import '../modules/onboarding_screen/views/onboarding_screen_view.dart';
import '../modules/payment_history/bindings/payment_history_binding.dart';
import '../modules/payment_history/views/payment_history_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/sell_screen/bindings/sell_screen_binding.dart';
import '../modules/sell_screen/views/sell_screen_view.dart';
import '../modules/signup_screen/bindings/signup_screen_binding.dart';
import '../modules/signup_screen/views/signup_screen_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/sub_category/bindings/sub_category_binding.dart';
import '../modules/sub_category/views/sub_category_view.dart';
import '../modules/subscriptions/bindings/subscriptions_binding.dart';
import '../modules/subscriptions/views/subscriptions_view.dart';
import '../modules/verification/bindings/verification_binding.dart';
import '../modules/verification/views/verification_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import '../modules/my_purchases/bindings/my_purchases_binding.dart';
import '../modules/my_purchases/views/my_purchases_view.dart';
import '../modules/seller_reviews/bindings/seller_reviews_binding.dart';
import '../modules/seller_reviews/views/seller_reviews_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING_SCREEN,
      page: () => const OnboardingScreenView(),
      binding: OnboardingScreenBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN_SCREEN,
      page: () => LoginScreenView(),
      binding: LoginScreenBinding(),
    ),
    GetPage(
      name: _Paths.SIGNUP_SCREEN,
      page: () => SignupScreenView(),
      binding: SignupScreenBinding(),
    ),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD_SCREEN,
      page: () => const DashboardScreenView(),
      binding: DashboardScreenBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.CHATS,
      page: () => const ChatsView(),
      binding: ChatsBinding(),
    ),
    GetPage(
      name: _Paths.SELL_SCREEN,
      page: () => const SellScreenView(),
      binding: SellScreenBinding(),
    ),
    GetPage(
      name: _Paths.MY_ADS,
      page: () => const MyAdsView(),
      binding: MyAdsBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_PROFILE,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: _Paths.PAYMENT_HISTORY,
      page: () => const PaymentHistoryView(),
      binding: PaymentHistoryBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATIONS,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: _Paths.FAVOURITES,
      page: () => const FavouritesView(),
      binding: FavouritesBinding(),
    ),
    GetPage(
      name: _Paths.CONTACT_US,
      page: () => const ContactUsView(),
      binding: ContactUsBinding(),
    ),
    GetPage(
      name: _Paths.HTML_SCREEN,
      page: () => const HtmlScreenView(),
      binding: HtmlScreenBinding(),
    ),
    GetPage(
      name: _Paths.MY_ADDRESS,
      page: () => const MyAddressView(),
      binding: MyAddressBinding(),
    ),
    GetPage(
      name: _Paths.SUBSCRIPTIONS,
      page: () => const SubscriptionsView(),
      binding: SubscriptionsBinding(),
    ),
    GetPage(
      name: _Paths.LANGUAGE,
      page: () => const LanguageView(),
      binding: LanguageBinding(),
    ),
    GetPage(
      name: _Paths.CATEGORIES,
      page: () => const CategoriesView(),
      binding: CategoriesBinding(),
    ),
    GetPage(
      name: _Paths.SUB_CATEGORY,
      page: () => const SubCategoryView(),
      binding: SubCategoryBinding(),
    ),
    GetPage(
      name: _Paths.ADD_PRODUCTS,
      page: () => const AddProductsView(),
      binding: AddProductsBinding(),
    ),
    GetPage(
      name: _Paths.ADS_LISTING,
      page: () => const AdsListingView(),
      binding: AdsListingBinding(),
    ),
    GetPage(
      name: _Paths.AD_LISTING_DETAIL,
      page: () => const AdListingDetailView(),
      binding: AdListingDetailBinding(),
    ),
    GetPage(
      name: _Paths.BLOCKED_USERS,
      page: () => const BlockedUsersView(),
      binding: BlockedUsersBinding(),
    ),
    GetPage(
      name: _Paths.MY_REPORTS,
      page: () => const MyReportsView(),
      binding: MyReportsBinding(),
    ),
    GetPage(
      name: _Paths.PAYMENT_METHOD,
      page: () => const PaymentMethodView(),
      binding: PaymentMethodBinding(),
    ),
    GetPage(
      name: _Paths.VERIFICATION,
      page: () => const VerificationView(),
      binding: VerificationBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: _Paths.MY_PURCHASES,
      page: () => const MyPurchasesView(),
      binding: MyPurchasesBinding(),
    ),
    GetPage(
      name: _Paths.SELLER_REVIEWS,
      page: () => const SellerReviewsView(),
      binding: SellerReviewsBinding(),
    ),
  ];
}
