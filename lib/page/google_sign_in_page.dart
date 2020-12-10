import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoapp/main.dart';

class GoogleSignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var canPop = true;
    return WillPopScope(
      onWillPop: () async => canPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('sign_in Page'),
          backgroundColor: const Color(0xFF212121),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RaisedButton(
                child: const Text('email login'),
                onPressed: () {},
              ),
              Builder(
                builder: (context) => RaisedButton(
                  child: const Text('google login'),
                  onPressed: () async {
                    canPop = false;
                    await showGeneralDialog<Center>(
                      context: context,
                      barrierDismissible: false,
                      pageBuilder: (context, animation, secondanimation) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );
                    try {
                      await context.read(authProvider).signInWithGoogle();

                      await context
                          .read(synctagnamesprovider)
                          .loadsynctagnames();
                    } on PlatformException catch (e) {
                      debugPrint('$e');
                    }

                    Navigator.pop(context);

                    Scaffold.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'ログインしました!',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                    canPop = true;
                  },
                ),
              ),
              RaisedButton(
                child: const Text('logout'),
                onPressed: () async {
                  try {
                    await context.read(authProvider).googleSignOut();

                    await context.read(synctagnamesprovider).loadsynctagnames();

                    Navigator.pop(context);
                  } on PlatformException catch (e) {
                    debugPrint('$e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
