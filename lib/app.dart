import 'dart:math';

import 'package:critical_app/Pages/emoji_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/scheduler.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

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
  late bool emoji;
  Map<int, String> emojiMap = {
    0: "Fallen.png",
    1: "RemiDance.gif",
  };

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    scrollController = ScrollController();
    emoji = false;
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseStorage.instance;
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    DateTime lastDate;
                    messages.last == messages[index]
                        ? lastDate = DateTime(0, 0, 0)
                        : lastDate = messages[index + 1].timestamp;
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
                            '${message.timestamp.hour}:${message.timestamp.minute < 10 ? '0' : ''}${message.timestamp.minute}',
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
                  child: Focus(
                    onFocusChange: (value) {
                      if (value) {
                        setState(() {
                          emoji = false;
                        });
                      }
                    },
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              emoji = !emoji;
                            });
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          icon: Icon(
                            Icons.tag_faces,
                            color: Colors.grey[400],
                          ),
                          padding: const EdgeInsets.only(left: 16.0),
                          iconSize: 26.0,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      addMessage("General", text, widget.user.email.toString());
                    }
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
          Offstage(
            offstage: !emoji,
            child: SizedBox(
              height: 250,
              child: Column(children: [
                const Divider(
                  height: 0,
                  thickness: 2,
                ),
                Container(
                  padding: const EdgeInsets.all(6.0),
                  height: 250,
                  child: GridView.builder(
                    itemCount: emojiMap.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey[850]!, width: 2),
                        ),
                        child: FutureBuilder(
                          future: fs.ref(emojiMap[index]).getDownloadURL(),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }
                            return SizedBox(
                              height: 64,
                              child: Image.network(snapshot.data!),
                            );
                          },
                        ),
                      );
                    },
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const Divider(
            height: 0,
            thickness: 2,
          ),
          SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Center(
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.chat_bubble,
                      color: Colors.grey[400],
                    ),
                    padding: const EdgeInsets.only(left: 16.0),
                    iconSize: 26.0,
                  ),
                ),
                VerticalDivider(
                  width: 0,
                  thickness: 2,
                  indent: 10,
                  endIndent: 10,
                  color: Colors.grey[600],
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => EmojiManager(),
                    ));
                  },
                  icon: Icon(
                    Icons.emoji_objects_outlined,
                    color: Colors.grey[400],
                  ),
                  padding: const EdgeInsets.only(left: 16.0),
                  iconSize: 26.0,
                ),
                VerticalDivider(
                  width: 0,
                  thickness: 2,
                  indent: 10,
                  endIndent: 10,
                  color: Colors.grey[600],
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.connect_without_contact_rounded,
                    color: Colors.grey[400],
                  ),
                  padding: const EdgeInsets.only(left: 16.0),
                  iconSize: 26.0,
                ),
                VerticalDivider(
                  width: 0,
                  thickness: 2,
                  indent: 10,
                  endIndent: 10,
                  color: Colors.grey[600],
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.person,
                    color: Colors.grey[400],
                  ),
                  padding: const EdgeInsets.only(left: 16.0),
                  iconSize: 26.0,
                ),
              ],
            ),
          )
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
