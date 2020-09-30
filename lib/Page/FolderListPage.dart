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
    Directory.current = widget.dir;
    debugPrint(
        'current.path => ${RegExp(r'([^/]+?)?$').stringMatch(Directory.current.path)}');

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
      floatingActionButton: selectMode
          ? null
          : FloatingActionButton(
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
    return StreamBuilder(
        stream: fileSystemEvent.stream,
        builder: (context, snapshot) {
          fsEntityToCheck = {};
          if (selectMode) {
            return Column(
              children: [
                Expanded(
                  child: Scrollbar(
                    child: ListView(
                      children: getList(),
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
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          width: 0.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                  //選択したかどうかの判定、リストをここでつかう
                                  if (fsEntityToCheck.isEmpty) {
                                    debugPrint('何も選択されてません(folderlistpage');
                                  } else {
                                    for (var key in fsEntityToCheck.keys) {
                                      if (!fsEntityToCheck[key]) {
                                        debugPrint('何も選択されてません(folderlistpage');
                                      } else {
                                        debugPrint('$key');
                                        showDeleteDialog(context);
                                        setState(() {
                                          selectMode = false;
                                        });
                                        break;
                                      }
                                    }
                                  }
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
                ),
              ],
            );
          } else {
            return Scrollbar(
                child: ListView(
              children: getList(),
            ));
          }
        });
  }

  List<Widget> getList() {
    try {
      resultList = [];
      List<Widget> checkList = [];
      fileList = [];
      folderList = [];
      List<FileCheckboxWidget> fileCheckList = [];
      List<FolderCheckboxWidget> folderCheckList = [];

      Directory.current.listSync().forEach(
        (FileSystemEntity entity) {
          if (!selectMode) {
            if (entity is File) {
              fileList.add(
                FileWidget(
                  name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                  file: entity,
                ),
              );
              fileList.sort((a, b) => a.name.compareTo(b.name));
            } else if (entity is Directory) {
              folderList.add(
                FolderWidget(
                  name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                  dir: entity,
                ),
              );
              folderList.sort((a, b) => a.name.compareTo(b.name));
            }
          } else {
            if (entity is File) {
              fileCheckList.add(
                FileCheckboxWidget(
                  name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                  file: entity,
                ),
              );
              fileCheckList.sort((a, b) => a.name.compareTo(b.name));
            } else if (entity is Directory) {
              folderCheckList.add(
                FolderCheckboxWidget(
                  name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
                  dir: entity,
                ),
              );
              folderCheckList.sort((a, b) => a.name.compareTo(b.name));
            }
          }
        },
      );
      if (selectMode) {
        checkList = [];
        folderCheckList.forEach(checkList.add);
        fileCheckList.forEach(checkList.add);

        return checkList;
      } else {
        resultList = [];
        folderList.forEach(resultList.add);
        fileList.forEach(resultList.add);

        return resultList;
      }
    } catch (error) {
      debugPrint('catch $error');
    }

    return [];
  }

  showDeleteDialog(BuildContext context) {
    return showDialog(
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
          title: const Text('キャンセル'),
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
                    entity.deleteSync();
                  } else if (entity is Directory) {
                    entity.deleteSync(recursive: true);
                  }
                }
                fileSystemEvent.add('');
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }
}
