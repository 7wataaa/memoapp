import 'dart:io';

//import 'dart:math';

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:memoapp/widget/file_widget.dart';

//import 'package:memoapp/handling.dart';

///FileInfo(File [file])
class FileInfo {
  final File file;
  static File tagsFile;
  static File readyTagFile;
  Map<String, dynamic> _pathToTags;
  FileInfo(this.file);

  ///このファイルでのFileWidgetを返す
  Widget getWidget() {
    return FileWidget(
      file: file,
      name: '${RegExp(r'([^/]+?)?$').stringMatch(file.path)}',
      tags: getTags(),
    );
  }

  ///fileに対応したtagリストをファイルから取得する
  List<Tag> getTags() {
    _loadPathToTagsFromJson();
    //debugPrint('pathtotags => $_pathToTags');

    if (_pathToTags.isEmpty) return null;

    if (!_pathToTags.containsKey(file.path)) {
      debugPrint(
          'pathtotagsのkeyに ${RegExp(r'([^/]+?)?$').stringMatch(file.path)} が登録されていない');
      return [];
    }

    debugPrint(
        '${RegExp(r'([^/]+?)?$').stringMatch(file.path)} のタグ => ${_pathToTags[file.path]}');

    List<Tag> result = [];
    /*for (List<String> tagtitle in _pathToTags[file.path]) {
      result.add(
        Tag(tagtitle),
      );
    }*/
    debugPrint('${_pathToTags[file.path].runtimeType}');
    List tags = _pathToTags[file.path];
    for (String tagname in tags) {
      result.add(
        Tag(tagname),
      );
    }
    return result;
  }

  ///[_pathToTags] に [tagsFile.json] の Mapを代入する
  void _loadPathToTagsFromJson() {
    String tagsFileValue = tagsFile.readAsStringSync();
    if (tagsFileValue.isEmpty) return;

    _pathToTags = jsonDecode(tagsFile.readAsStringSync());
  }

  ///[tag]をtagsFileに追加
  void addTag(Tag tag) {
    _loadPathToTagsFromJson();
    if (!_pathToTags.containsKey(file.path)) {
      _pathToTags[file.path] = [];
    }
    debugPrint('$tag');
    _pathToTags[file.path].add(tag.tagName);
    tagsFile.writeAsStringSync(jsonEncode(_pathToTags));
  }

  void fileCreateAndAddTag(List<Tag> taglist) {
    file.create();
    for (Tag tag in taglist) {
      addTag(tag);
    }
  }
}

class Tag {
  String tagName;

  Tag(this.tagName);

  dynamic toJson() {
    return {"tagName": tagName};
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
