import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SyncMemoEditPage extends StatefulWidget {
  const SyncMemoEditPage(this.documentSnapshot);

  final QueryDocumentSnapshot documentSnapshot;

  @override
  _SyncMemoEditPageState createState() => _SyncMemoEditPageState();
}

class _SyncMemoEditPageState extends State<SyncMemoEditPage> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: '${widget.documentSnapshot.get('content')}');
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
        ),
      ),
    );
  }
}
