import 'dart:io';

import 'package:flutter/material.dart';

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
  String nameStr = '';
  String type = 'file';
  String path;

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
      labelText: '${RegExp(r'([^/]+?)?$').stringMatch(widget.tDir.path)}/',
      hintText: '$type の名前を入力してください',
    );
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
                  padding: EdgeInsets.only(
                      left: 10.0, right: 10.0, top: 5, bottom: 0),
                  child: TextField(
                    controller: textEditingController,
                    //autofocus: true,
                    decoration: parentDecoration(),
                    onChanged: (str) => nameStr = str,
                  ),
                ),
              ),
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
              //TODO ファイル作成時に、{[パス: [タグ],]}のJSONファイルも作成する

              path = widget.isRoot
                  ? "${await localPath()}/root"
                  : Directory.current.path;

              bool overlapping = File('$path/$nameStr').existsSync() ||
                  Directory('$path/$nameStr').existsSync();

              if (nameStr == '') {
                debugPrint('! 名前未入力 !');
                return;
              } else if (overlapping) {
                debugPrint('! 重複した名前はつけることができません !');
              }

              switch (type) {
                case 'file':
                  try {
                    File('$path/$nameStr').create();
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
