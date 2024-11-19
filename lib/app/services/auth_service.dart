// lib/app/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
   final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<String?> verificationId = Rx<String?>(null);

 Future<void> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+221$phoneNumber',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw 'Erreur d\'envoi du code: ${e.message}';
        },
        codeSent: (String verId, int? resendToken) {
          verificationId.value = verId; // Utilisons la version Rx
          Get.snackbar('Succès', 'Code envoyé avec succès');
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId.value = verId; // Utilisons la version Rx
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      throw 'Erreur d\'envoi du code: $e';
    }
  }


  Future<bool> verifyOTP(String smsCode) async {
    if (verificationId.value == null) {
      throw 'Erreur: Aucun code n\'a été envoyé';
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value!,
        smsCode: smsCode,
      );
      return await _signInWithCredential(credential);
    } catch (e) {
      throw 'Code incorrect';
    }
  }
  Future<bool> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user != null;
    } catch (e) {
      throw 'Erreur de connexion: $e';
    }
  }
  Future<AuthService> init() async {
    return this;
  }
}