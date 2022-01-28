import 'dart:io';
import 'package:critical_app/Classes/firebasefile.dart';
import 'package:critical_app/app.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomEmoji {
  String path;
  String code;
  bool fav;
  CustomEmoji(this.path, this.code, {this.fav = false});
}

class EmojiManager extends StatelessWidget {
  List<CustomEmoji> cemojis = [];
  EmojiManager({Key? key, required this.cemojis}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text('Emoji Page'),
        backgroundColor: Colors.grey[700],
      ),
      body: EmojiList(emojiList: cemojis),
    );
  }
}

class EmojiList extends StatefulWidget {
  List<CustomEmoji> emojiList;
  EmojiList({Key? key, required this.emojiList}) : super(key: key);

  @override
  State<EmojiList> createState() => _EmojiListState();
}

class _EmojiListState extends State<EmojiList> {
  XFile? imageFile;
  late Future<List<FirebaseFile>> futureFiles;
  @override
  void initState() {
    futureFiles = FirebaseApi.listAll('Emojis/');
    super.initState();
  }

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
    await FirebaseStorage.instance.ref('Emojis/$name').putFile(file);
    setState(() {
      imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseStorage.instance;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 300),
          child: IconButton(
            onPressed: () {
              // String name = imageFile!.path.split('/').last;
              // uploadFileAbs(imageFile!.path, name).then((value) {
              //   _cemojis.add(CustomEmoji(name, name));
              // });
              _showChoiceDialog(context);
            },
            iconSize: 40,
            icon: const Icon(
              Icons.add,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            //mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  "Emoticonos",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Alias",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 120),
                child: Text(
                  "Manage",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
                itemCount: widget.emojiList.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      const Divider(color: Colors.black),
                      ListTile(
                        leading: FutureBuilder(
                          future: fs
                              .ref(widget.emojiList.elementAt(index).path)
                              .getDownloadURL(),
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
                        title: Padding(
                          padding: const EdgeInsets.only(left: 38),
                          child: Text(widget.emojiList.elementAt(index).code),
                        ),
                        trailing: SizedBox(
                          width: 150,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      widget.emojiList.elementAt(index).fav =
                                          !widget.emojiList
                                              .elementAt(index)
                                              .fav;
                                    });
                                  },
                                  icon: Icon(Icons.star,
                                      color:
                                          widget.emojiList.elementAt(index).fav
                                              ? Colors.yellow
                                              : Colors.grey),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.close,
                                  ),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
          ),
        ),
      ],
    );
  }
}
