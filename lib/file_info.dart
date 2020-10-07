import 'dart:io';

import 'dart:math';

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:memoapp/widget/file_widget.dart';

import 'package:memoapp/handling.dart';

class FileInfo {
  final File file;
  Set<Tag> _tags;
  FileInfo(this.file);

  //static tagsFile = File('${await localPath()}/tagsFile');

  Widget getWidget() {
    return FileWidget(
      file: file,
      name: '${RegExp(r'([^/]+?)?$').stringMatch(file.path)}',
      tags: getTags(),
    );
  }

  void setTags(Tag tag) {
    _tags.add(tag);
  }

  ///fileに対応したリストをファイルから取得する
  List<Tag> getTags() {
    return [];
  }

  Future<void> saveAllTags() async {
    File tagsFile = File('${await localPath()}/tagsFile');
    if (!await tagsFile.exists()) {
      await tagsFile.create();
    }

    try {
      tagsFile.writeAsStringSync(jsonEncode(tagsMap));
    } catch (e) {
      debugPrint('$e');
    }
  }
}

class Tag {
  String tagName;

  Tag(this.tagName);

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
}
