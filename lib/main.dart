import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'app/modules/login/views/login_view.dart';
import 'app/services/auth_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  
  // Initialiser AuthService
  await Get.putAsync(() => AuthService().init());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
   const MyApp({super.key});
 @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: Routes.LOGIN,
      getPages: AppPages.routes,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}