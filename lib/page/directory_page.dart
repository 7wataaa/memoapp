import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memoapp/handling.dart';
import 'package:memoapp/page/create_page.dart';
import 'package:memoapp/widget/file_widget.dart';
import 'package:memoapp/widget/folder_widget.dart';

class FolderListPage extends StatefulWidget {
  const FolderListPage({this.name, this.dir});

  final String name;
  final Directory dir;

  @override
  _FolderListPageState createState() => _FolderListPageState();
}

class _FolderListPageState extends State<FolderListPage> {
  bool _selectMode = false;

  @override
  Widget build(BuildContext context) {
    Directory.current = widget.dir;
    debugPrint('current.path => '
        '${RegExp(r'([^/]+?)?$').stringMatch(Directory.current.path)}');

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
                _selectMode = !_selectMode;
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
                await Navigator.push<MaterialPageRoute>(
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
                                  //TODO moveの実装
                                },
                              ),
                              const Positioned(
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
                                    debugPrint('!! 何も選択されてません(folderlistpage');
                                  } else {
                                    showDeleteDialog(context);
                                    setState(() {
                                      _selectMode = false;
                                    });
                                  }
                                },
                              ),
                              const Positioned(
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
    return _selectMode ? _checkboxTiles() : _normalTiles();
  }

  List<Widget> _normalTiles() {
    final _folderTiles = <FolderWidget>[];
    final _fileTiles = <FileWidget>[];

    Directory.current.listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        _fileTiles
          ..add(
            FileWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              file: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        _folderTiles
          ..add(
            FolderWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              dir: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    });

    final _result = <Widget>[..._folderTiles, ..._fileTiles];
    return _result;
  }

  List<Widget> _checkboxTiles() {
    final _fileCheckList = <FileCheckboxWidget>[];
    final _folderCheckList = <FolderCheckboxWidget>[];

    Directory.current.listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        _fileCheckList
          ..add(
            FileCheckboxWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              file: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        _folderCheckList
          ..add(
            FolderCheckboxWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              dir: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    });

    final _result = <Widget>[..._folderCheckList, ..._fileCheckList];
    return _result;
  }

  Future showDeleteDialog(BuildContext context) {
    return showDialog<AlertDialog>(
      context: context,
      builder: (BuildContext context) {
        final _deleteList = <dynamic>[];
        final _deleteListToString = <String>[];

        for (final key in fsEntityToCheck.keys) {
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
                for (final entity in _deleteList) {
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
