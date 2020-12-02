import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoapp/main.dart';
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

    WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => context.read(synctagnamesprovider).loadsynctagnames());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, watch, child) {
      final _synctags = watch(synctagnamesprovider.state);

      ///同期されているtagnamesと保存されているtagnamesでのChip
      final _tags = <Widget>[
        ..._synctags.map((s) => Tag(s).createSyncTagChip()),
        if (!(Tag.localTagFile.readAsStringSync()).isEmpty)
          ...Tag.localTagFile
              .readAsLinesSync()
              .map((s) => Tag(s).createTagChip())
      ];

      debugPrint('$_tags');
      debugPrint('$_synctags');

      final existingtags = <String>[
        ..._synctags,
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
            child: Wrap(
              spacing: 5,
              children: _tags,
            ),
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
                      decoration:
                          const InputDecoration(labelText: 'タグの名前を入力...'),
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
                          Tag.localTagFile.readAsStringSync().isEmpty
                              ? inputValue
                              : '\n$inputValue';

                      _textEditingController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _textEditingController.text.length);

                      setState(() {
                        Tag.localTagFile.writeAsStringSync(
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
  }
}
