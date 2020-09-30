import 'dart:io';

import 'package:flutter/material.dart';

import 'package:memoapp/handling.dart';

import 'package:memoapp/page/create_page.dart';

import 'package:memoapp/widget/file_widget.dart';

import 'package:memoapp/widget/folder_widget.dart';

class FolderListPage extends StatefulWidget {
  final String name;
  final Directory dir;

  FolderListPage({this.name, this.dir});

  @override
  _FolderListPageState createState() => _FolderListPageState();
}

class _FolderListPageState extends State<FolderListPage> {
  bool _selectMode = false;

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
            icon: _btnIcon(),
            onPressed: () {
              fileSystemEvent.sink.add('');
              setState(() {
                _selectMode = _selectMode ? false : true;
              });
            },
          ),
        ],
      ),
      body: _body(),
      floatingActionButton: _selectMode
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

  Widget _btnIcon() {
    if (_selectMode) {
      return const Icon(Icons.edit);
    } else {
      return const Icon(Icons.edit_outlined);
    }
  }

  Widget _body() {
    return StreamBuilder(
        stream: fileSystemEvent.stream,
        builder: (context, snapshot) {
          fsEntityToCheck = {};
          if (_selectMode) {
            return Column(
              children: [
                Expanded(
                  child: Scrollbar(
                    child: ListView(
                      children: _getList(),
                    ),
                  ),
                ),
                Container(
                  child: Container(
                    margin: const EdgeInsets.only(
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
                                  color: Color(0xFF484848),
                                ),
                                onPressed: () {
                                  //koko
                                },
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
                                  if (fsEntityToCheck.isEmpty ||
                                      fsEntityToCheck.values
                                          .every((bool b) => b == false)) {
                                    debugPrint('何も選択されてません(folderlistpage');
                                  } else {
                                    showDeleteDialog(context);
                                    setState(() {
                                      _selectMode = false;
                                    });
                                  }
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
                ),
              ],
            );
          } else {
            return Scrollbar(
                child: ListView(
              children: _getList(),
            ));
          }
        });
  }

  ///[_selectMode]に応じたリストを返す
  ///
  ///true なら[checkboxTiles()]
  ///false なら[normalTiles()]
  List<Widget> _getList() {
    try {
      return _selectMode ? _checkboxTiles() : _normalTiles();
    } catch (e) {
      debugPrint('$e');
      return null;
    }
  }

  List<Widget> _normalTiles() {
    List<FolderWidget> _folderTiles = [];
    List<FileWidget> _fileTiles = [];

    Directory.current.listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        _fileTiles.add(
          FileWidget(
            name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
            file: entity,
          ),
        );
        _fileTiles.sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        _folderTiles.add(
          FolderWidget(
            name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
            dir: entity,
          ),
        );
        _folderTiles.sort((a, b) => a.name.compareTo(b.name));
      }
    });

    List<Widget> _result = [..._folderTiles, ..._fileTiles];
    return _result;
  }

  List<Widget> _checkboxTiles() {
    List<FileCheckboxWidget> _fileCheckList = [];
    List<FolderCheckboxWidget> _folderCheckList = [];

    Directory.current.listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        _fileCheckList.add(
          FileCheckboxWidget(
            name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
            file: entity,
          ),
        );
        _fileCheckList.sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        _folderCheckList.add(
          FolderCheckboxWidget(
            name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
            dir: entity,
          ),
        );
        _folderCheckList.sort((a, b) => a.name.compareTo(b.name));
      }
    });

    List<Widget> _result = [..._folderCheckList, ..._fileCheckList];
    return _result;
  }

  Future showDeleteDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        List<dynamic> _deleteList = [];
        List<String> _deleteListToString = [];

        for (var key in fsEntityToCheck.keys) {
          if (fsEntityToCheck[key]) {
            _deleteList.add(key);
            _deleteListToString
                .add('${RegExp(r'([^/]+?)?$').stringMatch(key.path)}');
          }
        }

        return AlertDialog(
          title: const Text('キャンセル'),
          content: Text('$_deleteListToString を削除します'),
          actions: [
            FlatButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.pop(context),
            ),
            FlatButton(
              child: const Text('すべて削除'),
              onPressed: () {
                for (var entity in _deleteList) {
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
