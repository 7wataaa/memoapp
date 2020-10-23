import 'dart:io';

import 'package:flutter/material.dart';

class TextEditPage extends StatefulWidget {
  const TextEditPage({@required this.file});

  final File file;

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
    str = textEditingController.text;
    return Scaffold(
      appBar: AppBar(
        title: const Text('File edit'),
        backgroundColor: const Color(0xFF212121),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 15, right: 10, top: 0, bottom: 0),
        child: TextField(
          controller: textEditingController,
          style: const TextStyle(
            fontSize: 24,
          ),
          maxLines: 80,
          onChanged: (string) => str = string,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'PageBtn',
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
