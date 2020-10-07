import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

///Android,iOS に対応するパスを非同期的に取得
Future<String> localPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

///rootディレクトリを確認して、なければ作る。
Future<void> rootSet() async {
  final path = await localPath();
  Directory rootFolder = Directory('$path/root');
  bool isThere = await rootFolder.exists();

  if (!isThere) {
    await rootFolder
        .create()
        .then((Directory dir) => debugPrint('root folderを${dir.path}に作成'));
  } else if (isThere) {
    debugPrint('${rootFolder.path} はすでに存在');
  }
}

///JSONファイルにするための{"path": "tags"}
Map tagsMap = {};

var fileSystemEvent = StreamController<String>.broadcast();

Map<FileSystemEntity, bool> fsEntityToCheck = {};
