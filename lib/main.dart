import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';

import 'package:screen/screen.dart';

import 'package:memoapp/page/create_page.dart';

import 'package:memoapp/handling.dart';

import 'package:memoapp/widget/file_widget.dart';

import 'package:memoapp/widget/folder_widget.dart';

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
  bool selectMode = false;

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
          actions: <Widget>[
            IconButton(
                icon: editIcon(),
                onPressed: () {
                  fileSystemEvent.sink.add('');
                  setState(() {
                    selectMode = selectMode ? false : true;
                  });
                })
          ],
        ),
        body: StreamBuilder(
            stream: fileSystemEvent.stream,
            builder: (context, snapshot) {
              return FutureBuilder(
                  future: getRootList(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      if (selectMode) {
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
                              //color: Color(0xFFeeeeee),
                              child: Container(
                                margin: EdgeInsets.only(
                                  bottom: 13,
                                  left: 10,
                                  right: 10,
                                ),
                                decoration: BoxDecoration(
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
                                              color: const Color(0xFF484848),
                                            ),
                                            onPressed: () {},
                                          ),
                                          Positioned(
                                            bottom: -8,
                                            child: Text(
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
                                              color: const Color(0xFF484848),
                                            ),
                                            onPressed: () {
                                              deleteSelectedEntities();
                                            },
                                          ),
                                          Positioned(
                                            bottom: -8,
                                            child: Text(
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
                      debugPrint('hasData is false');
                      return Center(
                        child: Container(
                          child: Text(
                            'hasData is false',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      );
                    }
                  });
            }),
        floatingActionButton: selectMode
            ? null
            : FloatingActionButton(
                heroTag: 'PageBtn',
                backgroundColor: const Color(0xFF212121),
                child: const Icon(Icons.add),
                onPressed: () async {
                  Directory rootdir = Directory('${await localPath()}/root');
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreatePage(tDir: rootdir, isRoot: true),
                      )).then((_) {
                    setState(() {});
                  });
                },
              ),
      ),
    );
  }

  Widget editIcon() {
    if (selectMode) {
      return const Icon(Icons.edit);
    } else {
      return const Icon(Icons.edit_outlined);
    }
  }

  void deleteSelectedEntities() {
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
                  //koko
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
            selectMode = false;
          },
        );
      });
    }
  }

  ///[selectMode]に応じたリストを返す
  ///
  ///true なら[checkboxTiles()]
  ///false なら[normalTiles()]
  Future<List> getRootList() async {
    String path = await localPath();
    try {
      return selectMode ? checkboxTiles(path) : normalTiles(path);
    } catch (e) {
      debugPrint('$e');
      return null;
    }
  }

  List<Widget> normalTiles(String path) {
    List<FolderWidget> mainFolderList = [];
    List<FileWidget> mainFileList = [];
    Directory('$path/root').listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        mainFileList.add(
          FileWidget(
            name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
            file: entity,
          ),
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

  List<Widget> checkboxTiles(String path) {
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
}
/*
ファイルとディレクトリの名前が同じだとエラー
ファイルに入力→save→開く→save→開く→消えてる
root/dir1/dir2からroot/dir1に移動して作成するとdir2に作られる
*/
