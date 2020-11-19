import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memoapp/handling.dart';
import 'package:memoapp/tag.dart';

class TagEditPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        title: const Text('TagEditPage'),
      ),
      body: TagCreatePageBody(),
    );
  }
}

class TagCreatePageBody extends StatefulWidget {
  @override
  _TagCreatePageBodyState createState() => _TagCreatePageBodyState();
}

class _TagCreatePageBodyState extends State<TagCreatePageBody> {
  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();
  String inputValue = '';

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _textEditingController.selection = TextSelection(
            baseOffset: 0, extentOffset: _textEditingController.text.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
        stream: tagChipEvent.stream,
        builder: (context, snapshot) {
          return FutureBuilder<List<Widget>>(
              future: loadChips(),
              builder: (context, snapshot) {
                final existingtags = [
                  ...Tag.readyTagFile.readAsLinesSync(),
                  ...Tag.syncTagFile.readAsLinesSync(),
                ];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(
                        left: 5,
                        right: 5,
                        top: 10,
                        bottom: 0,
                      ),
                      child: snapshot.hasData
                          ? Wrap(
                              spacing: 5,
                              children: snapshot.data,
                            )
                          : const CircularProgressIndicator(),
                    ),
                    Container(
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.only(
                                left: 15,
                                right: 0,
                                top: 5,
                                bottom: 0,
                              ),
                              child: TextField(
                                focusNode: _focusNode,
                                decoration: const InputDecoration(
                                    labelText: 'タグの名前を入力...'),
                                controller: _textEditingController,
                                onChanged: (value) => inputValue = value,
                                autofocus: true,
                              ),
                            ),
                          ),
                          IconButton(
                              icon: const Icon(Icons.create),
                              onPressed: () {
                                if (inputValue.isEmpty) {
                                  debugPrint('!! inputvalue is empty');
                                  return;
                                }

                                if (existingtags.contains(inputValue)) {
                                  debugPrint('!! 重複した名前');
                                  return;
                                }

                                final writestr =
                                    Tag.readyTagFile.readAsStringSync().isEmpty
                                        ? inputValue
                                        : '\n$inputValue';

                                _textEditingController.selection =
                                    TextSelection(
                                        baseOffset: 0,
                                        extentOffset:
                                            _textEditingController.text.length);

                                setState(() {
                                  Tag.readyTagFile.writeAsStringSync(
                                    writestr,
                                    mode: FileMode.append,
                                  );
                                });
                              }),
                        ],
                      ),
                    )
                  ],
                );
              });
        });
  }

  Future<List<Widget>> loadChips() async {
    final result = <Widget>[];

    if (!(await Tag.syncTagFile.readAsString()).isEmpty) {
      for (final str in await Tag.syncTagFile.readAsLines()) {
        result.add(Tag(str).createSyncTagChip());
      }
    }

    if (!(await Tag.readyTagFile.readAsString()).isEmpty) {
      for (final str in await Tag.readyTagFile.readAsLines()) {
        result.add(Tag(str).createTagChip());
      }
    }

    return result;
  }
}
