import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class CustomEmoji {
  String path;
  String code;
  bool fav;
  CustomEmoji(this.path, this.code) : fav = false;
}

class EmojiManager extends StatelessWidget {
  final Map<int, String> emojimap;
  const EmojiManager({Key? key, required this.emojimap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text('Emoji Page'),
        backgroundColor: Colors.grey[700],
      ),
      body: EmojiList(eMap: emojimap),
    );
  }
}

class EmojiList extends StatefulWidget {
  final Map<int, String> eMap;
  const EmojiList({Key? key, required this.eMap}) : super(key: key);

  @override
  State<EmojiList> createState() => _EmojiListState();
}

class _EmojiListState extends State<EmojiList> {
  final List<CustomEmoji> _cemojis = [];
  @override
  void initState() {
    for (int i = 0; i < widget.eMap.length; ++i) {
      String name = widget.eMap[i]!.split(".").first;
      _cemojis.add(CustomEmoji(widget.eMap[i]!, name));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseStorage.instance;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
              itemCount: _cemojis.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    const Divider(color: Colors.black),
                    ListTile(
                      leading: FutureBuilder(
                        future: fs
                            .ref(_cemojis.elementAt(index).path)
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
                      title: Text(_cemojis.elementAt(index).code),
                      trailing: SizedBox(
                        width: 150,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _cemojis.elementAt(index).fav =
                                        !_cemojis.elementAt(index).fav;
                                  });
                                },
                                icon: Icon(Icons.star,
                                    color: _cemojis.elementAt(index).fav
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
      ],
    );
  }
}
