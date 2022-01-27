import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String userMail;
  const ProfileScreen({Key? key, required this.userMail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: db.doc("/users/$userMail").snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                      snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final doc = snapshot.data!.data();
                if (doc != null) {
                  return ListView.builder(
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return Text(doc["Name"]);
                        case 1:
                          return Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(doc["ColorA"],
                                  doc["ColorR"], doc["ColorG"], doc["ColorB"]),
                            ),
                          );
                        default:
                          break;
                      }
                      return Container();
                    },
                  );
                } else {
                  return const Center(child: Text("doc is null!"));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
