// lib/app/modules/transfert/views/transfert_simple_view.dart
import 'package:flutter/material.dart';

class TransfertSimpleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfert Simple'),
      ),
      body: Center(
        child: Text('Interface pour un transfert simple'),
      ),
    );
  }
}
