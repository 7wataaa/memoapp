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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate
      ],
      supportedLocales: [
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
                _storageMode = _storageMode ? false : true;
              });
            },
          ),
          actions: <Widget>[
            IconButton(
                icon: _editIcon(),
                onPressed: () {
                  fileSystemEvent.sink.add('');
                  setState(() {
                    _selectMode = _selectMode ? false : true;
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
                                    children: snapshot.data,
                                  ),
                                ),
                              ),
                              Container(
                                child: Container(
                                  margin: EdgeInsets.only(
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
                                            Positioned(
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
                                            Positioned(
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
                              children: snapshot.data,
                            ),
                          );
                        }
                      } else {
                        return Center(
                          child: Container(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                  );
                },
              )
            : null, //TODO tag画面の実装
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
                    Directory rootdir = Directory('${await localPath()}/root');
                    await Navigator.push(
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

  Future<List<Tag>> createTagList() async {
    //irankamo
    File tagsFile = FileInfo.tagsFile;
    List<Tag> resultList = [];

    if (tagsFile.existsSync()) {
      for (var str in await tagsFile.readAsLines()) {
        resultList.add(Tag(str));
        debugPrint('$str');
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
  Future<List> _getRootList() async {
    String path = await localPath();

    if (FileInfo.tagsFile != File('$path/tagsFile.json')) {
      FileInfo.tagsFile = File('$path/tagsFile.json');
    }

    if (!await FileInfo.tagsFile.exists()) {
      FileInfo.tagsFile.create();
      debugPrint('tagFile created');
    }

    return _selectMode ? _checkboxTiles(path) : _normalTiles(path);
  }

  List<Widget> _normalTiles(String path) {
    List<FolderWidget> mainFolderList = [];
    List<FileWidget> mainFileList = [];
    Directory('$path/root').listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        FileInfo fileEx = FileInfo(entity);
        mainFileList.add(
          fileEx.getWidget(),
        );
        mainFileList.sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        mainFolderList.add(
          FolderWidget(
            name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
            dir: entity,
          ),
        );
        mainFolderList.sort((a, b) => a.name.compareTo(b.name));
      }
    });

    List<Widget> result = [...mainFolderList, ...mainFileList];
    return result;
  }

  List<Widget> _checkboxTiles(String path) {
    List<FolderCheckboxWidget> mainFolderCheckList = [];
    List<FileCheckboxWidget> mainFileCheckList = [];

    Directory('$path/root').listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        mainFileCheckList.add(
          FileCheckboxWidget(
            name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
            file: entity,
          ),
        );
        mainFileCheckList.sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        mainFolderCheckList.add(
          FolderCheckboxWidget(
            name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
            dir: entity,
          ),
        );
        mainFolderCheckList.sort((a, b) => a.name.compareTo(b.name));
      }
    });

    List<Widget> result = [...mainFolderCheckList, ...mainFileCheckList];
    return result;
  }

  void _deleteSelectedEntities() {
    if (fsEntityToCheck.isEmpty ||
        fsEntityToCheck.values.every((bool b) => b == false)) {
      debugPrint('何も選択されてません');
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          List<dynamic> deleteList = [];
          List<String> deleteListToString = [];

          for (var key in fsEntityToCheck.keys) {
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
                  for (var entity in deleteList) {
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
