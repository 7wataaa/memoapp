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

bool _canPop = false;

class Home extends StatefulWidget {
  const Home(this.appDocsDirPath);

  final String appDocsDirPath;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ///複数選択
  bool _selectMode = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _canPop,
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
                  context.read(authProvider).googleSignOut();
                  fileSystemEvent.sink.add('');
                  setState(() {
                    _selectMode = !_selectMode;
                  });
                })
          ],
        ),
        drawer: const HomeDrawer(),
        body: Consumer(
          builder: (context, watch, child) {
            return watch(modeProvider).isTagmode
                ? tagHomeBody()
                : rootHomeBody();
          },
        ),
        floatingActionButton: _selectMode
            ? null
            : FloatingActionButton(
                heroTag: 'PageBtn',
                backgroundColor: const Color(0xFF212121),
                child: const Icon(Icons.add),
                onPressed: () async {
                  final rootdir = Directory('${widget.appDocsDirPath}/root');
                  await Navigator.push<MaterialPageRoute>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            //TODO タグ画面のときに選択しているものをデフォで追加する
                            CreatePage(tDir: rootdir, isRoot: true),
                      ));
                  setState(() {});
                },
              ),
      ),
    );
  }

  StreamBuilder<String> rootHomeBody() {
    return StreamBuilder(
      stream: fileSystemEvent.stream,
      builder: (context, snapshot) {
        if (_normalTiles(widget.appDocsDirPath).isEmpty) {
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
        children: _normalTiles(widget.appDocsDirPath),
      ),
    );
  }

  Widget _selectModetiles() {
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            child: ListView(
              children: _checkboxTiles(widget.appDocsDirPath),
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
                          color: Color(0xFF484848),
                        ),
                        onPressed: () {
                          _deleteSelectedEntities();
                        },
                      ),
                      const Positioned(
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
        )
      ],
    );
  }

  Widget tagHomeBody() {
    return Consumer(
      builder: (context, watch, child) {
        final synctagnames = watch(synctagnamesprovider.state);
        final localtagnames = watch(localtagnamesprovider.state);
        final selectedtagname = context.read(selectedtagnameprovider.state);

        if (synctagnames.isEmpty && localtagnames.isEmpty) {
          return const Center(
            child: Text('タグがありません'),
          );
        }

        // selectedMapを作る

        final tagnames = [...synctagnames, ...localtagnames];

        int sindex() {
          final i = tagnames.indexWhere((str) => str == selectedtagname);

          if (i == -1) {
            return 0;
          }
          return i;
        }

        final selectedtagnameindex = sindex();

        final selectedList =
            List.generate(tagnames.length, (i) => i == selectedtagnameindex);

        final selectedMap = Map.fromIterables(tagnames, selectedList);

        //trueが一つ存在しているかどうか
        bool trueCountIs1() {
          var truecount = 0;
          for (final value in selectedMap.values) {
            if (value) {
              truecount++;
            }
          }
          return truecount <= 1;
        }

        assert(trueCountIs1());

        Widget localTagChip(int i, String tagname) {
          return ChoiceChip(
            key: ValueKey(i),
            label: Text(
              tagname,
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
            selected: selectedMap[tagname],
            onSelected: (bool newBool) {
              if (!newBool) {
                return;
              }
              setState(() {
                context.read(selectedtagnameprovider).tagname = tagname;
              });
            },
          );
        }

        Widget syncTagChip(int i, String tagname) {
          return ChoiceChip(
            key: ValueKey(i),
            avatar: const CircleAvatar(
              child: Icon(Icons.sync),
            ),
            label: Text(
              tagname,
              style: const TextStyle(fontSize: 20),
            ),
            selected: selectedMap[tagname],
            onSelected: (bool newBool) {
              if (!newBool) {
                return;
              }
              setState(() {
                context.read(selectedtagnameprovider).tagname = tagname;
              });
            },
          );
        }

        final chiplist = <Widget>[];

        for (var i = 0; i < synctagnames.length; i++) {
          final synctagname = synctagnames[i];

          chiplist.add(
            syncTagChip(i, synctagname),
          );
        }

        for (var i = 0; i < localtagnames.length; i++) {
          final localtagname = localtagnames[i];

          chiplist.add(
            localTagChip(i, localtagname),
          );
        }

        debugPrint('selectedMap = $selectedMap');

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              margin:
                  const EdgeInsets.only(top: 10, bottom: 10, left: 1, right: 1),
              height: 45,
              child: ListView.separated(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(left: 4),
                ),
                itemCount: tagnames.length,
                itemBuilder: (context, i) {
                  return chiplist[i];
                },
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  String containselectedkey() {
                    for (final key in selectedMap.keys) {
                      if (selectedMap[key]) {
                        return key;
                      }
                    }
                    assert(false);
                    return '';
                  }

                  final selectedkey = containselectedkey();

                  //selectedkeyがsynctagだったらこっちのwidget
                  if (synctagnames.contains(selectedkey)) {
                    return FutureBuilder<List<Widget>>(
                      future: Future(() async {
                        _lastSelectedKeyStr
                          ..clear()
                          ..write('$selectedkey');

                        await context
                            .read(taggedsyncfileprovider)
                            .fetchTaggedStoreFiles();

                        final docs = context.read(taggedsyncfileprovider.state);
                        //TODO providrからもらったリストをfilewidget肉バル

                        debugPrint('docs = $docs');

                        final result = <Widget>[];
                        for (final docsnapshot in docs) {
                          if ((docsnapshot.get('tag') as List<dynamic>)
                              .cast<String>()
                              .contains('$selectedkey')) {
                            result.add(SyncFileWidget(
                              docsnapshot: docsnapshot,
                            ));
                          }
                        }

                        return result;
                      }),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData ||
                            '$_lastSelectedKeyStr' != selectedkey) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        debugPrint('snapshot.data = ${snapshot.data}');

                        return ListView(
                          children: snapshot.data,
                        );
                      },
                    );
                  }

                  //selectedkeyがsynctagじゃなかったらこっちのwidget

                  //TODO タグ付けされていないファイルの一覧ほしい
                  final result = <FileWidget>[];

                  final tagsFileJsonFileStr =
                      FilePlusTag.tagsFileJsonFile.readAsStringSync();

                  final pathtagsMap = (jsonDecode(tagsFileJsonFileStr != ''
                          ? tagsFileJsonFileStr
                          : '{}') as Map<String, dynamic>)
                      .cast<String, List<dynamic>>();

                  //root下のファイルを探索 ここから
                  Directory('${widget.appDocsDirPath}/root')
                      .listSync(recursive: true)
                      .forEach((fsEntity) {
                    if (fsEntity is File) {
                      if (pathtagsMap[fsEntity.path] == null) {
                        return;
                      }

                      //TODO tagnameに選ばれているタグを入れる
                      if ((pathtagsMap[fsEntity.path]).contains(selectedkey)) {
                        result.add(FilePlusTag(fsEntity).getWidget());
                      }
                    }
                  });
                  //ここまでfor

                  if (result.isNotEmpty) {
                    return ListView(
                      children: result,
                    );
                  } else {
                    //TODO 使われていないtagの削除機能
                    return const Center(child: Text('このタグが付けられたファイルはありません'));
                  }
                },
              ),
            )
          ],
        );
      },
    );
  }

  ///synctagchipからsynctagchipに移るとsnapshotが空にならないのでそれ対策
  final _lastSelectedKeyStr = StringBuffer('');

  ///[tagname]がついているファイルをtagsFileJsonFileから見つけて、一覧のリストを返す
  List<Widget> taggedFileTiles(String tagname) {
    debugPrint('$tagname');
    final result = <FileWidget>[];

    final synctagnames = context.read(synctagnamesprovider.state);

    if (synctagnames.contains(tagname)) {}

    final pathtagsMap =
        (jsonDecode(FilePlusTag.tagsFileJsonFile.readAsStringSync())
                as Map<String, dynamic>)
            .cast<String, List<dynamic>>();

    Directory('${widget.appDocsDirPath}/root')
        .listSync(recursive: true)
        .forEach((fsEntity) {
      if (fsEntity is File) {
        if (pathtagsMap[fsEntity.path] == null) {
          return;
        }

        final fileplustag = FilePlusTag(fsEntity);

        if ((pathtagsMap[fileplustag.file.path]).contains(tagname)) {
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
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read(synctagnamesprovider).loadsynctagnames());
  }

  @override
  Widget build(BuildContext context) {
    if (Tag.localTagFile == null) {
      return null;
    }

    return Drawer(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Consumer(builder: (context, watch, child) {
              final _user = FirebaseAuth.instance.currentUser;

              final userisNotNull = _user != null;
              assert(
                  userisNotNull == (FirebaseAuth.instance.currentUser != null));

              final synctagnames = watch(synctagnamesprovider.state);
              final localtagnames = watch(localtagnamesprovider.state);

              final drawerList = <Widget>[
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.grey),
                  currentAccountPicture: GestureDetector(
                    child: CircleAvatar(
                      child: userisNotNull
                          ? null
                          : const Icon(Icons.person_add_alt_1),
                      backgroundImage: userisNotNull
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
                      Text(userisNotNull ? _user.displayName : 'Guest'),
                  accountEmail: Text(userisNotNull ? _user.email : '-'),
                ),
                ...synctagnames.map<Widget>((tagstr) {
                  return ListTile(
                    key: GlobalKey(),
                    leading: const Icon(Icons.label),
                    title: Text('$tagstr'),
                    onTap: () {},
                  );
                }),
                ...localtagnames.map<Widget>((tagname) {
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
