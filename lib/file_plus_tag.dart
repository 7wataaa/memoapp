import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memoapp/tag.dart';
import 'package:memoapp/widget/file_widget.dart';

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
