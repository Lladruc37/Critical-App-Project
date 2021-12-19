import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/scheduler.dart';

import 'Classes/message.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.grey),
      home: ChatScreen(user: user),
    );
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
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[700],
        title: Text(
          "General",
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.grey[400],
            ),
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
                  controller: scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    DateTime lastDate;
                    messages.first == messages[index]
                        ? lastDate = DateTime(0, 0, 0)
                        : lastDate = messages[index - 1].timestamp;
                    final message = messages[index];
                    bool isSender = widget.user.email == message.author;
                    return Column(
                      children: [
                        if (lastDate.day != message.timestamp.day)
                          NewDate(date: message.timestamp),
                        Container(
                          alignment:
                              isSender ? Alignment.topRight : Alignment.topLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              message.author,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSender
                                    ? Colors.blueGrey[600]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        BubbleNormal(
                          text: message.text,
                          isSender: isSender,
                          color:
                              isSender ? Colors.blue[400]! : Colors.grey[400]!,
                          tail: true,
                          textStyle: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          alignment:
                              isSender ? Alignment.topRight : Alignment.topLeft,
                          child: Text(
                            '${message.timestamp.hour}:${message.timestamp.second}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        Container(height: 10),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(
            height: 0,
            thickness: 2,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: controller),
                ),
                //Container(width: 10),
                IconButton(
                  onPressed: () {
                    addMessage("General", controller.text,
                        widget.user.email.toString());
                    controller.clear();
                  },
                  icon: Icon(
                    Icons.send,
                    color: Colors.grey[400],
                  ),
                  padding: const EdgeInsets.only(left: 16.0),
                  iconSize: 26.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewDate extends StatelessWidget {
  final DateTime date;
  const NewDate({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DateChip(
        date: date,
        color: Colors.grey[600]!,
      ),
    );
  }
}


// ${widget.user.email.toString()}