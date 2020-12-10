import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:memoapp/file_plus_tag.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memoapp/handling.dart';
import 'package:memoapp/page/edit_page.dart';
import 'package:memoapp/page/select_page.dart';
import 'package:memoapp/tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoapp/main.dart';

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
    //この時点でのcontextを残しておくのはpopupでScaffoldがなくなってしまうため(要調べる)
    final scontext = context;
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 0, top: 5, bottom: 0),
      child: ListTile(
        key: GlobalKey(),
        title: Text('${widget.name}'),
        leading: const Icon(Icons.insert_drive_file_outlined),
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
                    onPressed: () {
                      final targetFile = widget.file;
                      var originalTags = <String>[];

                      //実際のファイルの削除
                      widget.file.deleteSync();
                      fileSystemEvent.sink.add('');

                      //filepath : [tagname]
                      final pathTags = jsonDecode(
                              FilePlusTag.tagsFileJsonFile.readAsStringSync())
                          as Map<String, dynamic>;
                      //tagsFileJsonFileに登録されているパスを削除する
                      if (pathTags.containsKey(widget.file.path)) {
                        originalTags = (pathTags[widget.file.path] as List)
                            .map<String>((dynamic str) => str as String)
                            .toList();

                        pathTags.remove(widget.file.path);
                        FilePlusTag.tagsFileJsonFile
                            .writeAsStringSync(jsonEncode(pathTags));
                      }

                      Navigator.pop(context);

                      final entityname =
                          RegExp(r'([^/]+?)?$').stringMatch(widget.file.path);

                      Scaffold.of(scontext).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$entityname を削除しました',
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          action: SnackBarAction(
                            label: '取り消す',
                            onPressed: () {
                              targetFile.createSync();
                              pathTags[targetFile.path] = originalTags;
                              FilePlusTag.tagsFileJsonFile
                                  .writeAsStringSync(jsonEncode(pathTags));
                              fileSystemEvent.sink.add('');
                            },
                          ),
                        ),
                      );
                    },
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

  Future<void> onEditTags() async {
    Navigator.pop(context);
    await context.read(synctagnamesprovider).loadsynctagnames();
    //TODO onEditTags()の実装
    final localTags =
        jsonDecode(FilePlusTag.tagsFileJsonFile.readAsStringSync())
            as Map<String, dynamic>;

    List<String> ownLocalTags;

    if (localTags['${widget.file.path}'] == null ||
        localTags['${widget.file.path}'] == '') {
      ownLocalTags = [];
    } else {
      ownLocalTags =
          localTags['${widget.file.path}'].cast<String>() as List<String> ?? [];
    }

    var ownSynctagnameChips = <Widget>[];
    if (FirebaseAuth.instance.currentUser != null) {
      final filedoc = await FirebaseFirestore.instance
          .collection('files')
          .doc(FirebaseAuth.instance.currentUser.uid)
          .collection('userFiles')
          .doc(RegExp(r'([^/]+?)?$').stringMatch(widget.file.path))
          .get();

      final tmpsynctagnames = filedoc.exists
          ? filedoc.data()['tag'].cast<String>() as List<String>
          : <String>[];

      ownSynctagnameChips =
          tmpsynctagnames.map((e) => synctagchip(context, e)).toList();
    }

    await showDialog<AlertDialog>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('タグの編集'),
            content: SingleChildScrollView(
              child: Consumer(builder: (context, watch, child) {
                //TODO synctag と tag のかみ合わせを考えてから実装する
                final synctagnames = watch(synctagnamesprovider.state);

                final localtagnames = watch(localtagnamesprovider.state);

                //ついてるタグの一覧↓から、そのファイルに付いてるのを出す
                final pathtags =
                    (jsonDecode(FilePlusTag.tagsFileJsonFile.readAsStringSync())
                            as Map<String, dynamic>)
                        .cast<String, List<String>>();

                final ownLocaltagnamesChips =
                    ownLocalTags.map((e) => localtagchip(context, e)) ?? [];

                return Wrap(
                  spacing: 5,
                  children: [
                    ...ownSynctagnameChips,
                    ...ownLocaltagnamesChips,
                    ActionChip(
                      label: const Icon(Icons.add),
                      onPressed: () {
                        //TODO つけるタグを追加する
                      },
                    ),
                  ],
                );
              }),
            ),
            actions: [
              FlatButton(
                child: const Text('キャンセル'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
              FlatButton(
                child: const Text('完了'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ],
          );
        });
  }

  Widget synctagchip(BuildContext context, String tagname) {
    return ActionChip(
      avatar: const CircleAvatar(
        child: Icon(
          Icons.sync,
          size: 20,
        ),
      ),
      label: Text(
        '$tagname',
        style: const TextStyle(fontSize: 18),
      ),
      onPressed: () {
        showDialog<AlertDialog>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('$tagname'),
                content: const Text('このタグを外しますか'),
                actions: [
                  FlatButton(
                    child: const Text('キャンセル'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FlatButton(
                    child: const Text('このタグを外す'),
                    onPressed: () {
                      //TODO tagを外す処理
                    },
                  ),
                ],
              );
            });
      },
    );
  }

  Widget localtagchip(BuildContext context, String tagname) {
    return ActionChip(
      label: Text(
        '$tagname',
        style: const TextStyle(fontSize: 18),
      ),
      onPressed: () {
        showDialog<AlertDialog>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('$tagname'),
                content: const Text('このタグを外しますか'),
                actions: [
                  FlatButton(
                    child: const Text('キャンセル'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FlatButton(
                    child: const Text('外す'),
                    onPressed: () {
                      //TODO 外す処理
                    },
                  ),
                ],
              );
            });
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
    if (widget.tags.isEmpty) {
      return null;
    }
    final string = StringBuffer();

    for (final tag in widget.tags) {
      final name = ' #${tag.tagName} ';
      string.write(name);
    }

    return Text(string.toString());
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
        key: GlobalKey(),
        title: Text('${widget.name}'),
        secondary: const Icon(Icons.insert_drive_file),
        value: isChecked,
        //TODO subtitileを追加する
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
