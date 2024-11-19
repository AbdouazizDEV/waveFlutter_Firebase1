// lib/app/modules/login/views/login_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        centerTitle: true,
      ),
      body: GetBuilder<LoginController>(
        init: LoginController(),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!controller.codeSent.value) ...[
              TextField(
                keyboardType: TextInputType.phone,
                maxLength: 9,
                onChanged: (value) => controller.phoneNumber.value = value,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixText: '+221 ',
                  border: OutlineInputBorder(),
                ),
              ),
               
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.sendVerificationCode,
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text('Envoyer le code'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => controller.signInWithGoogle(),
                icon: Icon(Icons.g_mobiledata),
                label: Text('Se connecter avec Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => controller.signInWithFacebook(),
                icon: Icon(Icons.facebook),
                label: Text('Se connecter avec Facebook'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              Text(
                'Code envoyé au +221 ${controller.phoneNumber.value}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (value) => controller.verificationCode.value = value,
                decoration: const InputDecoration(
                  labelText: 'Code de vérification',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.verifyCode,
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text('Vérifier'),
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.codeSent.value = false;
                  controller.verificationCode.value = '';
                },
                child: const Text('Changer de numéro'),
              ),
             
            ],
          ],
        )),
      ),
    ));
  }
}