import 'dart:async';
import 'dart:io';

StreamController<String> fileSystemEvent = StreamController<String>.broadcast();

///tag_edit_pageのタグの表示更新要
StreamController<String> tagChipEvent = StreamController<String>.broadcast();

Map<FileSystemEntity, bool> fsEntityToCheck = {};
