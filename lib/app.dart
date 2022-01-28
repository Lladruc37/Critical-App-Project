import 'dart:io';
import 'dart:ui';

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
import 'Classes/firebasefile.dart';

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

class FirebaseApi {
  static Future<List<String>> _getDownloadLinks(List<Reference> refs) =>
      Future.wait(refs.map((ref) => ref.getDownloadURL()).toList());

  static Future<List<FirebaseFile>> listAll(String path) async {
    final ref = FirebaseStorage.instance.ref('Emojis/');
    final result = await ref.listAll();

    final urls = await _getDownloadLinks(result.items);
    return urls
        .asMap()
        .map((index, url) {
          final ref = result.items[index];
          final name = ref.name;
          final file = FirebaseFile(ref: ref, name: name, url: url);

          return MapEntry(index, file);
        })
        .values
        .toList();
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
  late Future<List<FirebaseFile>> futureFiles;
  Map<String, Color> userMap = {};
  List<CustomEmoji> emojiList = [];
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
    futureFiles = FirebaseApi.listAll('Emojis/');
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
    int favCount = 0;
    for (var item in emojiList) {
      if (item.fav) {
        favCount++;
      }
    }
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
          FutureBuilder<List<FirebaseFile>>(
              future: futureFiles,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const Center(child: CircularProgressIndicator());
                  default:
                    if (snapshot.hasError) {
                      return const Center(child: Text('Some error occurred!'));
                    } else {
                      final files = snapshot.data!;
                      emojiList.clear();
                      for (var item in files) {
                        emojiList.add(CustomEmoji(
                            "Emojis/" + item.name,
                            item.name
                                .substring(0, item.name.lastIndexOf("."))));
                      }
                      return Container();
                    }
                }
              }),
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
                                ? BubbleChat(
                                    isSender: isSender,
                                    text: message.text,
                                    emojiList: emojiList,
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
                          child: const Icon(Icons.close),
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
                      addMessage(chat, text, user.name, 0);
                      controller.clear();
                    }
                    if (imageFile != null) {
                      String name = imageFile!.path.split('/').last;
                      uploadFileAbs(imageFile!.path, name).then((value) {
                        addMessage(chat, 'Files/$name', user.name, 1);
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text("Favourites"),
                      ),
                      Divider(
                        indent: 6,
                        endIndent: 6,
                        thickness: 1.5,
                        color: Colors.grey[850],
                      ),
                      favCount == 0
                          ? Container()
                          : GridView.builder(
                              shrinkWrap: true,
                              itemCount: favCount,
                              itemBuilder: (context, index) {
                                return emojiList[index].fav
                                    ? Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[850]!,
                                              width: 2),
                                        ),
                                        child: FutureBuilder(
                                          future: fs
                                              .ref(emojiList[index].path)
                                              .getDownloadURL(),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<String> snapshot) {
                                            if (!snapshot.hasData) {
                                              return const SizedBox();
                                            }
                                            return TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  controller.text = controller
                                                          .text +
                                                      " :" +
                                                      emojiList[index].code +
                                                      ":";
                                                });
                                              },
                                              child: SizedBox(
                                                height: 64,
                                                child: Image.network(
                                                    snapshot.data!),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Container();
                              },
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                              ),
                            ),
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text("All"),
                      ),
                      Divider(
                        indent: 6,
                        endIndent: 6,
                        thickness: 1.5,
                        color: Colors.grey[850],
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        itemCount: emojiList.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey[850]!, width: 2),
                            ),
                            child: FutureBuilder(
                              future: fs
                                  .ref(emojiList[index].path)
                                  .getDownloadURL(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox();
                                }
                                return TextButton(
                                  onPressed: () {
                                    setState(() {
                                      controller.text = controller.text +
                                          " :" +
                                          emojiList[index].code +
                                          ":";
                                    });
                                  },
                                  child: SizedBox(
                                    height: 64,
                                    child: Image.network(snapshot.data!),
                                  ),
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
                    ],
                  ),
                ),
              ]),
            ),
          ),
          BottomBar(
            screen: 0,
            emojiList: emojiList,
            email: widget.user.email!,
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

class MessageInfo {
  String info;
  bool isText;
  MessageInfo(this.info, {this.isText = true});
}

class BubbleChat extends StatelessWidget {
  final bool isSender;
  final String text;
  final List<CustomEmoji> emojiList;
  const BubbleChat(
      {Key? key,
      required this.isSender,
      required this.text,
      required this.emojiList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseStorage.instance;
    List<String> splits = text.split(' ');
    List<MessageInfo> message = [];
    for (String element in splits) {
      message.add(MessageInfo(element));
    }
    if (message.length > 1) {
      for (MessageInfo item in message) {
        if (item.info.startsWith(':') && item.info.endsWith(':')) {
          for (var index in emojiList) {
            if (item.info.substring(1, item.info.length - 1).toLowerCase() ==
                index.code.toLowerCase()) {
              item.isText = false;
              item.info = index.path;
            }
          }
        }
      }
      List<MessageInfo> newMesage = [];
      int i = 0;
      newMesage.add(MessageInfo(""));
      for (MessageInfo item in message) {
        if (item.isText) {
          newMesage[i].info = newMesage[i].info + item.info + " ";
        } else {
          i += 2;
          newMesage.add(item);
          newMesage.add(MessageInfo(""));
        }
      }
      message = newMesage;
    } else {
      for (MessageInfo item in message) {
        if (item.info.startsWith(':') && item.info.endsWith(':')) {
          for (var index in emojiList) {
            if (item.info.substring(1, item.info.length - 1).toLowerCase() ==
                index.code.toLowerCase()) {
              item.isText = false;
              item.info = index.path;
              //print('SUCCESSS');
            }
          }
        }
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isSender
            ? Expanded(
                child: Container(),
              )
            : Container(),
        Container(
          alignment: isSender ? Alignment.topRight : Alignment.topLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Padding(
                padding: isSender
                    ? const EdgeInsets.only(left: 6.0)
                    : const EdgeInsets.only(right: 6.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 100,
                      minWidth: 15),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (MessageInfo item in message)
                        item.isText
                            ? Flexible(
                                child: Text(
                                  item.info,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            : Container(
                                height: 34,
                                width: 34,
                                alignment: isSender
                                    ? Alignment.topRight
                                    : Alignment.topLeft,
                                child: FutureBuilder(
                                  future: fs.ref(item.info).getDownloadURL(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    if (!snapshot.hasData) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Image.network(
                                        snapshot.data!,
                                        width: 30,
                                        height: 30,
                                      ),
                                    );
                                  },
                                ),
                              )
                    ],
                  ),
                ),
              ),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(25),
                topRight: const Radius.circular(25),
                bottomLeft: !isSender ? Radius.zero : const Radius.circular(25),
                bottomRight: isSender ? Radius.zero : const Radius.circular(25),
              ),
              color: isSender ? Colors.blue[400]! : Colors.grey[400]!,
            ),
          ),
        ),
        !isSender ? Expanded(child: Container()) : Container(),
      ],
    );
  }
}

class BottomBar extends StatelessWidget {
  final int screen;
  final String email;
  List<CustomEmoji> emojiList = [];
  BottomBar({
    Key? key,
    required this.screen,
    required this.email,
    required this.emojiList,
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
                  screen == 0
                      ? Container()
                      : Navigator.popUntil(context, (route) => route.isFirst);
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
                  screen == 1
                      ? Container()
                      : Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                EmojiManager(cemojis: emojiList, email: email),
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
                  screen == 2
                      ? Container()
                      : Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              userMail: email,
                              emojiList: emojiList,
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
