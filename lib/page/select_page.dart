import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:memoapp/handling.dart';

class Cdpage extends StatefulWidget {
  const Cdpage({@required this.file});

  final File file;

  @override
  _CdpageState createState() => _CdpageState();
}

class _CdpageState extends State<Cdpage> {
  List<Widget> radioDir = [];
  String selectedDirPath = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('"${RegExp(r'([^/]+?)?$').stringMatch(widget.file.path)}"...'),
        backgroundColor: const Color(0xFF212121),
      ),
      body: FutureBuilder(
        future: localPath(),
        builder: (context, snapshot) {
          radioDir = [];
          if (!snapshot.hasData) {
            return Center(
              child: Text('hasdata is ${snapshot.hasData}'),
            );
          } else {
            radioDir
                .add(directoryRadioWidget(Directory('${snapshot.data}/root')));
            Directory('${snapshot.data}/root')
                .listSync(recursive: true)
                .forEach((FileSystemEntity entity) {
              if (entity is Directory) {
                radioDir.add(
                  directoryRadioWidget(entity),
                );
              }
            });
            return ListView(
              children: radioDir,
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'CdpageButton',
        backgroundColor: const Color(0xFF212121),
        child: const Icon(Icons.check),
        onPressed: () {
          final newFilePath =
              '$selectedDirPath/${RegExp(r'([^/]+?)?$').stringMatch(widget.file.path)}';
          File(newFilePath).createSync();
          widget.file.copySync(newFilePath);
          widget.file.delete();
          Navigator.pop(context);
          fileSystemEvent.add('');
        },
      ),
    );
  }

  Widget directoryRadioWidget(Directory dir) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 0),
      child: RadioListTile(
        secondary: const Icon(Icons.folder),
        controlAffinity: ListTileControlAffinity.trailing,
        title: Text(RegExp(r'([^/]+?)?$').stringMatch(dir.path)),
        value: dir.path,
        groupValue: selectedDirPath,
        onChanged: (String value) {
          setState(() {
            selectedDirPath = value;
          });
          debugPrint('selectedDirPath => $selectedDirPath');
        },
      ),
    );
  }
}
