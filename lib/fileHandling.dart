import 'dart:io';

import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

///localPath()
///Android,iOS に対応するパスを非同期的に取得
Future<String> localPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

///localPathSync()
///Android, iOS に対応するパスを同期的に取得
String localPathSync() {
  String path;
  getApplicationDocumentsDirectory().then((dir) => path = dir.path);
  return path;
}

///rootSet()
///rootディレクトリを確認して、なければ作る。
Future<dynamic> rootSet() async {
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
