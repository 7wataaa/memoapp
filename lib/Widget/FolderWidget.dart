import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

import 'package:memoapp/Page/FolderListPage.dart';

import 'package:memoapp/fileHandling.dart';

class FolderWidget extends StatefulWidget {
  final String name;
  final Directory dir;

  FolderWidget({this.name, this.dir});

  @override
  _FolderState createState() => _FolderState();
}

class _FolderState extends State<FolderWidget> {
  String string = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 5, bottom: 0),
      child: ListTile(
        title: Text('${widget.name}', style: TextStyle(fontSize: 18.5)),
        leading: const Icon(Icons.folder),
        onLongPress: () async {
          await showDialog(
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
                        return showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('リネーム'),
                                content: TextField(
                                  autofocus: true,
                                  onChanged: (value) => string = value,
                                  decoration:
                                      InputDecoration(labelText: '新しいフォルダ名'),
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
                        showDialog(
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
                                      widget.dir
                                          .delete()
                                          .then((_) =>
                                              fileSystemEvent.sink.add(''))
                                          .catchError((_) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text('ERROR'),
                                                content: const Text(
                                                    'ファイル内が空ではありません'),
                                                actions: [
                                                  FlatButton(
                                                    child: const Text('OK'),
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                  ),
                                                ],
                                              );
                                            });
                                      });
                                    },
                                  ),
                                  FlatButton(
                                    child: const Text('すべて削除'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showDialog(
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
                                                        .then((_) {
                                                      fileSystemEvent.sink
                                                          .add('');
                                                    });
                                                  },
                                                ),
                                              ],
                                            );
                                          });
                                    },
                                  )
                                ],
                              );
                            });
                      },
                    ),
                  ],
                );
              });
        },
        onTap: () {
          openFolder();
        },
      ),
    );
  }

  openFolder() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          return FolderListPage(
            name: '${widget.name}',
            dir: widget.dir,
          );
        },
      ),
    );
  }
}
