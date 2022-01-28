import 'package:flutter/material.dart';

typedef StringVoidFunc = void Function(String);

class ChannelDrawer extends StatefulWidget {
  StringVoidFunc updateChatScreen;
  String chat;
  String user;
  ChannelDrawer(
      {Key? key,
      required this.updateChatScreen,
      required this.chat,
      required this.user})
      : super(key: key);

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
    return Drawer(
      child: Material(
        color: Colors.grey.shade800,
        child: Column(
          children: [
            const SizedBox(height: 18),
            Center(
              child: Text(
                'List of chats',
                style: TextStyle(color: Colors.grey[300], fontSize: 30),
              ),
              heightFactor: 1.75,
            ),
            Container(
              height: 500,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ListView.separated(
                padding: EdgeInsets
                    .zero, //This is necessary to remove a ListView's default padding
                controller: scrollController,
                itemCount: 8,
                itemBuilder: (context, index) {
                  String text;

                  switch (index) {
                    case 0:
                      text = "General";
                      break;
                    case 1:
                      text = "General_2";
                      break;
                    case 2:
                      text = "Announcements";
                      break;
                    case 3:
                      text = "Memes";
                      break;
                    case 4:
                      text = "Gaming";
                      break;
                    case 5:
                      text = "DnD";
                      break;
                    case 6:
                      text = "Work";
                      break;
                    case 7:
                      text = "Random";
                      break;
                    default:
                      text = "";
                  }

                  return Column(
                    children: [
                      buildMenuItem(
                        text: text,
                        color: widget.chat == text
                            ? Colors.blue.shade300
                            : Colors.white60,
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
              ),
            ),
            const Spacer(),
            Text(
              "Logged in as:",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 2.0)),
            Text(
              widget.user,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 18,
              ),
            ),
            const Spacer(),
            // Row(
            //   children: [Text("a")],
            // )
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
    Color color = Colors.white,
    //required IconData icon,
    VoidCallback? onClicked,
  }) {
    //final color = Colors.white;
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
