import 'dart:io';

import 'package:flutter/material.dart';

import 'package:memoapp/file_info.dart';

import 'package:memoapp/handling.dart';

//TODO このページを削除する
class CreatePage extends StatefulWidget {
  final Directory tDir;
  final bool isRoot;

  CreatePage({@required this.tDir, this.isRoot});

  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  TextEditingController textEditingController;

  ///入力する名前
  String nameStr = '';

  ///file または folder
  String type = 'file';

  ///パス
  String path;

  ///新規追加するタグの内容
  String stringTagValue = '';

  ///追加するタグ
  List<Tag> tmpTags = [];

  ///追加するタグ(デコレーション用)
  String labelTagStr = '';

  List<PopupMenuEntry<String>> menuEntry = [
    const PopupMenuItem(
      value: '<<<defaultItem: add>>>',
      child: Text('タグを追加...'),
    ),
  ];

  ///btnIcon()
  ///-> typeごとの iconを 表示する
  Widget btnIcon() {
    if (type == 'file') {
      return const Icon(Icons.insert_drive_file);
    } else {
      return const Icon(Icons.folder);
    }
  }

  ///typeSwitch()
  ///-> 'file'と'folder'を切り替える
  void typeSwitch() {
    if (type == 'file') {
      setState(() {
        type = 'folder';
      });
    } else {
      setState(() {
        type = 'file';
      });
    }
  }

  ///parentDecoration()
  ///type, directory ごとのデコレーション
  InputDecoration parentDecoration() {
    return InputDecoration(
      labelText:
          '${RegExp(r'([^/]+?)?$').stringMatch(widget.tDir.path)}/  $labelTagStr',
      hintText: '$type の名前を入力してください',
    );
  }

  void _onSelected(String value) {
    if (value == '<<<defaultItem: add>>>') {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('タグを追加'),
            content: TextField(
              autofocus: true,
              onChanged: (value) => stringTagValue = value,
              decoration: InputDecoration(labelText: 'タグの名前'),
            ),
            actions: [
              FlatButton(
                child: Text('追加'),
                onPressed: () {
                  if (stringTagValue == '') {
                    return;
                  }
                  menuEntry.add(
                    //TODO (タグの永続化)
                    //TODO (タグの削除)
                    PopupMenuItem(
                      value: stringTagValue,
                      child: Text('$stringTagValue'),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text('キャンセル'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    } else {
      for (Tag tag in tmpTags) {
        if (value == tag.tagName) {
          return;
        }
      }
      tmpTags.add(
        Tag('$value'),
      );

      labelTagStr = '';
      setState(() {
        for (var tag in tmpTags) {
          labelTagStr += '#${tag.tagName} ';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF212121),
        title: Text('CreatePage'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              IconButton(
                icon: btnIcon(),
                onPressed: () => typeSwitch(),
              ),
              Flexible(
                child: Container(
                  padding:
                      EdgeInsets.only(left: 10.0, right: 0, top: 5, bottom: 0),
                  child: TextField(
                    controller: textEditingController,
                    autofocus: true,
                    decoration: parentDecoration(),
                    onChanged: (str) => nameStr = str,
                  ),
                ),
              ),
              PopupMenuButton(
                  onSelected: _onSelected,
                  itemBuilder: (BuildContext context) => menuEntry),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF212121),
              child: btnIcon(),
              onPressed: () => typeSwitch(),
            ),
          ),
          FloatingActionButton.extended(
            heroTag: 'PageBtn',
            backgroundColor: const Color(0xFF212121),
            icon: Icon(Icons.check),
            label: Text('$type を保存'),
            onPressed: () async {
              //TODO ファイル作成時に、tagsmapを操作とsavealltags()

              path = widget.isRoot
                  ? "${await localPath()}/root"
                  : Directory.current.path;

              bool overlapping = File('$path/$nameStr').existsSync() ||
                  Directory('$path/$nameStr').existsSync();

              if (nameStr == '') {
                debugPrint('! 名前が未入力です !');
                return;
              } else if (overlapping) {
                debugPrint('! 重複した名前はつけることができません !');
                return;
              }

              switch (type) {
                case 'file':
                  try {
                    FileInfo newFileInfo = FileInfo(File('$path/$nameStr'));

                    newFileInfo.file.create();
                    debugPrint('file created');
                  } catch (e) {
                    debugPrint('$e');
                  }
                  Navigator.pop(context);
                  break;
                case 'folder':
                  try {
                    Directory('$path/$nameStr').create();
                    debugPrint('folder created');
                  } catch (e) {
                    debugPrint('$e');
                  }
                  Navigator.pop(context);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
