import 'dart:io';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';

import 'package:memoapp/Page/CreatePage.dart';

import 'package:memoapp/fileHandling.dart';

import 'package:memoapp/Widget/FileWidget.dart';

import 'package:screen/screen.dart';

import 'Page/EditPage.dart';

import 'Widget/FolderWidget.dart';

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
        '~/Show': (BuildContext context) => TextEditPage(),
      },
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
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
  bool mode = false;
  List<Widget> mainList = [];
  List<FolderWidget> mainFolderList = [];
  List<FileWidget> mainFileList = [];

  @override
  // ignore: must_call_super
  void initState() {
    rootSet();
  }

  ///modeSwitch()
  ///false trueを切り替える
  void modeSwitch(bool bool) {
    setState(() {
      mode = bool;
    });
  }

  Future rootList() async {
    String path = await localPath();
    try {
      mainFileList = [];
      mainFolderList = [];
      Directory('$path/root').listSync().forEach(
        (FileSystemEntity entity) {
          if (entity is File) {
            mainFileList.add(
              FileWidget(
                name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                file: entity,
              ),
            );
            mainFileList.sort((a, b) => a.name.compareTo(b.name));
            debugPrint('entitiy is File.        mainFileList => $mainFileList');
          } else if (entity is Directory) {
            mainFolderList.add(
              FolderWidget(
                name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                dir: entity,
              ),
            );
            mainFolderList.sort((a, b) => a.name.compareTo(b.name));
            debugPrint(
                'entitiy is Directory. mainFolderList => $mainFolderList');
          }
          mainList = [];
          mainFolderList.forEach((FolderWidget widget) => mainList.add(widget));
          mainFileList.forEach((FileWidget widget) => mainList.add(widget));
        },
      );
    } catch (error) {
      debugPrint('catch $error');
    }
    debugPrint('mainList ===> $mainList');

    return mainList;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('MEMO'),
            backgroundColor: const Color(0xFF212121),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {});
                  })
            ],
          ),
          body: FutureBuilder(
              future: rootList(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return ListView(
                    children: snapshot.data,
                  );
                } else {
                  debugPrint('hasData is false');
                  return Center(child: CircularProgressIndicator());
                }
              }),
          floatingActionButton: FloatingActionButton(
            heroTag: 'PageBtn',
            backgroundColor: const Color(0xFF212121),
            child: const Icon(Icons.add),
            onPressed: () async {
              Directory rootdir = Directory('${await localPath()}/root');
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePage(tDir: rootdir),
                  )).then((_) {
                setState(() {});
              });
            },
          ),
        ),
      ),
    );
  }
}
/*
currentの管理
  rootにいるときのcreateと
  listPageにいるときのcreateを判別して、作る場所を決める
*/
