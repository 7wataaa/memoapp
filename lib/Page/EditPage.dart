import 'package:flutter/material.dart';

class TextEditPage extends StatefulWidget {
  @override
  _TextEditPageState createState() => _TextEditPageState();
}

class _TextEditPageState extends State<TextEditPage> {
  String str = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File edit'),
        backgroundColor: const Color(0xFF212121),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(left: 15.0, right: 10.0, top: 5, bottom: 0),
          child: TextField(
            style: const TextStyle(
              fontSize: 24,
            ),
            maxLines: 80,
            onChanged: (string) => str = string,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'saveBtn',
        icon: const Icon(Icons.check),
        label: const Text('save'),
        backgroundColor: const Color(0xFF212121),
        onPressed: () {
          // ignore: todo
          //TODO ファイルに保存する
          debugPrint('$str');
          Navigator.pop(context);
        },
      ),
    );
  }
}
