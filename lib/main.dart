import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wifi_p2p_demo_app/src/page/demo_connected_page.dart';
import 'package:wifi_p2p_demo_app/src/page/demo_home_page.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WiFi-P2P Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const DemoHomePage(),
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
    );
  }

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DemoHomePage(),
      ),

    ],
  );
}
