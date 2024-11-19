// lib/app/routes/app_pages.dart
import 'package:get/get.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/home/views/home_view.dart';

part 'app_routes.dart';

class AppPages {
  static final routes = [
  GetPage(name: Routes.LOGIN, page: () => const LoginView(), binding: LoginBinding()),
  GetPage(name: Routes.HOME, page: () => HomeView()),
];
}