// lib/app/modules/login/controllers/login_controller.dart
import 'package:get/get.dart';
import '../../../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  final RxString phoneNumber = ''.obs;
  final RxString verificationCode = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool codeSent = false.obs;

  Future<void> sendVerificationCode() async {
    if (phoneNumber.value.length != 9) {
      Get.snackbar('Erreur', 'Le numéro doit contenir 9 chiffres');
      return;
    }

    isLoading.value = true;
    try {
      await _authService.sendOTP(phoneNumber.value);
      codeSent.value = true;
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyCode() async {
    if (verificationCode.value.length != 6) {
      Get.snackbar('Erreur', 'Le code doit contenir 6 chiffres');
      return;
    }

    isLoading.value = true;
    try {
      final bool success = await _authService.verifyOTP(verificationCode.value);
      if (success) {
        Get.offAllNamed('/home');
      }
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
