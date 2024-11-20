// lib/app/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class AuthService extends GetxService {
   final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<String?> verificationId = Rx<String?>(null);
 final GoogleSignIn _googleSignIn = GoogleSignIn();
 final FacebookAuth _facebookAuth = FacebookAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
Future<void> createUserInFirestore(
    UserCredential userCredential, String authProvider) async {
  final userDoc = _firestore.collection('users').doc(userCredential.user!.uid);

  // Vérifiez si l'utilisateur existe déjà dans la base de données
  final docSnapshot = await userDoc.get();

  if (!docSnapshot.exists) {
    // Créez un nouvel utilisateur s'il n'existe pas
    final user = UserModel(
      uid: userCredential.user!.uid,
      phone: userCredential.user!.phoneNumber ?? '',
      email: userCredential.user!.email ?? '',
      userType: 'client', // Par défaut
      authProvider: authProvider,
      balance: 0.0, // Add this line
    );

    await userDoc.set(user.toMap());
    Get.snackbar('Succès', 'Compte utilisateur créé avec succès');
  } else {
    // Si l'utilisateur existe déjà
    Get.snackbar('Succès', 'Utilisateur existant connecté');
  }
}

 Future<void> sendOTP(String phoneNumber) async {
  try {
    // Vérifiez si le numéro de téléphone existe dans Firestore
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: '+221$phoneNumber')
        .get();

    if (snapshot.docs.isEmpty) {
      throw 'Ce numéro de téléphone n\'est pas enregistré dans notre base de données.';
    }

    // Envoyer l'OTP si le numéro existe
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
    // Affichez un message d'erreur
    Get.snackbar('Erreur', e.toString());
    throw 'Erreur d\'envoi du code: $e';
  }
}

Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Vérifiez ou créez l'utilisateur dans Firestore
    await createUserInFirestore(userCredential, 'google');

    return userCredential;
  } catch (e) {
    Get.snackbar('Erreur', 'Erreur de connexion Google: $e');
    return null;
  }
}


Future<UserCredential?> signInWithFacebook() async {
  try {
    final LoginResult result = await _facebookAuth.login();

    if (result.status == LoginStatus.success) {
      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken!.token);

      final userCredential = await _auth.signInWithCredential(credential);

      // Vérifiez ou créez l'utilisateur dans Firestore
      await createUserInFirestore(userCredential, 'facebook');

      return userCredential;
    }
    return null;
  } catch (e) {
    Get.snackbar('Erreur', 'Erreur de connexion Facebook: $e');
    return null;
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