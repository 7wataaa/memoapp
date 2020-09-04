import 'dart:io';

import 'package:flutter/material.dart';

import 'fileHandling.dart';

class CreatePage extends StatefulWidget {
  final Directory dir;
  final bool root;

  CreatePage({@required this.dir, this.root = false});

  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  String nameStr = '';
  String type = 'file';

  //btnIcon()
  //-> typeごとの iconを 表示する
  Widget btnIcon() {
    if (type == 'file') {
      return Icon(Icons.insert_drive_file);
    } else {
      return Icon(Icons.folder);
    }
  }

  //typeSwitch()
  //-> 'file'と'folder'を切り替える
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
                    decoration: InputDecoration(
                        labelText: '~${widget.dir.path}', //root以下を消す
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
              if (nameStr == '') {
                // ignore: todo
                //TODO 名前を勝手につけて保存する
                debugPrint('err 名前未入力');
              } else if (type == 'file') {
                //fileを保存する
                try {
                  await File(widget.root
                          ? '${await localPath()}/root/$nameStr'
                          : '${widget.dir.path}/$nameStr')
                      .create();
                } catch (error) {
                  debugPrint("$error");
                }
                Navigator.pop(context);
                debugPrint('file created');
              } else if (type == 'folder') {
                //folderを保存する
                try {
                  await Directory(widget.root
                          ? '${await localPath()}/root/$nameStr'
                          : '${widget.dir.path}/$nameStr')
                      .create();
                } catch (error) {
                  debugPrint('$error');
                }
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
