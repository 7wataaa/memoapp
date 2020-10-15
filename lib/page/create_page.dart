import 'dart:io';

import 'package:flutter/material.dart';

import 'package:memoapp/file_info.dart';

import 'package:memoapp/handling.dart';
import 'package:memoapp/page/tag_edit_page.dart';

// TODO このページでメモの内容を入力できるようにする

class CreatePage extends StatefulWidget {
  const CreatePage({@required this.tDir, this.isRoot});

  final Directory tDir;
  final bool isRoot;

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
  StringBuffer labelTagStr = StringBuffer('');

  List<PopupMenuEntry<String>> menuEntry = [
    const PopupMenuItem(
      value: 'PDw8ZGVmYXVsdEl0ZW06IGFkZD4+Pg==',
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
          '${RegExp(r'([^/]+?)?$').stringMatch(widget.tDir.path)}/  ${labelTagStr.toString()}',
      hintText: '$type の名前を入力してください',
    );
  }

  void _onSelected(String value) {
    if (value == 'PDw8ZGVmYXVsdEl0ZW06IGFkZD4+Pg==') {
      pushTagEditPage();
    } else {
      for (final tag in tmpTags) {
        if (value == tag.tagName) {
          return;
        }
      }
      tmpTags.add(
        Tag('$value'),
      );
      labelTagStr.clear();
      setState(() {
        for (final tag in tmpTags) {
          labelTagStr.write('#${tag.tagName} ');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        title: const Text('CreatePage'),
        actions: <IconButton>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              pushTagEditPage();
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              IconButton(
                icon: btnIcon(),
                onPressed: typeSwitch,
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 0,
                    top: 5,
                    bottom: 0,
                  ),
                  child: TextField(
                    controller: textEditingController,
                    autofocus: true,
                    decoration: parentDecoration(),
                    onChanged: (str) => nameStr = str,
                  ),
                ),
              ),
              FutureBuilder<List<PopupMenuEntry<String>>>(
                  future: addmenuentry(),
                  builder: (context, snapshot) {
                    return PopupMenuButton(
                        onSelected: _onSelected,
                        itemBuilder: (BuildContext context) => snapshot.data);
                  }),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF212121),
              child: btnIcon(),
              onPressed: typeSwitch,
            ),
          ),
          FloatingActionButton.extended(
            heroTag: 'PageBtn',
            backgroundColor: const Color(0xFF212121),
            icon: const Icon(Icons.check),
            label: Text('$type を保存'),
            onPressed: () async {
              path = widget.isRoot
                  ? '${await localPath()}/root'
                  : Directory.current.path;

              final overlapping = File('$path/$nameStr').existsSync() ||
                  Directory('$path/$nameStr').existsSync();

              if (nameStr == '') {
                debugPrint('!! 名前が未入力です');
                return;
              } else if (overlapping) {
                debugPrint('!! 重複した名前はつけることができません');
                return;
              }

              switch (type) {
                case 'file':
                  final newFileInfo = FileInfo(File('$path/$nameStr'));

                  newFileInfo.fileCreateAndAddTag(tmpTags);
                  debugPrint('file created');

                  Navigator.pop(context);
                  break;
                case 'folder':
                  Directory('$path/$nameStr').create();
                  debugPrint('folder created');

                  Navigator.pop(context);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Future pushTagEditPage() async {
    await Navigator.push<MaterialPageRoute>(
        context, MaterialPageRoute(builder: (context) => TagEditPage()));
    setState(() {});
  }

  Future<List<PopupMenuEntry<String>>> addmenuentry() async {
    final menuEntry = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'PDw8ZGVmYXVsdEl0ZW06IGFkZD4+Pg==',
        child: Text('タグを追加...'),
      ),
    ];

    final readytag = await FileInfo.readyTagFile.readAsString();

    debugPrint('${readytag.split(RegExp(r'\n'))}');

    for (final tagstr in readytag.split(RegExp(r'\n')).toList()) {
      if (tagstr.isEmpty) {
        debugPrint('tagstr($tagstr) is empty');
        continue;
      }

      debugPrint('tagstr => $tagstr');

      menuEntry.insert(
        0,
        new PopupMenuItem(
          value: '$tagstr',
          child: Text('$tagstr'),
        ),
      );

      debugPrint('$menuEntry');
    }

    /*readytag.split(RegExp(r'\n')).forEach((tagstr) {
      if (tagstr.isEmpty) {
        debugPrint('tagstr($tagstr) is empty');
        return;
      }
      debugPrint('tagstr => $tagstr');

      menuEntry.insert(
        0,
        new PopupMenuItem(
          value: '$tagstr',
          child: Text('$tagstr'),
        ),
      );

      debugPrint('$menuEntry');
    });*/

    return menuEntry;
  }
}
