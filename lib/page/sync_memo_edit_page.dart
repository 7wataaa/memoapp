import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SyncMemoEditPage extends StatefulWidget {
  const SyncMemoEditPage(this.documentSnapshot, this.initContent);

  final QueryDocumentSnapshot documentSnapshot;

  final String initContent;

  @override
  _SyncMemoEditPageState createState() => _SyncMemoEditPageState();
}

class _SyncMemoEditPageState extends State<SyncMemoEditPage> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initContent}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentSnapshot.id),
        backgroundColor: const Color(0xFF212121),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 15, right: 10, top: 0, bottom: 0),
        child: TextField(
          controller: _controller,
          style: const TextStyle(fontSize: 24),
          maxLines: 99,
          onChanged: (String string) {
            debugPrint(_controller.text);
          },
          onSubmitted: (s) => debugPrint('onSubmitted s = $s'),
          onEditingComplete: () =>
              debugPrint('onEditingComplete text = ${_controller.text}'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'PageBtn',
        icon: const Icon(Icons.check),
        label: const Text('save'),
        backgroundColor: const Color(0xFF212121),
        onPressed: () async {
          await widget.documentSnapshot.reference.set(
              <String, dynamic>{'content': _controller.text},
              SetOptions(merge: true));

          Navigator.pop(context);
        },
      ),
    );
  }
}
