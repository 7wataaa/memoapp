import 'dart:io';

import 'package:flutter/material.dart';

import 'fileWidget.dart';

import 'CreatePage.dart';

class FolderListPage extends StatefulWidget {
  final String name;
  final Directory dir;

  FolderListPage({this.name, this.dir});

  @override
  _FolderListPageState createState() => _FolderListPageState();
}

class _FolderListPageState extends State<FolderListPage> {
  List<Widget> resultList = [];
  List<FolderWidget> folderList = [];
  List<FileWidget> fileList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name}'),
        backgroundColor: const Color(0xFF212121),
      ),
      body: listPageList(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'PageBtn',
        backgroundColor: const Color(0xFF212121),
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePage(
                  dir: widget.dir,
                  root: false,
                ), //どこに作るか入れる
              )).then((returnWidget) {
            setState(() {
              //kokokesu
              if (returnWidget.runtimeType == FolderWidget) {
                debugPrint('folder add');
                folderList.add(returnWidget);
                folderList.sort((a, b) => a.name.compareTo(b.name));
              } else if (returnWidget.runtimeType == FileWidget) {
                debugPrint('file add');
                fileList.add(returnWidget);
                fileList.sort((a, b) => a.name.compareTo(b.name));
              } else {
                debugPrint('受け取ったWidgetの型が一致しないか、なにも返されなかった');
              }
              resultList = [];
              folderList.forEach((w) => resultList.add(w));
              fileList.forEach((w) => resultList.add(w));
            });
          }).catchError((e) => debugPrint('folderListPage $e'));
        },
      ),
    );
  }

  Widget listPageList() {
    try {
      Directory.current = widget.dir;
      debugPrint(
          'listPage => ${RegExp(r'([^/]+?)?$').stringMatch(Directory.current.path)}');
      Directory.current.list().listen((FileSystemEntity entity) {
        if (entity is File) {
          setState(() {
            fileList.add(FileWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              file: entity,
            ));
          });
          debugPrint('fileList => $fileList');
        } else if (entity is Directory) {
          setState(() {
            folderList.add(FolderWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              dir: entity,
            ));
          });
          debugPrint('folderList => $folderList');
        } else {
          debugPrint('何も追加されてない');
        }
      });
    } catch (error) {
      debugPrint('$error err');
    }

    return ListView.builder(
      itemCount: resultList.length,
      itemBuilder: (BuildContext context, index) {
        return resultList[index];
      },
    );
  }
}
