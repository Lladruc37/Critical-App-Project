import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String text;
  DateTime timestamp;
  String author;
  int type;

  Message.fromFirestore(Map<String, dynamic> data)
      : text = data['text'],
        timestamp = (data['timestamp'] as Timestamp).toDate(),
        author = data['author'],
        type = data['type'];

  Map<String, dynamic> toFirestore() => {
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'author': author,
        'type': type,
      };
}

Stream<List<Message>> chatSnapshots(String chat) {
  final db = FirebaseFirestore.instance;
  final snapshots = db
      .collection("chats")
      .doc(chat)
      .collection("Messages")
      .orderBy("timestamp", descending: true)
      .snapshots();
  return snapshots.map((querySnapshot) {
    final messages = querySnapshot.docs;
    return messages.map((qdoc) => Message.fromFirestore(qdoc.data())).toList();
  });
}

Future<void> addMessage(
    String chat, String text, String author, int type) async {
  final db = FirebaseFirestore.instance;
  await db.collection("chats").doc(chat).collection("Messages").add({
    'text': text,
    'author': author,
    'timestamp': Timestamp.now(),
    'type': type,
  });
}
