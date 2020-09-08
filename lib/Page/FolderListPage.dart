import 'dart:io';

import 'package:flutter/material.dart';

import 'CreatePage.dart';

import '../Widget/FileWidget.dart';

import '../Widget/FolderWidget.dart';

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
                builder: (context) => CreatePage(tDir: widget.dir),
              )).then((returnWidget) {
            setState(() {});
          }).catchError((e) => debugPrint('folderListPage $e'));
        },
      ),
    );
  }

  Widget listPageList() {
    try {
      Directory.current = widget.dir;
      debugPrint(
          'current.path => ${RegExp(r'([^/]+?)?$').stringMatch(Directory.current.path)}');
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
