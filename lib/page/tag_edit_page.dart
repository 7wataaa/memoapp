import 'package:flutter/material.dart';
import 'package:memoapp/file_info.dart';

class TagEditPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        title: const Text('TagCreatePage'),
      ),
      body: TagCreatePageBody(),
    );
  }
}

class TagCreatePageBody extends StatefulWidget {
  @override
  _TagCreatePageBodyState createState() => _TagCreatePageBodyState();
}

class _TagCreatePageBodyState extends State<TagCreatePageBody> {
  final _textEditingController = TextEditingController();
  String inputValue = '';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Chip>>(
        future: loadChips(),
        builder: (context, snapshot) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 15,
                          right: 0,
                          top: 5,
                          bottom: 0,
                        ),
                        child: TextField(
                          controller: _textEditingController,
                          onChanged: (value) => inputValue = value,
                        ),
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.create),
                        onPressed: () {
                          if (inputValue.isEmpty) {
                            debugPrint('inputvalue is empty');
                            return;
                          }
                          for (final chip in snapshot.data) {
                            if ((chip.label as Text).data == inputValue) {
                              debugPrint('重複した名前');
                              return;
                            }
                          }
                          debugPrint('inputValue => $inputValue');
                          //TODO save to file
                          /*setState(() {
                        chips.add(
                          Chip(
                            label: Text('$inputValue'),
                          ),
                        );
                      });*/
                        })
                  ],
                ),
              ),
              snapshot.hasData
                  ? Wrap(
                      spacing: 5,
                      children: snapshot.data,
                    )
                  : const CircularProgressIndicator(),
            ],
          );
        });
  }

  Future<List<Chip>> loadChips() async {
    final result = <Chip>[];

    if ((await FileInfo.readyTagCsvFile.readAsString()).isEmpty) {
      debugPrint('readyTag.csv is empty');
      return result;
    }

    final readyTagCsvFile = await FileInfo.readyTagCsvFile.readAsString();
    final tagnames = readyTagCsvFile.split(RegExp(r'\n')).toList();

    debugPrint('${tagnames.length}');
    for (final tagname in tagnames) {
      if (tagname.isEmpty) {
        break;
      }
      result.add(
        Chip(
          label: Text(
            tagname,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return result;
  }
}
