import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';

class PetCard extends StatelessWidget {

  final String petId;
  final String name;
  final String breed;
  final int age;

  const PetCard({
    super.key,
    required this.petId,
    required this.name,
    required this.breed,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {

    final firestore = FirestoreService();

    return Card(
      margin: const EdgeInsets.all(10),

      child: ListTile(

        leading: const Icon(Icons.pets),

        title: Text(name),

        subtitle: Text("$breed • Age: $age"),

        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            firestore.deletePet(petId);
          },
        ),
      ),
    );
  }
}