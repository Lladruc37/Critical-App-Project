import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  Color color;
  String name;
  String email;

  UserData.fromFirestore(this.email, Map<String, dynamic> data)
      : name = data['Name'],
        color = Color.fromARGB(
            data['ColorA'], data['ColorR'], data['ColorG'], data['ColorB']);

  UserData.fromData(this.name, this.email, this.color);

  Map<String, dynamic> toFirestore() => {
        'Name': name,
        'ColorA': color.alpha,
        'ColorR': color.red,
        'ColorG': color.green,
        'ColorB': color.blue,
      };
}

Stream<List<UserData>> userDataSnapshots() {
  final db = FirebaseFirestore.instance;
  final snapshots = db.collection("users").snapshots();
  return snapshots.map((querySnapshot) {
    final users = querySnapshot.docs;
    return users
        .map((qdoc) => UserData.fromFirestore(qdoc.id, qdoc.data()))
        .toList();
  });
}

Future<void> updateProfile(
    String name, String email, int a, int r, int g, int b) async {
  final db = FirebaseFirestore.instance;
  await db.collection("users").doc(email).update({
    'ColorA': a,
    'ColorB': b,
    'ColorG': g,
    'ColorR': r,
    'Name': name,
  });
}
