import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:memoapp/Page/SelectPage.dart';

import 'package:memoapp/fileHandling.dart';

import 'package:memoapp/Page/EditPage.dart';

class FileWidget extends StatefulWidget {
  final String name;
  final File file;

  FileWidget({this.name, this.file});

  @override
  _FileState createState() => _FileState();
}

class _FileState extends State<FileWidget> {
  String newName = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, right: 0, top: 5, bottom: 0),
      child: ListTile(
          title: Text('${widget.name}'),
          leading: const Icon(Icons.insert_drive_file),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TextEditPage(file: widget.file)));
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
                        Navigator.pop(context);
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    TextEditPage(file: widget.file)));
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
                                onChanged: (value) => newName = value,
                                decoration:
                                    InputDecoration(labelText: '新しいファイル名'),
                              ),
                              actions: [
                                FlatButton(
                                  child: const Text('キャンセル'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                FlatButton(
                                  child: const Text('決定'),
                                  onPressed: () {
                                    widget.file
                                        .rename(
                                            '${widget.file.parent.path}/$newName')
                                        .then((_) =>
                                            fileSystemEvent.sink.add(''));
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    SimpleDialogOption(
                      child: const Text('移動'),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (BuildContext context) {
                              return Cdpage(file: widget.file);
                            },
                          ),
                        );
                        fileSystemEvent.add('');
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
                                      widget.file.delete().then(
                                          (_) => fileSystemEvent.sink.add(''));
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                    )
                  ],
                );
              },
            );
          }),
    );
  }
}

class FileCheckboxWidget extends StatefulWidget {
  final String name;
  final File file;

  FileCheckboxWidget({this.name, this.file});

  @override
  _FileCheckboxWidgetState createState() => _FileCheckboxWidgetState();
}

class _FileCheckboxWidgetState extends State<FileCheckboxWidget> {
  bool isChecked = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, right: 0, top: 5, bottom: 0),
      child: CheckboxListTile(
        title: Text('${widget.name}'),
        secondary: const Icon(Icons.insert_drive_file),
        value: isChecked,
        onChanged: (value) {
          setState(() {
            isChecked = value;
          });
        },
      ),
    );
  }
}
