import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:memoapp/page/select_page.dart';

import 'package:memoapp/handling.dart';

import 'package:memoapp/page/edit_page.dart';

import 'package:memoapp/file_info.dart';

class FileWidget extends StatefulWidget {
  final String name;
  final File file;
  final List<Tag> tags;

  FileWidget({@required this.name, @required this.file, this.tags});

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
        subtitle: widget.tags == null
            ? null
            : subtext(), //widget.tags.isEmpty ? null : subtext(),
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
                    onPressed: () => onOpen(),
                  ),
                  SimpleDialogOption(
                    child: const Text('リネーム'),
                    onPressed: () => onRename(),
                  ),
                  SimpleDialogOption(
                    child: const Text('移動'),
                    onPressed: () => onMove(),
                  ),
                  SimpleDialogOption(
                    child: const Text('タグの管理'),
                    onPressed: () => onEditTags(),
                  ),
                  SimpleDialogOption(
                    child: const Text('削除'),
                    onPressed: () => onDelete(),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }

  void onOpen() async {
    Navigator.pop(context);
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TextEditPage(file: widget.file)));
  }

  void onEditTags() {
    //TODO onEditTags()の実装
  }

  void onDelete() {
    //TODO 削除時に、tagsFileでの情報も削除する
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
                widget.file.delete().then((_) => fileSystemEvent.sink.add(''));
              },
            ),
          ],
        );
      },
    );
  }

  void onMove() {
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
  }

  void onRename() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('リネーム'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => newName = value,
            decoration: InputDecoration(labelText: '新しいファイル名'),
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
                    .rename('${widget.file.parent.path}/$newName')
                    .then((_) => fileSystemEvent.sink.add(''));
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Text subtext() {
    String string = '';
    for (var tag in widget.tags) {
      string += ' #${tag.tagName} ';
    }

    if (string.length == 0) {
      return null;
    }
    return Text(string.substring(0, string.length - 1));
  }
}

class FileCheckboxWidget extends StatefulWidget {
  final String name;
  final File file;
  final List<Tag> tags;

  FileCheckboxWidget({this.name, this.file, this.tags});

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
          setState(
            () {
              isChecked = value;
              fsEntityToCheck[widget.file] = isChecked;
            },
          );
        },
      ),
    );
  }
}
