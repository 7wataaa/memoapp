import 'dart:io';

import 'package:flutter/material.dart';

import 'package:memoapp/fileHandling.dart';

import './CreatePage.dart';

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
  bool selectMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name}'),
        backgroundColor: const Color(0xFF212121),
        actions: [
          IconButton(
            icon: btnIcon(),
            onPressed: () {
              fileSystemEvent.sink.add('');
              setState(() {
                selectMode = selectMode ? false : true;
              });
            },
          ),
        ],
      ),
      body: body(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'PageBtn',
        backgroundColor: const Color(0xFF212121),
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePage(
                  tDir: widget.dir,
                  isRoot: false,
                ),
              )).then((returnWidget) {
            setState(() {});
          });
        },
      ),
    );
  }

  Widget btnIcon() {
    if (selectMode) {
      return const Icon(Icons.edit);
    } else {
      return const Icon(Icons.edit_outlined);
    }
  }

  Widget body() {
    return StreamBuilder<Object>(
        stream: fileSystemEvent.stream,
        builder: (context, snapshot) {
          return Scrollbar(
            child: ListView(
              children: getList(),
            ),
          );
        });
  }

  getList() {
    try {
      Directory.current = widget.dir;
      debugPrint(
          'current.path => ${RegExp(r'([^/]+?)?$').stringMatch(Directory.current.path)}');
      fileList = [];
      folderList = [];
      //↓
      Directory.current.listSync().forEach((FileSystemEntity entity) {
        if (entity is File) {
          fileList.add(
            FileWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              file: entity,
            ),
          );
          fileList.sort((a, b) => a.name.compareTo(b.name));
          debugPrint('listpage entity is File');
        } else if (entity is Directory) {
          folderList.add(
            FolderWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              dir: entity,
            ),
          );
          folderList.sort((a, b) => a.name.compareTo(b.name));
          debugPrint('listpage entity is Directory');
        }
        resultList = [];
        folderList.forEach((FolderWidget widget) => resultList.add(widget));
        fileList.forEach((FileWidget widget) => resultList.add(widget));
        //↑
      });
    } catch (error) {
      debugPrint('catch $error');
    }

    return resultList;
  }
}
