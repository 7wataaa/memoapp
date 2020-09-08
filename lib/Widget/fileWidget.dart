import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

class FileWidget extends StatefulWidget {
  final String name;
  final File file;

  FileWidget({this.name, this.file});

  @override
  _FileState createState() => _FileState();
}

class _FileState extends State<FileWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 5, bottom: 0),
      child: ListTile(
          title: Text('${widget.name}'),
          leading: const Icon(Icons.insert_drive_file),
          onTap: () {
            // 保存する処理
            Navigator.of(context).pushNamed('~/Show');
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return SimpleDialog(
                  title: Text('${widget.name}'),
                  children: <Widget>[
                    SimpleDialogOption(
                      child: Text('開く'),
                      onPressed: () async {
                        debugPrint('編集が選択されました');
                        await Navigator.of(context).pushNamed('~/Show');
                        Navigator.pop(context);
                      },
                    ),
                    SimpleDialogOption(
                      child: Text('rename (未実装)'),
                    ),
                    SimpleDialogOption(
                      child: Text('削除 (未実装)'),
                    )
                  ],
                );
              },
            );
          }),
    );
  }
}
