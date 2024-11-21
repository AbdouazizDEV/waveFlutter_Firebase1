import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../modules/home/views/home_view.dart';

class TransfertSimpleView extends StatefulWidget {
  const TransfertSimpleView({Key? key}) : super(key: key);

  @override
  _TransfertSimpleViewState createState() => _TransfertSimpleViewState();
}

class _TransfertSimpleViewState extends State<TransfertSimpleView> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController montantController = TextEditingController();
  double fraisTransfert = 0.0;
  List<Contact> contacts = [];
  bool isLoadingContacts = false;
  String? destinataireId;

  @override
  void initState() {
    super.initState();
    _requestContactPermission();
  }

  Future<void> _verifierDestinataire(String phone) async {
    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: '+221$phone')
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        Get.snackbar(
          'Erreur',
          'Aucun utilisateur trouvé avec ce numéro',
          backgroundColor: Colors.red[100],
        );
        destinataireId = null;
      } else {
        destinataireId = result.docs.first.id;
        Get.snackbar(
          'Succès',
          'Destinataire trouvé',
          backgroundColor: Colors.green[100],
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la vérification: $e');
      destinataireId = null;
    }
  }

  Future<void> _requestContactPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      _loadContacts();
    } else {
      Get.snackbar(
        'Permission refusée',
        'L\'accès aux contacts est nécessaire pour cette fonctionnalité',
      );
    }
  }

  Future<void> _loadContacts() async {
    setState(() => isLoadingContacts = true);
    try {
      final List<Contact> fetchedContacts = await ContactsService.getContacts(
        withThumbnails: false,
        photoHighResolution: false,
      );
      setState(() {
        contacts = fetchedContacts.where((contact) => 
          contact.phones != null && contact.phones!.isNotEmpty
        ).toList();
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les contacts: $e');
    } finally {
      setState(() => isLoadingContacts = false);
    }
  }

  void _selectContact() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Sélectionner un contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: isLoadingContacts
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (BuildContext context, int index) {
                        final contact = contacts[index];
                        final phone = contact.phones?.first.value ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(contact.displayName?[0] ?? '?'),
                          ),
                          title: Text(contact.displayName ?? 'Sans nom'),
                          subtitle: Text(phone),
                          onTap: () async {
                            final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
                            phoneController.text = cleanPhone;
                            await _verifierDestinataire(cleanPhone);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _calculerFrais(String montant) {
    if (montant.isNotEmpty) {
      try {
        setState(() {
          fraisTransfert = double.parse(montant) * 0.01; // 1% du montant
        });
      } catch (e) {
        print('Erreur de calcul des frais: $e');
      }
    } else {
      setState(() {
        fraisTransfert = 0.0;
      });
    }
  }

  Future<void> _effectuerTransfert() async {
    if (phoneController.text.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer un numéro de téléphone');
      return;
    }

    if (montantController.text.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer un montant');
      return;
    }

    // Vérifier le destinataire
    await _verifierDestinataire(phoneController.text);
    if (destinataireId == null) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return;
      }

      final montant = double.parse(montantController.text);
      final total = montant + fraisTransfert;

      // Vérifier le solde de l'expéditeur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final solde = userDoc.data()?['balance'] ?? 0.0;
      
      if (solde < total) {
        Get.snackbar('Erreur', 'Solde insuffisant');
        return;
      }

      // Commencer la transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Créer le transfert
        final transfertRef = FirebaseFirestore.instance.collection('transferts').doc();
        transaction.set(transfertRef, {
          'expediteurId': user.uid,
          'destinataireId': destinataireId,
          'numeroDestinataire': phoneController.text,
          'montant': montant,
          'frais': fraisTransfert,
          'status': 'effectue',
          'dateCreation': FieldValue.serverTimestamp(),
        });

        // Mettre à jour le solde de l'expéditeur
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(user.uid),
          {'balance': FieldValue.increment(-total)}
        );

        // Mettre à jour le solde du destinataire
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(destinataireId),
          {'balance': FieldValue.increment(montant)} // Le destinataire reçoit le montant sans les frais
        );
      });

      Get.snackbar('Succès', 'Transfert effectué avec succès');
      Get.offAll(() => HomeView());
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du transfert: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfert Simple'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixText: '+221',
                    ),
                    onChanged: (value) {
                      if (value.length >= 9) {
                        _verifierDestinataire(value);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.contacts),
                  onPressed: _selectContact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant (XOF)',
              ),
              onChanged: _calculerFrais,
            ),
            const SizedBox(height: 16),
            Text(
              'Frais de transfert: ${fraisTransfert.toStringAsFixed(2)} XOF',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Total: ${(double.tryParse(montantController.text) ?? 0 + fraisTransfert).toStringAsFixed(2)} XOF',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _effectuerTransfert,
              child: const Text('Effectuer le transfert'),
            ),
          ],
        ),
      ),
    );
  }
}