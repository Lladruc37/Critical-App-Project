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
    return ListView.builder(
        itemCount: _cemojis.length,
        itemBuilder: (context, index) {
          return ListTile(
              title: Row(children: [
            Text(_cemojis[index].path),
            Text(_cemojis[index].code),
          ]));
        });
  }
}
