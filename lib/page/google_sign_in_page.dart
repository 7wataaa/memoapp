import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoapp/main.dart';

class GoogleSignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            RaisedButton(
              child: const Text('google login'),
              onPressed: () async {
                try {
                  await context.read(authProvider).signInWithGoogle();
                  debugPrint('koko');
                  await context.read(synctagnamesprovider).loadsynctagnames();

                  Navigator.pop(context);
                } on PlatformException catch (e) {
                  debugPrint('$e');
                }
                //Navigator.pop(context);
              },
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
    );
  }
}
