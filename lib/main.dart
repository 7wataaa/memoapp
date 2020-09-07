import 'dart:io';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';

import 'package:memoapp/CreatePage.dart';

import 'package:memoapp/fileHandling.dart';

import 'package:memoapp/fileWidget.dart';

import 'package:screen/screen.dart';

import 'EditPage.dart';

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
                    setState(() {
                      debugPrint('refresh');
                    });
                  })
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

  Widget mainListPage() {
    localPath().then((path) {
      try {
        Directory('$path/root').list().listen((FileSystemEntity entity) {
          //この中はstreamが来るたびに繰り返される?
          if (entity is File) {
            debugPrint('entitiy is File');
            mainFileList.add(
              FileWidget(
                name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                file: entity,
              ),
            );
            debugPrint('mainFileSet => $mainFileList');
            mainFileList.sort((a, b) => a.name.compareTo(b.name));
          } else if (entity is Directory) {
            debugPrint('entitiy is Directory');
            mainFolderList.add(
              FolderWidget(
                name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                dir: entity,
              ),
            );
            mainFolderList.sort((a, b) => a.name.compareTo(b.name));
            debugPrint('mainFolderSet => $mainFolderList');
          }
        });
      } catch (error) {
        debugPrint('catch $error');
      }
      mainList = [];
      mainFolderList.forEach((FolderWidget widget) => mainList.add(widget));
      mainFileList.forEach((FileWidget widget) => mainList.add(widget));

      debugPrint('$mainList');

      return ListView.builder(
        itemCount: mainList.length,
        itemBuilder: (BuildContext context, index) {
          debugPrint('build');
          return mainList[index];
        },
      );
    });
  }
}
