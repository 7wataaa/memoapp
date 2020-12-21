import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoapp/main.dart';
import 'package:memoapp/tag.dart';

final synctagmodeprovider = StateNotifierProvider((ref) => SyncTagModeModel());

class SyncTagModeModel extends StateNotifier<bool> {
  SyncTagModeModel() : super(FirebaseAuth.instance.currentUser != null);

  void switchMode() {
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('!! サインインしていません');
      return;
    }
    state = !state;
  }
}

class TagEditPage extends StatefulWidget {
  @override
  _TagEditPageState createState() => _TagEditPageState();
}

class _TagEditPageState extends State<TagEditPage> {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        title: const Text('TagEditPage'),
      ),
      body: Column(
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
          Row(
            children: [
              Consumer(
                builder: (context, watch, child) {
                  final isSyncTagMode = watch(synctagmodeprovider.state);

                  return IconButton(
                    icon:
                        Icon(isSyncTagMode ? Icons.sync : Icons.sync_disabled),
                    onPressed: () {
                      context.read(synctagmodeprovider).switchMode();
                    },
                  );
                },
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 15,
                  ),
                  child: TextField(
                    autofocus: true,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(labelText: 'タグの名前を入力...'),
                    controller: _textEditingController,
                    //style: const TextStyle(fontSize: 16),
                    onChanged: (value) => inputValue = '#$value',
                  ),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.create),
                  onPressed: () async {
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

                    if (context.read(synctagmodeprovider.state)) {
                      await context
                          .read(synctagnamesprovider)
                          .uploadtagname(inputValue);
                    } else {
                      context
                          .read(localtagnamesprovider)
                          .writelocalTagname(inputValue);
                    }

                    _textEditingController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _textEditingController.text.length);
                  }),
            ],
          )
        ],
      ),
    );
  }
}
