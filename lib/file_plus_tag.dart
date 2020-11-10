//import 'dart:math';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memoapp/handling.dart';
import 'package:memoapp/widget/file_widget.dart';

//import 'package:memoapp/handling.dart';

///FileInfo(File [file])
class FilePlusTag {
  FilePlusTag(this.file);

  final File file;
  static File tagsFileJsonFile;
  static Map<String, dynamic> pathToTags;

  Map<String, dynamic> get pathtag {
    loadPathToTagsFromJson();
    debugPrint('$pathToTags');
    return pathToTags;
  }

  ///このファイルでのFileWidgetを返す
  FileWidget getWidget() {
    return FileWidget(
      file: file,
      name: '${RegExp(r'([^/]+?)?$').stringMatch(file.path)}',
      tags: getTags(),
    );
  }

  ///fileに対応したtagリストをファイルから取得する
  List<Tag> getTags() {
    loadPathToTagsFromJson();

    if (pathToTags.isEmpty) {
      debugPrint('!! _pathtotags is empty');
      return [];
    }

    if (!pathToTags.containsKey(file.path)) {
      //debugPrint('!! pathtotagsのkeyに登録されていないパス');
      return <Tag>[];
    }

    final result = <Tag>[];

    for (final tagtitle in pathToTags[file.path]) {
      result.add(
        Tag(tagtitle as String),
      );
    }
    return result;
  }

  ///[pathToTags] に tagsFile.json の Mapを代入する
  void loadPathToTagsFromJson() {
    final tagsFileValue = tagsFileJsonFile.readAsStringSync();

    //jsondecodeの引数にnullが入れられないから
    if (tagsFileValue.isEmpty) {
      tagsFileJsonFile.writeAsStringSync('{}');
    }

    pathToTags = Map<String, dynamic>.from(
        jsonDecode(tagsFileJsonFile.readAsStringSync()) as Map);
  }

  ///[tag]をtagsFileに追加
  void addTag(Tag tag) {
    loadPathToTagsFromJson();

    if (!pathToTags.containsKey(file.path)) {
      pathToTags[file.path] = <String>[];
    }

    pathToTags[file.path].add(tag.tagName);

    tagsFileJsonFile.writeAsStringSync(jsonEncode(pathToTags));
  }

  void fileCreateAndAddTag(List<Tag> taglist) {
    file.createSync();
    taglist.forEach(addTag);
  }

  static Map<String, dynamic> returnPathToTagsFromJson() {
    final tagsFileValue = tagsFileJsonFile.readAsStringSync();

    if (tagsFileValue.isEmpty) {
      tagsFileJsonFile.writeAsStringSync('{}');
    }

    final result = Map<String, dynamic>.from(
        jsonDecode(tagsFileJsonFile.readAsStringSync()) as Map);

    return result;
  }
}

class Tag {
  Tag(this.tagName);

  static File readyTagFile;

  static File syncTagFile;

  String tagName;

  Widget createTagChip() {
    //TODO chipを変える
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
                  SimpleDialogOption(
                    child: const Text('同期化'),
                    onPressed: () {
                      final tmplist = readyTagFile.readAsLinesSync()
                        ..removeWhere((tagstr) => tagstr == tagName);

                      readyTagFile.writeAsStringSync('');

                      for (final _name in tmplist) {
                        readyTagFile.writeAsStringSync(
                          readyTagFile.readAsStringSync().isEmpty
                              ? _name
                              : '\n$_name',
                          mode: FileMode.append,
                        );
                      }

                      syncTagFile.writeAsStringSync(
                        syncTagFile.readAsStringSync().isEmpty
                            ? tagName
                            : '\n$tagName',
                        mode: FileMode.append,
                      );

                      tagChipEvent.add('');

                      Navigator.pop(context);
                    },
                  ),
                  SimpleDialogOption(
                    child: const Text('削除'),
                    onPressed: () async {
                      final taglist = await readyTagFile.readAsLines();
                      taglist.removeWhere((tagname) => tagname == tagName);

                      //'[tag1, tag2]'からtag1\ntag2にする
                      readyTagFile.writeAsStringSync('');

                      for (var str in taglist) {
                        str = readyTagFile.readAsStringSync().isEmpty
                            ? str
                            : '\n$str';
                        readyTagFile.writeAsStringSync(str,
                            mode: FileMode.append);
                      }

                      final pathtotags = FilePlusTag.returnPathToTagsFromJson();

                      for (final key in pathtotags.keys) {
                        (pathtotags[key] as List)
                            .removeWhere((dynamic item) => item == tagName);
                      }
                      FilePlusTag.tagsFileJsonFile
                          .writeAsString(jsonEncode(pathtotags));

                      tagChipEvent.add('');

                      Navigator.pop(context);
                    },
                  )
                ],
              ));
        },
      ),
    );
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
                      onPressed: () async {
                        final staglist = await syncTagFile.readAsLines();
                        staglist.removeWhere((tagname) => tagname == tagName);

                        //'[tag1, tag2]'からtag1\ntag2にする
                        syncTagFile.writeAsStringSync('');
                        for (var str in staglist) {
                          str = syncTagFile.readAsStringSync().isEmpty
                              ? str
                              : '\n$str';
                          syncTagFile.writeAsStringSync(str,
                              mode: FileMode.append);
                        }

                        final pathTagsMap =
                            FilePlusTag.returnPathToTagsFromJson();

                        for (final key in pathTagsMap.keys) {
                          (pathTagsMap[key] as List)
                              .removeWhere((dynamic item) => item == tagName);
                          /* if ((pathtotags[key] as List<dynamic>).isEmpty) {
                          pathtotags.remove(key);
                          } */
                        }
                        FilePlusTag.tagsFileJsonFile
                            .writeAsString(jsonEncode(pathTagsMap));

                        tagChipEvent.add('');

                        Navigator.pop(context);
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
