import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memoapp/tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:memoapp/file_plus_tag.dart';
import 'package:memoapp/page/home_page.dart';
import 'package:screen/screen.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ProviderContainer()
      .read(firebaseInitializeProvider)
      .initializeFlutterApp();

  final appDocsDirPath = (await getApplicationDocumentsDirectory()).path;

  final rootFolder = Directory('$appDocsDirPath/root');

  if (!rootFolder.existsSync()) {
    rootFolder.createSync();
    debugPrint('root folderを$rootFolderに作成');
  } else {
    debugPrint('$rootFolder はすでに存在');
  }

  FilePlusTag.tagsFileJsonFile = File('$appDocsDirPath/tagsFile.json');

  if (!FilePlusTag.tagsFileJsonFile.existsSync()) {
    FilePlusTag.tagsFileJsonFile
      ..createSync()
      ..writeAsStringSync('{}');
    debugPrint('tagFileJsonFile created');
  }

  Tag.localTagFile = File('$appDocsDirPath/localTag');

  if (!Tag.localTagFile.existsSync()) {
    Tag.localTagFile.createSync();
    debugPrint('localTagFile created');
  }

  runApp(ProviderScope(child: MyApp(appDocsDirPath: appDocsDirPath)));
  await Screen.keepOn(true); //完成したら消す
}

final modeProvider = ChangeNotifierProvider.autoDispose((ref) => ModeModel());

class ModeModel extends ChangeNotifier {
  bool isTagmode = true;

  ///tagmode rootmodeの切り替えの通知
  void onModeSwitch() {
    isTagmode = !isTagmode;
    notifyListeners();
  }
}

final firebaseInitializeProvider =
    ChangeNotifierProvider((ref) => FirebaseInitializeModel());

class FirebaseInitializeModel extends ChangeNotifier {
  Future<void> initializeFlutterApp() async {
    await Firebase.initializeApp();
    debugPrint(FirebaseAuth.instance.currentUser?.uid);
    notifyListeners();
  }
}

final authProvider =
    ChangeNotifierProvider.autoDispose((ref) => FirebaseAuthModel());

class FirebaseAuthModel extends ChangeNotifier {
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> signInWithGoogle() async {
    GoogleSignInAccount googleUser;

    if (Platform.isIOS) {
      googleUser = await GoogleSignIn(
        scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly'],
        hostedDomain: '',
        clientId: '',
      ).signIn();
      debugPrint('iOSでのサインイン');
    } else {
      googleUser = await GoogleSignIn().signIn();
      debugPrint('iOSではないOSでのサインイン');
    }

    assert(googleUser != null);

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await auth.signInWithCredential(credential);

    final currentUser = FirebaseAuth.instance.currentUser;
    final store = FirebaseFirestore.instance;

    if (!(await store.collection('files').doc('${currentUser.uid}').get())
        .exists) {
      if (currentUser == null) {
        throw Error();
      }

      //firestoreの雛形的なものを作成する
      await FirebaseFirestore.instance
          .collection('files')
          .doc('${currentUser.uid}')
          .set(<String, dynamic>{'tagnames': <String>[]});
    }
  }

  Future<void> googleSignOut() async {
    await auth.signOut();
  }
}

final firestoreProvider =
    ChangeNotifierProvider.autoDispose((ref) => FireStoreModel());

class FireStoreModel extends ChangeNotifier {
  FirebaseFirestore store = FirebaseFirestore.instance;

  void uploadTaggedFiles(String tagname) {
    final _currentUser = FirebaseAuth.instance.currentUser;

    final userFiles = store
        .collection('files')
        .doc('${_currentUser.uid}')
        .collection('userFiles');

    final _taggedFileJson =
        jsonDecode(FilePlusTag.tagsFileJsonFile.readAsStringSync() ?? '{}')
            as Map<String, dynamic>;

    final _tmpFiles = <File>[];

    for (final _path in _taggedFileJson.keys) {
      if (_taggedFileJson[_path] is! List) {
        assert(false);
        return;
      }

      if ((_taggedFileJson[_path] as List).contains(tagname)) {
        _tmpFiles.add(File(_path));
      }
    }

    for (final _taggedFile in _tmpFiles) {
      final _fileName = RegExp(r'([^/]+?)?$').stringMatch(_taggedFile.path);

      final _tags = (jsonDecode(FilePlusTag.tagsFileJsonFile.readAsStringSync())
          as Map<String, dynamic>)['${_taggedFile.path}'] as List<dynamic>;

      debugPrint('$_tags');

      final _setData = <String, dynamic>{
        'name': _fileName,
        'content': _taggedFile.readAsStringSync(),
        'tag': _tags,
      };

      userFiles.doc('$_fileName').set(_setData);
    }
  }
}

