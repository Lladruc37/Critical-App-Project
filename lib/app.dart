import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'Classes/message.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return MaterialApp(
        debugShowCheckedModeBanner: false, home: ChatScreen(user: user));
  }
}

class ChatScreen extends StatefulWidget {
  final User user;
  const ChatScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("General"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: chatSnapshots(),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<Message>> snapshot,
              ) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Container(
                        alignment: widget.user.email == message.author
                            ? Alignment.topRight
                            : Alignment.topLeft,
                        child: Text(message.author),
                      ),
                      subtitle: Container(
                        alignment: widget.user.email == message.author
                            ? Alignment.topRight
                            : Alignment.topLeft,
                        child: Column(
                          children: [
                            Text(message.text),
                            Text(
                              message.timestamp.toString(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: controller),
                ),
                IconButton(
                  onPressed: () {
                    addMessage("General", controller.text,
                        widget.user.email.toString());
                    controller.clear();
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ${widget.user.email.toString()}