class PetModel {
  final String id;
  final String name;
  final String breed;
  final int age;
  final String instructions;
  final String imageUrl;
  final String ownerId;

  PetModel({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.instructions,
    required this.imageUrl,
    required this.ownerId,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "breed": breed,
      "age": age,
      "instructions": instructions,
      "imageUrl": imageUrl,
      "ownerId": ownerId,
    };
  }

  factory PetModel.fromMap(Map<String, dynamic> map, String id) {
    return PetModel(
      id: id,
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      age: map['age'] ?? 0,
      instructions: map['instructions'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
    );
  }
}