///state = firestoreにあるアカウントのtagnames
final synctagnamesprovider =
    StateNotifierProvider((ref) => SyncTagNamesModel());

class SyncTagNamesModel extends StateNotifier<List<String>> {
  SyncTagNamesModel() : super(<String>[]);
  final _storeinstance = FirebaseFirestore.instance;

  ///files/_user.uid/にあるtagnamesをstateに入れるやつ
  Future<void> loadsynctagnames() async {
    final _user = FirebaseAuth.instance.currentUser;
    debugPrint('load called');
    if (_user == null) {
      state = [];
      debugPrint('user is null');
      return;
    }

    final synctagnames =
        ((await _storeinstance.collection('files').doc('${_user.uid}').get())
                .get('tagnames') as List<dynamic>)
            .cast<String>();

    debugPrint('state = $state');
    debugPrint('synctagnames = $synctagnames');
    debugPrint(
        'equals = ${ListEquality<String>().equals(state, synctagnames)}');

    if (!const ListEquality<String>().equals(state, synctagnames)) {
      state = synctagnames;
      return;
    }
  }

  ///storeのリストに[tagname]を追加したリストをセットするだけ
  Future<void> uploadtagname(String tagname) async {
    final _user = FirebaseAuth.instance.currentUser;
    assert(_user != null);

    final userdocument = _storeinstance.collection('files').doc('${_user.uid}');

    final synctagnames = (await userdocument.get()).get('tagnames')
        as List<dynamic>
      ..add(tagname);

    await userdocument.update(<String, dynamic>{'tagnames': synctagnames});

    await loadsynctagnames();
  }

  Future<void> deleteSyncTag(String deletetTag) async {
    final user = FirebaseAuth.instance.currentUser;
    assert(user != null);

    final synctagnames = <String>[...state];
    //synctagnames = state にしたらうまく動かない。ここではstateのデータがほしいだけなのでこれでﾖｼ

    assert(synctagnames.contains(deletetTag));

    synctagnames.removeWhere((tagname) => tagname == deletetTag);
    debugPrint('koko state = $state');

    final userdocument = _storeinstance.collection('files').doc('${user.uid}');

    final userFiles = userdocument.collection('userFiles');

    final files = await userFiles.where('tag', arrayContains: deletetTag).get();

    for (final filesnapshot in files.docs) {
      final tag = (filesnapshot.get('tag') as List<dynamic>).cast<String>()
        ..removeWhere((element) => element == deletetTag);

      await filesnapshot.reference.update(<String, dynamic>{
        'tag': tag,
      });
    }

    await userdocument.update(<String, List<String>>{'tagnames': synctagnames});

    await loadsynctagnames();

    await ProviderContainer()
        .read(taggedsyncfileprovider)
        .fetchTaggedStoreFiles();
  }
}

final localtagnamesprovider =
    StateNotifierProvider((ref) => LocalTagNamesModel());

class LocalTagNamesModel extends StateNotifier<List<String>> {
  LocalTagNamesModel() : super(<String>[...Tag.localTagFile.readAsLinesSync()]);

  void loadLocalTagnames() {
    state = Tag.localTagFile.readAsLinesSync();
  }

  void writelocalTagname(String newlocaltagname) {
    assert(Tag.localTagFile.existsSync());

    final localTagFile = Tag.localTagFile;

    final localtagnames = localTagFile.readAsLinesSync()..add(newlocaltagname);

    final str = StringBuffer();

    for (final localtagname in localtagnames) {
      str.write('$localtagname\n');
    }

    localTagFile.writeAsStringSync(str.toString().trimRight());

    loadLocalTagnames();
  }

