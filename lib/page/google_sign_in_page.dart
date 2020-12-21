import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoapp/main.dart';

class GoogleSignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _context = context;
    var canPop = true;
    return WillPopScope(
      onWillPop: () async => canPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Setting'),
          backgroundColor: const Color(0xFF212121),
        ),
        body: ListView(
          children: ListTile.divideTiles(context: context, tiles: <Widget>[
            Builder(builder: (context) {
              return ListTile(
                title: const Text('Google login'),
                leading: const Icon(Icons.login),
                onTap: () async {
                  canPop = false;
                  // ignore: unawaited_futures
                  showGeneralDialog<Center>(
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

                    await context.read(synctagnamesprovider).loadsynctagnames();
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
                onLongPress: () {},
              );
            }),
            ListTile(
              title: const Text('logout'),
              leading: const Icon(Icons.logout),
              onTap: () async {
                try {
                  await context.read(authProvider).googleSignOut();

                  await context.read(synctagnamesprovider).loadsynctagnames();

                  Navigator.pop(context);
                } on PlatformException catch (e) {
                  debugPrint('$e');
                }
              },
              onLongPress: () {},
            ),
          ]).toList(),
        ),
      ),
    );
  }
}
