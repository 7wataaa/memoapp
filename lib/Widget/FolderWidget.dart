import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

import 'package:memoapp/Page/FolderListPage.dart';

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
                      child: const Text('リネーム'),
                      onPressed: () async {
                        Navigator.pop(context);
                        //koko
                        return showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('リネーム'),
                                content: TextField(
                                  autofocus: true,
                                  onChanged: (value) => string = value,
                                  decoration: InputDecoration(
                                      labelText: '新しいフォルダの名前を入力してください'),
                                ),
                                actions: [
                                  FlatButton(
                                    child: Text('戻る'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  FlatButton(
                                    child: Text('変更'),
                                    onPressed: () {
                                      widget.dir.rename(
                                          '${widget.dir.parent.path}/$string');
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                    ),
                  ],
                );
              });
        },
        onTap: () async {
          await Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) {
                return FolderListPage(
                  name: '${widget.name}',
                  dir: widget.dir,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
