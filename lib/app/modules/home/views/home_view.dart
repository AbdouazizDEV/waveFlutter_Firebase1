// lib/app/modules/home/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../transfert/views/planifier_transfert_view.dart';
import '../../transfert/views/transfert_multiple_view.dart';
import '../../transfert/views/transfert_simple_view.dart';


class HomeView extends GetView {
  final RxBool showBalance = true.obs; // Pour gérer l'affichage/masquage du solde
  final RxDouble balance = 0.0.obs; // Solde de l'utilisateur connecté

  @override
  Widget build(BuildContext context) {
    // Charger les données utilisateur au démarrage
    _loadUserBalance();

    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil Client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Solde
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Solde :',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      showBalance.value ? '${balance.value.toStringAsFixed(2)} XOF' : '******',
                      style: TextStyle(fontSize: 20, color: Colors.green),
                    ),
                    IconButton(
                      icon: Icon(
                        showBalance.value ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        showBalance.value = !showBalance.value;
                      },
                    ),
                  ],
                )),
            const SizedBox(height: 30),

            // Section Menu
            Text(
              'Menu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.send),
              title: Text('Transfert Simple'),
              onTap: () {
                Get.to(TransfertSimpleView());  
              },
            ),
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Transfert Multiple'),
              onTap: () {
                Get.to(() => TransfertMultipleView());
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('Planifier un Transfert'),
              onTap: () {
                Get.to(() => PlanifierTransfertView());
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Fonction pour charger la balance de l'utilisateur connecté
  Future<void> _loadUserBalance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Récupérer les données de l'utilisateur depuis Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final userData = doc.data()!;
          balance.value = userData['balance']?.toDouble() ?? 0.0; // Charger la balance
        } else {
          Get.snackbar('Erreur', 'Utilisateur non trouvé dans la base de données');
        }
      } else {
        Get.snackbar('Erreur', 'Aucun utilisateur connecté');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger la balance: $e');
    }
  }
}
