import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    final googleUser = await GoogleSignIn().signIn();

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
  final users = FirebaseFirestore.instance.collection('users');

  void addCurrentUser() {
    final _user = FirebaseAuth.instance.currentUser;
    final _currentUserData = <String, dynamic>{
      'uid': _user.uid,
      //'name': _user.displayName,
      //TODO このユーザーのファイル置き場を指定する
    };

    users.doc('${FirebaseAuth.instance.currentUser.uid}').set(_currentUserData);
  }

  //TODO ファイル置き場を作成する

}

final firestoreProvider =
    ChangeNotifierProvider.autoDispose((ref) => FireStoreModel());

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
