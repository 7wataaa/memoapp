import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:memoapp/file_plus_tag.dart';
import 'package:memoapp/page/home_page.dart';
import 'package:memoapp/tag.dart';
import 'package:screen/screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProviderContainer()
      .read(firebaseInitializeProvider)
      .initializeFlutterApp();
  runApp(ProviderScope(child: MyApp()));
  Screen.keepOn(true); //完成したら消す
}

class ModeModel extends ChangeNotifier {
  bool isTagmode = false;

  ///tagmode rootmodeの切り替えの通知
  void onModeSwitch() {
    isTagmode = !isTagmode;
    notifyListeners();
  }
}

final modeProvider = ChangeNotifierProvider.autoDispose((ref) => ModeModel());

class FirebaseInitializeModel extends ChangeNotifier {
  bool initialized = false;
  bool error = false;

  Future<void> initializeFlutterApp() async {
    try {
      await Firebase.initializeApp();
      initialized = true;
      debugPrint('$initialized');
      notifyListeners();
    } catch (e) {
      debugPrint('$e');
      error = true;
      notifyListeners();
    }
  }
}

final firebaseInitializeProvider =
    ChangeNotifierProvider((ref) => FirebaseInitializeModel());

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

    return auth.signInWithCredential(credential);
  }

  Future<void> googleSignOut() async {
    await auth.signOut();
  }
}

final authProvider =
    ChangeNotifierProvider.autoDispose((ref) => FirebaseAuthModel());

class FireStoreModel extends ChangeNotifier {
  FirebaseFirestore store = FirebaseFirestore.instance;
  final _users = FirebaseFirestore.instance.collection('users');

  void createMemoUser() {
    final _currentUser = FirebaseAuth.instance.currentUser;

    final _currentUsersFiles = store
        .collection('files')
        .doc("${_currentUser.uid}'sFiles")
          ..set(<String, dynamic>{
            'tagnames': Tag.syncTagFile.readAsLinesSync()
          }); //ガバ

    final _tmpCurrentUserData = <String, dynamic>{
      'uid': _currentUser.uid,
      'files': _currentUsersFiles,
    };

    _users.doc('${_currentUser.uid}').set(_tmpCurrentUserData);
  }

  //TODO そのタグが付いているファイルを同期させる
  //readytagfileからそのタグが付いているファイルを持ってきてどうにかする
  void addTaggedFiles(String tagname) {
    final _currentUser = FirebaseAuth.instance.currentUser;

    final _ownFiles = store
        .collection('files')
        .doc("${_currentUser.uid}'sFiles")
        .collection('ownFiles');

    final _taggedFileJson =
        jsonDecode(FilePlusTag.tagsFileJsonFile.readAsStringSync())
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

      _ownFiles.doc('$_fileName').set(_setData);
    }
  }
}

final firestoreProvider =
    ChangeNotifierProvider.autoDispose((ref) => FireStoreModel());

class SyncTagNamesModel extends StateNotifier<List<String>> {
  SyncTagNamesModel() : super(<String>[]);

  Future<void> load() async {
    final _user = FirebaseAuth.instance.currentUser;
    debugPrint('load called');
    if (_user == null) {
      state = [];
      debugPrint('_user == null');
      return;
    }

    final _tagnames = ((await FirebaseFirestore.instance
                .collection('files')
                .doc("${_user.uid}'sFiles")
                .get())
            .data()['tagnames'] as List<dynamic>)
        .cast<String>();

    if (!const ListEquality<String>().equals(state, _tagnames)) {
      state = _tagnames;
      return;
    }
  }
}

///state = firestoreにあるアカウントのtagnames
final synctagnamesprovider =
    StateNotifierProvider((ref) => SyncTagNamesModel());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      home: Home(),
    );
  }
}

/*
ファイルとディレクトリの名前が同じだとエラー

勝手に名前付ける機能だけどそれをそのままファイルネームにするより、idか何かで管理したほうが使いやすい

入力時に文字がいっぱいだと右下がfabにかぶって押せない

リネーム時に元の名前を入れとくと使いやすい
*/
