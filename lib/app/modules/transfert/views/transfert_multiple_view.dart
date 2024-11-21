import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../modules/home/views/home_view.dart';

class TransfertMultipleView extends StatefulWidget {
  const TransfertMultipleView({Key? key}) : super(key: key);

  @override
  _TransfertMultipleViewState createState() => _TransfertMultipleViewState();
}

class _TransfertMultipleViewState extends State<TransfertMultipleView> {
  final TextEditingController montantController = TextEditingController();
  final List<Map<String, dynamic>> selectedContacts = [];
  List<Contact> contacts = [];
  bool isLoadingContacts = false;
  double fraisTransfert = 0.0;

  @override
  void initState() {
    super.initState();
    _requestContactPermission();
  }

  Future<void> _requestContactPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      _loadContacts();
    } else {
      Get.snackbar('Permission refusée',
          'L\'accès aux contacts est nécessaire pour cette fonctionnalité');
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
        contacts = fetchedContacts
            .where((contact) => contact.phones != null && contact.phones!.isNotEmpty)
            .toList();
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les contacts: $e');
    } finally {
      setState(() => isLoadingContacts = false);
    }
  }

  Future<String?> _verifierDestinataireId(String phone) async {
    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: '$phone')
          .limit(1)
          .get();

      if (result.docs.isEmpty) return null;
      return result.docs.first.id;
    } catch (e) {
      print('Erreur de vérification: $e');
      return null;
    }
  }

  void _selectContacts() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Sélectionner des contacts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: isLoadingContacts
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: contacts.length,
                            itemBuilder: (context, index) {
                              final contact = contacts[index];
                              final phone = contact.phones?.first.value ?? '';
                              final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
                              final isSelected = selectedContacts.any(
                                  (c) => c['phone'] == cleanPhone);

                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(contact.displayName?[0] ?? '?'),
                                ),
                                title: Text(contact.displayName ?? 'Sans nom'),
                                subtitle: Text(phone),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                onTap: () async {
                                  final destinataireId = await _verifierDestinataireId(cleanPhone);
                                  //if (destinataireId != null) {
                                    setState(() {
                                      if (isSelected) {
                                        selectedContacts.removeWhere(
                                            (c) => c['phone'] == cleanPhone);
                                      } else {
                                        selectedContacts.add({
                                          'name': contact.displayName ?? 'Sans nom',
                                          'phone': cleanPhone,
                                          'destinataireId': destinataireId,
                                        });
                                      }
                                    });
                                  // } else {
                                  //   Get.snackbar('Erreur',
                                  //       'Ce contact n\'a pas de compte');
                                  // }
                                },
                              );
                            },
                          ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {}); // Rafraîchir l'UI principale
                    },
                    child: Text('Valider (${selectedContacts.length})'),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _calculerFrais(String montant) {
    if (montant.isNotEmpty) {
      try {
        setState(() {
          fraisTransfert = double.parse(montant) * 0.01 * selectedContacts.length;
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

 // Inside _TransfertMultipleViewState class

Future<void> _effectuerTransferts() async {
  if (selectedContacts.isEmpty) {
    Get.snackbar('Erreur', 'Veuillez sélectionner au moins un contact');
    return;
  }

  if (montantController.text.isEmpty) {
    Get.snackbar('Erreur', 'Veuillez entrer un montant');
    return;
  }

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Erreur', 'Utilisateur non connecté');
      return;
    }

    // Vérifier que tous les destinataires existent toujours
    final batch = FirebaseFirestore.instance.batch();
    List<Map<String, dynamic>> validDestinataires = [];
    
    for (var destinataire in selectedContacts) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(destinataire['destinataireId'])
          .get();
          
      if (!userDoc.exists) {
        Get.snackbar('Erreur', 
          'Le compte de ${destinataire['name']} n\'existe plus ou n\'est pas accessible');
        return;
      }
      validDestinataires.add(destinataire);
    }

    final montantParPersonne = double.parse(montantController.text);
    final montantTotal = montantParPersonne * validDestinataires.length;
    final fraisTotal = montantTotal * 0.01; // 1% par transfert
    final total = montantTotal + fraisTotal;

    // Vérifier le solde de l'expéditeur
    final expediteurDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (!expediteurDoc.exists) {
      Get.snackbar('Erreur', 'Votre compte n\'est pas accessible');
      return;
    }
    
    final solde = expediteurDoc.data()?['balance'] ?? 0.0;
    
    if (solde < total) {
      Get.snackbar('Erreur', 'Solde insuffisant');
      return;
    }

    // Effectuer les transferts
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Déduire le montant total de l'expéditeur
      transaction.update(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {'balance': FieldValue.increment(-total)}
      );

      // Traiter chaque transfert
      for (var destinataire in validDestinataires) {
        // Créer le document de transfert
        final transfertRef = FirebaseFirestore.instance.collection('transferts').doc();
        
        transaction.set(transfertRef, {
          'expediteurId': user.uid,
          'destinataireId': destinataire['destinataireId'],
          'numeroDestinataire': destinataire['phone'],
          'montant': montantParPersonne,
          'frais': montantParPersonne * 0.01,
          'status': 'effectue',
          'dateCreation': FieldValue.serverTimestamp(),
        });

        // Mettre à jour le solde du destinataire
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(destinataire['destinataireId']),
          {'balance': FieldValue.increment(montantParPersonne)}
        );
      }
    });

    Get.snackbar('Succès', 'Transferts effectués avec succès');
    Get.offAll(() => HomeView());
  } catch (e) {
    Get.snackbar('Erreur', 'Erreur lors des transferts: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfert Multiple'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: Text('Sélectionner des contacts (${selectedContacts.length})'),
              onPressed: _selectContacts,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = selectedContacts[index];
                  return ListTile(
                    title: Text(contact['name']),
                    subtitle: Text('${contact['phone']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          selectedContacts.removeAt(index);
                          _calculerFrais(montantController.text);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant par personne (XOF)',
              ),
              onChanged: _calculerFrais,
            ),
            const SizedBox(height: 16),
            Text(
              'Frais de transfert total: ${fraisTransfert.toStringAsFixed(2)} XOF',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Montant total: ${((double.tryParse(montantController.text) ?? 0) * selectedContacts.length).toStringAsFixed(2)} XOF',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Total à débiter: ${((double.tryParse(montantController.text) ?? 0) * selectedContacts.length + fraisTransfert).toStringAsFixed(2)} XOF',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _effectuerTransferts,
              child: const Text('Effectuer les transferts'),
            ),
          ],
        ),
      ),
    );
  }
}