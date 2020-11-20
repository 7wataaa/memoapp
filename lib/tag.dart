import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memoapp/file_plus_tag.dart';
import 'package:memoapp/handling.dart';
import 'package:memoapp/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Tag {
  Tag(this.tagName);

  static File readyTagFile;

  static File syncTagFile;

  String tagName;

  Widget createTagChip() {
    return Builder(
      builder: (context) => ActionChip(
        label: Text(
          tagName,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
        onPressed: () {
          showDialog<SimpleDialog>(
              context: context,
              child: SimpleDialog(
                title: Text('$tagName'),
                children: [
                  //TODO サインインしていたら同期化を表示させる
                  SimpleDialogOption(
                    child: const Text('同期化'),
                    onPressed: () {
                      Navigator.pop(context);

                      showDialog<AlertDialog>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('同期'),
                            content: Text('$tagName を同期させますか?'),
                            actions: [
                              FlatButton(
                                child: const Text('キャンセル'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              FlatButton(
                                child: const Text('同期'),
                                onPressed: () {
                                  onTagSync();
                                  //TODO ここでfirestoreにタグを実装させる

                                  context.read(firestoreProvider)
                                    ..createMemoUser()
                                    ..addTaggedFiles(tagName);
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          );
                        },
                      );
                    },
                  ),
                  SimpleDialogOption(
                      child: const Text('削除'),
                      onPressed: () async {
                        Navigator.pop(context);

                        showDialog<AlertDialog>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('本当に削除しますか'),
                                content: Text('$tagName を削除します'),
                                actions: [
                                  FlatButton(
                                    child: const Text('キャンセル'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  FlatButton(
                                    child: const Text('削除'),
                                    onPressed: () async {
                                      final taglist =
                                          await readyTagFile.readAsLines();
                                      taglist.removeWhere(
                                          (tagname) => tagname == tagName);

                                      //'[tag1, tag2]'からtag1\ntag2にする
                                      readyTagFile.writeAsStringSync('');

                                      for (var str in taglist) {
                                        str = readyTagFile
                                                .readAsStringSync()
                                                .isEmpty
                                            ? str
                                            : '\n$str';
                                        readyTagFile.writeAsStringSync(str,
                                            mode: FileMode.append);
                                      }

                                      final pathtotags = FilePlusTag
                                          .returnPathToTagsFromJson();

                                      for (final key in pathtotags.keys) {
                                        (pathtotags[key] as List).removeWhere(
                                            (dynamic item) => item == tagName);
                                      }
                                      FilePlusTag.tagsFileJsonFile
                                          .writeAsString(
                                              jsonEncode(pathtotags));

                                      tagChipEvent.add('');

                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            });
                      })
                ],
              ));
        },
      ),
    );
  }

  void onTagSync() {
    final tmplist = readyTagFile.readAsLinesSync()
      ..removeWhere((tagstr) => tagstr == tagName);

    readyTagFile.writeAsStringSync('');

    for (final _name in tmplist) {
      final _isreadytagfileEmpty = readyTagFile.readAsStringSync().isEmpty;
      readyTagFile.writeAsStringSync(
        _isreadytagfileEmpty ? _name : '\n$_name',
        mode: FileMode.append,
      );
    }

    final _isSyncTagFileEmpty = syncTagFile.readAsStringSync().isEmpty;
    syncTagFile.writeAsStringSync(
      _isSyncTagFileEmpty ? tagName : '\n$tagName',
      mode: FileMode.append,
    );

    tagChipEvent.add('');
  }

  Widget createSyncTagChip() {
    return Builder(
      builder: (context) => ActionChip(
        avatar: const CircleAvatar(
          child: Icon(Icons.sync),
        ),
        label: Text(
          tagName,
          style: const TextStyle(fontSize: 18),
        ),
        onPressed: () {
          showDialog<SimpleDialog>(
              context: context,
              builder: (context) {
                return SimpleDialog(
                  title: Text('$tagName'),
                  children: [
                    SimpleDialogOption(
                      child: const Text('削除'),
                      onPressed: () {
                        Navigator.pop(context);

                        showDialog<AlertDialog>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('本当に削除しますか'),
                                content: Text('$tagName を削除します'),
                                actions: [
                                  FlatButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('キャンセル'),
                                  ),
                                  FlatButton(
                                      onPressed: () async {
                                        final staglist =
                                            await syncTagFile.readAsLines();
                                        staglist.removeWhere(
                                            (tagname) => tagname == tagName);

                                        //'[tag1, tag2]'からtag1\ntag2にする
                                        syncTagFile.writeAsStringSync('');
                                        for (var str in staglist) {
                                          str = syncTagFile
                                                  .readAsStringSync()
                                                  .isEmpty
                                              ? str
                                              : '\n$str';
                                          syncTagFile.writeAsStringSync(str,
                                              mode: FileMode.append);
                                        }

                                        final pathTagsMap = FilePlusTag
                                            .returnPathToTagsFromJson();

                                        for (final key in pathTagsMap.keys) {
                                          (pathTagsMap[key] as List)
                                              .removeWhere((dynamic item) =>
                                                  item == tagName);
                                        }
                                        FilePlusTag.tagsFileJsonFile
                                            .writeAsString(
                                                jsonEncode(pathTagsMap));

                                        tagChipEvent.add('');

                                        Navigator.pop(context);
                                      },
                                      child: const Text('削除'))
                                ],
                              );
                            });
                      },
                    ),
                  ],
                );
              });
        },
      ),
    );
  }
}
