import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:critical_app/Classes/user.dart';
import 'package:critical_app/Pages/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:critical_app/Pages/channel_drawer.dart';

import 'Classes/message.dart';
import 'Pages/emoji_manager.dart';

typedef StringVoidFunc = void Function(String);

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.grey),
      home: ChatScreen(
        user: user,
      ),
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
  Map<String, Color> userMap = {};
  Map<int, String> emojiMap = {
    0: "Fallen.png",
    1: "RemiDance.gif",
  };
  String chat = "General";
  late UserData user;
  XFile? imageFile;

  void _openGallery(BuildContext context) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    setState(() {
      imageFile = pickedFile!;
    });

    Navigator.pop(context);
  }

  void _openCamera(BuildContext context) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    setState(() {
      imageFile = pickedFile!;
    });
    Navigator.pop(context);
  }

  Future<void> _showChoiceDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              "Choose option",
              style: TextStyle(color: Colors.blue),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  const Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      _openGallery(context);
                    },
                    title: const Text("Gallery"),
                    leading: const Icon(
                      Icons.account_box,
                      color: Colors.blue,
                    ),
                  ),
                  const Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      _openCamera(context);
                    },
                    title: const Text("Camera"),
                    leading: const Icon(
                      Icons.camera,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> uploadFileAbs(String filePath, String name) async {
    File file = File(filePath);
    await FirebaseStorage.instance.ref('Files/$name').putFile(file);
    setState(() {
      imageFile = null;
    });
  }

  @override
  void initState() {
    controller = TextEditingController();
    scrollController = ScrollController();
    emoji = false;
    user = UserData.fromData("", "", const Color.fromARGB(255, 0, 0, 0));
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseStorage.instance;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[800],
      drawer: ChannelDrawer(
        user: widget.user.email!,
        updateChatScreen: (String newChat) {
          setState(() {
            chat = newChat;
          });
        },
        chat: chat,
      ),
      appBar: AppBar(
        backgroundColor: Colors.grey[700],
        leading: Builder(builder: (context) {
          return IconButton(
            icon: Icon(Icons.padding_outlined, color: Colors.grey[400]),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        title: Text(
          chat,
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: userDataSnapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<UserData>> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final newUserData = snapshot.data!;
                for (int i = 0; i < newUserData.length; ++i) {
                  userMap[newUserData[i].name] = newUserData[i].color;
                  if (widget.user.email! == newUserData[i].email) {
                    user = newUserData[i];
                  }
                }
                return StreamBuilder(
                  stream: chatSnapshots(chat),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<List<Message>> snapshot,
                  ) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
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
                        bool isSender = user.name == message.author;
                        return Column(
                          children: [
                            if (lastDate.day != message.timestamp.day)
                              NewDate(date: message.timestamp),
                            Container(
                              alignment: isSender
                                  ? Alignment.topRight
                                  : Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Text(
                                  message.author,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: userMap[message.author],
                                  ),
                                ),
                              ),
                            ),
                            message.type == 0
                                ? BubbleNormal(
                                    text: message.text,
                                    isSender: isSender,
                                    color: isSender
                                        ? Colors.blue[400]!
                                        : Colors.grey[400]!,
                                    tail: true,
                                    textStyle: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                    ),
                                  )
                                : Container(),
                            message.type == 1
                                ? Container(
                                    alignment: isSender
                                        ? Alignment.topRight
                                        : Alignment.topLeft,
                                    child: FutureBuilder(
                                      future:
                                          fs.ref(message.text).getDownloadURL(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<String> snapshot) {
                                        if (!snapshot.hasData) {
                                          return const SizedBox();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0, horizontal: 16.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(10.0)),
                                            child: Image.network(
                                              snapshot.data!,
                                              width: 250,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              alignment: isSender
                                  ? Alignment.topRight
                                  : Alignment.topLeft,
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
                );
              },
            ),
          ),
          Container(
            color: Colors.grey[700],
            alignment: Alignment.topLeft,
            child: imageFile != null
                ? Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(44.0, 4.0, 16.0, 10.0),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10.0)),
                          child: Image.file(
                            File(imageFile!.path),
                            width: 175,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 8.0),
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: () {
                            setState(() {
                              imageFile = null;
                            });
                          },
                          child: const Icon(Icons.delete),
                        ),
                      ),
                    ],
                  )
                : Container(),
          ),
          const Divider(
            height: 0,
            thickness: 2,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    _showChoiceDialog(context);
                  },
                  icon: const Icon(Icons.photo),
                  color: Colors.grey[400],
                  padding: const EdgeInsets.only(right: 16.0),
                ),
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
                      addMessage(chat, text, widget.user.email.toString(), 0);
                      controller.clear();
                    }
                    if (imageFile != null) {
                      String name = imageFile!.path.split('/').last;
                      uploadFileAbs(imageFile!.path, name).then((value) {
                        addMessage(chat, 'Files/$name',
                            widget.user.email.toString(), 1);
                      });
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
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
          BottomBar(
            chat: true,
            email: widget.user.email!,
            emojiMap: emojiMap,
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

class BottomBar extends StatelessWidget {
  final bool chat;
  final String email;
  final Map<int, String> emojiMap;
  const BottomBar({
    Key? key,
    required this.chat,
    required this.email,
    required this.emojiMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(
          height: 0,
          thickness: 2,
        ),
        SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  chat ? Container() : Navigator.pop(context);
                },
                icon: Icon(
                  Icons.chat_bubble,
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EmojiManager(emojimap: emojiMap),
                    ),
                  );
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userMail: email,
                        emojiMap: emojiMap,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.person,
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
        )
      ],
    );
  }
}
