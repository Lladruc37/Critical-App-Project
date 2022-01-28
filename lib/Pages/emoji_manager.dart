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
  final String email;
  EmojiManager({Key? key, required this.email, required this.cemojis})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[700],
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 56),
            Text(
              'Emoji Page',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
      body: EmojiList(emojiList: cemojis, email: email),
    );
  }
}

class EmojiList extends StatefulWidget {
  List<CustomEmoji> emojiList;
  final String email;
  EmojiList({Key? key, required this.email, required this.emojiList})
      : super(key: key);

  @override
  State<EmojiList> createState() => _EmojiListState();
}

class _EmojiListState extends State<EmojiList> {
  XFile? imageFile;
  late TextEditingController controller;
  late Future<List<FirebaseFile>> futureFiles;
  @override
  void initState() {
    controller = TextEditingController();
    futureFiles = FirebaseApi.listAll('Emojis/');
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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

  Future<void> uploadFileAbs(String filePath, String name) async {
    File file = File(filePath);
    await FirebaseStorage.instance.ref('Emojis/$name.png').putFile(file);
    setState(() {
      imageFile = null;
    });
  }

  Future<void> deleteFileAbs(String filePath) async {
    await FirebaseStorage.instance.ref("Emojis/" + filePath).delete();
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
              _openGallery(context);
            },
            iconSize: 40,
            icon: Icon(
              Icons.add_box_outlined,
              color: Colors.grey[400],
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
                  "Delete",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: Colors.grey[900],
          indent: 6,
          endIndent: 6,
          thickness: 2,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
                itemCount: widget.emojiList.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      index == 0
                          ? Container()
                          : const Divider(
                              color: Colors.black,
                              indent: 6,
                              endIndent: 6,
                            ),
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
                            child: Padding(
                              padding: const EdgeInsets.only(left: 48),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    deleteFileAbs(
                                        widget.emojiList.elementAt(index).path);
                                    widget.emojiList.removeAt(index);
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                ),
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Focus(
                onFocusChange: (value) {
                  if (value) {}
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: controller,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  if (imageFile != null) {
                    uploadFileAbs(imageFile!.path, text);
                  }
                  controller.clear();
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
        BottomBar(screen: 1, email: widget.email, emojiList: widget.emojiList),
      ],
    );
  }
}
