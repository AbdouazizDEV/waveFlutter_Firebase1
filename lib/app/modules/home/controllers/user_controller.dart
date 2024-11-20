// lib/app/modules/home/controllers/user_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';

class UserController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Vérifier si un utilisateur existe déjà
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Erreur lors de la vérification de l\'utilisateur: $e');
      return false;
    }
  }

  // Vérifier si un numéro de téléphone existe
  Future<bool> phoneExists(String phone) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du téléphone: $e');
      return false;
    }
  }

  // Créer un nouvel utilisateur
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      currentUser.value = user;
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur: $e');
      throw 'Erreur lors de la création de l\'utilisateur';
    }
  }

  // Charger les informations d'un utilisateur
  Future<void> loadUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        currentUser.value = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        // Rediriger vers la bonne vue
        _redirectBasedOnUserType();
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'utilisateur: $e');
      throw 'Erreur lors du chargement de l\'utilisateur';
    }
  }

  // Rediriger l'utilisateur selon son type
  void _redirectBasedOnUserType() {
    if (currentUser.value != null) {
      if (currentUser.value!.userType == 'client') {
        Get.offAllNamed('/client-home');
      } else if (currentUser.value!.userType == 'distributeur') {
        Get.offAllNamed('/distributor-home');
      }
    }
  }

  void setUser(UserModel user) {
    currentUser.value = user;
    _redirectBasedOnUserType();
  }

  void clearUser() {
    currentUser.value = null;
  }

  @override
  void onInit() {
    super.onInit();
    // Vous pouvez ajouter ici l'initialisation si nécessaire
  }
}