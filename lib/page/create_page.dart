import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoapp/file_plus_tag.dart';
import 'package:memoapp/main.dart';
import 'package:memoapp/page/tag_edit_page.dart';
import 'package:memoapp/tag.dart';
import 'package:path_provider/path_provider.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({@required this.tDir, this.isRoot});

  final Directory tDir;
  final bool isRoot;

  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final FocusNode _focusNode = FocusNode();

  ///fileまたはfolderのコントローラー
  final _nameEditingController = TextEditingController();

  ///メモのコントローラー
  final _memoController = TextEditingController();

  ///入力する名前
  String _nameStr = '';

  ///file または folder
  String _type = 'file';

  ///パス
  String _path;

  ///追加するタグ
  final _tmpTags = <Tag>[];

  ///追加するタグ(デコレーション用)
  final _labelTagStr = StringBuffer('');

  final menuEntry = <PopupMenuEntry<String>>[
    const PopupMenuItem(
      value: 'PDw8ZGVmYXVsdEl0ZW06IGFkZD4+Pg==',
      //このvalueだと同じ名前のタグを作ったときにバグるかも → 新規タグ名に'#'を追加して回避
      child: Text('タグを追加...'),
    ),
  ];

  ///btnIcon()
  ///-> typeごとの iconを 表示する
  Widget btnIcon() {
    if (_type == 'file') {
      return const Icon(Icons.insert_drive_file);
    } else {
      return const Icon(Icons.folder);
    }
  }

  ///typeSwitch()
  ///-> 'file'と'folder'を切り替える
  void typeSwitch() {
    if (_type == 'file') {
      setState(() {
        _type = 'folder';
      });
    } else {
      setState(() {
        _type = 'file';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _nameEditingController.selection = TextSelection(
            baseOffset: 0, extentOffset: _nameEditingController.text.length);
      }
    });
  }

  ///parentDecoration()
  ///type, directory ごとのデコレーション
  InputDecoration createTargetDecoration() {
    return InputDecoration(
      labelText: ' ${_labelTagStr.isEmpty ? '...' : _labelTagStr}',
      hintText: '$_type の名前を入力してください',
    );
  }

  void _onSelected(String selectedValue) {
    if (selectedValue == 'PDw8ZGVmYXVsdEl0ZW06IGFkZD4+Pg==') {
      pushTagEditPage();
      return;
    }

    if (_tmpTags.map((e) => e.tagName).contains(selectedValue)) {
      _tmpTags.removeWhere((tag) => tag.tagName == selectedValue);
    } else {
      _tmpTags.add(
        Tag('$selectedValue'),
      );
    }

    _labelTagStr.clear();
    setState(() {
      for (final tag in _tmpTags) {
        _labelTagStr.write('${tag.tagName} ');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        title: Text('${RegExp(r'([^/]+?)?$').stringMatch(widget.tDir.path)}/'),
        actions: <IconButton>[
          IconButton(
            tooltip: 'tag edit',
            icon: const Icon(Icons.label_outline),
            onPressed: () {
              pushTagEditPage();
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            //color: Color(Colors.grey.value),
            child: Row(
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
                      focusNode: _focusNode,
                      style: const TextStyle(fontSize: 20),
                      controller: _nameEditingController,
                      decoration: createTargetDecoration(),
                      onChanged: (str) => _nameStr = str,
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, watch, child) {
                    final synctagnames = watch(synctagnamesprovider.state);
                    final menuEntry = <PopupMenuEntry<String>>[
                      const PopupMenuItem(
                        value: 'PDw8ZGVmYXVsdEl0ZW06IGFkZD4+Pg==',
                        child: Text('タグを追加...'),
                      ),
                    ];

                    for (final tagstr in Tag.localTagFile.readAsLinesSync()) {
                      if (tagstr.isEmpty) {
                        continue;
                      }

                      menuEntry.insert(
                        0,
                        PopupMenuItem(
                          value: '$tagstr',
                          child: Text('$tagstr'),
                        ),
                      );
                    }
                    return PopupMenuButton(
                        onSelected: _onSelected,
                        itemBuilder: (BuildContext context) => [
                              ...synctagnames.map((str) => PopupMenuItem(
                                    child: Text('$str'),
                                    value: str,
                                  )),
                              ...menuEntry,
                            ]);
                  },
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 0),
              child: TextField(
                controller: _memoController,
                autofocus: true,
                maxLines: 30,
                style: const TextStyle(
                  fontSize: 20,
                ),
                onChanged: (String value) {
                  var str = _memoController.text
                      .split('\n')
                      .firstWhere((e) => e != '' && e.contains(RegExp(r'[^ ]')),
                          orElse: () => '')
                      .trim();

                  if (str.length > 30) {
                    str = str.substring(0, 30);
                  }
                  debugPrint('$str');

                  if (_nameEditingController.text != str) {
                    _nameEditingController.text = str;
                    _nameStr = str;
                  }
                },
              ),
            ),
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
            label: Text('$_type を保存'),
            onPressed: () async {
              final providerContainer = ProviderContainer();

              await providerContainer
                  .read(synctagnamesprovider)
                  .loadsynctagnames();

              final synctagnames =
                  providerContainer.read(synctagnamesprovider.state);
              final localtagnames =
                  providerContainer.read(localtagnamesprovider.state);

              _path = widget.isRoot
                  ? '${(await getApplicationDocumentsDirectory()).path}/root'
                  : Directory.current.path;

              var fileisSyncFile = false;
              var fileisLocalFile = false;

              for (final tag in _tmpTags) {
                if (synctagnames.contains(tag.tagName)) {
                  fileisSyncFile = true;
                }
                if (localtagnames.contains(tag.tagName)) {
                  fileisLocalFile = true;
                }
              }
              assert(fileisSyncFile || fileisLocalFile);

              //名前が重複しているかどうかファイルとディレクトリも含める
              final overlapping = File('$_path/$_nameStr').existsSync() ||
                  Directory('$_path/$_nameStr').existsSync();

              if (_nameStr == '') {
                debugPrint('!! 名前が未入力です');
                return;
              } else if (overlapping) {
                debugPrint('!! 重複した名前はつけることができません');
                return;
              } else if (fileisSyncFile && fileisLocalFile) {
                debugPrint('!! タグがローカルとサーバーの2種類存在しています');
                return;
              }

              switch (_type) {
                case 'file':
                  if (fileisLocalFile) {
                    FilePlusTag(File('$_path/$_nameStr'))
                      ..createLocalFileAndAddTag(_tmpTags)
                      ..file.writeAsStringSync('${_memoController.text}');
                    debugPrint('file created');
                  } else {
                    await FirebaseFirestore.instance
                        .collection('files')
                        .doc('${FirebaseAuth.instance.currentUser.uid}')
                        .collection('userFiles')
                        .doc('$_nameStr')
                        .set(<String, dynamic>{
                      'name': _nameStr,
                      'content': _memoController.text,
                      'tag': <String>[..._tmpTags.map((e) => e.tagName)],
                    });
                  }

                  Navigator.pop(context);
                  break;
                case 'folder':
                  Directory('$_path/$_nameStr').createSync();
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

    for (final tagstr in Tag.localTagFile.readAsLinesSync()) {
      if (tagstr.isEmpty) {
        continue;
      }

      menuEntry.insert(
        0,
        PopupMenuItem(
          value: '$tagstr',
          child: Text('$tagstr'),
        ),
      );
    }

    return menuEntry;
  }
}