  ///localTagFileとtagsFileJsonFileから[tTagname]を削除する
  void deletelocalTagname(String tTagname) {
    //localTagFileから削除
    final tmplist = state..removeWhere((String str) => str == tTagname);

    final stringBuffer = StringBuffer();

    for (final tagname in tmplist) {
      stringBuffer.write('\n$tagname');
    }

    Tag.localTagFile.writeAsStringSync('$stringBuffer'.trim());

    //tagsFileJsonFileから削除
    final pathTagsMap =
        (jsonDecode(FilePlusTag.tagsFileJsonFile.readAsStringSync())
                as Map<String, dynamic>)
            .cast<String, List<dynamic>>();

    for (final key in pathTagsMap.keys) {
      pathTagsMap[key].removeWhere((dynamic str) => str as String == tTagname);
    }

    FilePlusTag.tagsFileJsonFile.writeAsStringSync(jsonEncode(pathTagsMap));

    loadLocalTagnames();
  }
}

final selectedmapprovider = StateNotifierProvider((ref) => SelectedMapModel());

class SelectedMapModel extends StateNotifier<Map<String, bool>> {
  SelectedMapModel() : super(<String, bool>{});

  void createtagnamesMap(
      List<String> synctagnames, List<String> localtagnames) {
    final map = <String, bool>{};

    for (final sname in synctagnames) {
      map[sname] = false;
    }
    for (final lname in localtagnames) {
      map[lname] = false;
    }

    //state = map;
  }

  ///(true,false,false)みたいなのから真ん中の[keystr]で(false,true,false)にする
  void toggleValues(String keystr) {
    final map = state;

    for (final k in map.keys) {
      if (map[k] ?? false) {
        map[k] = false;
      }
    }

    map[keystr] = true;
  }

  String selectedTagname() {
    final map = state;

    for (final key in map.keys) {
      if (map[key] ?? false) {
        debugPrint('selectedTagname = $key');
        return key;
      }
    }
    return '';
  }
}

final selectedtagnameprovider =
    StateNotifierProvider((ref) => SelectedTagnameModel());

class SelectedTagnameModel extends StateNotifier<String> {
  SelectedTagnameModel() : super('');

  String get tagname => state;

  set tagname(String str) {
    state = str;
  }
}

final taggedsyncfileprovider =
    StateNotifierProvider((ref) => TaggedSyncFileModel());

class TaggedSyncFileModel extends StateNotifier<List<QueryDocumentSnapshot>> {
  TaggedSyncFileModel() : super(<QueryDocumentSnapshot>[]);

  Future<void> fetchTaggedStoreFiles() async {
    assert(FirebaseAuth.instance.currentUser != null);

    final user = FirebaseAuth.instance.currentUser;
    final store = FirebaseFirestore.instance;

    final userfiles =
        store.collection('files').doc('${user.uid}').collection('userFiles');

    final snapshot = await userfiles.get();

    debugPrint('syncfile state = $state');

    state = snapshot.docs;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({@required this.appDocsDirPath});

  final String appDocsDirPath;

  @override
  Widget build(BuildContext context) {
    context.read(synctagnamesprovider).loadsynctagnames();
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      title: 'Memo',
      home: Home(appDocsDirPath),
    );
  }
}

/*
ファイルとディレクトリの名前が同じだとエラー

勝手に名前付ける機能だけどそれをそのままファイルネームにするより、idか何かで管理したほうが使いやすい

入力時に文字がいっぱいだと右下がfabにかぶって押せない

リネーム時に元の名前を入れとくと使いやすい

要確認→リネーム時のタグの扱い

ログイン必須にするメリットとログインしないでいいメリットを考えると、校舎がいいのかも

ログインしたら機能が追加されるっていう感じがいいのかも

同期させるファイルとローカルのみのファイルをそもそも分けておく→タグの追加も同じタイプのみ→syncタグがなくなったらローカルのみのファイルに戻る。

TODO tagを同期させるときに同じ名前を弾く
*/
