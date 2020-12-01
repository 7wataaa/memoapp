import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoapp/file_plus_tag.dart';
import 'package:memoapp/handling.dart';
import 'package:memoapp/main.dart';
import 'package:memoapp/page/create_page.dart';
import 'package:memoapp/page/google_sign_in_page.dart';
import 'package:memoapp/tag.dart';
import 'package:memoapp/widget/file_widget.dart';
import 'package:memoapp/widget/folder_widget.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ///複数選択
  bool _selectMode = false;

  ///タグの名前りすと
  List<String> tagnames;

  ///ファイルをこのタグがついたものにソートするために使う
  String selectedChip;

  ///selected chipを管理する
  List<bool> isSelected;

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
          actions: <Widget>[
            IconButton(
                icon: _selectMode
                    ? const Icon(Icons.check_box)
                    : const Icon(Icons.check_box_outline_blank),
                onPressed: () {
                  tagUpdateEvent.add('');
                  fileSystemEvent.sink.add('');
                  setState(() {
                    _selectMode = !_selectMode;
                  });
                })
          ],
        ),
        drawer: const HomeDrawer(),
        body: StreamBuilder<String>(
            stream: tagUpdateEvent.stream,
            builder: (context, snapshot) {
              return FutureBuilder<bool>(
                future: Future(() async {
                  //共通のパスを設定
                  path = await localPath();

                  //tagsFile.jsonを設定 なければ作成
                  FilePlusTag.tagsFileJsonFile ??= File('$path/tagsFile.json');

                  if (!FilePlusTag.tagsFileJsonFile.existsSync()) {
                    await FilePlusTag.tagsFileJsonFile.create();
                    debugPrint('tagFileJsonFile created');
                  }

                  //syncTagを設定 なければ作成
                  Tag.syncTagFile ??= File('$path/syncTag');

                  if (!Tag.syncTagFile.existsSync()) {
                    await Tag.syncTagFile.create();
                    debugPrint('syncTagFile created');
                  }

                  //readyTagを設定 なければ作成
                  final readytag = File('$path/readyTag');

                  Tag.readyTagFile ??= readytag;

                  if (!readytag.existsSync()) {
                    Tag.readyTagFile = readytag;
                    await readytag.create();
                    debugPrint('readyTagFile created');
                  }

                  //readyTagFileからtagnamesを作成
                  tagnames = [
                    ...Tag.syncTagFile.readAsLinesSync(),
                    ...Tag.readyTagFile.readAsLinesSync(),
                  ];

                  if (tagnames.isNotEmpty) {
                    //選ばれているチップがなければ、1つ目のタグを設定
                    selectedChip ??= tagnames[0];

                    //選択状態を管理するリストがなければ、1つ目を選んだ状態のリストを設定
                    isSelected ??= List.generate(tagnames.length, (index) {
                      return index == 0;
                    });

                    //リストに更新があれば作り直す
                    if (isSelected.length != tagnames.length) {
                      isSelected = List.generate(tagnames.length, (index) {
                        return index == 0;
                      });
                      selectedChip = tagnames[0];
                    }
                  }

                  return true;
                }),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Consumer(
                      builder: (context, watch, child) {
                        return watch(modeProvider).isTagmode
                            ? tagHomeBody()
                            : rootHomeBody();
                      },
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );
            }),
        floatingActionButton: _selectMode
            ? null
            : FloatingActionButton(
                heroTag: 'PageBtn',
                backgroundColor: const Color(0xFF212121),
                child: const Icon(Icons.add),
                onPressed: () async {
                  final rootdir = Directory('${await localPath()}/root');
                  await Navigator.push<MaterialPageRoute>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            //TODO タグ画面のときに選択しているものをデフォで追加する
                            CreatePage(tDir: rootdir, isRoot: true),
                      ));

                  setState(() {
                    tagUpdateEvent.add('');
                  });
                },
              ),
      ),
    );
  }

  StreamBuilder<String> rootHomeBody() {
    return StreamBuilder(
      stream: fileSystemEvent.stream,
      builder: (context, snapshot) {
        if (_normalTiles(path).isEmpty) {
          return const Center(
            child: Text('ファイルもしくはフォルダがありません'),
          );
        }
        fsEntityToCheck = {};
        return _selectMode ? _selectModetiles() : _normalModetiles();
      },
    );
  }

  Scrollbar _normalModetiles() {
    return Scrollbar(
      child: ListView(
        children: _normalTiles(path),
      ),
    );
  }

  Widget _selectModetiles() {
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
  }

  Widget tagHomeBody() {
    final _tagHomeChips = <Widget>[];

    final syncTagFileLine = Tag.syncTagFile.readAsLinesSync();

    for (var i = 0; i < tagnames.length; i++) {
      if (i < syncTagFileLine.length) {
        _tagHomeChips.add(
          ChoiceChip(
            avatar: const CircleAvatar(
              child: Icon(Icons.sync),
            ),
            selected: isSelected[i],
            label: Text(
              syncTagFileLine[i],
              style: const TextStyle(fontSize: 20),
            ),
            onSelected: (bool newValue) {
              if (!isSelected[i]) {
                selectedChip = syncTagFileLine[i];
                isSelected = List.generate(isSelected.length, (index) => false);
                setState(() {
                  isSelected[i] = newValue;
                });
              }
            },
          ),
        );
      } else {
        _tagHomeChips.add(
          ChoiceChip(
            selected: isSelected[i],
            label: Text(
              tagnames[i],
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
            onSelected: (bool newValue) {
              if (!isSelected[i]) {
                selectedChip = tagnames[i];
                isSelected = List.generate(isSelected.length, (index) => false);
                setState(() {
                  isSelected[i] = newValue;
                });
              }
            },
          ),
        );
      }
    }

    if (_tagHomeChips.isEmpty) {
      return const Center(
        child: Text('タグがありません'),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5, bottom: 5),
          height: 45,
          child: Container(
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(left: 5),
              ),
              itemCount: _tagHomeChips.length,
              itemBuilder: (context, i) {
                return _tagHomeChips[i];
              },
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Widget>>(
            future: taggedFileTiles('$selectedChip'),
            builder: (context, snapshot) {
              selectedChip ??= tagnames[0];
              if (snapshot.hasData && snapshot.data.isNotEmpty) {
                return ListView(
                  children: snapshot.data,
                );
              } else if (snapshot.hasData) {
                return const Center(child: Text('このタグが付けられたファイルはありません'));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        )
      ],
    );
  }

  Future<List<Widget>> taggedFileTiles(String tagname) async {
    debugPrint('$tagname');
    final result = <FileWidget>[];

    //await Future<Duration>.delayed(const Duration(seconds: 3));

    Directory('$path/root').listSync(recursive: true).forEach((entity) {
      if (entity is File) {
        final fileplustag = FilePlusTag(entity)..loadPathToTagsFromJson();

        final pathtagsMap = FilePlusTag.pathToTags;

        if (pathtagsMap[fileplustag.file.path] == null ||
            (pathtagsMap[fileplustag.file.path] as List).isEmpty) {
          return;
        }

        if ((pathtagsMap[fileplustag.file.path] as List).contains(tagname)) {
          result.add(fileplustag.getWidget());
        }
      }
    });

    return result;
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
          final deletePathList = <String>[];

          for (final key in fsEntityToCheck.keys) {
            if (fsEntityToCheck[key]) {
              deleteList.add(key);
              deletePathList
                  .add('${RegExp(r'([^/]+?)?$').stringMatch(key.path)}');
            }
          }

          return AlertDialog(
            title: const Text('delete'),
            content: Text('$deletePathList を削除します'),
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

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({
    Key key,
  }) : super(key: key);

  @override
  _HomeDrawerState createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read(synctagnamesprovider).load());
  }

  @override
  Widget build(BuildContext context) {
    if (Tag.readyTagFile == null) {
      return null;
    }

    final _user = FirebaseAuth.instance.currentUser;

    debugPrint('consumer元のbuildメソッド内');

    return Drawer(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Consumer(builder: (context, watch, child) {
              debugPrint('consumer内のメソッド');
              final _userisNotNull = _user != null;
              final _synctagname = watch(synctagnamesprovider.state);
              final drawerList = <Widget>[
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.grey),
                  currentAccountPicture: GestureDetector(
                    child: CircleAvatar(
                      child: _userisNotNull
                          ? null
                          : const Icon(Icons.person_add_alt_1),
                      backgroundImage: _userisNotNull
                          ? NetworkImage(
                              FirebaseAuth.instance.currentUser.photoURL)
                          : null,
                      radius: 60,
                    ),
                    onTap: () async {
                      await Navigator.push<MaterialPageRoute>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoogleSignInPage(),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                  accountName:
                      Text(_userisNotNull ? _user.displayName : 'none'),
                  accountEmail: Text(_userisNotNull ? _user.email : 'none'),
                ),
                ..._synctagname.map<Widget>((tagstr) {
                  return ListTile(
                    key: GlobalKey(),
                    leading: const Icon(Icons.label),
                    title: Text('$tagstr'),
                    onTap: () {},
                  );
                }),
                ...Tag.readyTagFile.readAsLinesSync().map<Widget>((tagname) {
                  return ListTile(
                    key: GlobalKey(),
                    leading: const Icon(Icons.label_outline),
                    title: Text('$tagname'),
                    onTap: () {},
                  );
                }),
              ];

              return ListView(
                children: drawerList,
              );
            }),
          ),
          ListTile(
            tileColor: const Color(0xFFE0E0E0),
            title: const Center(
              child: Text('モード切替'),
            ),
            onTap: () {
              context.read(modeProvider).onModeSwitch();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
