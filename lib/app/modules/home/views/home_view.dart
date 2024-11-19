// lib/app/modules/home/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeView extends GetView {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Welcome')),
    );
  }
}