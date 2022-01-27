import 'package:flutter/material.dart';

typedef StringVoidFunc = void Function(String);

class ChannelDrawer extends StatefulWidget {
  StringVoidFunc updateChatScreen;
  ChannelDrawer({Key? key, required this.updateChatScreen}) : super(key: key);

  @override
  _ChannelDrawerState createState() => _ChannelDrawerState();
}

class _ChannelDrawerState extends State<ChannelDrawer> {
  final padding = const EdgeInsets.symmetric(horizontal: 20);
  @override
  void initState() {
    scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  late ScrollController scrollController;
  @override
  Widget build(BuildContext context) {
    String account = 'Your account';
    return Drawer(
      child: Material(
        color: Colors.blue.shade800,
        child: Column(
          children: [
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'List of chats',
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
              heightFactor: 1.75,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withAlpha(200)),
              ),
              height: 500,
              child: ListView.separated(
                controller: scrollController,
                itemCount: 10,
                itemBuilder: (context, index) {
                  String text = 'Channel ${index + 1}';
                  return Column(
                    children: [
                      buildMenuItem(
                        text: text,
                        onClicked: () {
                          widget.updateChatScreen(text);
                          selectedItem(context, text);
                        },
                      ),
                    ],
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider(color: Colors.white70);
                },
                //padding: padding,
                // children: [
                //   const SizedBox(height: 48),
                //   const Center(
                //     child: Text(
                //       'List of chats',
                //       style: TextStyle(color: Colors.white, fontSize: 30),
                //     ),
                //   ),
                //   const Divider(color: Colors.black),
                //   buildMenuItem(
                //     text: 'Channel 1',
                //     onClicked: () => selectedItem(context, 0),
                //   ),
                //   const Divider(color: Colors.white70),
                //   buildMenuItem(
                //     text: 'Channel 2',
                //     onClicked: () => selectedItem(context, 1),
                //   ),
                //   const Divider(color: Colors.white70),
                //   buildMenuItem(
                //     text: 'Channel 3',
                //     onClicked: () => selectedItem(context, 2),
                //   ),
                //   const Divider(color: Colors.white70),
                //   buildMenuItem(
                //     text: 'Channel 4',
                //     onClicked: () => selectedItem(context, 3),
                //   ),
                //   const Divider(color: Colors.white70),
                // ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget buildHeader({
  //   required String title,
  // }) {
  //   Container(
  //     child: Text(title),
  //   );
  // }

  Widget buildMenuItem({
    required String text,
    //required IconData icon,
    VoidCallback? onClicked,
  }) {
    final color = Colors.white;
    final hoverColor = Colors.white70;
    final size = 20.0;
    return ListTile(
      //leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color, fontSize: size)),
      hoverColor: hoverColor,
      onTap: onClicked,
    );
  }

  void selectedItem(BuildContext context, String chat) {
    String newChat = chat;
    Navigator.pop(context, newChat);
  }
}
