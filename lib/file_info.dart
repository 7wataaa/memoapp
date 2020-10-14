//import 'dart:math';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memoapp/widget/file_widget.dart';

//import 'package:memoapp/handling.dart';

///FileInfo(File [file])
class FileInfo {
  FileInfo(this.file);

  final File file;
  static File tagsFileJsonFile;
  static File readyTagCsvFile;
  Map<String, dynamic> _pathToTags;

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
    _loadPathToTagsFromJson();

    if (_pathToTags.isEmpty) {
      debugPrint('_pathtotags is empty');
      return null;
    }

    if (!_pathToTags.containsKey(file.path)) {
      /*debugPrint('pathtotagsのkeyに '
          '${RegExp(r'([^/]+?)?$').stringMatch(file.path)} が登録されていない');*/
      return <Tag>[];
    }

    debugPrint('${RegExp(r'([^/]+?)?$').stringMatch(file.path)}'
        ' のタグ => ${_pathToTags[file.path]}');

    final result = <Tag>[];

    for (final tagtitle in _pathToTags[file.path]) {
      result.add(
        Tag(tagtitle as String),
      );
    }
    return result;
  }

  ///[_pathToTags] に tagsFile.json の Mapを代入する
  void _loadPathToTagsFromJson() {
    final tagsFileValue = tagsFileJsonFile.readAsStringSync();
    if (tagsFileValue.isEmpty) {
      return;
    }
    _pathToTags = Map<String, dynamic>.from(
        jsonDecode(tagsFileJsonFile.readAsStringSync()) as Map);
  }

  ///[tag]をtagsFileに追加
  void addTag(Tag tag) {
    _loadPathToTagsFromJson();

    if (!_pathToTags.containsKey(file.path)) {
      _pathToTags[file.path] = <String>[];
    }

    _pathToTags[file.path].add(tag.tagName);

    tagsFileJsonFile.writeAsStringSync(jsonEncode(_pathToTags));
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
  /*
  List<MaterialColor> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.grey,
    Colors.yellow,
  ];

  MaterialColor getColor() {
    return _colors[Random().nextInt(4)];
  }
  */
}
