import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoapp/file_plus_tag.dart';
import 'package:memoapp/handling.dart';
import 'package:memoapp/main.dart';

class Tag {
  Tag(this.tagName);

  static File localTagFile;

  static File syncTagFile;

  String tagName;

  Widget createTagChip() {
    return Builder(builder: (context) {
      return ActionChip(
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
                  SimpleDialogOption(
                    child: const Text('同期化'),
                    onPressed: () {
                      Navigator.pop(context);

                      showDialog<AlertDialog>(
                        context: context,
                        builder: (context) {
                          if (FirebaseAuth.instance.currentUser == null) {
                            return AlertDialog(
                              title: const Text('この機能は使用できません'),
                              content: Text('$tagName を同期させるにはログインしてください'),
                              actions: [
                                FlatButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('戻る'),
                                )
                              ],
                            );
                          }
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
                                  onSync(context);
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

                        await showDialog<AlertDialog>(
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
                                          await localTagFile.readAsLines();
                                      taglist.removeWhere(
                                          (tagname) => tagname == tagName);

                                      //'[tag1, tag2]'からtag1\ntag2にする
                                      localTagFile.writeAsStringSync('');

                                      for (var str in taglist) {
                                        str = localTagFile
                                                .readAsStringSync()
                                                .isEmpty
                                            ? str
                                            : '\n$str';
                                        localTagFile.writeAsStringSync(str,
                                            mode: FileMode.append);
                                      }

                                      final pathtotags = (jsonDecode(FilePlusTag
                                                  .tagsFileJsonFile
                                                  .readAsStringSync())
                                              as Map<String, dynamic>)
                                          .cast<String, List<String>>();

                                      for (final key in pathtotags.keys) {
                                        (pathtotags[key]).removeWhere(
                                            (dynamic item) => item == tagName);
                                      }
                                      FilePlusTag.tagsFileJsonFile
                                          .writeAsStringSync(
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
      );
    });
  }

  void onSync(BuildContext context) {
    final tmplist = localTagFile.readAsLinesSync()
      ..removeWhere((tagstr) => tagstr == tagName);

    localTagFile.writeAsStringSync('');

    for (final _name in tmplist) {
      final islocaltagfileEmpty = localTagFile.readAsStringSync().isEmpty;
      localTagFile.writeAsStringSync(
        islocaltagfileEmpty ? _name : '\n$_name',
        mode: FileMode.append,
      );
    }

    context.read(synctagnamesprovider).uploadtagname(tagName);
    context.read(firestoreProvider).uploadTaggedFiles(tagName);
    context.read(synctagnamesprovider).loadsynctagnames();
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
                                        //TODO firestoreから消す処理
                                        final pathTagsMap = (jsonDecode(
                                                    FilePlusTag.tagsFileJsonFile
                                                        .readAsStringSync())
                                                as Map<String, dynamic>)
                                            .cast<String, List<String>>();

                                        for (final key in pathTagsMap.keys) {
                                          (pathTagsMap[key]).removeWhere(
                                              (dynamic item) =>
                                                  item == tagName);
                                        }
                                        FilePlusTag.tagsFileJsonFile
                                            .writeAsStringSync(
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
