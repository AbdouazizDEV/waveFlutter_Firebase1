// lib/app/modules/login/bindings/login_binding.dart
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../services/auth_service.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService());
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
