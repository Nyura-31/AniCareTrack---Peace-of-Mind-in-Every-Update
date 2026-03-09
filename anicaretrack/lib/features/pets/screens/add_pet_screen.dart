import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firestore_service.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final ageController = TextEditingController();
  final instructionController = TextEditingController();

  File? petImage;

  final picker = ImagePicker();

  final firestore = FirestoreService();

  Future pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        petImage = File(picked.path);
      });
    }
  }

  Future addPet() async {

    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    await firestore.addPet({
      "name": nameController.text,
      "breed": breedController.text,
      "age": int.parse(ageController.text),
      "instructions": instructionController.text,
      "ownerId": userId,
      "imageUrl": ""
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Add Pet")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: ListView(
            children: [

              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      petImage != null ? FileImage(petImage!) : null,
                  child: petImage == null
                      ? const Icon(Icons.pets, size: 40)
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Pet Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: breedController,
                decoration: const InputDecoration(labelText: "Breed"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: instructionController,
                decoration:
                    const InputDecoration(labelText: "Special Instructions"),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: addPet,
                child: const Text("Save Pet"),
              )
            ],
          ),
        ),
      ),
    );
  }
}