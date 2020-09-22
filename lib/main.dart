import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';

import 'package:memoapp/Page/CreatePage.dart';

import 'package:memoapp/fileHandling.dart';

import 'package:memoapp/Widget/FileWidget.dart';

import 'Widget/FolderWidget.dart';

import 'package:screen/screen.dart';

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
  List<Widget> mainList = [];
  List<Widget> mainCheckList = [];
  List<FolderWidget> mainFolderList = [];
  List<FileWidget> mainFileList = [];
  List<FolderCheckboxWidget> mainFolderCheckList = [];
  List<FileCheckboxWidget> mainFileCheckList = [];
  bool selectMode = false;

  @override
  void initState() {
    super.initState();
    rootSet();
  }

  Future<List> getRootList() async {
    String path = await localPath();
    try {
      mainFileList = [];
      mainFolderList = [];
      mainFileCheckList = [];
      mainFolderCheckList = [];
      Directory('$path/root').listSync().forEach(
        (FileSystemEntity entity) {
          if (!selectMode) {
            //ここでmainCheckListを操作する
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
          } else {
            //debugPrint('createCheckboxList called');

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
          }
        },
      );
      if (selectMode) {
        mainCheckList = [];
        mainFolderCheckList.forEach((widget) => mainCheckList.add(widget));
        mainFileCheckList.forEach((widget) => mainCheckList.add(widget));

        return mainCheckList;
      } else {
        mainList = [];
        mainFolderList.forEach((widget) => mainList.add(widget));
        mainFileList.forEach((widget) => mainList.add(widget));

        return mainList;
      }
    } on FileSystemException {
      //rootディレクトリがなかったときの処理
      await rootSet();
      //FileSystemException がもっと広いエラーだと終わらないかも
      Directory('$path/root').exists().then(
          (bool b) => b ? getRootList() : debugPrint('rootファイルを作ることができない'));
    } catch (error) {
      debugPrint('catch $error');
    }
    return [];
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
            Switch(
                value: selectMode,
                onChanged: (bool value) {
                  fileSystemEvent.sink.add('');
                  setState(() {
                    selectMode = value;
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
                              color: Color(0xFFeeeeee),
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
                                              //checkboxlisttileで判別したものの削除機能
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
}
