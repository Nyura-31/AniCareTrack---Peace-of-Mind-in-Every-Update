import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add Pet
  Future<void> addPet(Map<String, dynamic> data) async {
    await _db.collection('pets').add(data);
  }

  // Get Pets by Owner
  Stream<QuerySnapshot> getPets(String ownerId) {
    return _db
        .collection('pets')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots();
  }

  // Delete Pet
  Future<void> deletePet(String petId) async {
    await _db.collection('pets').doc(petId).delete();
  }

  // Update Pet
  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    await _db.collection('pets').doc(petId).update(data);
  }
}