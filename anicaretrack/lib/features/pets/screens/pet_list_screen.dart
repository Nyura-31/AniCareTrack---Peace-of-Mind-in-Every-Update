import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firestore_service.dart';
import '../widgets/pet_card.dart';
import 'add_pet_screen.dart';

class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirestoreService();

    return Scaffold(

      appBar: AppBar(title: const Text("My Pets")),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPetScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: firestore.getPets(userId),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pets = snapshot.data!.docs;

          if (pets.isEmpty) {
            return const Center(child: Text("No pets added yet"));
          }

          return ListView.builder(
            itemCount: pets.length,
            itemBuilder: (context, index) {

              final pet = pets[index];

              return PetCard(
                petId: pet.id,
                name: pet['name'],
                breed: pet['breed'],
                age: pet['age'],
              );
            },
          );
        },
      ),
    );
  }
}