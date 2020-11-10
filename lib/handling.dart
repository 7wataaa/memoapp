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
  final rootFolder = Directory('$path/root');

  if (!rootFolder.existsSync()) {
    await rootFolder
        .create()
        .then((Directory dir) => debugPrint('root folderを${dir.path}に作成'));
  } else {
    debugPrint('${rootFolder.path} はすでに存在');
  }
}

///File('$path/root')みたいな、osごとの保存場所のパス
String path;

StreamController<String> fileSystemEvent = StreamController<String>.broadcast();

StreamController<String> tagChipEvent = StreamController<String>.broadcast();

StreamController<String> tagUpdateEvent = StreamController<String>.broadcast();

Map<FileSystemEntity, bool> fsEntityToCheck = {};
