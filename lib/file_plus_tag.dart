import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:memoapp/main.dart';
import 'package:memoapp/tag.dart';
import 'package:memoapp/widget/file_widget.dart';

///FileInfo(File [file])
class FilePlusTag {
  FilePlusTag(this.file);

  final File file;
  static File tagsFileJsonFile;

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
    final pathToTags = loadPathToTagsFromJson();

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

  ///tagsFile.json の Map
  Map<String, dynamic> loadPathToTagsFromJson() {
    final tagsFileValue = tagsFileJsonFile.readAsStringSync();

    //jsondecodeの引数にnullが入れられないから
    if (tagsFileValue.isEmpty) {
      tagsFileJsonFile.writeAsStringSync('{}');
    }

    return jsonDecode(tagsFileJsonFile.readAsStringSync())
        as Map<String, dynamic>;
  }

  ///[tag]をtagsFileに追加
  void addLocalTag(Tag tag) {
    final pathToTags = loadPathToTagsFromJson();

    if (!pathToTags.containsKey(file.path)) {
      pathToTags[file.path] = <String>[];
    }

    pathToTags[file.path].add(tag.tagName);

    tagsFileJsonFile.writeAsStringSync(jsonEncode(pathToTags));
  }

  void createLocalFileAndAddTag(List<Tag> taglist) {
    file.createSync();
    taglist.forEach(addLocalTag);
  }
}
