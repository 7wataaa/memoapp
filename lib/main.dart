import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';

import 'package:screen/screen.dart';

import 'package:memoapp/page/create_page.dart';

import 'package:memoapp/handling.dart';

import 'package:memoapp/widget/file_widget.dart';

import 'package:memoapp/widget/folder_widget.dart';

import 'package:memoapp/file_info.dart';

void main() {
  runApp(MyApp());
  Screen.keepOn(true); //完成したら消す
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '~/',
      routes: <String, WidgetBuilder>{
        '~/': (BuildContext context) => Home(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      title: 'Memo',
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _selectMode = false;
  bool _storageMode = true;

  @override
  void initState() {
    super.initState();
    rootSet();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MEMO'),
          backgroundColor: const Color(0xFF212121),
          leading: IconButton(
            icon: tagOrStorageIcon(),
            onPressed: () {
              setState(() {
                _storageMode = !_storageMode;
              });
            },
          ),
          actions: <Widget>[
            IconButton(
                icon: _editIcon(),
                onPressed: () {
                  fileSystemEvent.sink.add('');
                  setState(() {
                    _selectMode = !_selectMode;
                  });
                })
          ],
        ),
        body: _storageMode
            ? StreamBuilder(
                stream: fileSystemEvent.stream,
                builder: (context, snapshot) {
                  return FutureBuilder(
                    future: _getRootList(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        if (_selectMode) {
                          fsEntityToCheck = {};
                          return Column(
                            children: [
                              Expanded(
                                child: Scrollbar(
                                  child: ListView(
                                    children: snapshot.data as List<Widget>,
                                  ),
                                ),
                              ),
                              Container(
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 13,
                                    left: 10,
                                    right: 10,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        width: 0.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        child: Stack(
                                          overflow: Overflow.visible,
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            IconButton(
                                              iconSize: 35,
                                              icon: const Icon(
                                                Icons.forward,
                                                color: Color(0xFF484848),
                                              ),
                                              onPressed: () {},
                                            ),
                                            const Positioned(
                                              bottom: -8,
                                              child: const Text(
                                                'move',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        child: Stack(
                                          overflow: Overflow.visible,
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            IconButton(
                                              iconSize: 35,
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Color(0xFF484848),
                                              ),
                                              onPressed: () {
                                                _deleteSelectedEntities();
                                              },
                                            ),
                                            const Positioned(
                                              bottom: -8,
                                              child: const Text(
                                                'delete',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          );
                        } else {
                          return Scrollbar(
                            child: ListView(
                              children: snapshot.data as List<Widget>,
                            ),
                          );
                        }
                      } else {
                        return Center(
                          child: Container(
                            child: const CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                  );
                },
              )
            : tagPageBody(),
        floatingActionButton: _selectMode
            ? null
            : FloatingActionButton(
                heroTag: 'PageBtn',
                backgroundColor: const Color(0xFF212121),
                child: const Icon(Icons.add),
                onPressed: () async {
                  if (_selectMode) {
                    //TODO FAB押した時タグを追加する画面
                  } else {
                    final rootdir = Directory('${await localPath()}/root');
                    await Navigator.push<MaterialPageRoute>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreatePage(tDir: rootdir, isRoot: true),
                        )).then((_) {
                      setState(() {});
                    });
                  }
                },
              ),
      ),
    );
  }

  Widget tagPageBody() {
    //TODO タグページの実装

    //TODO Tag.allTags を読み込んで、上に
    return const Center(
      child: Text('aiuoe'),
    );
  }

  Future<List<Tag>> createTagList() async {
    //irankamo
    final tagsFile = FileInfo.tagsFileJsonFile;
    final resultList = <Tag>[];

    if (tagsFile.existsSync()) {
      for (final str in await tagsFile.readAsLines()) {
        resultList.add(Tag(str));
      }
      return resultList;
    }
    return null;
  }

  Widget _editIcon() {
    if (_selectMode) {
      return const Icon(Icons.edit);
    }
    return const Icon(Icons.edit_outlined);
  }

  Widget tagOrStorageIcon() {
    if (_storageMode) {
      return const Icon(
        Icons.folder,
        color: Color(0xFFFFFFFF),
      );
    }
    return const Icon(
      Icons.local_offer_outlined,
      color: Color(0xFFFFFFFF),
    );
  }

  ///[_selectMode]に応じたリストを返す
  ///
  ///true なら[checkboxTiles()]
  ///false なら[normalTiles()]
  Future<List<Widget>> _getRootList() async {
    final path = await localPath();
    final readytag = File('$path/readyTag.csv');

    FileInfo.tagsFileJsonFile ??= File('$path/tagsFile.json');
    FileInfo.readyTagCsvFile ??= readytag;

    if (!readytag.existsSync()) {
      FileInfo.readyTagCsvFile = readytag;
      readytag.create();
    }

    if (!FileInfo.tagsFileJsonFile.existsSync()) {
      FileInfo.tagsFileJsonFile.create();
      debugPrint('tagFile created');
    }

    return _selectMode ? _checkboxTiles(path) : _normalTiles(path);
  }

  List<Widget> _normalTiles(String path) {
    final mainFolderList = <FolderWidget>[];
    final mainFileList = <FileWidget>[];
    Directory('$path/root').listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        final fileinfo = FileInfo(entity);
        mainFileList
          ..add(
            fileinfo.getWidget(),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        mainFolderList
          ..add(
            FolderWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              dir: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    });

    final result = <Widget>[...mainFolderList, ...mainFileList];
    return result;
  }

  List<Widget> _checkboxTiles(String path) {
    final mainFolderCheckList = <FolderCheckboxWidget>[];
    final mainFileCheckList = <FileCheckboxWidget>[];

    Directory('$path/root').listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        mainFileCheckList
          ..add(
            FileCheckboxWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              file: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        mainFolderCheckList
          ..add(
            FolderCheckboxWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              dir: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    });

    final result = <Widget>[...mainFolderCheckList, ...mainFileCheckList];
    return result;
  }

  void _deleteSelectedEntities() {
    if (fsEntityToCheck.isEmpty ||
        fsEntityToCheck.values.every((bool b) => b == false)) {
      debugPrint('何も選択されてません');
    } else {
      showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          final deleteList = <dynamic>[];
          final deleteListToString = <String>[];

          for (final key in fsEntityToCheck.keys) {
            if (fsEntityToCheck[key]) {
              deleteList.add(key);
              deleteListToString
                  .add('${RegExp(r'([^/]+?)?$').stringMatch(key.path)}');
            }
          }

          return AlertDialog(
            title: const Text('delete'),
            content: Text('$deleteListToString を削除します'),
            actions: [
              FlatButton(
                child: const Text('キャンセル'),
                onPressed: () => Navigator.pop(context),
              ),
              FlatButton(
                child: const Text('すべて削除'),
                onPressed: () {
                  for (final entity in deleteList) {
                    if (entity is File) {
                      entity.delete();
                    } else if (entity is Directory) {
                      entity.delete(recursive: true);
                    }
                  }
                  fileSystemEvent.add('');
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ).then((_) {
        setState(
          () {
            _selectMode = false;
          },
        );
      });
    }
  }
}
/*
ファイルとディレクトリの名前が同じだとエラー
ファイルに入力→save→開く→save→開く→消えてる

勝手に名前付ける機能だけどそれをそのままファイルネームにするより、idか何かで管理したほうが使いやすい
*/
