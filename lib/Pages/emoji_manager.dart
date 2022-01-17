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
      appBar: AppBar(
        title: const Text('Emoji Page'),
      ),
      body: EmojiList(),
    );
  }
}

class EmojiList extends StatefulWidget {
  const EmojiList({
    Key? key,
  }) : super(key: key);

  @override
  State<EmojiList> createState() => _EmojiListState();
}

class _EmojiListState extends State<EmojiList> {
  late List<CustomEmoji> _cemojis;
  @override
  void initState() {
    _cemojis = [
      CustomEmoji("path1", "primero"),
      CustomEmoji("path2", "segundo"),
      CustomEmoji("path3", "tercero"),
    ];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: _cemojis.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_cemojis[index].code),
          );
        });
  }
}
