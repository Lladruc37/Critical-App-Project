import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:critical_app/Classes/user.dart';
import 'package:critical_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ProfileScreen extends StatefulWidget {
  final String userMail;
  final Map<int, String> emojiMap;

  const ProfileScreen({
    Key? key,
    required this.userMail,
    required this.emojiMap,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Color pickerColor = const Color.fromARGB(255, 10, 10, 10);

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  Future<void> _showColorDialog(
      BuildContext context, Map<String, dynamic> doc) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: changeColor,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Got it'),
              onPressed: () {
                setState(() {
                  updateProfile(doc["Name"], widget.userMail, pickerColor.alpha,
                      pickerColor.red, pickerColor.green, pickerColor.blue);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    Color newColor = const Color.fromARGB(255, 10, 100, 10);
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[700],
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 56),
            Text(
              "Profile",
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: db.doc("/users/${widget.userMail}").snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                      snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final doc = snapshot.data!.data();
                if (doc != null) {
                  newColor = Color.fromARGB(doc["ColorA"], doc["ColorR"],
                      doc["ColorG"], doc["ColorB"]);
                  return Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            doc["Name"],
                            style: TextStyle(
                              fontSize: 24,
                              color: newColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            widget.userMail,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(34.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Username Color: ",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[400]),
                                ),
                              ),
                              ElevatedButton(
                                style:
                                    ElevatedButton.styleFrom(primary: newColor),
                                onPressed: () {
                                  _showColorDialog(context, doc);
                                },
                                child: SizedBox(
                                  width: 100,
                                  height: 60,
                                  child: Center(
                                    child: Text(
                                      "Change Color",
                                      style: TextStyle(
                                          color:
                                              newColor.computeLuminance() > 0.5
                                                  ? Colors.black
                                                  : Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(child: Text("doc is null!"));
                }
              },
            ),
          ),
          BottomBar(
            screen: 2,
            email: widget.userMail,
            emojiMap: widget.emojiMap,
          ),
        ],
      ),
    );
  }
}
