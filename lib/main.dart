//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // await dotenv.load(fileName: '.env');
  runApp(
    const AuthGate(
      app: App(),
    ),
  );
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final db = FirebaseFirestore.instance;
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         body: StreamBuilder(
//           stream: db.doc("/chats/jhGZ6Bx7EvKocNdvLUVU").snapshots(),
//           builder: (
//             BuildContext context,
//             AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
//           ) {
//             if (!snapshot.hasData) {
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }
//             final doc = snapshot.data!.data();
//             if (doc != null) {
//               return Center(
//                 child: Text(doc['title']),
//               );
//             } else {
//               return const Center(
//                 child: Text("doc is null"),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }