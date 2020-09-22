import 'dart:io';

import 'package:flutter/material.dart';

class TextEditPage extends StatefulWidget {
  final File file;

  TextEditPage({@required this.file});

  @override
  _TextEditPageState createState() => _TextEditPageState();
}

class _TextEditPageState extends State<TextEditPage> {
  TextEditingController textEditingController;
  String str = '';

  @override
  void initState() {
    super.initState();

    textEditingController =
        TextEditingController(text: '${widget.file.readAsStringSync()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File edit'),
        backgroundColor: const Color(0xFF212121),
      ),
      body: Container(
        padding: EdgeInsets.only(left: 15.0, right: 10.0, top: 0, bottom: 0),
        child: TextField(
          autofocus: true,
          controller: textEditingController,
          style: const TextStyle(
            fontSize: 24,
          ),
          maxLines: 80,
          onChanged: (string) => str = string,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'saveBtn',
        icon: const Icon(Icons.check),
        label: const Text('save'),
        backgroundColor: const Color(0xFF212121),
        onPressed: () {
          widget.file.writeAsStringSync(str);
          Navigator.pop(context);
        },
      ),
    );
  }
}
