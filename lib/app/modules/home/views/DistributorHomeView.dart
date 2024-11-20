import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';

class DistributorHomeView extends StatelessWidget {
  final UserController userController = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Distributeur - Accueil')),
      body: Obx(() {
        final user = userController.currentUser.value;

        if (user == null) {
          return Center(child: Text('Aucun utilisateur connecté.'));
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenue, ${user.email ?? 'Utilisateur'}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Votre solde : ${user.balance.toStringAsFixed(2)} OXF',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Get.snackbar('Info', 'Ceci est le menu du distributeur.');
              },
              child: Text('Accéder au menu distributeur'),
            ),
          ],
        );
      }),
    );
  }
}
