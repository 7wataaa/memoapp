import 'dart:io';

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:memoapp/widget/file_widget.dart';

//import 'package:memoapp/handling.dart';

class FileInfo {
  final File file;
  Set<Tag> _tags;
  FileInfo(this.file);

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

  List<Tag> getTags() {
    //fileに対応したリストをファイルから取得する
    return [];
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
