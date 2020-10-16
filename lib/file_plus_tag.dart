//import 'dart:math';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memoapp/widget/file_widget.dart';

//import 'package:memoapp/handling.dart';

///FileInfo(File [file])
class FilePlusTag {
  FilePlusTag(this.file);

  final File file;
  static File tagsFileJsonFile;
  static File readyTagFile;
  Map<String, dynamic> pathToTags;

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

    debugPrint('${RegExp(r'([^/]+?)?$').stringMatch(file.path)}'
        ' のタグ => ${pathToTags[file.path]}');

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
    file.create();
    taglist.forEach(addTag);
  }
}

class Tag {
  Tag(this.tagName);

  static List<Tag> allTags;

  String tagName;

  dynamic toJson() {
    return {'tagName': tagName};
  }

  Chip getTagChip() {
    return Chip(
      label: Text(
        tagName,
        style: const TextStyle(
          fontSize: 18,
        ),
      ),
      onDeleted: () {},
    );
  }
}
