import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memoapp/file_plus_tag.dart';
import 'package:memoapp/handling.dart';

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
  String inputValue = '';

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(print);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
        stream: chipEvent.stream,
        builder: (context, snapshot) {
          return FutureBuilder<List<Chip>>(
              future: loadChips(),
              builder: (context, snapshot) {
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
                                for (final chip in snapshot.data) {
                                  if ((chip.label as Text).data == inputValue) {
                                    debugPrint('!! 重複した名前');
                                    return;
                                  }
                                }
                                final writestr =
                                    Tag.readyTagFile.readAsStringSync().isEmpty
                                        ? inputValue
                                        : '\n$inputValue';

                                setState(() {
                                  Tag.readyTagFile.writeAsString(
                                    writestr,
                                    mode: FileMode.append,
                                  );
                                });
                                tagUpdateEvent.add('');
                              })
                        ],
                      ),
                    )
                  ],
                );
              });
        });
  }

  Future<List<Chip>> loadChips() async {
    final result = <Chip>[];
    final taglist = <Tag>[];

    if ((await Tag.readyTagFile.readAsString()).isEmpty) {
      debugPrint('!! readyTag is empty');
      return result;
    }

    final readyTagFile = await Tag.readyTagFile.readAsString();
    readyTagFile.split(RegExp(r'\n')).forEach((str) {
      if (str.isEmpty) {
        return;
      }
      taglist.add(Tag(str));
    });

    for (final tag in taglist) {
      result.add(tag.getTagChip());
    }

    return result;
  }

  void print() {
    debugPrint('${_textEditingController.text}');
  }
}
