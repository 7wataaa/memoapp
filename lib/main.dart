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
  Future<void> initializeFlutterApp() async {
    await Firebase.initializeApp();
    notifyListeners();
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

    final authuser = await auth.signInWithCredential(credential);

    if (authuser.additionalUserInfo.isNewUser) {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Error();
      }

      //firestoreの雛形的なものを作成する
      FirebaseFirestore.instance
          .collection('files')
          .doc('${currentUser.uid}')
          .set(<String, dynamic>{'tagnames': <String>[]});
    }
  }

  Future<void> googleSignOut() async {
    await auth.signOut();
  }
}

final authProvider =
    ChangeNotifierProvider.autoDispose((ref) => FirebaseAuthModel());

class FireStoreModel extends ChangeNotifier {
  FirebaseFirestore store = FirebaseFirestore.instance;

  void uploadTaggedFiles(String tagname) {
    final _currentUser = FirebaseAuth.instance.currentUser;

    final _ownFiles = store
        .collection('files')
        .doc('${_currentUser.uid}')
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

  Future<void> loadsynctagnames() async {
    final storeinstance = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('load called');
    if (user == null) {
      state = [];
      debugPrint('user == null');
      return;
    }

    final _tagnames =
        ((await storeinstance.collection('files').doc('${user.uid}').get())
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

要確認→リネーム時のタグの扱い

ログイン必須にするメリットとログインしないでいいメリットを考えると、校舎がいいのかも

ログインしたら機能が追加されるっていう感じがいいのかも
*/
