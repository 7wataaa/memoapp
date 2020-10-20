import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memoapp/file_plus_tag.dart';
import 'package:memoapp/handling.dart';
import 'package:memoapp/page/create_page.dart';
import 'package:memoapp/widget/file_widget.dart';
import 'package:memoapp/widget/folder_widget.dart';
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate
      ],
      supportedLocales: const [
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
  bool _selectMode = false;
  bool _storageMode = true;

  @override
  void initState() {
    super.initState();
    rootSet();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MEMO'),
          backgroundColor: const Color(0xFF212121),
          leading: IconButton(
            icon: tagOrStorageIcon(),
            onPressed: () {
              setState(() {
                _storageMode = !_storageMode;
              });
            },
          ),
          actions: <Widget>[
            IconButton(
                icon: _editIcon(),
                onPressed: () {
                  fileSystemEvent.sink.add('');
                  setState(() {
                    _selectMode = !_selectMode;
                  });
                })
          ],
        ),
        body: FutureBuilder<int>(
          future: Future(() async {
            path = await localPath();
            final readytag = File('$path/readyTag');

            FilePlusTag.tagsFileJsonFile ??= File('$path/tagsFile.json');
            Tag.readyTagFile ??= readytag;

            if (!readytag.existsSync()) {
              Tag.readyTagFile = readytag;
              readytag.create();
              debugPrint('readyTagFile created');
            }

            if (!FilePlusTag.tagsFileJsonFile.existsSync()) {
              FilePlusTag.tagsFileJsonFile.create();
              debugPrint('tagFileJsonFile created');
            }

            tagnames = Tag.readyTagFile.readAsStringSync().split(RegExp(r'\n'));
            selectedChip = tagnames[0];
            isSelected = List.generate(tagnames.length, (index) {
              if (index == 0) {
                return true;
              }
              return false;
            });

            return 0;
          }),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _storageMode ? rootHomeBody() : tagHomeBody();
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
        floatingActionButton: _selectMode
            ? null
            : FloatingActionButton(
                heroTag: 'PageBtn',
                backgroundColor: const Color(0xFF212121),
                child: const Icon(Icons.add),
                onPressed: () async {
                  if (_selectMode) {
                    //TODO FAB押した時タグを追加する画面
                  } else {
                    final rootdir = Directory('${await localPath()}/root');
                    await Navigator.push<MaterialPageRoute>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreatePage(tDir: rootdir, isRoot: true),
                        )).then((_) {
                      setState(() {});
                    });
                  }
                },
              ),
      ),
    );
  }

  StreamBuilder<String> rootHomeBody() {
    return StreamBuilder(
      stream: fileSystemEvent.stream,
      builder: (context, snapshot) {
        if (_selectMode) {
          fsEntityToCheck = {};
          return Column(
            children: [
              Expanded(
                child: Scrollbar(
                  child: ListView(
                    children: _checkboxTiles(path),
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
                              onPressed: () {},
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
                                _deleteSelectedEntities();
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
              )
            ],
          );
        } else {
          //通常モード時
          return Scrollbar(
            child: ListView(
              children: _normalTiles(path),
            ),
          );
        }
      },
    );
  }

  Widget tagHomeBody() {
    //TODO タグページの実装

    final tagChips = createChips();
    debugPrint('$tagChips');

    if (tagChips.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, bottom: 5),
            height: 45,
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(left: 5),
              ),
              itemCount: tagChips.length,
              itemBuilder: (context, i) {
                return tagChips[i];
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Widget>>(
              future: fileTagTiles('$selectedChip'),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView(
                    children: snapshot.data,
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          )
        ],
      );
    } else {
      return const Center(
        child: Text('タグがありません'),
      );
    }
  }

  Future<List<Widget>> fileTagTiles(String tagname) async {
    final result = <FileWidget>[];

    Directory('$path/root')
        .list(recursive: true)
        .listen((FileSystemEntity entity) {
      if (entity is File) {
        final fileplustag = FilePlusTag(entity)..loadPathToTagsFromJson();

        if (FilePlusTag.pathToTags[fileplustag.file.path] == null ||
            (FilePlusTag.pathToTags[fileplustag.file.path] as List).isEmpty) {
          return;
        }
        if ((FilePlusTag.pathToTags[fileplustag.file.path] as List)
            .contains(tagname)) {
          result.add(fileplustag.getWidget());
        }
      }
    });

    return result;
  }

  List<Widget> createChips() {
    if (tagnames[0].isEmpty) {
      return [];
    }
    final _chips = <ChoiceChip>[];
    for (var i = 0; i < tagnames.length; i++) {
      debugPrint('aaa => ${tagnames.length}');
      _chips.add(
        ChoiceChip(
          selected: isSelected[i],
          label: Text(
            tagnames[i],
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          onSelected: (bool selected) {
            if (!isSelected[i]) {
              selectedChip = tagnames[i];
              isSelected = List.generate(isSelected.length, (index) => false);
              setState(() {
                isSelected[i] = selected;
              });
            }
          },
        ),
      );
    }

    return _chips;
  }

  Future<List<Tag>> createTagList() async {
    final tagsFile = FilePlusTag.tagsFileJsonFile;
    final resultList = <Tag>[];

    if (tagsFile.existsSync()) {
      for (final str in await tagsFile.readAsLines()) {
        resultList.add(Tag(str));
      }
      return resultList;
    }
    return null;
  }

  Widget _editIcon() {
    if (_selectMode) {
      return const Icon(Icons.check_box);
    }
    return const Icon(Icons.check_box_outline_blank);
  }

  Widget tagOrStorageIcon() {
    if (_storageMode) {
      return const Icon(
        Icons.folder,
        color: Color(0xFFFFFFFF),
      );
    }
    return const Icon(
      Icons.local_offer_outlined,
      color: Color(0xFFFFFFFF),
    );
  }

  List<Widget> _normalTiles(String path) {
    final mainFolderList = <FolderWidget>[];
    final mainFileList = <FileWidget>[];
    Directory('$path/root').listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        final fileinfo = FilePlusTag(entity);
        mainFileList
          ..add(
            fileinfo.getWidget(),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        mainFolderList
          ..add(
            FolderWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              dir: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    });

    final result = <Widget>[...mainFolderList, ...mainFileList];
    return result;
  }

  List<Widget> _checkboxTiles(String path) {
    final mainFolderCheckList = <FolderCheckboxWidget>[];
    final mainFileCheckList = <FileCheckboxWidget>[];

    Directory('$path/root').listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        mainFileCheckList
          ..add(
            FileCheckboxWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              file: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      } else if (entity is Directory) {
        mainFolderCheckList
          ..add(
            FolderCheckboxWidget(
              name: '${RegExp(r'([^/]+?)?$').stringMatch(entity.path)}',
              dir: entity,
            ),
          )
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    });

    final result = <Widget>[...mainFolderCheckList, ...mainFileCheckList];
    return result;
  }

  void _deleteSelectedEntities() {
    if (fsEntityToCheck.isEmpty ||
        fsEntityToCheck.values.every((bool b) => b == false)) {
      debugPrint('!! 何も選択されてません');
    } else {
      showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          final deleteList = <dynamic>[];
          final deleteListToString = <String>[];

          for (final key in fsEntityToCheck.keys) {
            if (fsEntityToCheck[key]) {
              deleteList.add(key);
              deleteListToString
                  .add('${RegExp(r'([^/]+?)?$').stringMatch(key.path)}');
            }
          }

          return AlertDialog(
            title: const Text('delete'),
            content: Text('$deleteListToString を削除します'),
            actions: [
              FlatButton(
                child: const Text('キャンセル'),
                onPressed: () => Navigator.pop(context),
              ),
              FlatButton(
                child: const Text('すべて削除'),
                onPressed: () {
                  for (final entity in deleteList) {
                    if (entity is File) {
                      final pathTags = jsonDecode(
                              FilePlusTag.tagsFileJsonFile.readAsStringSync())
                          as Map
                        ..remove(entity.path);
                      entity.delete();
                      FilePlusTag.tagsFileJsonFile
                          .writeAsStringSync(jsonEncode(pathTags));
                    } else if (entity is Directory) {
                      entity.delete(recursive: true);
                    }
                  }
                  fileSystemEvent.add('');
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ).then((_) {
        setState(
          () {
            _selectMode = false;
          },
        );
      });
    }
  }
}
/*
ファイルとディレクトリの名前が同じだとエラー
ファイルに入力→save→開く→save→開く→消えてる

勝手に名前付ける機能だけどそれをそのままファイルネームにするより、idか何かで管理したほうが使いやすい
*/
