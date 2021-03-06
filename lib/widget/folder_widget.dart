import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

import 'package:memoapp/page/directory_page.dart';

import 'package:memoapp/handling.dart';

class FolderWidget extends StatefulWidget {
  const FolderWidget({this.name, this.dir});

  final String name;
  final Directory dir;

  @override
  _FolderState createState() => _FolderState();
}

class _FolderState extends State<FolderWidget> {
  String string = '';

  Widget text = const Text('ファイル内が空ではありません。\n内容も削除したい場合は、「すべて削除」を選択してください');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 0, top: 5, bottom: 0),
      child: ListTile(
        key: GlobalKey(),
        title: Text('${widget.name}', style: const TextStyle(fontSize: 18.5)),
        leading: const Icon(Icons.folder),
        onTap: () {
          openFolder();
        },
        onLongPress: () async {
          await showDialog<SimpleDialog>(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: Text('${widget.name}'),
                children: [
                  SimpleDialogOption(
                    child: const Text('開く'),
                    onPressed: () {
                      Navigator.pop(context);
                      openFolder();
                    },
                  ),
                  SimpleDialogOption(
                    child: const Text('リネーム'),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog<AlertDialog>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('リネーム'),
                              content: TextField(
                                autofocus: true,
                                onChanged: (value) => string = value,
                                decoration: const InputDecoration(
                                    labelText: '新しいフォルダ名'),
                              ),
                              actions: [
                                FlatButton(
                                  child: const Text('キャンセル'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                FlatButton(
                                  child: const Text('決定'),
                                  onPressed: () {
                                    widget.dir
                                        .rename(
                                            '${widget.dir.parent.path}/$string')
                                        .then((_) =>
                                            fileSystemEvent.sink.add(''));
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          });
                    },
                  ),
                  SimpleDialogOption(
                    child: const Text('削除'),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog<AlertDialog>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('削除'),
                            content: const Text('この動作はもとに戻すことができません'),
                            actions: [
                              FlatButton(
                                child: const Text('キャンセル'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              FlatButton(
                                child: const Text('削除'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.dir.delete().then(
                                      (_) => fileSystemEvent.sink.add(''));
                                },
                              ),
                              FlatButton(
                                child: const Text('すべて削除'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  showDialog<AlertDialog>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('すべて削除'),
                                        content: const Text(
                                          'ファイルの内容もすべて削除されます。',
                                        ),
                                        actions: [
                                          FlatButton(
                                            child: const Text('キャンセル'),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          FlatButton(
                                            child: const Text('すべて削除'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              widget.dir
                                                  .delete(recursive: true)
                                                  .then(
                                                (_) {
                                                  fileSystemEvent.sink.add('');
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              )
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  dynamic openFolder() async {
    await Navigator.of(context).push<CupertinoPageRoute>(
      CupertinoPageRoute(
        builder: (context) {
          return FolderListPage(
            name: '${widget.name}',
            dir: widget.dir,
          );
        },
      ),
    );
    Directory.current = widget.dir.parent;
    debugPrint('back current.path => '
        '${RegExp(r'([^/]+?)?$').stringMatch(Directory.current.path)}');
  }
}

class FolderCheckboxWidget extends StatefulWidget {
  const FolderCheckboxWidget({this.name, this.dir});

  final String name;
  final Directory dir;

  @override
  _FolderCheckboxWidgetState createState() => _FolderCheckboxWidgetState();
}

class _FolderCheckboxWidgetState extends State<FolderCheckboxWidget> {
  bool isChecked = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 0, top: 5, bottom: 0),
      child: CheckboxListTile(
        key: GlobalKey(),
        title: Text('${widget.name}', style: const TextStyle(fontSize: 18.5)),
        secondary: const Icon(Icons.folder),
        value: isChecked,
        onChanged: (value) {
          setState(() {
            isChecked = value;
            fsEntityToCheck[widget.dir] = isChecked;
          });
        },
      ),
    );
  }
}
