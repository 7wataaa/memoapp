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
    //TODO はじめに読み込む機能の実装
    _loadPathToTagsFromJson();
    debugPrint('pathtotags => $_pathToTags');

    if (_pathToTags == null) return null;

    List<Tag> result = [];
    for (var tagtitle in _pathToTags[file.path]) {
      result.add(
        Tag(tagtitle),
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
    //TODO addtagの実装
    if (!_pathToTags.keys.contains(file.path)) {
      _pathToTags[file.path] = [];
      tagsFile.writeAsStringSync(jsonEncode(_pathToTags));
    }
    _pathToTags[file.path].add(tag);
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
