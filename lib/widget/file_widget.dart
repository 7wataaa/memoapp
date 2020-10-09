import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:memoapp/page/select_page.dart';

import 'package:memoapp/handling.dart';

import 'package:memoapp/page/edit_page.dart';

import 'package:memoapp/file_info.dart';

class FileWidget extends StatefulWidget {
  const FileWidget({@required this.name, @required this.file, this.tags});

  final String name;
  final File file;
  final List<Tag> tags;

  @override
  _FileState createState() => _FileState();
}

class _FileState extends State<FileWidget> {
  String newName = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 0, top: 5, bottom: 0),
      child: ListTile(
        title: Text('${widget.name}'),
        leading: const Icon(Icons.insert_drive_file),
        subtitle: widget.tags == null
            ? null
            : subtext(), //widget.tags.isEmpty ? null : subtext(),
        onTap: () {
          Navigator.push<MaterialPageRoute>(
              context,
              MaterialPageRoute(
                  builder: (context) => TextEditPage(file: widget.file)));
        },
        onLongPress: () {
          showDialog<SimpleDialog>(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: Text('${widget.name}'),
                children: <Widget>[
                  SimpleDialogOption(
                    child: const Text('開く'),
                    onPressed: onOpen,
                  ),
                  SimpleDialogOption(
                    child: const Text('リネーム'),
                    onPressed: onRename,
                  ),
                  SimpleDialogOption(
                    child: const Text('移動'),
                    onPressed: onMove,
                  ),
                  SimpleDialogOption(
                    child: const Text('タグの管理'),
                    onPressed: onEditTags,
                  ),
                  SimpleDialogOption(
                    child: const Text('削除'),
                    onPressed: onDelete,
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }

  void onOpen() {
    Navigator.pop(context);
    Navigator.push<MaterialPageRoute>(
        context,
        MaterialPageRoute(
            builder: (context) => TextEditPage(file: widget.file)));
  }

  void onEditTags() {
    // ignore: flutter_style_todos
    //TODO onEditTags()の実装
  }

  void onDelete() {
    // ignore: flutter_style_todos
    //TODO 削除時に、tagsFileでの情報も削除する
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
    Navigator.push<CupertinoPageRoute>(
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
    showDialog<AlertDialog>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('リネーム'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => newName = value,
            decoration: const InputDecoration(labelText: '新しいファイル名'),
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
    StringBuffer string;
    for (final tag in widget.tags) {
      final name = ' #${tag.tagName} ';
      string.write(name);
    }

    if (string.length == 0) {
      return null;
    }
    return Text(string.toString().substring(0, string.length - 1));
  }
}

class FileCheckboxWidget extends StatefulWidget {
  const FileCheckboxWidget({this.name, this.file, this.tags});

  final String name;
  final File file;
  final List<Tag> tags;

  @override
  _FileCheckboxWidgetState createState() => _FileCheckboxWidgetState();
}

class _FileCheckboxWidgetState extends State<FileCheckboxWidget> {
  bool isChecked = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 0, top: 5, bottom: 0),
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
