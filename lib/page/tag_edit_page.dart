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
          child: Consumer(builder: (context, watch, child) {
            final synctagnames = watch(synctagnamesprovider.state);
            final localtagnames = watch(localtagnamesprovider.state);

            ///同期されているtagnamesと保存されているtagnamesでのChip
            final tagChips = <Widget>[
              ...synctagnames.map((s) => Tag(s).createSyncTagChip()),
              ...localtagnames.map((s) => Tag(s).createTagChip()),
            ];

            debugPrint('tagChips = $tagChips');

            return Wrap(
              spacing: 5,
              children: tagChips,
            );
          }),
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
                    decoration: const InputDecoration(labelText: 'タグの名前を入力...'),
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
                    if ([
                      ...context.read(synctagnamesprovider.state),
                      ...context.read(localtagnamesprovider.state),
                    ].contains(inputValue)) {
                      debugPrint('!! 重複した名前');
                      return;
                    }

                    context
                        .read(localtagnamesprovider)
                        .writelocalTagname(inputValue);

                    _textEditingController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _textEditingController.text.length);
                    //TODO kokoでlocaltagnamesproviderを呼ぶ
                  }),
            ],
          ),
        )
      ],
    );
  }
}
