import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memoapp/fileHandling.dart';

class CreatePage extends StatefulWidget {
  final Directory tDir;
  final bool isRoot;

  CreatePage({@required this.tDir, this.isRoot});

  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  //初期値を入れる
  TextEditingController textEditingController;
  String nameStr = '';
  String type = 'file';
  String path;

  ///btnIcon()
  ///-> typeごとの iconを 表示する
  Widget btnIcon() {
    if (type == 'file') {
      return Icon(Icons.insert_drive_file);
    } else {
      return Icon(Icons.folder);
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
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: '~${widget.tDir.path}', //root以下を消す
                        hintText: '$type の名前を入力してください'),
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
              heroTag: 'switchBtn',
              backgroundColor: const Color(0xFF212121),
              child: btnIcon(),
              onPressed: () => typeSwitch(),
            ),
          ),
          FloatingActionButton.extended(
            heroTag: 'saveBtn',
            backgroundColor: const Color(0xFF212121),
            icon: Icon(Icons.check),
            label: Text('$type を保存'),
            onPressed: () async {
              if (widget.isRoot) {
                path = "${await localPath()}/root";
              } else {
                path = Directory.current.path;
              }
              if (nameStr == '') {
                // ignore: todo
                //TODO 名前を勝手につけて保存する
                debugPrint('err 名前未入力');
              } else if (type == 'file') {
                if (!File('$path/$nameStr').existsSync()) {
                  try {
                    await File('$path/$nameStr').create().then((file) {
                      file.exists().then((value) =>
                          value ? debugPrint('true') : debugPrint('false'));
                    });
                  } catch (error) {
                    debugPrint("$error");
                  }
                  Navigator.pop(context);
                } else {
                  //上書きかどうかなどを選択させる
                  debugPrint('そのファイルはすでに存在しています');
                }
              } else if (type == 'folder') {
                if (!Directory('$path/$nameStr').existsSync()) {
                  try {
                    await Directory('$path/$nameStr')
                        .create()
                        .then((value) => debugPrint('directory created'));
                  } catch (error) {
                    debugPrint('$error');
                  }
                  Navigator.pop(context);
                } else {
                  //上書きかどうかなどを選択させる
                  debugPrint('そのディレクトリはすでに存在しています');
                }
              } else {
                debugPrint('ファイルまたはディレクトリではない');
              }
            },
          ),
        ],
      ),
    );
  }
}
