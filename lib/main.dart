import 'dart:io';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';

import 'package:memoapp/CreatePage.dart';

import 'package:memoapp/fileHandling.dart';

import 'package:memoapp/fileWidget.dart';

import 'package:screen/screen.dart';

import 'EditPage.dart';

void main() async {
  debugPrint('mainrunning');
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        //currentの管理
        String path = await localPath();
        Directory.current = Directory('$path/root');
        Directory.current.list().listen((FileSystemEntity entity) {
          if (entity is File) {
            debugPrint('entitiy is File');
            setState(() {
              mainFileList.add(FileWidget(
                name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                file: entity,
              ));
            });
            debugPrint('FileList => $mainFileList');
          } else if (entity is Directory) {
            debugPrint('entitiy is Directory');
            setState(() {
              mainFolderList.add(FolderWidget(
                name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                dir: entity,
              ));
            });
            debugPrint('mainFolderList => $mainFolderList');
          } else {
            debugPrint('何も追加されてない');
          }
        });
      } catch (error) {
        debugPrint('$error err');
      }
    });
  }

  ///modeSwitch()
  ///false trueを切り替える
  void modeSwitch(bool bool) {
    setState(() {
      mode = bool;
    });
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
              Checkbox(
                checkColor: Color(0xFFFFFFFF),
                hoverColor: Color(0xFF1E1F21),
                value: mode,
                onChanged: modeSwitch,
              ),
            ],
          ),
          body: mainListPage(),
          floatingActionButton: FloatingActionButton(
            heroTag: 'PageBtn',
            backgroundColor: const Color(0xFF212121),
            child: const Icon(Icons.add),
            onPressed: () async {
              Directory rootdir = Directory('${await localPath()}/root');
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePage(
                      dir: rootdir,
                      root: true,
                    ),
                  )).then((_) {
                setState(() {
                  debugPrint('更新');
                });
              });
            },
          ),
        ),
      ),
    );
  }

  Widget mainListPage() {
    //mainListを開くとき、path/root/を参照して名前からwidgetを作る
    mainList = [];
    mainFolderList.sort((a, b) => a.name.compareTo(b.name));
    mainFileList.sort((a, b) => a.name.compareTo(b.name));
    mainFolderList.forEach((FolderWidget widget) => mainList.add(widget));
    mainFileList.forEach((FileWidget widget) => mainList.add(widget));

    debugPrint(
        'current => ${RegExp(r'([^/]+?)?$').stringMatch(Directory.current.path)}');

    return ListView.builder(
      itemCount: mainList.length,
      itemBuilder: (BuildContext context, index) {
        return mainList[index];
      },
    );
  }
}
