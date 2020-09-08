import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

import 'package:memoapp/FolderListPage.dart';

class FolderWidget extends StatefulWidget {
  final String name;
  final Directory dir;

  FolderWidget({this.name, this.dir});

  @override
  _FolderState createState() => _FolderState();
}

class _FolderState extends State<FolderWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 5, bottom: 0),
      child: ListTile(
        title: Text('${widget.name}', style: TextStyle(fontSize: 18.5)),
        leading: const Icon(Icons.folder),
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
        onLongPress: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return SimpleDialog(
                  title: Text('${widget.name}'),
                  children: [
                    SimpleDialogOption(
                      child: Text('開く (未実装)'),
                    ),
                    SimpleDialogOption(
                      child: Text('rename (未実装)'),
                    ),
                    SimpleDialogOption(
                      child: Text('削除 (未実装)'),
                    )
                  ],
                );
              });
        },
      ),
    );
  }
}
